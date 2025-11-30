#ifndef VFS_H
#define VFS_H

// Virtual File System (VFS) layer for xv6
// Provides abstraction for multiple filesystem types

// Forward declarations
struct inode;
struct file;
struct stat;
struct superblock;
struct filesystem_type;
struct vfsmount;

// Superblock operations (filesystem-level)
struct super_operations {
  struct inode* (*alloc_inode)(struct superblock *sb);
  void (*destroy_inode)(struct inode *ip);
  void (*write_inode)(struct inode *ip);
  void (*put_super)(struct superblock *sb);
  int (*statfs)(struct superblock *sb, void *buf);
};

// Inode operations (file metadata operations)
struct inode_operations {
  int (*lookup)(struct inode *dir, const char *name, struct inode **result);
  int (*create)(struct inode *dir, const char *name, short type, struct inode **result);
  int (*link)(struct inode *old, struct inode *dir, const char *name);
  int (*unlink)(struct inode *dir, const char *name);
  int (*mkdir)(struct inode *dir, const char *name);
  int (*rmdir)(struct inode *dir, const char *name);
  int (*getattr)(struct inode *ip, struct stat *st);
};

// File operations (data access operations)
struct file_operations {
  int (*read)(struct file *f, uint64 addr, int n);
  int (*write)(struct file *f, uint64 addr, int n);
  int (*open)(struct inode *ip, struct file *f);
  int (*release)(struct inode *ip, struct file *f);
};

// Generic superblock (wraps filesystem-specific superblocks)
struct superblock {
  uint dev;                          // Device number (0 for network FS)
  struct super_operations *s_op;     // Superblock operations
  void *s_fs_info;                   // Filesystem-specific data
  struct filesystem_type *s_type;    // Filesystem type
  struct inode *s_root;              // Root inode
  int s_blocksize;                   // Block size
  struct spinlock s_lock;            // Superblock lock
};

// Filesystem type registry
#define FS_REQUIRES_DEV  0x0001      // Filesystem requires a device

struct filesystem_type {
  char name[16];                     // "xv6fs", "nfs", etc.
  int fs_flags;                      // FS_REQUIRES_DEV, etc.
  struct superblock* (*mount)(uint dev, void *data);
  void (*kill_sb)(struct superblock *sb);
  struct filesystem_type *next;      // Linked list of FS types
};

// Mount table entry
struct vfsmount {
  struct superblock *mnt_sb;         // Mounted filesystem's superblock
  struct inode *mnt_mountpoint;      // Inode where it's mounted
  struct inode *mnt_root;            // Root inode of mounted fs
  struct vfsmount *mnt_parent;       // Parent mount (NULL for root)
  char mnt_devname[16];              // Device name for reference
  char mnt_dirname[MAXPATH];         // Mount point path
  struct vfsmount *next;             // Linked list
};

// Global VFS data
extern struct vfsmount *vfs_root_mnt;
extern struct filesystem_type *filesystems;
extern struct spinlock vfs_lock;

// VFS core functions
void vfs_init(void);
int vfs_register_filesystem(struct filesystem_type *fs);
int vfs_mount(const char *dev, const char *mountpoint, const char *type, void *data);
int vfs_umount(const char *mountpoint);
struct inode* vfs_namei(const char *path);
struct inode* vfs_nameiparent(const char *path, char *name);
int vfs_open(struct inode *ip, struct file *f);
int vfs_read(struct file *f, uint64 addr, int n);
int vfs_write(struct file *f, uint64 addr, int n);
int vfs_stat(struct inode *ip, struct stat *st);
int vfs_create(struct inode *dir, const char *name, short type, struct inode **result);
int vfs_mkdir(struct inode *dir, const char *name);
int vfs_unlink(struct inode *dir, const char *name);
int vfs_link(struct inode *ip, struct inode *dir, const char *name);

// Mount point helpers
struct vfsmount* vfs_find_mount(const char *path);
int vfs_is_mountpoint(struct inode *ip);

#endif
