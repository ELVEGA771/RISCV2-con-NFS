//
// Virtual File System (VFS) layer
// Provides abstraction for multiple filesystem types
//

#include "types.h"
#include "param.h"
#include "stat.h"
#include "riscv.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "proc.h"
#include "defs.h"
#include "file.h"
#include "vfs.h"

// Global VFS state
struct spinlock vfs_lock;
struct filesystem_type *filesystems = 0;
struct vfsmount *vfs_root_mnt = 0;
struct vfsmount *vfs_mounts = 0;

// VFS initialization
void
vfs_init(void)
{
  initlock(&vfs_lock, "vfs");
}

// Register a filesystem type
int
vfs_register_filesystem(struct filesystem_type *fs)
{
  if(!fs || !fs->name[0] || !fs->mount)
    return -1;

  acquire(&vfs_lock);
  fs->next = filesystems;
  filesystems = fs;
  release(&vfs_lock);

  return 0;
}

// Find a filesystem type by name
static struct filesystem_type*
vfs_find_filesystem(const char *name)
{
  struct filesystem_type *fs;

  acquire(&vfs_lock);
  for(fs = filesystems; fs; fs = fs->next) {
    if(strncmp(fs->name, name, 16) == 0) {
      release(&vfs_lock);
      return fs;
    }
  }
  release(&vfs_lock);

  return 0;
}

// Find mount by mount point path
struct vfsmount*
vfs_find_mount(const char *path)
{
  struct vfsmount *mnt;

  acquire(&vfs_lock);
  for(mnt = vfs_mounts; mnt; mnt = mnt->next) {
    if(strncmp(mnt->mnt_dirname, path, MAXPATH) == 0) {
      release(&vfs_lock);
      return mnt;
    }
  }
  release(&vfs_lock);

  return 0;
}

// Check if inode is a mount point
int
vfs_is_mountpoint(struct inode *ip)
{
  return ip->i_mount != 0;
}

// Mount a filesystem
int
vfs_mount(const char *source, const char *target, const char *fstype, void *data)
{
  struct filesystem_type *fs;
  struct superblock *sb;
  struct vfsmount *mnt;
  struct inode *mountpoint = 0;
  uint dev = ROOTDEV;

  // Find filesystem type
  fs = vfs_find_filesystem(fstype);
  if(!fs) {
    printf("vfs_mount: unknown filesystem type: %s\n", fstype);
    return -1;
  }

  // For first mount (root), target should be "/"
  if(!vfs_root_mnt) {
    if(strncmp(target, "/", MAXPATH) != 0) {
      printf("vfs_mount: first mount must be at /\n");
      return -1;
    }
  } else {
    // Find mount point inode
    mountpoint = namei((char*)target);
    if(!mountpoint) {
      printf("vfs_mount: mount point not found: %s\n", target);
      return -1;
    }

    // Check if already a mount point
    if(vfs_is_mountpoint(mountpoint)) {
      iput(mountpoint);
      printf("vfs_mount: already a mount point: %s\n", target);
      return -1;
    }
  }

  // Parse device if needed
  if(fs->fs_flags & FS_REQUIRES_DEV) {
    // In xv6, we just use ROOTDEV for now
    // TODO: Parse device name properly
    dev = ROOTDEV;
  }

  // Call filesystem mount function
  sb = fs->mount(dev, data);
  if(!sb) {
    if(mountpoint)
      iput(mountpoint);
    printf("vfs_mount: mount failed\n");
    return -1;
  }

  // Allocate vfsmount structure
  mnt = (struct vfsmount*)kalloc();
  if(!mnt) {
    if(mountpoint)
      iput(mountpoint);
    printf("vfs_mount: out of memory\n");
    return -1;
  }

  // Initialize mount
  mnt->mnt_sb = sb;
  mnt->mnt_mountpoint = mountpoint;
  mnt->mnt_root = sb->s_root;
  mnt->mnt_parent = vfs_root_mnt;
  safestrcpy(mnt->mnt_devname, source, 16);
  safestrcpy(mnt->mnt_dirname, target, MAXPATH);

  // Add to mount list
  acquire(&vfs_lock);
  mnt->next = vfs_mounts;
  vfs_mounts = mnt;

  // If this is the first mount, set as root
  if(!vfs_root_mnt) {
    vfs_root_mnt = mnt;
  } else {
    // Mark mount point
    mountpoint->i_mount = mnt;
  }

  release(&vfs_lock);

  return 0;
}

// Unmount a filesystem
int
vfs_umount(const char *target)
{
  struct vfsmount *mnt, **prev;

  // Find mount
  acquire(&vfs_lock);
  prev = &vfs_mounts;
  for(mnt = vfs_mounts; mnt; mnt = mnt->next) {
    if(strncmp(mnt->mnt_dirname, target, MAXPATH) == 0) {
      // Cannot unmount root
      if(mnt == vfs_root_mnt) {
        release(&vfs_lock);
        return -1;
      }

      // Remove from list
      *prev = mnt->next;

      // Clear mount point
      if(mnt->mnt_mountpoint) {
        mnt->mnt_mountpoint->i_mount = 0;
        iput(mnt->mnt_mountpoint);
      }

      release(&vfs_lock);

      // TODO: Call filesystem kill_sb
      // TODO: Free superblock and mount

      kfree(mnt);
      return 0;
    }
    prev = &mnt->next;
  }

  release(&vfs_lock);
  return -1;
}

