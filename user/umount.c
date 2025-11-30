#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc != 2) {
    fprintf(2, "Usage: umount <target>\n");
    fprintf(2, "Example: umount /mnt\n");
    exit(1);
  }

  if(umount(argv[1]) < 0) {
    fprintf(2, "umount: failed to unmount %s\n", argv[1]);
    exit(1);
  }

  printf("unmounted %s\n", argv[1]);
  exit(0);
}
