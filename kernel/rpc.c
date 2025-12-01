//
// Remote Procedure Call (RPC) implementation
//

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "net.h"
#include "xdr.h"
#include "rpc.h"

static uint32 rpc_xid = 1;
static struct spinlock rpc_lock;

// RPC reply state
static int rpc_reply_received;
static uchar rpc_reply_buf[8192];
static int rpc_reply_len;
static uint32 rpc_expected_xid;

void
rpc_init(void)
{
  initlock(&rpc_lock, "rpc");
  rpc_reply_received = 0;
}

// UDP handler for RPC replies
static void
rpc_recv_handler(uint32 src_ip, ushort src_port, void *data, int len)
{
  acquire(&rpc_lock);

  // Check if we're expecting a reply
  if(len <= sizeof(rpc_reply_buf)) {
    // Decode XID to verify it's our reply
    struct xdr_buf xdr;
    xdr_init(&xdr, data, len);
    uint32 xid;
    if(xdr_decode_uint32(&xdr, &xid) == 0) {
      if(xid == rpc_expected_xid) {
        memmove(rpc_reply_buf, data, len);
        rpc_reply_len = len;
        rpc_reply_received = 1;
      }
    }
  }

  release(&rpc_lock);
}

// Make an RPC call
int
rpc_call(uint32 server_ip, ushort port, uint32 prog, uint32 vers, uint32 proc,
         void *args, int args_len, void *result, int result_max)
{
  uchar *call_buf;
  struct xdr_buf xdr;
  uint32 xid;
  int retries = 3;

  call_buf = (uchar*)kalloc();
  if(call_buf == 0)
    return -1;
  memset(call_buf, 0, PGSIZE);

  // Generate XID
  acquire(&rpc_lock);
  xid = rpc_xid++;
  rpc_expected_xid = xid;
  rpc_reply_received = 0;
  release(&rpc_lock);

  // Encode RPC call header
  xdr_init(&xdr, call_buf, sizeof(call_buf));
  xdr_encode_uint32(&xdr, xid);
  xdr_encode_uint32(&xdr, RPC_CALL);
  xdr_encode_uint32(&xdr, 2);        // RPC version
  xdr_encode_uint32(&xdr, prog);
  xdr_encode_uint32(&xdr, vers);
  xdr_encode_uint32(&xdr, proc);

  // AUTH_NULL credentials
  xdr_encode_uint32(&xdr, RPC_AUTH_NULL);
  xdr_encode_uint32(&xdr, 0);        // cred length

  // AUTH_NULL verifier
  xdr_encode_uint32(&xdr, RPC_AUTH_NULL);
  xdr_encode_uint32(&xdr, 0);        // verf length

  // Append procedure arguments
  if(args && args_len > 0) {
    if(xdr.pos + args_len > sizeof(call_buf))
      return -1;
    memmove(call_buf + xdr.pos, args, args_len);
  }

  int total_len = xdr.pos + args_len;

  // Bind to temporary port for replies
  ushort reply_port = 7000 + (xid % 1000);
  int sock = udp_bind(reply_port, rpc_recv_handler);
  if(sock < 0)
    return -1;

  // Send request with retries
  while(retries-- > 0) {
    if(udp_send(server_ip, port, reply_port, call_buf, total_len) < 0)
      continue;

    // Wait for reply with timeout
    int timeout = 100;  // ~1 second
    while(timeout-- > 0) {
      acquire(&rpc_lock);
      if(rpc_reply_received) {
        release(&rpc_lock);
        goto got_reply;
      }
      release(&rpc_lock);

      // Simple busy-wait (in real impl, use sleep)
      for(int i = 0; i < 1000000; i++)
        ;
    }
  }

  // Timeout
  udp_unbind(sock);
  return -1;

got_reply:
  // Parse reply
  xdr_init(&xdr, rpc_reply_buf, rpc_reply_len);

  uint32 reply_xid, msg_type, reply_stat, accept_stat;

  if(xdr_decode_uint32(&xdr, &reply_xid) < 0 ||
     xdr_decode_uint32(&xdr, &msg_type) < 0)
    goto bad_reply;

  if(reply_xid != xid || msg_type != RPC_REPLY)
    goto bad_reply;

  if(xdr_decode_uint32(&xdr, &reply_stat) < 0)
    goto bad_reply;

  if(reply_stat != RPC_MSG_ACCEPTED)
    goto bad_reply;

  // Skip verifier
  uint32 verf_flavor, verf_len;
  if(xdr_decode_uint32(&xdr, &verf_flavor) < 0 ||
     xdr_decode_uint32(&xdr, &verf_len) < 0)
    goto bad_reply;

  xdr_skip(&xdr, verf_len);

  if(xdr_decode_uint32(&xdr, &accept_stat) < 0)
    goto bad_reply;

  if(accept_stat != RPC_SUCCESS)
    goto bad_reply;

  // Copy result
  int result_len = rpc_reply_len - xdr.pos;
  if(result_len > result_max)
    result_len = result_max;
  if(result_len > 0)
    memmove(result, rpc_reply_buf + xdr.pos, result_len);

  udp_unbind(sock);
  release(&rpc_lock);
  kfree(call_buf);
  return result_len;

bad_reply:
  udp_unbind(sock);
  release(&rpc_lock);
  kfree(call_buf);  
  return -1;
}
