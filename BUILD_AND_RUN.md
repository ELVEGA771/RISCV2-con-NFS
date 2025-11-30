# Building and Running xv6 with VFS and NFS Support

This guide provides complete instructions to build and run the xv6-riscv kernel with VFS and NFS support.

---

## Prerequisites

### System Requirements
- Linux (Ubuntu 20.04+ recommended) or macOS
- At least 2GB RAM
- 5GB free disk space

### Required Tools

#### 1. RISC-V GNU Toolchain

**Option A: Ubuntu/Debian**
```bash
sudo apt-get update
sudo apt-get install -y git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
```

**Option B: Build from Source (if packages not available)**
```bash
# Clone the toolchain
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain

# Install dependencies
sudo apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

# Configure and build (this takes 1-2 hours)
./configure --prefix=/opt/riscv --enable-multilib
sudo make -j$(nproc)

# Add to PATH
echo 'export PATH=/opt/riscv/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

**Option C: macOS with Homebrew**
```bash
brew tap riscv/riscv
brew install riscv-tools
```

#### 2. QEMU for RISC-V

**Ubuntu/Debian:**
```bash
sudo apt-get install qemu-system-misc
# Verify version (need 7.2+)
qemu-system-riscv64 --version
```

**macOS:**
```bash
brew install qemu
```

**Build from source (if needed):**
```bash
wget https://download.qemu.org/qemu-8.0.0.tar.xz
tar xvJf qemu-8.0.0.tar.xz
cd qemu-8.0.0
./configure --target-list=riscv64-softmmu
make -j$(nproc)
sudo make install
```

### Verify Installation

```bash
# Check RISC-V compiler
riscv64-unknown-elf-gcc --version
# OR
riscv64-linux-gnu-gcc --version

# Check QEMU
qemu-system-riscv64 --version
```

---

## Building xv6

### 1. Navigate to xv6 Directory
```bash
cd /path/to/xv6-riscv-riscv
```

### 2. Clean Previous Builds
```bash
make clean
```

### 3. Build the Kernel

**If using riscv64-linux-gnu toolchain:**
```bash
make TOOLPREFIX=riscv64-linux-gnu-
```

**If using riscv64-unknown-elf toolchain:**
```bash
make
```

**Expected output:**
```
gcc -march=rv64gc -g -c -o kernel/entry.o kernel/entry.S
gcc -Wall -Werror ... -c kernel/start.c
...
gcc -Wall -Werror ... -c kernel/vfs.c
gcc -Wall -Werror ... -c kernel/xv6fs.c
gcc -Wall -Werror ... -c kernel/virtio_net.c
...
ld -z max-page-size=4096 -T kernel/kernel.ld -o kernel/kernel ...
mkfs/mkfs fs.img README user/_cat user/_echo ... user/_mount user/_umount
```

### 4. Verify Build
```bash
ls -lh kernel/kernel fs.img
# Should show:
# kernel/kernel - ~200KB kernel binary
# fs.img - ~1MB filesystem image
```

---

## Running xv6

### Basic Run (No Network)

```bash
make qemu
```

**Expected output:**
```
qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel -m 128M -smp 3 -nographic -global virtio-mmio.force-legacy=false -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

xv6 kernel is booting

hart 2 starting
hart 1 starting
init: starting sh
$
```

### Exit QEMU
Press: `Ctrl-A` then `X`

---

## Testing VFS Features

### 1. Basic VFS Test

Start xv6 and verify VFS is working:

```bash
make qemu
```

Inside xv6:
```bash
$ ls /
.              1 1 1024
..             1 1 1024
README         2 2 2425
cat            2 3 24256
echo           2 4 23104
...
mount          2 30 25000
umount         2 31 24800

# VFS is working - files are accessed through VFS layer
```

### 2. Test Multiple Mounts

```bash
$ mkdir /mnt
$ mount rootdisk /mnt xv6fs
mounted rootdisk on /mnt (type xv6fs)

$ ls /mnt
# Shows same content as / (both mount points work)

$ cat /README
# Access via original mount point

$ cat /mnt/README
# Access via second mount point (same file)

