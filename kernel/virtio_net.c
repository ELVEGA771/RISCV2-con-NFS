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

// Registros de configuración (Offsets)
#define VIRTIO_MMIO_DEVICE_FEATURES_SEL 0x014
#define VIRTIO_MMIO_DRIVER_FEATURES_SEL 0x024

// Bits de estado
#define VIRTIO_CONFIG_S_ACKNOWLEDGE 1
#define VIRTIO_CONFIG_S_DRIVER      2
#define VIRTIO_CONFIG_S_DRIVER_OK   4
#define VIRTIO_CONFIG_S_FEATURES_OK 8

// Características del dispositivo
#define VIRTIO_NET_F_MAC    (1 << 5)
#define VIRTIO_F_VERSION_1  (1ULL << 32) // Bit crítico para QEMU moderno

// DIRECCIÓN DE LA TARJETA DE RED (Encontrada en el Slot 7)
// Añadimos 'L' para que sea tratada como long
#define VIRTIO_NET_BASE 0x10008000L 

// Macro R para acceder a registros
#define R(r) ((volatile uint32 *)(VIRTIO_NET_BASE + (r)))

static struct spinlock vnet_lock;

#define NUM 8

// Estructura del header de red
struct virtio_net_hdr {
  uint8 flags;
  uint8 gso_type;
  uint16 hdr_len;
  uint16 gso_size;
  uint16 csum_start;
  uint16 csum_offset;
  uint16 num_buffers;
} __attribute__((packed));

#define VRING_DESC_F_NEXT  1
#define VRING_DESC_F_WRITE 2

// Descriptores y anillos
static struct virtq_desc *rx_desc;
static struct virtq_avail *rx_avail;
static struct virtq_used *rx_used;

static struct virtq_desc *tx_desc;
static struct virtq_avail *tx_avail;
static struct virtq_used *tx_used;

static char rx_free[NUM];
static uint16 rx_used_idx;

static char tx_free[NUM];
static uint16 tx_used_idx;

#define RX_BUF_SIZE 2048
static char rx_buf[NUM][RX_BUF_SIZE];

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

  // Verificación básica
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
     *R(VIRTIO_MMIO_DEVICE_ID) != 1 ||
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    // CORREGIDO: Cast explícito a uint64 para coincidir con %lx
    printf("virtio_net: Device not found at 0x%lx\n", (uint64)VIRTIO_NET_BASE);
    return;
  }

  // 1. Resetear dispositivo
  *R(VIRTIO_MMIO_STATUS) = status;

  // 2. Setear bit ACKNOWLEDGE
  status |= VIRTIO_CONFIG_S_ACKNOWLEDGE;
  *R(VIRTIO_MMIO_STATUS) = status;

  // 3. Setear bit DRIVER
  status |= VIRTIO_CONFIG_S_DRIVER;
  *R(VIRTIO_MMIO_STATUS) = status;

  // 4. Negociación de características (COMPLETA DE 64 BITS)
  uint64 features = 0;
  
  // Leer parte baja (bits 0-31)
  *R(VIRTIO_MMIO_DEVICE_FEATURES_SEL) = 0;
  features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
  
  // Leer parte alta (bits 32-63)
  *R(VIRTIO_MMIO_DEVICE_FEATURES_SEL) = 1;
  features |= ((uint64)(*R(VIRTIO_MMIO_DEVICE_FEATURES)) << 32);

  // Aceptar características
  *R(VIRTIO_MMIO_DRIVER_FEATURES_SEL) = 0;
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = (uint32)features;

  *R(VIRTIO_MMIO_DRIVER_FEATURES_SEL) = 1;
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = (uint32)(features >> 32);

  // 5. Setear FEATURES_OK
  status |= VIRTIO_CONFIG_S_FEATURES_OK;
  *R(VIRTIO_MMIO_STATUS) = status;

  // 6. Verificar si el dispositivo aceptó las características
  status = *R(VIRTIO_MMIO_STATUS);
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK)){
    printf("virtio_net: FEATURES_OK unset (Negotiation failed)\n");
    return;
  }

  // 7. Inicializar colas
  // Cola RX (índice 0)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    panic("virtio net rx queue ready");

  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
  if(max == 0) panic("virtio net has no queue 0");
  if(max < NUM) panic("virtio net max queue too short");

  rx_desc = kalloc();
  rx_avail = kalloc();
  rx_used = kalloc();
  if(!rx_desc || !rx_avail || !rx_used)
    panic("virtio net rx kalloc");
  memset(rx_desc, 0, PGSIZE);
  memset(rx_avail, 0, PGSIZE);
  memset(rx_used, 0, PGSIZE);

  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)rx_desc;
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)rx_desc >> 32;
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)rx_avail;
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)rx_avail >> 32;
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)rx_used;
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)rx_used >> 32;

  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;

  for(int i = 0; i < NUM; i++) rx_free[i] = 1;

  // Cola TX (índice 1)
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

  for(int i = 0; i < NUM; i++) tx_free[i] = 1;

  // 8. Driver OK
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
  *R(VIRTIO_MMIO_STATUS) = status;

  // Llenar descriptores RX
  for(int i = 0; i < NUM; i++) {
    int idx = alloc_rx_desc();
    rx_desc[idx].addr = (uint64)rx_buf[i];
    rx_desc[idx].len = RX_BUF_SIZE;
    rx_desc[idx].flags = VRING_DESC_F_WRITE;
    rx_desc[idx].next = 0;
    rx_avail->ring[rx_avail->idx % NUM] = idx;
    __sync_synchronize();
    rx_avail->idx++;
  }
  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;

  printf("virtio_net: initialized\n");
}

