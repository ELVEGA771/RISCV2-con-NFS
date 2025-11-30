# VFS and NFS Implementation Plan for xv6-riscv

## Executive Summary

This document outlines the plan to transform xv6's monolithic filesystem into a Virtual File System (VFS) architecture and add Network File System (NFS) client support.

**Current State**: xv6 has a tightly-coupled filesystem with no abstraction layer.

**Target State**: VFS layer supporting multiple filesystem types (xv6fs, NFS).

**Estimated Effort**: 5000 lines of code, 9-13 weeks of development.

---

## Table of Contents

1. [Current Architecture Analysis](#current-architecture-analysis)
2. [VFS Architecture Overview](#vfs-architecture-overview)
3. [Implementation Phases](#implementation-phases)
4. [Detailed Implementation Guide](#detailed-implementation-guide)
5. [Testing Strategy](#testing-strategy)
6. [Risk Assessment](#risk-assessment)

---

## Current Architecture Analysis

### xv6 File System Architecture

```
System Calls (sysfile.c)
    ↓
File Layer (file.c) - switch statements on file type
    ↓
FS Implementation (fs.c) - hardcoded xv6 format
    ↓
Buffer Cache (bio.c)
    ↓
Disk Driver (virtio_disk.c)
```

### Problems with Current Design

1. **Tightly Coupled**: `kernel/fs.c` directly implements operations for ONE filesystem format
2. **No FS Type Abstraction**: Single global superblock, no support for multiple FS types
3. **Hardcoded Dispatch**: Switch statements instead of function pointer tables
4. **No Mount Table**: No concept of mount points or multiple filesystems
5. **Direct Inode Access**: System calls directly invoke FS-specific functions

### Existing Building Blocks

✓ **Device abstraction**: `struct devsw` with function pointers
✓ **File descriptor layer**: `struct file` abstracts different file types
✓ **Buffer cache**: Generic block I/O layer

---

## VFS Architecture Overview

### Proposed Architecture

```
System Calls (sysfile.c)
    ↓
VFS Layer (vfs.c) - filesystem-agnostic operations
    ↓
    ├─→ xv6fs (xv6fs.c) - existing filesystem
    │       ↓
    │   Buffer Cache (bio.c)
    │       ↓
    │   Disk Driver
    │
    └─→ NFS Client (nfs.c)
            ↓
        RPC Layer (rpc.c)
            ↓
        Network Stack (udp.c, ip.c)
            ↓
        Network Driver (e1000.c or virtio-net.c)
```

### Key VFS Concepts

1. **struct superblock**: Generic superblock with operation pointers
2. **struct inode**: Generic inode with filesystem-specific data pointer
3. **Operation Tables**: Function pointers for FS operations
4. **Mount Table**: Track mounted filesystems and mount points
5. **Pathname Resolution**: Cross-mount-point path lookup

---

## Implementation Phases

### Phase 1: VFS Core Infrastructure (2-3 weeks, ~800 LOC)

**Goal**: Create VFS abstraction layer

**Deliverables**:
- `kernel/vfs.h` - VFS data structures and operation tables
- `kernel/vfs.c` - Core VFS functions (mount, lookup, open)
- Mount table implementation
- Generic inode modifications

**Success Criteria**: Can register filesystem types and mount a filesystem

---

### Phase 2: xv6fs Refactoring (1-2 weeks, ~600 LOC)

**Goal**: Adapt existing xv6 filesystem to VFS

**Deliverables**:
- `kernel/xv6fs.c` - VFS adapter for xv6 filesystem
- `kernel/xv6fs.h` - xv6fs-specific structures
- Refactored `kernel/file.c` to use VFS dispatch
- Refactored `kernel/sysfile.c` to use VFS functions

**Success Criteria**: xv6 boots and runs all existing programs through VFS layer

---

### Phase 3: Network Stack (3-4 weeks, ~2000 LOC)

**Goal**: Add minimal UDP/IP networking

**Deliverables**:
- `kernel/net/eth.c` - Ethernet frame handling
- `kernel/net/arp.c` - Address Resolution Protocol
- `kernel/net/ip.c` - IP packet handling
- `kernel/net/udp.c` - UDP implementation
- `kernel/net/socket.c` - Basic socket interface
- `kernel/drivers/e1000.c` or `virtio_net.c` - Network driver

**Success Criteria**: Can send/receive UDP packets

---

### Phase 4: NFS Client Implementation (2-3 weeks, ~1200 LOC)

**Goal**: Implement NFS v2/v3 client over UDP

**Deliverables**:
- `kernel/rpc/xdr.c` - XDR encoding/decoding
- `kernel/rpc/rpc.c` - RPC call/reply mechanism
- `kernel/nfs/nfs.c` - NFS protocol implementation
- `kernel/nfs/nfs_vfs.c` - NFS VFS integration
- Basic caching layer

**Success Criteria**: Can mount and access files on remote NFS server

---

### Phase 5: Integration and Testing (1 week, ~400 LOC)

**Goal**: Full integration and comprehensive testing

**Deliverables**:
- `user/mount.c` - Mount utility program
- `user/umount.c` - Unmount utility program
- Updated documentation
- Test suite

**Success Criteria**: Can simultaneously use xv6fs and NFS filesystems

---

## Detailed Implementation Guide

### Phase 1: VFS Core Infrastructure

#### Step 1.1: Create VFS Header (`kernel/vfs.h`)

```c
// VFS operation structures

// Superblock operations (filesystem-level)
struct super_operations {
  struct inode* (*alloc_inode)(struct superblock *sb);
  void (*destroy_inode)(struct inode *ip);
  void (*write_inode)(struct inode *ip);
  void (*put_super)(struct superblock *sb);
  int (*statfs)(struct superblock *sb, struct statfs *buf);
};

// Inode operations (file metadata operations)
struct inode_operations {
  int (*lookup)(struct inode *dir, const char *name, struct inode **result);
  int (*create)(struct inode *dir, const char *name, short type, struct inode **result);
  int (*link)(struct inode *old, struct inode *dir, const char *name);
  int (*unlink)(struct inode *dir, const char *name);
  int (*mkdir)(struct inode *dir, const char *name);
  int (*rmdir)(struct inode *dir, const char *name);
  int (*getattr)(struct inode *ip, struct stat *st);
};

// File operations (data access operations)
struct file_operations {
  int (*read)(struct file *f, uint64 addr, int n);
  int (*write)(struct file *f, uint64 addr, int n);
  int (*open)(struct inode *ip, struct file *f);
  int (*release)(struct inode *ip, struct file *f);
};

// Forward declarations
struct superblock;
struct filesystem_type;
struct vfsmount;

// Generic superblock (wraps filesystem-specific superblocks)
struct superblock {
  uint dev;                          // Device number (0 for network FS)
  struct super_operations *s_op;     // Superblock operations
  void *s_fs_info;                   // Filesystem-specific data
  struct filesystem_type *s_type;    // Filesystem type
  struct inode *s_root;              // Root inode
  int s_blocksize;                   // Block size
  struct spinlock s_lock;            // Superblock lock
};

// Filesystem type registry
struct filesystem_type {
  char name[16];                     // "xv6fs", "nfs", etc.
  int fs_flags;                      // FS_REQUIRES_DEV, etc.
  struct superblock* (*mount)(uint dev, void *data);
  void (*kill_sb)(struct superblock *sb);
  struct filesystem_type *next;      // Linked list of FS types
};

// Mount table entry
struct vfsmount {
  struct superblock *mnt_sb;         // Mounted filesystem's superblock
  struct inode *mnt_mountpoint;      // Inode where it's mounted
  struct inode *mnt_root;            // Root inode of mounted fs
  struct vfsmount *mnt_parent;       // Parent mount (NULL for root)
  char mnt_devname[16];              // Device name for reference
  char mnt_dirname[MAXPATH];         // Mount point path
  struct vfsmount *next;             // Linked list
};

// Global VFS data
extern struct vfsmount *vfs_root_mnt;
extern struct filesystem_type *filesystems;
extern struct spinlock vfs_lock;

// VFS core functions
void vfs_init(void);
int vfs_register_filesystem(struct filesystem_type *fs);
int vfs_mount(const char *dev, const char *mountpoint, const char *type, void *data);
int vfs_umount(const char *mountpoint);
struct inode* vfs_namei(const char *path);
struct inode* vfs_nameiparent(const char *path, char *name);
int vfs_open(struct inode *ip, struct file *f);
int vfs_read(struct file *f, uint64 addr, int n);
int vfs_write(struct file *f, uint64 addr, int n);
int vfs_stat(struct inode *ip, struct stat *st);
int vfs_create(struct inode *dir, const char *name, short type, struct inode **result);
int vfs_mkdir(struct inode *dir, const char *name);
int vfs_unlink(struct inode *dir, const char *name);
int vfs_link(struct inode *ip, struct inode *dir, const char *name);

// Mount point helpers
struct vfsmount* vfs_find_mount(const char *path);
int vfs_is_mountpoint(struct inode *ip);
```

#### Step 1.2: Modify `kernel/file.h`

Update struct inode to support VFS:

```c
// in-memory copy of an inode (VFS version)
struct inode {
  uint dev;                          // Device number
  uint inum;                         // Inode number
  int ref;                           // Reference count
  struct sleeplock lock;             // Protects everything below
  int valid;                         // Inode has been read from disk?

  // VFS fields
  struct superblock *i_sb;           // Superblock pointer
  struct inode_operations *i_op;     // Inode operations
  struct file_operations *i_fop;     // File operations

  // Generic inode fields (moved from old design)
  short type;                        // File type (T_DIR, T_FILE, T_DEVICE)
  uint64 size;                       // File size in bytes

  // Filesystem-specific data
  void *i_private;                   // FS-specific inode info

  // Mount point tracking
  struct vfsmount *i_mount;          // If this is a mount point
};
```

#### Step 1.3: Implement VFS Core (`kernel/vfs.c`)

Key functions to implement:

```c
// VFS initialization
void vfs_init(void) {
  initlock(&vfs_lock, "vfs");
  filesystems = 0;
  vfs_root_mnt = 0;
}

// Register a filesystem type
int vfs_register_filesystem(struct filesystem_type *fs) {
  // Add to linked list of filesystems
  acquire(&vfs_lock);
  fs->next = filesystems;
  filesystems = fs;
  release(&vfs_lock);
  return 0;
}

// Mount a filesystem
int vfs_mount(const char *dev, const char *mountpoint, const char *type, void *data) {
  // 1. Find filesystem type
  // 2. Find mount point inode (if not root)
  // 3. Call fs->mount()
  // 4. Create vfsmount entry
  // 5. Link into mount table
}

// Path resolution with mount point crossing
struct inode* vfs_namei(const char *path) {
  // 1. Start from root or cwd
  // 2. Parse path components
  // 3. For each component:
  //    a. Check if current inode is a mount point
  //    b. If yes, switch to mounted fs root
  //    c. Use i_op->lookup() to find next component
  // 4. Return final inode
}

// Generic read operation
int vfs_read(struct file *f, uint64 addr, int n) {
  if (!f->readable)
    return -1;
  if (f->ip && f->ip->i_fop && f->ip->i_fop->read)
    return f->ip->i_fop->read(f, addr, n);
  return -1;
}

// Generic write operation
int vfs_write(struct file *f, uint64 addr, int n) {
  if (!f->writable)
    return -1;
  if (f->ip && f->ip->i_fop && f->ip->i_fop->write)
    return f->ip->i_fop->write(f, addr, n);
  return -1;
}
```

#### Step 1.4: Add VFS to Kernel Build

Update `Makefile`:

```makefile
OBJS = \
  $K/entry.o \
  # ... existing objects ...
  $K/vfs.o \          # Add this line
  $K/virtio_disk.o
```

---

### Phase 2: xv6fs Refactoring

#### Step 2.1: Create xv6fs Header (`kernel/xv6fs.h`)

```c
#ifndef XV6FS_H
#define XV6FS_H

// xv6fs-specific inode information
struct xv6fs_inode_info {
  short major;                       // Device major number
  short minor;                       // Device minor number
  short nlink;                       // Number of links
  uint addrs[NDIRECT+1];            // Data block addresses
};

// xv6fs-specific superblock information
struct xv6fs_sb_info {
  struct superblock sb;              // On-disk superblock
  int dev;                           // Device number
};

// xv6fs functions
struct superblock* xv6fs_mount(uint dev, void *data);
void xv6fs_kill_sb(struct superblock *sb);
int xv6fs_register(void);

// External operation tables
extern struct super_operations xv6fs_super_ops;
extern struct inode_operations xv6fs_inode_ops;
extern struct inode_operations xv6fs_dir_ops;
extern struct file_operations xv6fs_file_ops;

#endif
```

#### Step 2.2: Implement xv6fs Adapter (`kernel/xv6fs.c`)

Wrap existing fs.c functions:

```c
#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "proc.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "vfs.h"
#include "xv6fs.h"

// Wrapper for file read
static int xv6fs_file_read(struct file *f, uint64 addr, int n) {
  struct inode *ip = f->ip;
  int r;

  ilock(ip);
  if((r = readi(ip, 1, addr, f->off, n)) > 0)
    f->off += r;
  iunlock(ip);

  return r;
}

// Wrapper for file write
static int xv6fs_file_write(struct file *f, uint64 addr, int n) {
  struct inode *ip = f->ip;
  int r, ret = 0;
  int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
  int i = 0;

  while(i < n){
    int n1 = n - i;
    if(n1 > max)
      n1 = max;

    begin_op();
    ilock(ip);
    if ((r = writei(ip, 1, addr + i, f->off, n1)) > 0)
      f->off += r;
    iunlock(ip);
    end_op();

    if(r != n1)
      break;
    i += r;
  }

  return (i == n ? n : -1);
}

// Wrapper for lookup
static int xv6fs_lookup(struct inode *dir, const char *name, struct inode **result) {
  uint off;
  *result = dirlookup(dir, (char*)name, &off);
  return (*result != 0) ? 0 : -1;
}

// Wrapper for create
static int xv6fs_create(struct inode *dir, const char *name, short type, struct inode **result) {
  // Use existing create logic from sysfile.c
  // This will be refactored from sys_open
  return -1;  // TODO: Implement
}

// Operation tables
struct file_operations xv6fs_file_ops = {
  .read = xv6fs_file_read,
  .write = xv6fs_file_write,
  .open = 0,                         // Not needed for xv6fs
  .release = 0,                      // Not needed for xv6fs
};

struct inode_operations xv6fs_dir_ops = {
  .lookup = xv6fs_lookup,
  .create = xv6fs_create,
  .link = 0,                         // TODO: Implement
  .unlink = 0,                       // TODO: Implement
  .mkdir = 0,                        // TODO: Implement
  .rmdir = 0,                        // TODO: Implement
  .getattr = 0,                      // TODO: Implement
};

struct inode_operations xv6fs_inode_ops = {
  .lookup = 0,                       // Only for directories
  .create = 0,                       // Only for directories
  .getattr = 0,                      // TODO: Implement
};

struct super_operations xv6fs_super_ops = {
  .alloc_inode = 0,                  // TODO: Implement
  .destroy_inode = 0,                // TODO: Implement
  .write_inode = 0,                  // TODO: Implement
  .put_super = 0,                    // TODO: Implement
  .statfs = 0,                       // TODO: Implement
};

// Mount function
struct superblock* xv6fs_mount(uint dev, void *data) {
  // 1. Allocate superblock
  // 2. Read disk superblock
  // 3. Initialize VFS superblock
  // 4. Set operation pointers
  // 5. Return superblock
  return 0;  // TODO: Implement
}

// Filesystem type registration
static struct filesystem_type xv6fs_type = {
  .name = "xv6fs",
  .mount = xv6fs_mount,
  .kill_sb = xv6fs_kill_sb,
};

int xv6fs_register(void) {
  return vfs_register_filesystem(&xv6fs_type);
}
```

#### Step 2.3: Refactor System Calls

Update `kernel/sysfile.c` to use VFS:

```c
uint64 sys_open(void) {
  char path[MAXPATH];
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, path, MAXPATH) < 0 || argint(1, &omode) < 0)
    return -1;

  begin_op();

  // Use VFS path resolution instead of namei
  if(omode & O_CREATE){
    char name[DIRSIZ];
    struct inode *dp = vfs_nameiparent(path, name);
    if(dp == 0){
      end_op();
      return -1;
    }

    // Use VFS create
    if(vfs_create(dp, name, T_FILE, &ip) < 0) {
      iput(dp);
      end_op();
      return -1;
    }
    iput(dp);
  } else {
    // Use VFS lookup
    if((ip = vfs_namei(path)) == 0){
      end_op();
      return -1;
    }
  }

  // Rest of the function remains similar...
}
```

---

### Phase 3: Network Stack

#### Step 3.1: Network Driver

Choose one:
- **Option A**: Intel E1000 (well documented)
- **Option B**: virtio-net (simpler, better for QEMU)

Recommendation: virtio-net

Create `kernel/net/virtio_net.c`:

```c
// virtio-net device driver
// Based on virtio specification

#define VIRTIO_NET_MMIO 0x10002000  // Second virtio device

struct virtio_net {
  uint32 status;
  uint32 feature;
  // ... virtio registers
};

// Packet transmission
int virtio_net_send(void *data, int len) {
  // 1. Allocate descriptor
  // 2. Copy data to descriptor buffer
  // 3. Add to TX queue
  // 4. Notify device
  return 0;
}

// Packet reception
int virtio_net_recv(void *buf, int maxlen) {
  // 1. Check RX queue
  // 2. Copy data from descriptor
  // 3. Return descriptor to device
  return 0;
}

void virtio_net_init(void) {
  // Initialize virtio-net device
}

void virtio_net_intr(void) {
  // Handle interrupts
}
```

#### Step 3.2: Ethernet Layer

Create `kernel/net/eth.c`:

```c
#include "types.h"
#include "net.h"

struct eth_hdr {
  uchar dst[6];                      // Destination MAC
  uchar src[6];                      // Source MAC
  ushort type;                       // EtherType (0x0800 = IP, 0x0806 = ARP)
} __attribute__((packed));

#define ETH_TYPE_IP  0x0800
#define ETH_TYPE_ARP 0x0806

// Local MAC address
static uchar local_mac[6] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x56};

int eth_send(uchar *dst_mac, ushort type, void *payload, int len) {
  struct eth_hdr hdr;
  uchar packet[1514];                // Max Ethernet frame

  // Build Ethernet header
  memmove(hdr.dst, dst_mac, 6);
  memmove(hdr.src, local_mac, 6);
  hdr.type = htons(type);

  // Copy header and payload
  memmove(packet, &hdr, sizeof(hdr));
  memmove(packet + sizeof(hdr), payload, len);

  // Send via driver
  return virtio_net_send(packet, sizeof(hdr) + len);
}

void eth_recv(void *packet, int len) {
  struct eth_hdr *hdr = (struct eth_hdr *)packet;
  void *payload = packet + sizeof(struct eth_hdr);
  int payload_len = len - sizeof(struct eth_hdr);

  ushort type = ntohs(hdr->type);

  switch(type) {
    case ETH_TYPE_ARP:
      arp_recv(payload, payload_len);
      break;
    case ETH_TYPE_IP:
      ip_recv(payload, payload_len);
      break;
  }
}
```

#### Step 3.3: ARP Implementation

Create `kernel/net/arp.c`:

```c
#include "types.h"
#include "net.h"

struct arp_entry {
  uint32 ip;
  uchar mac[6];
  int valid;
};

#define ARP_CACHE_SIZE 16
static struct arp_entry arp_cache[ARP_CACHE_SIZE];
static struct spinlock arp_lock;

struct arp_packet {
  ushort htype;                      // Hardware type (1 = Ethernet)
  ushort ptype;                      // Protocol type (0x0800 = IP)
  uchar hlen;                        // Hardware address length (6)
  uchar plen;                        // Protocol address length (4)
  ushort op;                         // Operation (1 = request, 2 = reply)
  uchar sha[6];                      // Sender hardware address
  uint32 spa;                        // Sender protocol address
  uchar tha[6];                      // Target hardware address
  uint32 tpa;                        // Target protocol address
} __attribute__((packed));

#define ARP_OP_REQUEST 1
#define ARP_OP_REPLY   2

void arp_init(void) {
  initlock(&arp_lock, "arp");
  memset(arp_cache, 0, sizeof(arp_cache));
}

int arp_lookup(uint32 ip, uchar *mac) {
  acquire(&arp_lock);
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    if(arp_cache[i].valid && arp_cache[i].ip == ip) {
      memmove(mac, arp_cache[i].mac, 6);
      release(&arp_lock);
      return 0;
    }
  }
  release(&arp_lock);
  return -1;
}

void arp_add(uint32 ip, uchar *mac) {
  acquire(&arp_lock);
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    if(!arp_cache[i].valid) {
      arp_cache[i].ip = ip;
      memmove(arp_cache[i].mac, mac, 6);
      arp_cache[i].valid = 1;
      release(&arp_lock);
      return;
    }
  }
  // Cache full, replace first entry
  arp_cache[0].ip = ip;
  memmove(arp_cache[0].mac, mac, 6);
  arp_cache[0].valid = 1;
  release(&arp_lock);
}

void arp_recv(void *data, int len) {
  struct arp_packet *arp = (struct arp_packet *)data;

  if(ntohs(arp->op) == ARP_OP_REQUEST) {
    // Handle ARP request
    if(arp->tpa == local_ip) {
      // Send ARP reply
      struct arp_packet reply;
      // ... build reply ...
      eth_send(arp->sha, ETH_TYPE_ARP, &reply, sizeof(reply));
    }
  } else if(ntohs(arp->op) == ARP_OP_REPLY) {
    // Add to cache
    arp_add(arp->spa, arp->sha);
  }
}

int arp_request(uint32 ip) {
  struct arp_packet req;
  uchar broadcast[6] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};

  // Build ARP request
  req.htype = htons(1);
  req.ptype = htons(0x0800);
  req.hlen = 6;
  req.plen = 4;
  req.op = htons(ARP_OP_REQUEST);
  memmove(req.sha, local_mac, 6);
  req.spa = local_ip;
  memset(req.tha, 0, 6);
  req.tpa = ip;

  return eth_send(broadcast, ETH_TYPE_ARP, &req, sizeof(req));
}
```

#### Step 3.4: IP Layer

Create `kernel/net/ip.c`:

```c
#include "types.h"
#include "net.h"

struct ip_hdr {
  uchar ver_ihl;                     // Version (4 bits) + IHL (4 bits)
  uchar tos;                         // Type of service
  ushort len;                        // Total length
  ushort id;                         // Identification
  ushort flags_offset;               // Flags (3 bits) + Fragment offset (13 bits)
  uchar ttl;                         // Time to live
  uchar proto;                       // Protocol (17 = UDP)
  ushort checksum;                   // Header checksum
  uint32 src;                        // Source IP
  uint32 dst;                        // Destination IP
} __attribute__((packed));

#define IP_PROTO_ICMP  1
#define IP_PROTO_TCP   6
#define IP_PROTO_UDP   17

uint32 local_ip = 0;                 // Set via configuration
uint32 gateway_ip = 0;
uint32 netmask = 0;

static ushort ip_id = 1;

ushort ip_checksum(void *data, int len) {
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

int ip_send(uint32 dst_ip, uchar proto, void *data, int len) {
  struct ip_hdr hdr;
  uchar packet[1500];
  uchar dst_mac[6];

  // Build IP header
  hdr.ver_ihl = 0x45;                // IPv4, 20 byte header
  hdr.tos = 0;
  hdr.len = htons(sizeof(hdr) + len);
  hdr.id = htons(ip_id++);
  hdr.flags_offset = 0;
  hdr.ttl = 64;
  hdr.proto = proto;
  hdr.checksum = 0;
  hdr.src = local_ip;
  hdr.dst = dst_ip;
  hdr.checksum = htons(ip_checksum(&hdr, sizeof(hdr)));

  // Copy header and payload
  memmove(packet, &hdr, sizeof(hdr));
  memmove(packet + sizeof(hdr), data, len);

  // Resolve MAC address
  if(arp_lookup(dst_ip, dst_mac) < 0) {
    arp_request(dst_ip);
    // In real implementation, queue packet
    return -1;
  }

  return eth_send(dst_mac, ETH_TYPE_IP, packet, sizeof(hdr) + len);
}

void ip_recv(void *data, int len) {
  struct ip_hdr *hdr = (struct ip_hdr *)data;
  void *payload = data + 20;         // Assuming no options
  int payload_len = ntohs(hdr->len) - 20;

  // Check if packet is for us
  if(hdr->dst != local_ip)
    return;

  // Dispatch based on protocol
  switch(hdr->proto) {
    case IP_PROTO_UDP:
      udp_recv(hdr->src, payload, payload_len);
      break;
    case IP_PROTO_ICMP:
      // Handle ICMP
      break;
  }
}
```

#### Step 3.5: UDP Layer

Create `kernel/net/udp.c`:

```c
#include "types.h"
#include "net.h"

struct udp_hdr {
  ushort src_port;
  ushort dst_port;
  ushort len;
  ushort checksum;
} __attribute__((packed));

struct udp_socket {
  int used;
  ushort port;
  void (*handler)(uint32 src_ip, ushort src_port, void *data, int len);
};

#define MAX_UDP_SOCKETS 16
static struct udp_socket udp_sockets[MAX_UDP_SOCKETS];
static struct spinlock udp_lock;

void udp_init(void) {
  initlock(&udp_lock, "udp");
  memset(udp_sockets, 0, sizeof(udp_sockets));
}

int udp_bind(ushort port, void (*handler)(uint32, ushort, void*, int)) {
  acquire(&udp_lock);
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
  return -1;
}

int udp_send(uint32 dst_ip, ushort dst_port, ushort src_port, void *data, int len) {
  struct udp_hdr hdr;
  uchar packet[1500];

  hdr.src_port = htons(src_port);
  hdr.dst_port = htons(dst_port);
  hdr.len = htons(sizeof(hdr) + len);
  hdr.checksum = 0;                  // Optional for IPv4

  memmove(packet, &hdr, sizeof(hdr));
  memmove(packet + sizeof(hdr), data, len);

  return ip_send(dst_ip, IP_PROTO_UDP, packet, sizeof(hdr) + len);
}

void udp_recv(uint32 src_ip, void *data, int len) {
  struct udp_hdr *hdr = (struct udp_hdr *)data;
  void *payload = data + sizeof(struct udp_hdr);
  int payload_len = ntohs(hdr->len) - sizeof(struct udp_hdr);
  ushort dst_port = ntohs(hdr->dst_port);
  ushort src_port = ntohs(hdr->src_port);

  acquire(&udp_lock);
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    if(udp_sockets[i].used && udp_sockets[i].port == dst_port) {
      if(udp_sockets[i].handler) {
        udp_sockets[i].handler(src_ip, src_port, payload, payload_len);
      }
      break;
    }
  }
  release(&udp_lock);
}
```

#### Step 3.6: Network Configuration

Add network configuration to `kernel/param.h`:

```c
// Network configuration
#define NET_ENABLED    1
#define NET_LOCAL_IP   0x0a000202      // 10.0.2.2
#define NET_GATEWAY    0x0a000201      // 10.0.2.1
#define NET_NETMASK    0xffffff00      // 255.255.255.0
```

---

### Phase 4: NFS Client Implementation

#### Step 4.1: XDR Encoding/Decoding

Create `kernel/rpc/xdr.h`:

```c
#ifndef XDR_H
#define XDR_H

struct xdr_buf {
  uchar *data;
  int pos;
  int len;
};

void xdr_init(struct xdr_buf *xdr, void *data, int len);
int xdr_encode_uint32(struct xdr_buf *xdr, uint32 val);
int xdr_encode_uint64(struct xdr_buf *xdr, uint64 val);
int xdr_encode_bytes(struct xdr_buf *xdr, void *data, int len);
int xdr_encode_string(struct xdr_buf *xdr, const char *str);
int xdr_decode_uint32(struct xdr_buf *xdr, uint32 *val);
int xdr_decode_uint64(struct xdr_buf *xdr, uint64 *val);
int xdr_decode_bytes(struct xdr_buf *xdr, void *data, int maxlen);
int xdr_decode_string(struct xdr_buf *xdr, char *str, int maxlen);

#endif
```

Create `kernel/rpc/xdr.c`:

```c
#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "xdr.h"

void xdr_init(struct xdr_buf *xdr, void *data, int len) {
  xdr->data = (uchar *)data;
  xdr->pos = 0;
  xdr->len = len;
}

int xdr_encode_uint32(struct xdr_buf *xdr, uint32 val) {
  if(xdr->pos + 4 > xdr->len)
    return -1;

  xdr->data[xdr->pos++] = (val >> 24) & 0xFF;
  xdr->data[xdr->pos++] = (val >> 16) & 0xFF;
  xdr->data[xdr->pos++] = (val >> 8) & 0xFF;
  xdr->data[xdr->pos++] = val & 0xFF;

  return 0;
}

int xdr_encode_bytes(struct xdr_buf *xdr, void *data, int len) {
  // XDR bytes: length (4 bytes) + data (padded to 4-byte boundary)
  if(xdr_encode_uint32(xdr, len) < 0)
    return -1;

  int padded = (len + 3) & ~3;       // Round up to multiple of 4
  if(xdr->pos + padded > xdr->len)
    return -1;

  memmove(xdr->data + xdr->pos, data, len);

  // Zero padding
  for(int i = len; i < padded; i++)
    xdr->data[xdr->pos + i] = 0;

  xdr->pos += padded;
  return 0;
}

int xdr_encode_string(struct xdr_buf *xdr, const char *str) {
  return xdr_encode_bytes(xdr, (void *)str, strlen(str));
}

int xdr_decode_uint32(struct xdr_buf *xdr, uint32 *val) {
  if(xdr->pos + 4 > xdr->len)
    return -1;

  *val = ((uint32)xdr->data[xdr->pos] << 24) |
         ((uint32)xdr->data[xdr->pos + 1] << 16) |
         ((uint32)xdr->data[xdr->pos + 2] << 8) |
         ((uint32)xdr->data[xdr->pos + 3]);

  xdr->pos += 4;
  return 0;
}

int xdr_decode_bytes(struct xdr_buf *xdr, void *data, int maxlen) {
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
```

#### Step 4.2: RPC Layer

Create `kernel/rpc/rpc.h`:

```c
#ifndef RPC_H
#define RPC_H

#define RPC_CALL  0
#define RPC_REPLY 1

#define RPC_MSG_ACCEPTED 0
#define RPC_MSG_DENIED   1

#define RPC_SUCCESS 0

struct rpc_call {
  uint32 xid;                        // Transaction ID
  uint32 prog;                       // Program number
  uint32 vers;                       // Program version
  uint32 proc;                       // Procedure number
  uint32 cred_flavor;                // Credential flavor
  uint32 cred_len;                   // Credential length
  uint32 verf_flavor;                // Verifier flavor
  uint32 verf_len;                   // Verifier length
};

struct rpc_reply {
  uint32 xid;
  uint32 reply_stat;
  uint32 verf_flavor;
  uint32 verf_len;
  uint32 accept_stat;
};

int rpc_call(uint32 server_ip, ushort port, uint32 prog, uint32 vers, uint32 proc,
             void *args, int args_len, void *result, int result_max);

#endif
```

Create `kernel/rpc/rpc.c`:

```c
#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "spinlock.h"
#include "net.h"
#include "xdr.h"
#include "rpc.h"

static uint32 rpc_xid = 1;
static struct spinlock rpc_lock;
static int rpc_reply_received;
static uchar rpc_reply_buf[8192];
static int rpc_reply_len;

void rpc_init(void) {
  initlock(&rpc_lock, "rpc");
}

static void rpc_recv_handler(uint32 src_ip, ushort src_port, void *data, int len) {
  acquire(&rpc_lock);
  if(len <= sizeof(rpc_reply_buf)) {
    memmove(rpc_reply_buf, data, len);
    rpc_reply_len = len;
    rpc_reply_received = 1;
  }
  release(&rpc_lock);
}

int rpc_call(uint32 server_ip, ushort port, uint32 prog, uint32 vers, uint32 proc,
             void *args, int args_len, void *result, int result_max) {
  uchar call_buf[8192];
  struct xdr_buf xdr;
  uint32 xid;

  // Generate XID
  acquire(&rpc_lock);
  xid = rpc_xid++;
  rpc_reply_received = 0;
  release(&rpc_lock);

  // Encode RPC call
  xdr_init(&xdr, call_buf, sizeof(call_buf));
  xdr_encode_uint32(&xdr, xid);
  xdr_encode_uint32(&xdr, RPC_CALL);
  xdr_encode_uint32(&xdr, 2);        // RPC version
  xdr_encode_uint32(&xdr, prog);
  xdr_encode_uint32(&xdr, vers);
  xdr_encode_uint32(&xdr, proc);
  xdr_encode_uint32(&xdr, 0);        // AUTH_NULL
  xdr_encode_uint32(&xdr, 0);        // cred length
  xdr_encode_uint32(&xdr, 0);        // AUTH_NULL
  xdr_encode_uint32(&xdr, 0);        // verf length

  // Append arguments
  if(args && args_len > 0)
    memmove(call_buf + xdr.pos, args, args_len);

  int total_len = xdr.pos + args_len;

  // Register handler temporarily
  int sock = udp_bind(port + 1000, rpc_recv_handler);
  if(sock < 0)
    return -1;

  // Send request
  if(udp_send(server_ip, port, port + 1000, call_buf, total_len) < 0)
    return -1;

  // Wait for reply (with timeout)
  int timeout = 100;                 // 100 ticks = ~1 second
  while(timeout-- > 0) {
    acquire(&rpc_lock);
    if(rpc_reply_received) {
      release(&rpc_lock);
      break;
    }
    release(&rpc_lock);
    // sleep(1);  // TODO: Implement proper sleep
  }

  if(!rpc_reply_received)
    return -1;

  // Decode reply
  xdr_init(&xdr, rpc_reply_buf, rpc_reply_len);
  uint32 reply_xid, msg_type, reply_stat, accept_stat;

  xdr_decode_uint32(&xdr, &reply_xid);
  xdr_decode_uint32(&xdr, &msg_type);

  if(reply_xid != xid || msg_type != RPC_REPLY)
    return -1;

  xdr_decode_uint32(&xdr, &reply_stat);
  if(reply_stat != RPC_MSG_ACCEPTED)
    return -1;

  // Skip verifier
  uint32 verf_flavor, verf_len;
  xdr_decode_uint32(&xdr, &verf_flavor);
  xdr_decode_uint32(&xdr, &verf_len);
  xdr.pos += ((verf_len + 3) & ~3);

  xdr_decode_uint32(&xdr, &accept_stat);
  if(accept_stat != RPC_SUCCESS)
    return -1;

  // Copy result
  int result_len = rpc_reply_len - xdr.pos;
  if(result_len > result_max)
    result_len = result_max;
  memmove(result, rpc_reply_buf + xdr.pos, result_len);

  return result_len;
}
```

#### Step 4.3: NFS Protocol

Create `kernel/nfs/nfs.h`:

```c
#ifndef NFS_H
#define NFS_H

// NFS v2 constants
#define NFS_PROGRAM  100003
#define NFS_VERSION  2

// NFS procedures
#define NFSPROC_NULL      0
#define NFSPROC_GETATTR   1
#define NFSPROC_SETATTR   2
#define NFSPROC_ROOT      3
#define NFSPROC_LOOKUP    4
#define NFSPROC_READLINK  5
#define NFSPROC_READ      6
#define NFSPROC_WRITE     7
#define NFSPROC_CREATE    8
#define NFSPROC_REMOVE    9
#define NFSPROC_RENAME    10
#define NFSPROC_LINK      11
#define NFSPROC_SYMLINK   12
#define NFSPROC_MKDIR     13
#define NFSPROC_RMDIR     14
#define NFSPROC_READDIR   15
#define NFSPROC_STATFS    16

// NFS file handle
#define NFS_FHSIZE 32
struct nfs_fh {
  uchar data[NFS_FHSIZE];
};

// NFS file attributes
struct nfs_fattr {
  uint32 type;
  uint32 mode;
  uint32 nlink;
  uint32 uid;
  uint32 gid;
  uint32 size;
  uint32 blocksize;
  uint32 rdev;
  uint32 blocks;
  uint32 fsid;
  uint32 fileid;
  // timestamps...
};

// NFS mount info
struct nfs_mount {
  uint32 server_ip;
  ushort port;
  struct nfs_fh root_fh;
};

// NFS operations
int nfs_getattr(struct nfs_mount *mnt, struct nfs_fh *fh, struct nfs_fattr *attr);
int nfs_lookup(struct nfs_mount *mnt, struct nfs_fh *dir_fh, const char *name,
               struct nfs_fh *fh, struct nfs_fattr *attr);
int nfs_read(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
             uint32 count, void *buf);
int nfs_write(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
              uint32 count, void *buf);

#endif
```

Create `kernel/nfs/nfs.c`:

```c
#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "xdr.h"
#include "rpc.h"
#include "nfs.h"

#define NFS_PORT 2049

int nfs_getattr(struct nfs_mount *mnt, struct nfs_fh *fh, struct nfs_fattr *attr) {
  uchar args[128];
  uchar result[256];
  struct xdr_buf xdr;

  // Encode arguments (file handle)
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_bytes(&xdr, fh->data, NFS_FHSIZE);

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_GETATTR, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
  uint32 status;
  xdr_decode_uint32(&xdr, &status);

  if(status != 0)
    return -1;

  // Decode attributes
  xdr_decode_uint32(&xdr, &attr->type);
  xdr_decode_uint32(&xdr, &attr->mode);
  xdr_decode_uint32(&xdr, &attr->nlink);
  xdr_decode_uint32(&xdr, &attr->uid);
  xdr_decode_uint32(&xdr, &attr->gid);
  xdr_decode_uint32(&xdr, &attr->size);
  // ... decode rest of attributes

  return 0;
}

int nfs_lookup(struct nfs_mount *mnt, struct nfs_fh *dir_fh, const char *name,
               struct nfs_fh *fh, struct nfs_fattr *attr) {
  uchar args[256];
  uchar result[512];
  struct xdr_buf xdr;

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_bytes(&xdr, dir_fh->data, NFS_FHSIZE);
  xdr_encode_string(&xdr, name);

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_LOOKUP, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
  uint32 status;
  xdr_decode_uint32(&xdr, &status);

  if(status != 0)
    return -1;

  // Decode file handle
  xdr_decode_bytes(&xdr, fh->data, NFS_FHSIZE);

  // Decode attributes
  xdr_decode_uint32(&xdr, &attr->type);
  xdr_decode_uint32(&xdr, &attr->mode);
  // ... decode rest

  return 0;
}

int nfs_read(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
             uint32 count, void *buf) {
  uchar args[128];
  uchar result[8192];
  struct xdr_buf xdr;

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_bytes(&xdr, fh->data, NFS_FHSIZE);
  xdr_encode_uint32(&xdr, offset);
  xdr_encode_uint32(&xdr, count);
  xdr_encode_uint32(&xdr, 0);        // total count (not used in v2)

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_READ, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
  uint32 status;
  xdr_decode_uint32(&xdr, &status);

  if(status != 0)
    return -1;

  // Skip attributes
  xdr.pos += 17 * 4;                 // Skip fattr (17 uint32s)

  // Decode data
  int data_len = xdr_decode_bytes(&xdr, buf, count);

  return data_len;
}

int nfs_write(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
              uint32 count, void *buf) {
  uchar args[8192];
  uchar result[256];
  struct xdr_buf xdr;

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
  xdr_encode_bytes(&xdr, fh->data, NFS_FHSIZE);
  xdr_encode_uint32(&xdr, 0);        // beginoffset (not used)
  xdr_encode_uint32(&xdr, offset);
  xdr_encode_uint32(&xdr, 0);        // totalcount (not used)
  xdr_encode_bytes(&xdr, buf, count);

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
                     NFSPROC_WRITE, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
  uint32 status;
  xdr_decode_uint32(&xdr, &status);

  if(status != 0)
    return -1;

  return count;
}
```

#### Step 4.4: NFS VFS Integration

Create `kernel/nfs/nfs_vfs.c`:

```c
#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "file.h"
#include "vfs.h"
#include "nfs.h"

// NFS inode private data
struct nfs_inode_info {
  struct nfs_fh fh;
  struct nfs_mount *mnt;
  uint64 cache_time;                 // For attribute caching
  int cached_valid;
  struct nfs_fattr cached_attr;
};

// NFS file operations
static int nfs_file_read(struct file *f, uint64 addr, int n) {
  struct inode *ip = f->ip;
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;
  uchar buf[1024];
  int total = 0;

  while(n > 0) {
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;
    int r = nfs_read(nfs_ip->mnt, &nfs_ip->fh, f->off, chunk, buf);

    if(r <= 0)
      break;

    // Copy to user space
    if(copyout(myproc()->pagetable, addr, (char *)buf, r) < 0)
      return -1;

    f->off += r;
    addr += r;
    total += r;
    n -= r;

    if(r < chunk)                    // Short read
      break;
  }

  return total;
}

static int nfs_file_write(struct file *f, uint64 addr, int n) {
  struct inode *ip = f->ip;
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;
  uchar buf[1024];
  int total = 0;

  while(n > 0) {
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;

    // Copy from user space
    if(copyin(myproc()->pagetable, (char *)buf, addr, chunk) < 0)
      return -1;

    int w = nfs_write(nfs_ip->mnt, &nfs_ip->fh, f->off, chunk, buf);

    if(w <= 0)
      break;

    f->off += w;
    addr += w;
    total += w;
    n -= w;

    if(w < chunk)
      break;
  }

  return total;
}

static struct file_operations nfs_file_ops = {
  .read = nfs_file_read,
  .write = nfs_file_write,
  .open = 0,
  .release = 0,
};

// NFS inode operations
static int nfs_lookup(struct inode *dir, const char *name, struct inode **result) {
  struct nfs_inode_info *nfs_dir = (struct nfs_inode_info *)dir->i_private;
  struct nfs_fh fh;
  struct nfs_fattr attr;

  if(nfs_lookup(nfs_dir->mnt, &nfs_dir->fh, name, &fh, &attr) < 0)
    return -1;

  // Allocate new inode
  struct inode *ip = ialloc(0, attr.type);  // Device 0 for NFS
  if(!ip)
    return -1;

  // Fill in inode
  ip->i_sb = dir->i_sb;
  ip->i_op = dir->i_op;
  ip->i_fop = &nfs_file_ops;
  ip->type = attr.type;
  ip->size = attr.size;

  // Allocate and fill private data
  struct nfs_inode_info *nfs_ip = kalloc();
  if(!nfs_ip) {
    iput(ip);
    return -1;
  }

  memmove(&nfs_ip->fh, &fh, sizeof(fh));
  nfs_ip->mnt = nfs_dir->mnt;
  nfs_ip->cached_valid = 0;
  ip->i_private = nfs_ip;

  *result = ip;
  return 0;
}

static struct inode_operations nfs_inode_ops = {
  .lookup = nfs_lookup,
  .create = 0,                       // TODO
  .link = 0,
  .unlink = 0,
  .mkdir = 0,
  .rmdir = 0,
  .getattr = 0,
};

// NFS mount function
struct superblock* nfs_mount(uint dev, void *data) {
  // data should contain: "server_ip:port:/export/path"
  // For simplicity, just use server IP for now

  struct superblock *sb = kalloc();
  if(!sb)
    return 0;

  struct nfs_mount *mnt = kalloc();
  if(!mnt) {
    kfree(sb);
    return 0;
  }

  // Parse mount data
  // For now, hardcode for testing
  mnt->server_ip = 0x0a000201;       // 10.0.2.1
  mnt->port = NFS_PORT;

  // Get root file handle via MOUNT protocol
  // For simplicity, assume we have it
  // TODO: Implement MOUNT protocol

  sb->dev = 0;                       // No device for network FS
  sb->s_fs_info = mnt;
  sb->s_blocksize = 8192;

  // Create root inode
  struct inode *root = ialloc(0, T_DIR);
  if(!root) {
    kfree(mnt);
    kfree(sb);
    return 0;
  }

  root->i_sb = sb;
  root->i_op = &nfs_inode_ops;
  root->i_fop = &nfs_file_ops;

  struct nfs_inode_info *nfs_root = kalloc();
  if(!nfs_root) {
    iput(root);
    kfree(mnt);
    kfree(sb);
    return 0;
  }

  memmove(&nfs_root->fh, &mnt->root_fh, sizeof(mnt->root_fh));
  nfs_root->mnt = mnt;
  nfs_root->cached_valid = 0;
  root->i_private = nfs_root;

  sb->s_root = root;

  return sb;
}

static struct filesystem_type nfs_type = {
  .name = "nfs",
  .mount = nfs_mount,
  .kill_sb = 0,                      // TODO
};

int nfs_register(void) {
  return vfs_register_filesystem(&nfs_type);
}
```

---

### Phase 5: Integration and Testing

#### Step 5.1: System Call Integration

Add `sys_mount` and `sys_umount` to `kernel/sysfile.c`:

```c
uint64 sys_mount(void) {
  char source[MAXPATH];
  char target[MAXPATH];
  char fstype[16];

  if(argstr(0, source, MAXPATH) < 0 ||
     argstr(1, target, MAXPATH) < 0 ||
     argstr(2, fstype, 16) < 0)
    return -1;

  return vfs_mount(source, target, fstype, 0);
}

uint64 sys_umount(void) {
  char target[MAXPATH];

  if(argstr(0, target, MAXPATH) < 0)
    return -1;

  return vfs_umount(target);
}
```

Add to `kernel/syscall.h`:

```c
#define SYS_mount  22
#define SYS_umount 23
```

Add to `user/usys.pl`:

```perl
entry("mount");
entry("umount");
```

Add to `user/user.h`:

```c
int mount(const char *source, const char *target, const char *fstype);
int umount(const char *target);
```

#### Step 5.2: User Utilities

Create `user/mount.c`:

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
  if(argc != 4) {
    fprintf(2, "Usage: mount <source> <target> <fstype>\n");
    fprintf(2, "Example: mount /dev/disk0 /mnt xv6fs\n");
    fprintf(2, "Example: mount 10.0.2.1:/export /nfs nfs\n");
    exit(1);
  }

  if(mount(argv[1], argv[2], argv[3]) < 0) {
    fprintf(2, "mount: failed\n");
    exit(1);
  }

  printf("mounted %s on %s\n", argv[1], argv[2]);
  exit(0);
}
```

Create `user/umount.c`:

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
  if(argc != 2) {
    fprintf(2, "Usage: umount <target>\n");
    exit(1);
  }

  if(umount(argv[1]) < 0) {
    fprintf(2, "umount: failed\n");
    exit(1);
  }

  printf("unmounted %s\n", argv[1]);
  exit(0);
}
```

#### Step 5.3: Kernel Initialization Updates

Update `kernel/main.c`:

```c
void main() {
  // ... existing initialization ...

  fileinit();
  vfs_init();                        // Initialize VFS
  xv6fs_register();                  // Register xv6fs

  #ifdef NET_ENABLED
  net_init();                        // Initialize network stack
  rpc_init();                        // Initialize RPC
  nfs_register();                    // Register NFS
  #endif

  userinit();

  // ... rest of main ...
}
```

#### Step 5.4: Testing Plan

**Test 1: VFS with xv6fs**
```bash
$ make qemu
xv6 kernel is booting

$ ls /
.   1 1 1024
..  1 1 1024
README  2 2 2425
cat     2 3 24256
# ... works as before
```

**Test 2: Mount xv6fs**
```bash
$ mkdir /mnt
$ mount /dev/rootdisk /mnt xv6fs
mounted /dev/rootdisk on /mnt
$ ls /mnt
# Should show same content as /
```

**Test 3: NFS Mount (requires NFS server on host)**

On host machine:
```bash
# Setup NFS export
sudo mkdir -p /export/xv6
sudo chmod 777 /export/xv6
echo "Hello from NFS" > /export/xv6/test.txt

# Add to /etc/exports
/export/xv6 10.0.2.0/24(rw,sync,no_subtree_check,insecure,no_root_squash)

sudo exportfs -ra
sudo systemctl restart nfs-server
```

In xv6:
```bash
$ mkdir /nfs
$ mount 10.0.2.1:/export/xv6 /nfs nfs
mounted 10.0.2.1:/export/xv6 on /nfs
$ ls /nfs
test.txt
$ cat /nfs/test.txt
Hello from NFS
```

**Test 4: Mixed Operations**
```bash
$ ls /              # Local xv6fs
$ ls /nfs           # Remote NFS
$ cp /README /nfs/  # Copy from local to NFS
$ cat /nfs/README   # Read from NFS
```

---

## Testing Strategy

### Unit Tests

1. **VFS Layer Tests**
   - Test mount/umount
   - Test path resolution
   - Test cross-mount lookups
   - Test operation dispatch

2. **Network Stack Tests**
   - Test Ethernet frame send/receive
   - Test ARP request/reply
   - Test IP packet send/receive
   - Test UDP send/receive

3. **RPC Tests**
   - Test XDR encoding/decoding
   - Test RPC call/reply
   - Test with NULL procedure

4. **NFS Tests**
   - Test GETATTR
   - Test LOOKUP
   - Test READ/WRITE
   - Test with various file sizes

### Integration Tests

1. **xv6fs through VFS** - Verify all existing programs work
2. **Multiple mounts** - Mount xv6fs at different mount points
3. **NFS basic operations** - Read, write, create, delete
4. **Performance** - Compare direct vs VFS overhead

### System Tests

1. **Boot test** - Verify xv6 boots correctly
2. **Stress test** - Run usertests with VFS
3. **Concurrent access** - Multiple processes accessing VFS/NFS
4. **Error handling** - Network failures, NFS server down, etc.

---

## Risk Assessment

### High Risk Items

1. **Stability**: VFS changes affect all file operations
   - Mitigation: Incremental testing, keep old code path initially

2. **Performance**: VFS indirection adds overhead
   - Mitigation: Measure overhead, optimize hot paths

3. **Network reliability**: UDP packets can be lost
   - Mitigation: Implement retries in RPC layer

4. **Complexity**: Adding 5000 LOC to a 10K LOC kernel
   - Mitigation: Modular design, good documentation

### Medium Risk Items

1. **NFS compatibility**: Server implementation variations
   - Mitigation: Test with multiple NFS server implementations

2. **Memory usage**: Network buffers, caches consume memory
   - Mitigation: Careful memory management, limits on buffers

3. **Debugging**: Network issues hard to debug
   - Mitigation: Add logging, packet capture capability

### Low Risk Items

1. **VFS API changes**: May need to adjust API
   - Mitigation: Design for flexibility

2. **Testing coverage**: Hard to test all combinations
   - Mitigation: Focus on common paths first

---

## Future Enhancements

### Short Term
- Add proper attribute caching in NFS
- Implement data caching for NFS
- Add retry logic for network operations
- Support NFS v3 (larger read/write sizes)

### Medium Term
- Add TCP support for NFS
- Implement file locking
- Add support for symbolic links
- Implement MOUNT protocol properly

### Long Term
- Support NFS v4
- Add other filesystems (FAT, ext2)
- Implement network security (AUTH_SYS, Kerberos)
- Add async I/O support

---

## References

### VFS Design
- Linux VFS documentation
- FreeBSD VFS architecture
- "The Design and Implementation of the FreeBSD Operating System"

### NFS Protocol
- RFC 1094 - NFS v2 specification
- RFC 1813 - NFS v3 specification
- RFC 1831 - RPC version 2 specification
- RFC 1832 - XDR specification

### Network Stack
- RFC 791 - Internet Protocol
- RFC 768 - User Datagram Protocol
- RFC 826 - Address Resolution Protocol

### xv6 Resources
- xv6 book: https://pdos.csail.mit.edu/6.828/2023/xv6/book-riscv-rev3.pdf
- MIT 6.S081 course materials

---

## Conclusion

This plan transforms xv6 from a monolithic filesystem design into a flexible VFS-based architecture supporting multiple filesystem types, including a network filesystem (NFS). The implementation is structured in phases to allow incremental development and testing.

**Key Milestones:**
- Phase 1-2: VFS with xv6fs (functional OS)
- Phase 3: Network stack (can send/receive packets)
- Phase 4: NFS client (can access remote files)
- Phase 5: Full integration (production-ready)

**Success Criteria:**
- xv6 boots and runs with VFS layer
- Can mount multiple filesystems
- Can read/write files on NFS server
- Performance overhead < 10% for local operations

The estimated timeline of 9-13 weeks assumes one full-time developer. With proper planning and execution, this project will provide xv6 with modern filesystem capabilities while maintaining its educational focus.