$ umount /mnt
unmounted /mnt
```

---

## Running with Network Support

### 1. Basic Network Mode

```bash
make qemu QEMUOPTS="-netdev user,id=net0 -device virtio-net-device,netdev=net0"
```

**Expected output:**
```
xv6 kernel is booting
...
virtio_net: initialized
xv6: VFS and network stack initialized
```

### 2. Network Mode with Port Forwarding

Forward a port from host to xv6 (useful for debugging):

```bash
make qemu QEMUOPTS="-netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-device,netdev=net0"
```

### 3. Configure QEMU Networking Permanently

Edit the Makefile and add to QEMUOPTS:

```makefile
QEMUOPTS = -machine virt -bios none -kernel $K/kernel -m 128M -smp $(CPUS) -nographic
QEMUOPTS += -global virtio-mmio.force-legacy=false
QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0
# Add these lines for network:
QEMUOPTS += -netdev user,id=net0
QEMUOPTS += -device virtio-net-device,netdev=net0
```

Then just run:
```bash
make qemu
```

---

## Testing NFS (Advanced)

### 1. Setup NFS Server on Host

**On Ubuntu/Debian host:**

```bash
# Install NFS server
sudo apt-get install nfs-kernel-server

# Create export directory
sudo mkdir -p /export/xv6
sudo chmod 777 /export/xv6

# Create test file
echo "Hello from NFS server!" > /export/xv6/test.txt
echo "This is xv6 accessing remote files" > /export/xv6/readme.txt

# Configure NFS export
sudo bash -c 'cat >> /etc/exports << EOF
/export/xv6 10.0.2.0/24(rw,sync,no_subtree_check,no_root_squash,insecure)
EOF'

# Apply configuration
sudo exportfs -ra

# Restart NFS server
sudo systemctl restart nfs-kernel-server

# Verify export
showmount -e localhost
```

### 2. Configure Network in QEMU

The default QEMU user networking assigns:
- Host: 10.0.2.2 (accessible from guest)
- Guest: 10.0.2.15 (xv6's IP)
- Gateway: 10.0.2.1

If using tap networking for better NFS performance:

```bash
# Create tap interface (requires root)
sudo ip tuntap add dev tap0 mode tap user $USER
sudo ip addr add 10.0.2.1/24 dev tap0
sudo ip link set dev tap0 up

# Run QEMU with tap
make qemu QEMUOPTS="-netdev tap,id=net0,ifname=tap0,script=no -device virtio-net-device,netdev=net0"
```

### 3. Mount NFS in xv6

Start xv6 with network support:

```bash
make qemu QEMUOPTS="-netdev user,id=net0 -device virtio-net-device,netdev=net0"
```

Inside xv6:
```bash
$ mkdir /nfs

# Mount NFS (use host IP 10.0.2.2 for user networking)
$ mount 10.0.2.2:/export/xv6 /nfs nfs
nfs_mount: mounted NFS from a000202

$ ls /nfs
test.txt
readme.txt

$ cat /nfs/test.txt
Hello from NFS server!

$ cat /nfs/readme.txt
This is xv6 accessing remote files
```

### 4. Test NFS Write (if implemented)

```bash
$ echo "Written from xv6" > /nfs/from_xv6.txt
$ cat /nfs/from_xv6.txt
Written from xv6

# On host, verify:
$ cat /export/xv6/from_xv6.txt
Written from xv6
```

---

## Debugging

### 1. Enable Debug Output

Build with debug symbols:
```bash
make clean
make CFLAGS="-g -DDEBUG"
```

### 2. Run with GDB

Terminal 1:
```bash
make qemu-gdb
```

Terminal 2:
```bash
gdb-multiarch kernel/kernel
(gdb) target remote localhost:26000
(gdb) break main
(gdb) continue
```

### 3. Check Kernel Messages

Look for initialization messages:
```
xv6 kernel is booting
virtio_disk: initialized
virtio_net: initialized
xv6: VFS and network stack initialized
```

### 4. Network Debugging

Add debug prints in network code:
```c
// In kernel/eth.c
printf("eth_send: dst=%x:%x:%x:%x:%x:%x type=%x len=%d\n",
       dst_mac[0], dst_mac[1], dst_mac[2],
       dst_mac[3], dst_mac[4], dst_mac[5],
       type, len);
```

### 5. NFS Debugging

Check NFS operations:
```c
// In kernel/nfs.c
printf("nfs_lookup: looking up '%s'\n", name);
printf("nfs_read: offset=%d count=%d\n", offset, count);
```

---

## Common Issues and Solutions

### Issue 1: "Couldn't find a riscv64 version of GCC"

**Solution:**
```bash
# Install toolchain
sudo apt-get install gcc-riscv64-linux-gnu

