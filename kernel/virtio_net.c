//
// driver for qemu's virtio network device.
// based on virtio spec v1.1 and virtio_disk.c
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "proc.h"
#include "net.h"
#include "virtio.h"

// status register bits, from qemu virtio_config.h
#define VIRTIO_CONFIG_S_ACKNOWLEDGE	1
#define VIRTIO_CONFIG_S_DRIVER		2
#define VIRTIO_CONFIG_S_DRIVER_OK	4
#define VIRTIO_CONFIG_S_FEATURES_OK	8

// device feature bits
#define VIRTIO_NET_F_MAC 	(1 << 5)

// virtio network device
// #define VIRTIO1 0x10002000L
// #define VIRTIO1_IRQ 2

// the address of virtio mmio register r.
#define R(r) ((volatile uint32 *)(VIRTIO1 + (r)))

static struct spinlock vnet_lock;

#define NUM 8

// virtio network header
struct virtio_net_hdr {
  uint8 flags;
  uint8 gso_type;
  uint16 hdr_len;
  uint16 gso_size;
  uint16 csum_start;
  uint16 csum_offset;
  uint16 num_buffers;
} __attribute__((packed));

// a single descriptor, from the spec.
#define VRING_DESC_F_NEXT  1 // chained with another descriptor
#define VRING_DESC_F_WRITE 2 // device writes (vs read)

// these are specific to virtio network.
static struct virtq_desc *rx_desc;
static struct virtq_avail *rx_avail;
static struct virtq_used *rx_used;

static struct virtq_desc *tx_desc;
static struct virtq_avail *tx_avail;
static struct virtq_used *tx_used;

// our own book-keeping.
static char rx_free[NUM];  // is a descriptor free?
static uint16 rx_used_idx; // we've looked this far in used[].

static char tx_free[NUM];
static uint16 tx_used_idx;

// Receive buffers
#define RX_BUF_SIZE 2048
static char rx_buf[NUM][RX_BUF_SIZE];

// Transmit buffer
#define TX_BUF_SIZE 2048
static char tx_buf[TX_BUF_SIZE];

static int
alloc_rx_desc()
{
  for(int i = 0; i < NUM; i++){
    if(rx_free[i]){
      rx_free[i] = 0;
      return i;
    }
  }
  return -1;
}

static int
alloc_tx_desc()
{
  for(int i = 0; i < NUM; i++){
    if(tx_free[i]){
      tx_free[i] = 0;
      return i;
    }
  }
  return -1;
}


void
virtio_net_init(void)
{
  uint32 status = 0;

  initlock(&vnet_lock, "virtio_net");

  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
     *R(VIRTIO_MMIO_VERSION) != 1 ||
     *R(VIRTIO_MMIO_DEVICE_ID) != 1 ||
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    // No virtio-net device
    return;
  }

  // Reset device
  *R(VIRTIO_MMIO_STATUS) = status;

  // Set ACKNOWLEDGE status bit
  status |= VIRTIO_CONFIG_S_ACKNOWLEDGE;
  *R(VIRTIO_MMIO_STATUS) = status;

  // Set DRIVER status bit
  status |= VIRTIO_CONFIG_S_DRIVER;
  *R(VIRTIO_MMIO_STATUS) = status;

  // Negotiate features
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
  features &= ~(1ULL << VIRTIO_NET_F_MAC);
  features &= ~(1ULL << VIRTIO_F_ANY_LAYOUT);
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;

  // Tell device that feature negotiation is complete
  status |= VIRTIO_CONFIG_S_FEATURES_OK;
  *R(VIRTIO_MMIO_STATUS) = status;

  // Re-read status to ensure FEATURES_OK is set
  status = *R(VIRTIO_MMIO_STATUS);
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    panic("virtio net FEATURES_OK unset");

  // Initialize RX queue (queue 0)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;

  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
  if(max == 0)
    panic("virtio net has no queue 0");
  if(max < NUM)
    panic("virtio net max queue too short");

  // Allocate and zero queue memory
  rx_desc = kalloc();
  rx_avail = kalloc();
  rx_used = kalloc();
  if(!rx_desc || !rx_avail || !rx_used)
    panic("virtio net rx kalloc");
  memset(rx_desc, 0, PGSIZE);
  memset(rx_avail, 0, PGSIZE);
  memset(rx_used, 0, PGSIZE);

  // Set queue size
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;

  // Write physical addresses
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)rx_desc;
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)rx_desc >> 32;
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)rx_avail;
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)rx_avail >> 32;
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)rx_used;
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)rx_used >> 32;

  // Queue is ready
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;

  // All NUM descriptors start out unused
  for(int i = 0; i < NUM; i++)
    rx_free[i] = 1;

  // Initialize TX queue (queue 1)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 1;

  tx_desc = kalloc();
  tx_avail = kalloc();
  tx_used = kalloc();
  if(!tx_desc || !tx_avail || !tx_used)
    panic("virtio net tx kalloc");
  memset(tx_desc, 0, PGSIZE);
  memset(tx_avail, 0, PGSIZE);
  memset(tx_used, 0, PGSIZE);

  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)tx_desc;
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)tx_desc >> 32;
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)tx_avail;
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)tx_avail >> 32;
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)tx_used;
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)tx_used >> 32;
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;

  for(int i = 0; i < NUM; i++)
    tx_free[i] = 1;

  // Tell device we're completely ready
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
  *R(VIRTIO_MMIO_STATUS) = status;

  // Prepare receive buffers
  for(int i = 0; i < NUM; i++) {
    int idx = alloc_rx_desc();
    if(idx < 0)
      panic("virtio_net_init: no rx desc");

    rx_desc[idx].addr = (uint64)rx_buf[i];
    rx_desc[idx].len = RX_BUF_SIZE;
    rx_desc[idx].flags = VRING_DESC_F_WRITE;
    rx_desc[idx].next = 0;

    rx_avail->ring[rx_avail->idx % NUM] = idx;
    __sync_synchronize();
    rx_avail->idx++;
  }

  // Notify device about RX buffers
  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;

  printf("virtio_net: initialized\n");
}

