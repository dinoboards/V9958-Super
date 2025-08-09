#include <stdint.h>
#include <v99x8.h>

void vdp_set_remap(const uint8_t back, const uint8_t fore) {
  vdp_reg_write(29, 15);
  vdp_reg_write(30, fore);
  vdp_reg_write(30, back);
}
