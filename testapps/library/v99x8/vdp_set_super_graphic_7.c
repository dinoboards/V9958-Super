#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8-super.h>

void vdp_set_super_graphic_7(void) {
  vdp_set_refresh(60);
  vdp_set_graphic_7();
  vdp_current_mode = 135; // 128 + 7;
  vdp_reg_write(29, 255);
  vdp_reg_write(30, 255); // reset VIEW PORT and BASE ADDR and PALETTE_DEPTH
  register_31_mirror = 4;
  vdp_reg_write(31, register_31_mirror);
}
