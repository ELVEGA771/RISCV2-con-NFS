#ifndef XDR_H
#define XDR_H

// External Data Representation (XDR) for RPC
// Used for encoding/decoding RPC messages

#include "types.h"

struct xdr_buf {
  uchar *data;
  int pos;
  int len;
};

// XDR initialization
void xdr_init(struct xdr_buf *xdr, void *data, int len);

// XDR encoding functions
int xdr_encode_uint32(struct xdr_buf *xdr, uint32 val);
int xdr_encode_uint64(struct xdr_buf *xdr, uint64 val);
int xdr_encode_bytes(struct xdr_buf *xdr, void *data, int len);
int xdr_encode_string(struct xdr_buf *xdr, const char *str);
int xdr_encode_opaque(struct xdr_buf *xdr, void *data, int len);

// XDR decoding functions
int xdr_decode_uint32(struct xdr_buf *xdr, uint32 *val);
int xdr_decode_uint64(struct xdr_buf *xdr, uint64 *val);
int xdr_decode_bytes(struct xdr_buf *xdr, void *data, int maxlen);
int xdr_decode_string(struct xdr_buf *xdr, char *str, int maxlen);
int xdr_decode_opaque(struct xdr_buf *xdr, void *data, int len);

// Skip bytes in XDR stream
int xdr_skip(struct xdr_buf *xdr, int n);

#endif
