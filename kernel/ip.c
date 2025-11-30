//
// Internet Protocol (IP)
//

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "net.h"

uint32 local_ip = NET_LOCAL_IP;
uint32 gateway_ip = NET_GATEWAY;
uint32 netmask = NET_NETMASK;

static uint16 ip_id = 1;
static struct spinlock ip_lock;

void
ip_init(void)
{
  initlock(&ip_lock, "ip");
}

// Calculate IP checksum
ushort
ip_checksum(void *data, int len)
{
  ushort *p = (ushort *)data;
  uint32 sum = 0;

  for(int i = 0; i < len / 2; i++)
    sum += ntohs(p[i]);

  if(len & 1)
    sum += ((uchar *)data)[len - 1] << 8;

  while(sum >> 16)
    sum = (sum & 0xFFFF) + (sum >> 16);

  return ~sum;
}

// Send an IP packet
int
ip_send(uint32 dst_ip, uchar proto, void *data, int len)
{
  uchar packet[1500];
  struct ip_hdr *hdr = (struct ip_hdr *)packet;
  uchar dst_mac[ETH_ADDR_LEN];
  uint32 next_hop;

  if(len > 1500 - sizeof(struct ip_hdr))
    return -1;

  // Determine next hop
  if((dst_ip & netmask) == (local_ip & netmask)) {
    // Same network
    next_hop = dst_ip;
  } else {
    // Different network, use gateway
    next_hop = gateway_ip;
  }

  // Resolve MAC address
  if(arp_lookup(next_hop, dst_mac) < 0) {
    // MAC not in cache, send ARP request
    arp_request(next_hop);
    // In real implementation, queue packet
    return -1;
  }

  // Build IP header
  hdr->ver_ihl = 0x45;  // IPv4, 20 byte header
  hdr->tos = 0;
  hdr->len = htons(sizeof(struct ip_hdr) + len);

  acquire(&ip_lock);
  hdr->id = htons(ip_id++);
  release(&ip_lock);

  hdr->flags_offset = 0;
  hdr->ttl = 64;
  hdr->proto = proto;
  hdr->checksum = 0;
  hdr->src = htonl(local_ip);
  hdr->dst = htonl(dst_ip);

  // Calculate checksum
  hdr->checksum = htons(ip_checksum(hdr, sizeof(struct ip_hdr)));

  // Copy payload
  memmove(packet + sizeof(struct ip_hdr), data, len);

  // Send via Ethernet
  return eth_send(dst_mac, ETH_TYPE_IP, packet, sizeof(struct ip_hdr) + len);
}

// Receive and process IP packet
void
ip_recv(void *data, int len)
{
  if(len < sizeof(struct ip_hdr))
    return;

  struct ip_hdr *hdr = (struct ip_hdr *)data;

  // Verify version and header length
  if((hdr->ver_ihl >> 4) != 4)
    return;

  int hdr_len = (hdr->ver_ihl & 0x0F) * 4;
  if(hdr_len < sizeof(struct ip_hdr) || hdr_len > len)
    return;

  // Verify checksum
  ushort saved_checksum = hdr->checksum;
  hdr->checksum = 0;
  if(ip_checksum(hdr, hdr_len) != ntohs(saved_checksum))
    return;
  hdr->checksum = saved_checksum;

  // Check if packet is for us
  uint32 dst = ntohl(hdr->dst);
  if(dst != local_ip && dst != 0xFFFFFFFF)  // Not for us and not broadcast
    return;

  // Extract payload
  void *payload = data + hdr_len;
  int payload_len = ntohs(hdr->len) - hdr_len;

  // Dispatch based on protocol
  switch(hdr->proto) {
    case IP_PROTO_ICMP:
      // ICMP not implemented
      break;
    case IP_PROTO_UDP:
      udp_recv(ntohl(hdr->src), payload, payload_len);
      break;
    case IP_PROTO_TCP:
      // TCP not implemented
      break;
    default:
      // Unknown protocol
      break;
  }
}