# Or specify TOOLPREFIX
make TOOLPREFIX=riscv64-linux-gnu-
```

### Issue 2: "qemu-system-riscv64: command not found"

**Solution:**
```bash
sudo apt-get install qemu-system-misc
```

### Issue 3: "virtio_net: No device found"

**Solution:**
- Make sure you added network device to QEMU options
- Check QEMU command includes: `-device virtio-net-device`

### Issue 4: NFS mount fails

**Solutions:**
1. Check NFS server is running:
   ```bash
   sudo systemctl status nfs-kernel-server
   ```

2. Verify export:
   ```bash
   showmount -e localhost
   ```

3. Check firewall:
   ```bash
   sudo ufw allow nfs
   ```

4. Use correct IP address (10.0.2.2 for QEMU user networking)

5. Add `insecure` option to /etc/exports for QEMU

### Issue 5: Kernel panic on boot

**Solution:**
- Check all object files compiled correctly
- Verify Makefile has all .o files
- Try clean rebuild: `make clean && make`

### Issue 6: Compilation errors

**Common fixes:**
```bash
# Missing function declaration
# Add to kernel/defs.h

# Type mismatch
# Check pointer types match between header and implementation

# Undefined reference
# Make sure .o file is in Makefile OBJS list
```

---

## Performance Tips

### 1. Use KVM Acceleration (Linux only)

```bash
make qemu QEMUOPTS="-netdev user,id=net0 -device virtio-net-device,netdev=net0 -enable-kvm"
```

### 2. Increase CPU Count

```bash
make qemu CPUS=4
```

### 3. Increase Memory

Edit Makefile:
```makefile
QEMUOPTS = -machine virt -bios none -kernel $K/kernel -m 256M ...
```

### 4. Use TAP networking instead of user networking

TAP provides better performance for NFS.

---

## Running Test Scripts

### Create a test script

```bash
#!/bin/bash
# test_vfs.sh

cat << 'EOF' | make qemu
ls /
mkdir /mnt
mount rootdisk /mnt xv6fs
ls /mnt
cat /README
cat /mnt/README
umount /mnt
exit
EOF
```

Run it:
```bash
chmod +x test_vfs.sh
./test_vfs.sh
```

---

## QEMU Command Line Reference

### Minimal (No Network)
```bash
qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel \
  -m 128M -smp 3 -nographic \
  -drive file=fs.img,if=none,format=raw,id=x0 \
  -device virtio-blk-device,drive=x0
```

### With Network (User Mode)
```bash
qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel \
  -m 128M -smp 3 -nographic \
  -drive file=fs.img,if=none,format=raw,id=x0 \
  -device virtio-blk-device,drive=x0 \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0
```

### With Network (TAP Mode)
```bash
sudo qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel \
  -m 128M -smp 3 -nographic \
  -drive file=fs.img,if=none,format=raw,id=x0 \
  -device virtio-blk-device,drive=x0 \
  -netdev tap,id=net0,ifname=tap0,script=no \
  -device virtio-net-device,netdev=net0
```

### With Serial Output to File
```bash
qemu-system-riscv64 ... -serial file:serial.log
```

---

## Quick Start Checklist

- [ ] Install riscv64 toolchain
- [ ] Install qemu-system-riscv64
- [ ] `cd xv6-riscv-riscv`
- [ ] `make clean`
- [ ] `make`
- [ ] `make qemu` (test basic boot)
- [ ] Test VFS: `mkdir /mnt`, `mount rootdisk /mnt xv6fs`, `ls /mnt`
- [ ] Exit: Ctrl-A, X
- [ ] Set up NFS server (optional)
- [ ] `make qemu` with network options
- [ ] Test NFS: `mount 10.0.2.2:/export/xv6 /nfs nfs`

---

## Additional Resources

- **xv6 Documentation**: https://pdos.csail.mit.edu/6.828/2023/xv6.html
- **RISC-V Spec**: https://riscv.org/technical/specifications/
- **QEMU Documentation**: https://www.qemu.org/docs/master/
- **NFS Protocol**: RFC 1094 (NFS v2)
- **RPC Specification**: RFC 1831

---

## Support

If you encounter issues:

1. Check this guide's troubleshooting section
2. Review VFS_NFS_IMPLEMENTATION_PLAN.md
3. Check IMPLEMENTATION_STATUS.md for known limitations
4. Review kernel logs for error messages
5. Enable debug output and recompile

---

*Last updated: 2025-11-12*
*xv6 with VFS and NFS support - Build and Run Guide*
