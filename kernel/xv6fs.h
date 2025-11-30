#ifndef XV6FS_H
#define XV6FS_H

// xv6 Filesystem adapter for VFS layer
// This wraps the existing xv6 filesystem to work with VFS

#include "types.h"
#include "fs.h"

// xv6fs-specific inode information
// This contains the fields that were in the old struct inode
struct xv6fs_inode_info {
  uint addrs[NDIRECT+1];            // Data block addresses
  // Other fields now in generic inode: type, major, minor, nlink, size
};

// xv6fs-specific superblock information
struct xv6fs_sb_info {
  struct superblock disk_sb;         // On-disk superblock
  int dev;                           // Device number
};

// xv6fs functions
struct superblock* xv6fs_mount(uint dev, void *data);
void xv6fs_kill_sb(struct superblock *sb);
int xv6fs_register(void);

// External operation tables
extern struct super_operations xv6fs_super_ops;
extern struct inode_operations xv6fs_inode_ops;
extern struct inode_operations xv6fs_dir_ops;
extern struct file_operations xv6fs_file_ops;

// Helper functions to convert between VFS inode and xv6fs inode info
static inline struct xv6fs_inode_info*
XV6FS_I(struct inode *ip)
{
  // For now, during transition, addrs is still in inode struct
  // Later this will return ip->i_private cast to xv6fs_inode_info*
  return (struct xv6fs_inode_info*)ip;  // Placeholder
}

#endif
