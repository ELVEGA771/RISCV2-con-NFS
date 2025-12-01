//
// Network File System (NFS) v2 protocol implementation
//

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "net.h"
#include "xdr.h"
#include "rpc.h"
#include "nfs.h"

// NULL procedure (ping)
int
nfs_null(struct nfs_mount *mnt)
{
  uchar result[256];

  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_NULL, 0, 0, result, sizeof(result));

  return len >= 0 ? 0 : -1;
}

// Get file attributes
int
nfs_getattr(struct nfs_mount *mnt, struct nfs_fh *fh, struct nfs_fattr *attr)
{
  uchar args[128];
  uchar result[512];
  struct xdr_buf xdr;

  // Encode arguments (file handle)
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_opaque(&xdr, fh->data, NFS_FHSIZE);

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_GETATTR, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    return -1;

  if(status != NFS_OK)
    return -1;

  // Decode attributes
  if(xdr_decode_uint32(&xdr, &attr->type) < 0 ||
     xdr_decode_uint32(&xdr, &attr->mode) < 0 ||
     xdr_decode_uint32(&xdr, &attr->nlink) < 0 ||
     xdr_decode_uint32(&xdr, &attr->uid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->gid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->size) < 0 ||
     xdr_decode_uint32(&xdr, &attr->blocksize) < 0 ||
     xdr_decode_uint32(&xdr, &attr->rdev) < 0 ||
     xdr_decode_uint32(&xdr, &attr->blocks) < 0 ||
     xdr_decode_uint32(&xdr, &attr->fsid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->fileid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->atime_sec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->atime_usec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->mtime_sec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->mtime_usec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->ctime_sec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->ctime_usec) < 0)
    return -1;

  return 0;
}

// Look up a file name in a directory
int
nfs_lookup(struct nfs_mount *mnt, struct nfs_fh *dir_fh, const char *name,
           struct nfs_fh *fh, struct nfs_fattr *attr)
{
  uchar args[512];
  uchar result[1024];
  struct xdr_buf xdr;

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_opaque(&xdr, dir_fh->data, NFS_FHSIZE);
  xdr_encode_string(&xdr, name);

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_LOOKUP, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    return -1;

  if(status != NFS_OK)
    return -1;

  // Decode file handle
  if(xdr_decode_opaque(&xdr, fh->data, NFS_FHSIZE) < 0)
    return -1;

  // Decode attributes
  if(xdr_decode_uint32(&xdr, &attr->type) < 0 ||
     xdr_decode_uint32(&xdr, &attr->mode) < 0 ||
     xdr_decode_uint32(&xdr, &attr->nlink) < 0 ||
     xdr_decode_uint32(&xdr, &attr->uid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->gid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->size) < 0 ||
     xdr_decode_uint32(&xdr, &attr->blocksize) < 0 ||
     xdr_decode_uint32(&xdr, &attr->rdev) < 0 ||
     xdr_decode_uint32(&xdr, &attr->blocks) < 0 ||
     xdr_decode_uint32(&xdr, &attr->fsid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->fileid) < 0 ||
     xdr_decode_uint32(&xdr, &attr->atime_sec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->atime_usec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->mtime_sec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->mtime_usec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->ctime_sec) < 0 ||
     xdr_decode_uint32(&xdr, &attr->ctime_usec) < 0)
    return -1;

  return 0;
}

// Read from a file
int
nfs_read(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
         uint32 count, void *buf, uint32 *bytes_read)
{
  uchar args[256];
  uchar *result;
  struct xdr_buf xdr;

  // Limit read size
  if(count > 8192)
    count = 8192;

  result = (uchar*)kalloc();
  if(result == 0)
    return -1;
  memset(result, 0, PGSIZE);

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_opaque(&xdr, fh->data, NFS_FHSIZE);
  xdr_encode_uint32(&xdr, offset);
  xdr_encode_uint32(&xdr, count);
  xdr_encode_uint32(&xdr, 0);  // totalcount (unused in NFS v2)

  if (count > 4000) count = 4000;

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_READ, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    return -1;

  if(status != NFS_OK)
    return -1;

  // Skip attributes (17 uint32s)
  xdr_skip(&xdr, 17 * 4);

  // Decode data
  int data_len = xdr_decode_bytes(&xdr, buf, count);
  if(data_len < 0)
    return -1;

  *bytes_read = data_len;
  kfree(result);
  return 0;
}

// Write to a file
int
nfs_write(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
          uint32 count, void *buf)
{
  uchar *args;
  uchar result[512];
  struct xdr_buf xdr;

  // Limit write size
  if(count > 4000)
    count = 4000;

  args = (uchar*)kalloc();
  if(args == 0)
    return -1;
  memset(args, 0, PGSIZE);

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_opaque(&xdr, fh->data, NFS_FHSIZE);
  xdr_encode_uint32(&xdr, 0);      // beginoffset (unused)
  xdr_encode_uint32(&xdr, offset);
  xdr_encode_uint32(&xdr, 0);      // totalcount (unused)
  xdr_encode_bytes(&xdr, buf, count);

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_WRITE, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    return -1;

  if(status != NFS_OK)
    return -1;

  kfree(args);
  return count;
}
