#ifndef NFS_H
#define NFS_H

// Network File System (NFS) v2 protocol

#include "types.h"

// NFS constants
#define NFS_PROGRAM  100003
#define NFS_VERSION  2
#define NFS_PORT     2049

// NFS procedures
#define NFSPROC_NULL      0
#define NFSPROC_GETATTR   1
#define NFSPROC_SETATTR   2
#define NFSPROC_ROOT      3
#define NFSPROC_LOOKUP    4
#define NFSPROC_READLINK  5
#define NFSPROC_READ      6
#define NFSPROC_WRITE     7
#define NFSPROC_CREATE    8
#define NFSPROC_REMOVE    9
#define NFSPROC_RENAME    10
#define NFSPROC_LINK      11
#define NFSPROC_SYMLINK   12
#define NFSPROC_MKDIR     13
#define NFSPROC_RMDIR     14
#define NFSPROC_READDIR   15
#define NFSPROC_STATFS    16

// NFS status codes
#define NFS_OK          0
#define NFSERR_PERM     1
#define NFSERR_NOENT    2
#define NFSERR_IO       5
#define NFSERR_NXIO     6
#define NFSERR_ACCES    13
#define NFSERR_EXIST    17
#define NFSERR_NODEV    19
#define NFSERR_NOTDIR   20
#define NFSERR_ISDIR    21
#define NFSERR_FBIG     27
#define NFSERR_NOSPC    28
#define NFSERR_ROFS     30
#define NFSERR_NAMETOOLONG 63
#define NFSERR_NOTEMPTY 66
#define NFSERR_DQUOT    69
#define NFSERR_STALE    70
#define NFSERR_WFLUSH   99

// NFS file types
#define NFNON   0
#define NFREG   1  // Regular file
#define NFDIR   2  // Directory
#define NFBLK   3  // Block device
#define NFCHR   4  // Character device
#define NFLNK   5  // Symbolic link

// NFS file handle size
#define NFS_FHSIZE 32

// NFS file handle
struct nfs_fh {
  uchar data[NFS_FHSIZE];
};

// NFS file attributes
struct nfs_fattr {
  uint32 type;
  uint32 mode;
  uint32 nlink;
  uint32 uid;
  uint32 gid;
  uint32 size;
  uint32 blocksize;
  uint32 rdev;
  uint32 blocks;
  uint32 fsid;
  uint32 fileid;
  uint32 atime_sec;
  uint32 atime_usec;
  uint32 mtime_sec;
  uint32 mtime_usec;
  uint32 ctime_sec;
  uint32 ctime_usec;
};

// NFS mount information
struct nfs_mount {
  uint32 server_ip;
  ushort port;
  struct nfs_fh root_fh;
};

// NFS operations
int nfs_null(struct nfs_mount *mnt);
int nfs_getattr(struct nfs_mount *mnt, struct nfs_fh *fh, struct nfs_fattr *attr);
int nfs_lookup(struct nfs_mount *mnt, struct nfs_fh *dir_fh, const char *name,
               struct nfs_fh *fh, struct nfs_fattr *attr);
int nfs_read(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
             uint32 count, void *buf, uint32 *bytes_read);
int nfs_write(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
              uint32 count, void *buf);

#endif