// Follow a path component, handling mount points
static struct inode*
vfs_follow_mount(struct inode *ip)
{
  while(ip && vfs_is_mountpoint(ip)) {
    struct vfsmount *mnt = ip->i_mount;
    struct inode *mounted = mnt->mnt_root;
    idup(mounted);
    iput(ip);
    ip = mounted;
  }
  return ip;
}

// Path resolution with mount point handling
struct inode*
vfs_namei(const char *path)
{
  char name[DIRSIZ];
  struct inode *ip, *next;
  const char *s;
  int len;

  if(*path == '/') {
    // Absolute path - start from root mount
    if(!vfs_root_mnt || !vfs_root_mnt->mnt_root)
      return 0;
    ip = vfs_root_mnt->mnt_root;
    idup(ip);
    path++;
  } else {
    // Relative path - start from cwd
    ip = myproc()->cwd;
    idup(ip);
  }

  // Follow mount point if at one
  ip = vfs_follow_mount(ip);

  // Parse path components
  while(*path) {
    // Skip slashes
    while(*path == '/')
      path++;

    if(*path == 0)
      break;

    // Extract next component
    s = path;
    len = 0;
    while(*path && *path != '/' && len < DIRSIZ) {
      name[len++] = *path++;
    }
    name[len] = 0;

    // Look up component
    ilock(ip);

    // Check if directory
    if(ip->type != T_DIR) {
      iunlockput(ip);
      return 0;
    }

    // Use inode operations if available, otherwise fall back to namex
    if(ip->i_op && ip->i_op->lookup) {
      iunlock(ip);
      if(ip->i_op->lookup(ip, name, &next) < 0) {
        iput(ip);
        return 0;
      }
      iput(ip);
      ip = next;
    } else {
      // Fall back to original dirlookup for xv6fs
      uint off;
      if((next = dirlookup(ip, name, &off)) == 0) {
        iunlockput(ip);
        return 0;
      }
      iunlockput(ip);
      ip = next;
    }

    // Follow mount point if needed
    ip = vfs_follow_mount(ip);
  }

  return ip;
}

// Path resolution returning parent
struct inode*
vfs_nameiparent(const char *path, char *name)
{
  // For now, use the original nameiparent
  // TODO: Implement proper VFS version
  return nameiparent((char*)path, name);
}

// VFS open operation
int
vfs_open(struct inode *ip, struct file *f)
{
  if(ip->i_fop && ip->i_fop->open)
    return ip->i_fop->open(ip, f);

  // No special open needed
  return 0;
}

// VFS read operation
int
vfs_read(struct file *f, uint64 addr, int n)
{
  if(!f->readable)
    return -1;

  if(f->ip && f->ip->i_fop && f->ip->i_fop->read)
    return f->ip->i_fop->read(f, addr, n);

  return -1;
}

// VFS write operation
int
vfs_write(struct file *f, uint64 addr, int n)
{
  if(!f->writable)
    return -1;

  if(f->ip && f->ip->i_fop && f->ip->i_fop->write)
    return f->ip->i_fop->write(f, addr, n);

  return -1;
}

// VFS stat operation
int
vfs_stat(struct inode *ip, struct stat *st)
{
  if(ip->i_op && ip->i_op->getattr)
    return ip->i_op->getattr(ip, st);

  // Fall back to using inode fields directly
  st->dev = ip->dev;
  st->ino = ip->inum;
  st->type = ip->type;
  st->nlink = ip->nlink;
  st->size = ip->size;

  return 0;
}

// VFS create operation
int
vfs_create(struct inode *dir, const char *name, short type, struct inode **result)
{
  if(!dir || dir->type != T_DIR)
    return -1;

  if(dir->i_op && dir->i_op->create)
    return dir->i_op->create(dir, name, type, result);

  return -1;
}

// VFS mkdir operation
int
vfs_mkdir(struct inode *dir, const char *name)
{
  if(!dir || dir->type != T_DIR)
    return -1;

  if(dir->i_op && dir->i_op->mkdir)
    return dir->i_op->mkdir(dir, name);

  return -1;
}

// VFS unlink operation
int
vfs_unlink(struct inode *dir, const char *name)
{
  if(!dir || dir->type != T_DIR)
    return -1;

  if(dir->i_op && dir->i_op->unlink)
    return dir->i_op->unlink(dir, name);

  return -1;
}

// VFS link operation
int
vfs_link(struct inode *ip, struct inode *dir, const char *name)
{
  if(!ip || !dir || dir->type != T_DIR)
    return -1;

  if(dir->i_op && dir->i_op->link)
    return dir->i_op->link(ip, dir, name);

  return -1;
}
