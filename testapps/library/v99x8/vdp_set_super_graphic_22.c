#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8-super.h>

void vdp_set_super_graphic_22(void) {
  vdp_set_super_graphic_6();
  vdp_current_mode = 150; // 128 + 16 + 6;
  vdp_reg_write(29, 14);  // select extended register PALETTE_DEPTH
  vdp_reg_write(30, 1);   // 2 pixels per byte aka 4 bits per pixel, 16 colours
}
