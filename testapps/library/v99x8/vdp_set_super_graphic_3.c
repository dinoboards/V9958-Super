#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8-super.h>

void vdp_set_super_graphic_3(void) {
  vdp_set_refresh(60);
  vdp_set_graphic_7();
  vdp_current_mode   = 131; // 128 + 3;
  register_31_mirror = 2;
  vdp_reg_write(29, 255);
  vdp_reg_write(30, 255);                // reset VIEW PORT and BASE ADDR and PALETTE_DEPTH
  vdp_reg_write(31, register_31_mirror); // set SUPER_MID mode
}
