struct file {
  enum { FD_NONE, FD_PIPE, FD_INODE, FD_DEVICE } type;
  int ref; // reference count
  char readable;
  char writable;
  struct pipe *pipe; // FD_PIPE
  struct inode *ip;  // FD_INODE and FD_DEVICE
  uint off;          // FD_INODE
  short major;       // FD_DEVICE
};

#define major(dev)  ((dev) >> 16 & 0xFFFF)
#define minor(dev)  ((dev) & 0xFFFF)
#define	mkdev(m,n)  ((uint)((m)<<16| (n)))

// Forward declarations for VFS
struct superblock;
struct inode_operations;
struct file_operations;
struct vfsmount;

// in-memory copy of an inode (VFS version)
struct inode {
  uint dev;                          // Device number
  uint inum;                         // Inode number
  int ref;                           // Reference count
  struct sleeplock lock;             // Protects everything below
  int valid;                         // Inode has been read from disk?

  // VFS fields
  struct superblock *i_sb;           // Superblock pointer
  struct inode_operations *i_op;     // Inode operations
  struct file_operations *i_fop;     // File operations

  // Generic inode fields
  short type;                        // File type (T_DIR, T_FILE, T_DEVICE)
  short major;                       // Device major (for T_DEVICE)
  short minor;                       // Device minor (for T_DEVICE)
  short nlink;                       // Number of links
  uint size;                         // File size

  // Filesystem-specific data pointer
  void *i_private;                   // FS-specific inode info

  // Mount point tracking
  struct vfsmount *i_mount;          // If this is a mount point

  // Legacy xv6fs fields (for backward compatibility during transition)
  uint addrs[NDIRECT+1];             // Data block addresses (xv6fs only)
};

// map major device number to device functions.
struct devsw {
  int (*read)(int, uint64, int);
  int (*write)(int, uint64, int);
};

extern struct devsw devsw[];

#define CONSOLE 1
