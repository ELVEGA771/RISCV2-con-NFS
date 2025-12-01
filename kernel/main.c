#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
  if(cpuid() == 0){
    consoleinit();
    printfinit();
    printf("\n");
    printf("xv6 kernel is booting\n");
    printf("\n");
    kinit();         // physical page allocator
    kvminit();       // create kernel page table
    kvminithart();   // turn on paging
    procinit();      // process table
    trapinit();      // trap vectors
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC for device interrupts
    binit();         // buffer cache
    iinit();         // inode table
    fileinit();      // file table
    vfs_init();      // virtual file system
    xv6fs_register(); // register xv6fs
    net_init();      // network stack
    nfs_register();  // register NFS
    printf("DEBUG: init disk\n");    
    virtio_disk_init(); // emulated hard disk
    // printf("DEBUG: fsinit\n");
    // fsinit(ROOTDEV); // initialize root filesystem
    // Mount root filesystem using VFS
    // printf("DEBUG: vfs_mount\n");
    // if(vfs_mount("rootdisk", "/", "xv6fs", 0) < 0)
      // panic("vfs_mount root failed");
    printf("xv6: VFS and network stack initialized\n");
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
      ;
    __sync_synchronize();
    printf("hart %d starting\n", cpuid());
    kvminithart();    // turn on paging
    trapinithart();   // install kernel trap vector
    plicinithart();   // ask PLIC for device interrupts
  }

  scheduler();        
}
