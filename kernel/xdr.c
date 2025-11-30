//
// External Data Representation (XDR) encoding/decoding
//

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "defs.h"
#include "xdr.h"

// Initialize XDR buffer
void
xdr_init(struct xdr_buf *xdr, void *data, int len)
{
  xdr->data = (uchar *)data;
  xdr->pos = 0;
  xdr->len = len;
}

// Encode uint32 (big-endian)
int
xdr_encode_uint32(struct xdr_buf *xdr, uint32 val)
{
  if(xdr->pos + 4 > xdr->len)
    return -1;

  xdr->data[xdr->pos++] = (val >> 24) & 0xFF;
  xdr->data[xdr->pos++] = (val >> 16) & 0xFF;
  xdr->data[xdr->pos++] = (val >> 8) & 0xFF;
  xdr->data[xdr->pos++] = val & 0xFF;

  return 0;
}

// Encode uint64 (big-endian)
int
xdr_encode_uint64(struct xdr_buf *xdr, uint64 val)
{
  if(xdr_encode_uint32(xdr, (uint32)(val >> 32)) < 0)
    return -1;
  if(xdr_encode_uint32(xdr, (uint32)(val & 0xFFFFFFFF)) < 0)
    return -1;
  return 0;
}

// Encode variable-length bytes
int
xdr_encode_bytes(struct xdr_buf *xdr, void *data, int len)
{
  // Encode length
  if(xdr_encode_uint32(xdr, len) < 0)
    return -1;

  // Encode data (padded to 4-byte boundary)
  int padded = (len + 3) & ~3;
  if(xdr->pos + padded > xdr->len)
    return -1;

  memmove(xdr->data + xdr->pos, data, len);

  // Zero padding
  for(int i = len; i < padded; i++)
    xdr->data[xdr->pos + i] = 0;

  xdr->pos += padded;
  return 0;
}

// Encode fixed-length opaque data
int
xdr_encode_opaque(struct xdr_buf *xdr, void *data, int len)
{
  // Encode data (padded to 4-byte boundary)
  int padded = (len + 3) & ~3;
  if(xdr->pos + padded > xdr->len)
    return -1;

  memmove(xdr->data + xdr->pos, data, len);

  // Zero padding
  for(int i = len; i < padded; i++)
    xdr->data[xdr->pos + i] = 0;

  xdr->pos += padded;
  return 0;
}

// Encode string
int
xdr_encode_string(struct xdr_buf *xdr, const char *str)
{
  return xdr_encode_bytes(xdr, (void *)str, strlen(str));
}

// Decode uint32 (big-endian)
int
xdr_decode_uint32(struct xdr_buf *xdr, uint32 *val)
{
  if(xdr->pos + 4 > xdr->len)
    return -1;

  *val = ((uint32)xdr->data[xdr->pos] << 24) |
         ((uint32)xdr->data[xdr->pos + 1] << 16) |
         ((uint32)xdr->data[xdr->pos + 2] << 8) |
         ((uint32)xdr->data[xdr->pos + 3]);

  xdr->pos += 4;
  return 0;
}

// Decode uint64 (big-endian)
int
xdr_decode_uint64(struct xdr_buf *xdr, uint64 *val)
{
  uint32 high, low;
  if(xdr_decode_uint32(xdr, &high) < 0)
    return -1;
  if(xdr_decode_uint32(xdr, &low) < 0)
    return -1;
  *val = ((uint64)high << 32) | low;
  return 0;
}

// Decode variable-length bytes
int
xdr_decode_bytes(struct xdr_buf *xdr, void *data, int maxlen)
{
  uint32 len;
  if(xdr_decode_uint32(xdr, &len) < 0)
    return -1;

  if(len > maxlen)
    return -1;

  int padded = (len + 3) & ~3;
  if(xdr->pos + padded > xdr->len)
    return -1;

  memmove(data, xdr->data + xdr->pos, len);
  xdr->pos += padded;

  return len;
}

// Decode fixed-length opaque data
int
xdr_decode_opaque(struct xdr_buf *xdr, void *data, int len)
{
  int padded = (len + 3) & ~3;
  if(xdr->pos + padded > xdr->len)
    return -1;

  memmove(data, xdr->data + xdr->pos, len);
  xdr->pos += padded;

  return len;
}

// Decode string
int
xdr_decode_string(struct xdr_buf *xdr, char *str, int maxlen)
{
  int len = xdr_decode_bytes(xdr, str, maxlen - 1);
  if(len < 0)
    return -1;
  str[len] = '\0';
  return len;
}

// Skip n bytes
int
xdr_skip(struct xdr_buf *xdr, int n)
{
  int padded = (n + 3) & ~3;
  if(xdr->pos + padded > xdr->len)
    return -1;
  xdr->pos += padded;
  return 0;
}
