//
// Network stack initialization
//

#include "types.h"
#include "defs.h"

void
net_init(void)
{
  // Initialize network layers in order
  arp_init();
  ip_init();
  udp_init();
  rpc_init();

  // Initialize network device
  virtio_net_init();
}
