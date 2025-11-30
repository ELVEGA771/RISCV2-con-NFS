#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc != 4) {
    fprintf(2, "Usage: mount <source> <target> <fstype>\n");
    fprintf(2, "Example: mount rootdisk /mnt xv6fs\n");
    exit(1);
  }

  if(mount(argv[1], argv[2], argv[3]) < 0) {
    fprintf(2, "mount: failed to mount %s on %s\n", argv[1], argv[2]);
    exit(1);
  }

  printf("mounted %s on %s (type %s)\n", argv[1], argv[2], argv[3]);
  exit(0);
}
