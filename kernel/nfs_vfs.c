//
// NFS VFS integration layer
// Connects NFS protocol to VFS layer
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
#include "net.h"
#include "nfs.h"

// NFS inode private data
struct nfs_inode_info {
  struct nfs_fh fh;
  struct nfs_mount *mnt;
  uint64 cache_time;
  int cached_valid;
  struct nfs_fattr cached_attr;
};

// Convert NFS file type to xv6 type
static short
nfs_type_to_xv6(uint32 nfs_type)
{
  switch(nfs_type) {
    case NFREG: return T_FILE;
    case NFDIR: return T_DIR;
    case NFCHR:
    case NFBLK: return T_DEVICE;
    default:    return T_FILE;
  }
}

// NFS file read operation
static int
nfs_file_read(struct file *f, uint64 addr, int n)
{
  struct inode *ip = f->ip;
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;
  uchar buf[1024];
  int total = 0;

  while(n > 0) {
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;
    uint32 bytes_read = 0;

    int r = nfs_read(nfs_ip->mnt, &nfs_ip->fh, f->off, chunk, buf, &bytes_read);

    if(r < 0)
      break;

    if(bytes_read == 0)
      break;

    // Copy to user space
    if(copyout(myproc()->pagetable, addr, (char *)buf, bytes_read) < 0)
      return -1;

    f->off += bytes_read;
    addr += bytes_read;
    total += bytes_read;
    n -= bytes_read;

    if(bytes_read < chunk)
      break;
  }

  return total;
}

// NFS file write operation
static int
nfs_file_write(struct file *f, uint64 addr, int n)
{
  struct inode *ip = f->ip;
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;
  uchar buf[1024];
  int total = 0;

  while(n > 0) {
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;

    // Copy from user space
    if(copyin(myproc()->pagetable, (char *)buf, addr, chunk) < 0)
      return -1;

    int w = nfs_write(nfs_ip->mnt, &nfs_ip->fh, f->off, chunk, buf);

    if(w <= 0)
      break;

    f->off += w;
    addr += w;
    total += w;
    n -= w;

    if(w < chunk)
      break;
  }

  return total;
}

static struct file_operations nfs_file_ops = {
  .read = nfs_file_read,
  .write = nfs_file_write,
  .open = 0,
  .release = 0,
};

// NFS lookup operation (VFS inode operation)
static int
nfs_vfs_lookup(struct inode *dir, const char *name, struct inode **result)
{
  struct nfs_inode_info *nfs_dir = (struct nfs_inode_info *)dir->i_private;
  struct nfs_fh fh;
  struct nfs_fattr attr;

  // Call NFS protocol lookup
  if(nfs_lookup(nfs_dir->mnt, &nfs_dir->fh, name, &fh, &attr) < 0)
    return -1;

  // Allocate new inode
  struct inode *ip = ialloc(0, nfs_type_to_xv6(attr.type));
  if(!ip)
    return -1;

  // Fill in inode
  ip->i_sb = dir->i_sb;
  ip->i_op = dir->i_op;
  ip->i_fop = &nfs_file_ops;
  ip->type = nfs_type_to_xv6(attr.type);
  ip->size = attr.size;
  ip->nlink = attr.nlink;
  ip->valid = 1;

  // Allocate and fill private data
  struct nfs_inode_info *nfs_ip = kalloc();
  if(!nfs_ip) {
    iput(ip);
    return -1;
  }

  memmove(&nfs_ip->fh, &fh, sizeof(fh));
  nfs_ip->mnt = nfs_dir->mnt;
  nfs_ip->cached_valid = 1;
  memmove(&nfs_ip->cached_attr, &attr, sizeof(attr));
  ip->i_private = nfs_ip;

  *result = ip;
  return 0;
}

