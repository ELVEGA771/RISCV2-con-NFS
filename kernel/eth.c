//
// Ethernet layer
//

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "net.h"

// Local MAC address (can be configured)
uchar local_mac[ETH_ADDR_LEN] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x56};

// Send an Ethernet frame
int
eth_send(uchar *dst_mac, ushort type, void *payload, int len)
{
  uchar packet[1514];  // Max Ethernet frame
  struct eth_hdr *hdr = (struct eth_hdr *)packet;

  if(len > 1514 - sizeof(struct eth_hdr))
    return -1;

  // Build Ethernet header
  memmove(hdr->dst, dst_mac, ETH_ADDR_LEN);
  memmove(hdr->src, local_mac, ETH_ADDR_LEN);
  hdr->type = htons(type);

  // Copy payload
  memmove(packet + sizeof(struct eth_hdr), payload, len);

  // Send via network driver
  return net_send(packet, sizeof(struct eth_hdr) + len);
}

// Receive and process an Ethernet frame
void
eth_recv(void *packet, int len)
{
  if(len < sizeof(struct eth_hdr))
    return;

  struct eth_hdr *hdr = (struct eth_hdr *)packet;
  void *payload = packet + sizeof(struct eth_hdr);
  int payload_len = len - sizeof(struct eth_hdr);
  ushort type = ntohs(hdr->type);

  // Dispatch based on EtherType
  switch(type) {
    case ETH_TYPE_ARP:
      arp_recv(payload, payload_len);
      break;
    case ETH_TYPE_IP:
      ip_recv(payload, payload_len);
      break;
    default:
      // Unknown protocol, drop packet
      break;
  }
}

// Network driver calls this when a packet is received
void
net_recv(void *data, int len)
{
  eth_recv(data, len);
}
