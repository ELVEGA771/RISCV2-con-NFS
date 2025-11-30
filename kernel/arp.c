//
// Address Resolution Protocol (ARP)
//

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "net.h"

struct arp_entry {
  uint32 ip;
  uchar mac[ETH_ADDR_LEN];
  int valid;
};

static struct arp_entry arp_cache[ARP_CACHE_SIZE];
static struct spinlock arp_lock;

void
arp_init(void)
{
  initlock(&arp_lock, "arp");
  memset(arp_cache, 0, sizeof(arp_cache));
}

// Look up MAC address for IP
int
arp_lookup(uint32 ip, uchar *mac)
{
  acquire(&arp_lock);
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    if(arp_cache[i].valid && arp_cache[i].ip == ip) {
      memmove(mac, arp_cache[i].mac, ETH_ADDR_LEN);
      release(&arp_lock);
      return 0;
    }
  }
  release(&arp_lock);
  return -1;
}

// Add or update ARP cache entry
void
arp_add(uint32 ip, uchar *mac)
{
  acquire(&arp_lock);

  // Check if already exists
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    if(arp_cache[i].valid && arp_cache[i].ip == ip) {
      memmove(arp_cache[i].mac, mac, ETH_ADDR_LEN);
      release(&arp_lock);
      return;
    }
  }

  // Find free slot
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    if(!arp_cache[i].valid) {
      arp_cache[i].ip = ip;
      memmove(arp_cache[i].mac, mac, ETH_ADDR_LEN);
      arp_cache[i].valid = 1;
      release(&arp_lock);
      return;
    }
  }

  // Cache full, replace first entry
  arp_cache[0].ip = ip;
  memmove(arp_cache[0].mac, mac, ETH_ADDR_LEN);
  arp_cache[0].valid = 1;

  release(&arp_lock);
}

// Send ARP request
int
arp_request(uint32 ip)
{
  struct arp_packet req;
  uchar broadcast[ETH_ADDR_LEN] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};

  // Build ARP request
  req.htype = htons(ARP_HW_ETHER);
  req.ptype = htons(ARP_PROTO_IP);
  req.hlen = ETH_ADDR_LEN;
  req.plen = 4;
  req.op = htons(ARP_OP_REQUEST);
  memmove(req.sha, local_mac, ETH_ADDR_LEN);
  req.spa = htonl(local_ip);
  memset(req.tha, 0, ETH_ADDR_LEN);
  req.tpa = htonl(ip);

  return eth_send(broadcast, ETH_TYPE_ARP, &req, sizeof(req));
}

// Process received ARP packet
void
arp_recv(void *data, int len)
{
  if(len < sizeof(struct arp_packet))
    return;

  struct arp_packet *arp = (struct arp_packet *)data;

  // Validate packet
  if(ntohs(arp->htype) != ARP_HW_ETHER ||
     ntohs(arp->ptype) != ARP_PROTO_IP ||
     arp->hlen != ETH_ADDR_LEN ||
     arp->plen != 4)
    return;

  uint32 spa = ntohl(arp->spa);
  uint32 tpa = ntohl(arp->tpa);
  ushort op = ntohs(arp->op);

  // Add sender to cache
  arp_add(spa, arp->sha);

  if(op == ARP_OP_REQUEST) {
    // Is request for us?
    if(tpa == local_ip) {
      // Send ARP reply
      struct arp_packet reply;
      reply.htype = htons(ARP_HW_ETHER);
      reply.ptype = htons(ARP_PROTO_IP);
      reply.hlen = ETH_ADDR_LEN;
      reply.plen = 4;
      reply.op = htons(ARP_OP_REPLY);
      memmove(reply.sha, local_mac, ETH_ADDR_LEN);
      reply.spa = htonl(local_ip);
      memmove(reply.tha, arp->sha, ETH_ADDR_LEN);
      reply.tpa = arp->spa;

      eth_send(arp->sha, ETH_TYPE_ARP, &reply, sizeof(reply));
    }
  } else if(op == ARP_OP_REPLY) {
    // ARP reply already added to cache above
  }
}