static void
free_tx_desc(int i)
{
  if(i >= NUM)
    panic("free_tx_desc");
  if(tx_free[i])
    panic("free_tx_desc");
  tx_desc[i].addr = 0;
  tx_free[i] = 1;
}

// Send a packet
int
virtio_net_send(void *data, int len)
{
  acquire(&vnet_lock);

  // Allocate TX descriptor
  int idx = alloc_tx_desc();
  if(idx < 0) {
    release(&vnet_lock);
    return -1;
  }

  // Prepend virtio net header (all zeros for simple packets)
  struct virtio_net_hdr hdr;
  memset(&hdr, 0, sizeof(hdr));

  // Copy header + data to tx buffer
  if(sizeof(hdr) + len > TX_BUF_SIZE) {
    free_tx_desc(idx);
    release(&vnet_lock);
    return -1;
  }

  memmove(tx_buf, &hdr, sizeof(hdr));
  memmove(tx_buf + sizeof(hdr), data, len);

  // Setup descriptor
  tx_desc[idx].addr = (uint64)tx_buf;
  tx_desc[idx].len = sizeof(hdr) + len;
  tx_desc[idx].flags = 0;
  tx_desc[idx].next = 0;

  // Add to avail ring
  tx_avail->ring[tx_avail->idx % NUM] = idx;
  __sync_synchronize();
  tx_avail->idx++;

  // Notify device (queue 1 for TX)
  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 1;

  // Wait for completion (simple blocking)
  while(tx_used_idx == tx_used->idx)
    ;

  // Free descriptor
  int used_idx = tx_used->ring[tx_used_idx % NUM].id;
  free_tx_desc(used_idx);
  tx_used_idx++;

  release(&vnet_lock);
  return 0;
}

// Interrupt handler
void
virtio_net_intr(void)
{
  acquire(&vnet_lock);

  // Acknowledge interrupt
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;

  // Process received packets
  while(rx_used_idx != rx_used->idx) {
    int id = rx_used->ring[rx_used_idx % NUM].id;
    int len = rx_used->ring[rx_used_idx % NUM].len;

    if(len > sizeof(struct virtio_net_hdr)) {
      // Skip virtio net header
      char *pkt = rx_buf[id] + sizeof(struct virtio_net_hdr);
      int pkt_len = len - sizeof(struct virtio_net_hdr);

      // Process packet
      net_recv(pkt, pkt_len);
    }

    // Refill RX descriptor
    rx_desc[id].addr = (uint64)rx_buf[id];
    rx_desc[id].len = RX_BUF_SIZE;
    rx_desc[id].flags = VRING_DESC_F_WRITE;

    rx_avail->ring[rx_avail->idx % NUM] = id;
    __sync_synchronize();
    rx_avail->idx++;

    rx_used_idx++;
  }

  // Notify device about new RX buffers
  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;

  release(&vnet_lock);
}

// Network layer calls this to send packets
int
net_send(void *data, int len)
{
  return virtio_net_send(data, len);
}