static void
free_tx_desc(int i)
{
  if(i >= NUM) panic("free_tx_desc");
  if(tx_free[i]) panic("free_tx_desc");
  tx_desc[i].addr = 0;
  tx_free[i] = 1;
}

int
virtio_net_send(void *data, int len)
{
  acquire(&vnet_lock);
  int idx = alloc_tx_desc();
  if(idx < 0) {
    release(&vnet_lock);
    return -1;
  }

  struct virtio_net_hdr hdr;
  memset(&hdr, 0, sizeof(hdr));

  if(sizeof(hdr) + len > TX_BUF_SIZE) {
    free_tx_desc(idx);
    release(&vnet_lock);
    return -1;
  }

  memmove(tx_buf, &hdr, sizeof(hdr));
  memmove(tx_buf + sizeof(hdr), data, len);

  tx_desc[idx].addr = (uint64)tx_buf;
  tx_desc[idx].len = sizeof(hdr) + len;
  tx_desc[idx].flags = 0;
  tx_desc[idx].next = 0;

  tx_avail->ring[tx_avail->idx % NUM] = idx;
  __sync_synchronize();
  tx_avail->idx++;

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 1;

  while(tx_used_idx == tx_used->idx);

  int used_idx = tx_used->ring[tx_used_idx % NUM].id;
  free_tx_desc(used_idx);
  tx_used_idx++;

  release(&vnet_lock);
  return 0;
}

void
virtio_net_intr(void)
{
  acquire(&vnet_lock);
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;

  while(rx_used_idx != rx_used->idx) {
    int id = rx_used->ring[rx_used_idx % NUM].id;
    int len = rx_used->ring[rx_used_idx % NUM].len;

    if(len > sizeof(struct virtio_net_hdr)) {
      char *pkt = rx_buf[id] + sizeof(struct virtio_net_hdr);
      int pkt_len = len - sizeof(struct virtio_net_hdr);
      net_recv(pkt, pkt_len);
    }

    rx_desc[id].addr = (uint64)rx_buf[id];
    rx_desc[id].len = RX_BUF_SIZE;
    rx_desc[id].flags = VRING_DESC_F_WRITE;
    rx_avail->ring[rx_avail->idx % NUM] = id;
    __sync_synchronize();
    rx_avail->idx++;
    rx_used_idx++;
  }
  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
  release(&vnet_lock);
}

int
net_send(void *data, int len)
{
  return virtio_net_send(data, len);
}
