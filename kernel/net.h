#ifndef NET_H
#define NET_H

// Network subsystem for xv6
// Includes Ethernet, ARP, IP, and UDP layers

#include "types.h"

// Network byte order conversion
#define htons(x) ((uint16)((((x) & 0xff) << 8) | (((x) & 0xff00) >> 8)))
#define ntohs(x) htons(x)
#define htonl(x) ((uint32)((((x) & 0xff) << 24) | (((x) & 0xff00) << 8) | \
                           (((x) & 0xff0000) >> 8) | (((x) & 0xff000000) >> 24)))
#define ntohl(x) htonl(x)

// MAC address size
#define ETH_ADDR_LEN 6

// Ethernet frame types
#define ETH_TYPE_ARP  0x0806
#define ETH_TYPE_IP   0x0800

// ARP constants
#define ARP_HW_ETHER    1
#define ARP_PROTO_IP    0x0800
#define ARP_OP_REQUEST  1
#define ARP_OP_REPLY    2
#define ARP_CACHE_SIZE  16

// IP protocol numbers
#define IP_PROTO_ICMP  1
#define IP_PROTO_TCP   6
#define IP_PROTO_UDP   17

// Network configuration (can be overridden in param.h)
#ifndef NET_LOCAL_IP
#define NET_LOCAL_IP    0x0a000202  // 10.0.2.2
#endif

#ifndef NET_GATEWAY
#define NET_GATEWAY     0x0a000201  // 10.0.2.1
#endif

#ifndef NET_NETMASK
#define NET_NETMASK     0xffffff00  // 255.255.255.0
#endif

// Ethernet header
struct eth_hdr {
  uchar dst[ETH_ADDR_LEN];
  uchar src[ETH_ADDR_LEN];
  ushort type;
} __attribute__((packed));

// ARP packet
struct arp_packet {
  ushort htype;        // Hardware type
  ushort ptype;        // Protocol type
  uchar hlen;          // Hardware address length
  uchar plen;          // Protocol address length
  ushort op;           // Operation
  uchar sha[ETH_ADDR_LEN];  // Sender hardware address
  uint32 spa;          // Sender protocol address
  uchar tha[ETH_ADDR_LEN];  // Target hardware address
  uint32 tpa;          // Target protocol address
} __attribute__((packed));

// IP header
struct ip_hdr {
  uchar ver_ihl;       // Version (4 bits) + IHL (4 bits)
  uchar tos;           // Type of service
  ushort len;          // Total length
  ushort id;           // Identification
  ushort flags_offset; // Flags (3 bits) + Fragment offset (13 bits)
  uchar ttl;           // Time to live
  uchar proto;         // Protocol
  ushort checksum;     // Header checksum
  uint32 src;          // Source IP
  uint32 dst;          // Destination IP
} __attribute__((packed));

// UDP header
struct udp_hdr {
  ushort src_port;
  ushort dst_port;
  ushort len;
  ushort checksum;
} __attribute__((packed));

// Network device interface
void net_init(void);
int net_send(void *data, int len);
void net_recv(void *data, int len);

// Ethernet layer
int eth_send(uchar *dst_mac, ushort type, void *payload, int len);
void eth_recv(void *packet, int len);
extern uchar local_mac[ETH_ADDR_LEN];

// ARP layer
void arp_init(void);
int arp_lookup(uint32 ip, uchar *mac);
void arp_add(uint32 ip, uchar *mac);
int arp_request(uint32 ip);
void arp_recv(void *data, int len);

// IP layer
void ip_init(void);
int ip_send(uint32 dst_ip, uchar proto, void *data, int len);
void ip_recv(void *data, int len);
ushort ip_checksum(void *data, int len);
extern uint32 local_ip;
extern uint32 gateway_ip;
extern uint32 netmask;

// UDP layer
void udp_init(void);
int udp_bind(ushort port, void (*handler)(uint32, ushort, void*, int));
int udp_send(uint32 dst_ip, ushort dst_port, ushort src_port, void *data, int len);
void udp_recv(uint32 src_ip, void *data, int len);

// UDP socket structure
struct udp_socket {
  int used;
  ushort port;
  void (*handler)(uint32 src_ip, ushort src_port, void *data, int len);
};

#define MAX_UDP_SOCKETS 16

#endif