// NFS getattr operation
static int
nfs_getattr(struct inode *ip, struct stat *st)
{
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;

  // Use cached attributes if valid
  if(nfs_ip->cached_valid) {
    st->dev = 0;
    st->ino = nfs_ip->cached_attr.fileid;
    st->type = ip->type;
    st->nlink = nfs_ip->cached_attr.nlink;
    st->size = nfs_ip->cached_attr.size;
    return 0;
  }

  // Fetch fresh attributes
  struct nfs_fattr attr;
  if(nfs_getattr(nfs_ip->mnt, &nfs_ip->fh, &attr) < 0)
    return -1;

  st->dev = 0;
  st->ino = attr.fileid;
  st->type = ip->type;
  st->nlink = attr.nlink;
  st->size = attr.size;

  // Update cache
  memmove(&nfs_ip->cached_attr, &attr, sizeof(attr));
  nfs_ip->cached_valid = 1;

  return 0;
}

static struct inode_operations nfs_inode_ops = {
  .lookup = nfs_vfs_lookup,
  .create = 0,       // TODO
  .link = 0,
  .unlink = 0,
  .mkdir = 0,
  .rmdir = 0,
  .getattr = nfs_getattr,
};

static struct super_operations nfs_super_ops = {
  .alloc_inode = 0,
  .destroy_inode = 0,
  .write_inode = 0,
  .put_super = 0,
  .statfs = 0,
};

// Parse NFS mount options
// Format: "server_ip:/path" or just "server_ip"
static int
parse_nfs_mount(const char *source, uint32 *server_ip, char *path)
{
  // For simplicity, assume source is just IP address in dotted notation
  // or hex format. In real implementation, parse properly.
  // For now, use configured server IP
  *server_ip = NET_GATEWAY;  // Use gateway as NFS server
  safestrcpy(path, "/export", MAXPATH);
  return 0;
}

// NFS mount function
struct superblock*
nfs_mount(uint dev, void *data)
{
  struct superblock *sb;
  struct nfs_mount *mnt;
  uint32 server_ip;
  char path[MAXPATH];

  // Parse mount options
  if(parse_nfs_mount((const char *)data, &server_ip, path) < 0)
    return 0;

  // Allocate VFS superblock
  sb = (struct superblock*)kalloc();
  if(!sb)
    return 0;

  // Allocate NFS mount info
  mnt = (struct nfs_mount*)kalloc();
  if(!mnt) {
    kfree(sb);
    return 0;
  }

  // Initialize mount
  mnt->server_ip = server_ip;
  mnt->port = NFS_PORT;

  // Get root file handle via MOUNT protocol
  // For simplicity, assume we have it. In real implementation,
  // would call MOUNT protocol to get root FH.
  // For now, zero FH (server should handle root)
  memset(&mnt->root_fh, 0, sizeof(mnt->root_fh));

  // Test connection
  if(nfs_null(mnt) < 0) {
    printf("nfs_mount: cannot contact NFS server\n");
    kfree(mnt);
    kfree(sb);
    return 0;
  }

  // Initialize VFS superblock
  sb->dev = 0;  // No device for network FS
  sb->s_op = &nfs_super_ops;
  sb->s_fs_info = mnt;
  sb->s_blocksize = 8192;
  initlock(&sb->s_lock, "nfs_sb");

  // Create root inode
  sb->s_root = ialloc(0, T_DIR);
  if(!sb->s_root) {
    kfree(mnt);
    kfree(sb);
    return 0;
  }

  // Initialize root inode
  sb->s_root->i_sb = sb;
  sb->s_root->i_op = &nfs_inode_ops;
  sb->s_root->i_fop = &nfs_file_ops;
  sb->s_root->type = T_DIR;
  sb->s_root->valid = 1;

  // Allocate root inode private data
  struct nfs_inode_info *nfs_root = kalloc();
  if(!nfs_root) {
    iput(sb->s_root);
    kfree(mnt);
    kfree(sb);
    return 0;
  }

  memmove(&nfs_root->fh, &mnt->root_fh, sizeof(mnt->root_fh));
  nfs_root->mnt = mnt;
  nfs_root->cached_valid = 0;
  sb->s_root->i_private = nfs_root;

  printf("nfs_mount: mounted NFS from %x\n", server_ip);
  return sb;
}

static struct filesystem_type nfs_type = {
  .name = "nfs",
  .fs_flags = 0,  // No device required
  .mount = nfs_mount,
  .kill_sb = 0,   // TODO
};

// Register NFS filesystem
int
nfs_register(void)
{
  safestrcpy(nfs_type.name, "nfs", 16);
  return vfs_register_filesystem(&nfs_type);
}
