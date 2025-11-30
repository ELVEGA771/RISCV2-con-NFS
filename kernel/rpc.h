#ifndef RPC_H
#define RPC_H

// Remote Procedure Call (RPC) layer for NFS
// Implements Sun RPC (ONC RPC)

#include "types.h"

// RPC message types
#define RPC_CALL  0
#define RPC_REPLY 1

// RPC reply status
#define RPC_MSG_ACCEPTED 0
#define RPC_MSG_DENIED   1

// RPC accept status
#define RPC_SUCCESS      0
#define RPC_PROG_UNAVAIL 1
#define RPC_PROG_MISMATCH 2
#define RPC_PROC_UNAVAIL 3
#define RPC_GARBAGE_ARGS 4
#define RPC_SYSTEM_ERR   5

// Authentication flavors
#define RPC_AUTH_NULL 0
#define RPC_AUTH_UNIX 1

// RPC call structure
struct rpc_call {
  uint32 xid;
  uint32 prog;
  uint32 vers;
  uint32 proc;
  uint32 cred_flavor;
  uint32 cred_len;
  uint32 verf_flavor;
  uint32 verf_len;
};

// RPC reply structure
struct rpc_reply {
  uint32 xid;
  uint32 reply_stat;
  uint32 verf_flavor;
  uint32 verf_len;
  uint32 accept_stat;
};

// RPC functions
void rpc_init(void);
int rpc_call(uint32 server_ip, ushort port, uint32 prog, uint32 vers, uint32 proc,
             void *args, int args_len, void *result, int result_max);

#endif
