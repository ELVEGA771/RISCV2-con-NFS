//
// xv6 Filesystem VFS adapter
// Wraps the existing xv6 filesystem to work with VFS layer
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
#include "fs.h"
#include "vfs.h"
#include "xv6fs.h"

// Wrapper for file read
static int
xv6fs_file_read(struct file *f, uint64 addr, int n)
{
  struct inode *ip = f->ip;
  int r;

  ilock(ip);
  if((r = readi(ip, 1, addr, f->off, n)) > 0)
    f->off += r;
  iunlock(ip);

  return r;
}

// Wrapper for file write
static int
xv6fs_file_write(struct file *f, uint64 addr, int n)
{
  struct inode *ip = f->ip;
  int r, ret = 0;
  int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
  int i = 0;

  while(i < n){
    int n1 = n - i;
    if(n1 > max)
      n1 = max;

    begin_op();
    ilock(ip);
    if ((r = writei(ip, 1, addr + i, f->off, n1)) > 0)
      f->off += r;
    iunlock(ip);
    end_op();

    if(r != n1)
      break;
    i += r;
  }

  return (i == n ? n : -1);
}

// File operations for xv6fs
struct file_operations xv6fs_file_ops = {
  .read = xv6fs_file_read,
  .write = xv6fs_file_write,
  .open = 0,                         // Not needed for xv6fs
  .release = 0,                      // Not needed for xv6fs
};

// Wrapper for lookup
static int
xv6fs_lookup(struct inode *dir, const char *name, struct inode **result)
{
  uint off;
  struct inode *ip;

  ilock(dir);
  ip = dirlookup(dir, (char*)name, &off);
  iunlock(dir);

  if(!ip)
    return -1;

  *result = ip;
  return 0;
}

// Wrapper for getattr
static int
xv6fs_getattr(struct inode *ip, struct stat *st)
{
  ilock(ip);
  stati(ip, st);
  iunlock(ip);
  return 0;
}

// Directory inode operations for xv6fs
struct inode_operations xv6fs_dir_ops = {
  .lookup = xv6fs_lookup,
  .create = 0,                       // TODO: Implement
  .link = 0,                         // TODO: Implement
  .unlink = 0,                       // TODO: Implement
  .mkdir = 0,                        // TODO: Implement
  .rmdir = 0,                        // TODO: Implement
  .getattr = xv6fs_getattr,
};

// Regular file inode operations for xv6fs
struct inode_operations xv6fs_inode_ops = {
  .lookup = 0,                       // Only for directories
  .create = 0,                       // Only for directories
  .link = 0,
  .unlink = 0,
  .mkdir = 0,
  .rmdir = 0,
  .getattr = xv6fs_getattr,
};

// Superblock operations for xv6fs
struct super_operations xv6fs_super_ops = {
  .alloc_inode = 0,                  // Use existing ialloc
  .destroy_inode = 0,                // Use existing iput
  .write_inode = 0,                  // Use existing iupdate
  .put_super = 0,                    // TODO: Implement
  .statfs = 0,                       // TODO: Implement
};

// Initialize inode with xv6fs operations
void
xv6fs_init_inode(struct inode *ip, struct superblock *sb)
{
  ip->i_sb = sb;

  if(ip->type == T_DIR) {
    ip->i_op = &xv6fs_dir_ops;
  } else {
    ip->i_op = &xv6fs_inode_ops;
  }

  ip->i_fop = &xv6fs_file_ops;
  ip->i_private = 0;                 // xv6fs uses fields directly in inode
  ip->i_mount = 0;
}

// Mount function for xv6fs
struct superblock*
xv6fs_mount(uint dev, void *data)
{
  struct superblock *vfs_sb;
  struct xv6fs_sb_info *sbi;

  // Allocate VFS superblock
  vfs_sb = (struct superblock*)kalloc();
  if(!vfs_sb)
    return 0;

  // Allocate xv6fs superblock info
  sbi = (struct xv6fs_sb_info*)kalloc();
  if(!sbi) {
    kfree(vfs_sb);
    return 0;
  }

  // Read disk superblock (this already happens in fsinit)
  // For now, we assume fsinit was called and just mark as mounted
  sbi->dev = dev;

  // Initialize VFS superblock
  vfs_sb->dev = dev;
  vfs_sb->s_op = &xv6fs_super_ops;
  vfs_sb->s_fs_info = sbi;
  vfs_sb->s_type = 0;                // Will be set by vfs_mount
  vfs_sb->s_blocksize = BSIZE;
  initlock(&vfs_sb->s_lock, "xv6fs_sb");

  // Get root inode (inode 1 is root)
  vfs_sb->s_root = iget(dev, ROOTINO);
  if(!vfs_sb->s_root) {
    kfree(sbi);
    kfree(vfs_sb);
    return 0;
  }

  // Initialize root inode operations
  ilock(vfs_sb->s_root);
  xv6fs_init_inode(vfs_sb->s_root, vfs_sb);
  iunlock(vfs_sb->s_root);

  return vfs_sb;
}

// Unmount function for xv6fs
void
xv6fs_kill_sb(struct superblock *sb)
{
  if(!sb)
    return;

  // Release root inode
  if(sb->s_root)
    iput(sb->s_root);

  // Free superblock info
  if(sb->s_fs_info)
    kfree(sb->s_fs_info);

  // Free VFS superblock
  kfree(sb);
}

// Filesystem type for xv6fs
static struct filesystem_type xv6fs_type = {
  .name = "xv6fs",
  .fs_flags = FS_REQUIRES_DEV,
  .mount = xv6fs_mount,
  .kill_sb = xv6fs_kill_sb,
};

// Register xv6fs with VFS
int
xv6fs_register(void)
{
  // Initialize the name
  safestrcpy(xv6fs_type.name, "xv6fs", 16);
  return vfs_register_filesystem(&xv6fs_type);
}
