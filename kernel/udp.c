//
// User Datagram Protocol (UDP)
//

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "net.h"

static struct udp_socket udp_sockets[MAX_UDP_SOCKETS];
static struct spinlock udp_lock;

void
udp_init(void)
{
  initlock(&udp_lock, "udp");
  memset(udp_sockets, 0, sizeof(udp_sockets));
}

// Bind to a UDP port
int
udp_bind(ushort port, void (*handler)(uint32, ushort, void*, int))
{
  acquire(&udp_lock);

  // Check if port already in use
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    if(udp_sockets[i].used && udp_sockets[i].port == port) {
      release(&udp_lock);
      return -1;
    }
  }

  // Find free socket
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    if(!udp_sockets[i].used) {
      udp_sockets[i].used = 1;
      udp_sockets[i].port = port;
      udp_sockets[i].handler = handler;
      release(&udp_lock);
      return i;
    }
  }

  release(&udp_lock);
  return -1;  // No free sockets
}

// Send a UDP packet
int
udp_send(uint32 dst_ip, ushort dst_port, ushort src_port, void *data, int len)
{
  uchar *packet = kalloc();
  struct udp_hdr *hdr = (struct udp_hdr *)packet;

  if(len > 1500 - sizeof(struct udp_hdr)){
    kfree(packet);
    return -1;
  }

  // Build UDP header
  hdr->src_port = htons(src_port);
  hdr->dst_port = htons(dst_port);
  hdr->len = htons(sizeof(struct udp_hdr) + len);
  hdr->checksum = 0;  // Optional for IPv4

  // Copy payload
  memmove(packet + sizeof(struct udp_hdr), data, len);

  kfree(packet);

  // Send via IP layer
  return ip_send(dst_ip, IP_PROTO_UDP, packet, sizeof(struct udp_hdr) + len);
}

// Receive and process UDP packet
void
udp_recv(uint32 src_ip, void *data, int len)
{
  if(len < sizeof(struct udp_hdr))
    return;

  struct udp_hdr *hdr = (struct udp_hdr *)data;
  void *payload = data + sizeof(struct udp_hdr);
  int payload_len = ntohs(hdr->len) - sizeof(struct udp_hdr);
  ushort dst_port = ntohs(hdr->dst_port);
  ushort src_port = ntohs(hdr->src_port);

  if(payload_len < 0 || payload_len > len - sizeof(struct udp_hdr))
    return;

  // Find socket and deliver packet
  acquire(&udp_lock);
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    if(udp_sockets[i].used && udp_sockets[i].port == dst_port) {
      if(udp_sockets[i].handler) {
        release(&udp_lock);
        udp_sockets[i].handler(src_ip, src_port, payload, payload_len);
        return;
      }
      break;
    }
  }
  release(&udp_lock);

  // No handler for this port, drop packet
}

// Unbind from a UDP port
void
udp_unbind(int sock)
{
  if(sock < 0 || sock >= MAX_UDP_SOCKETS)
    return;

  acquire(&udp_lock);
  udp_sockets[sock].used = 0;
  udp_sockets[sock].port = 0;
  udp_sockets[sock].handler = 0;
  release(&udp_lock);
}
