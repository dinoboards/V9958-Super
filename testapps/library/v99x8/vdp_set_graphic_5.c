#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>
#ifdef VDP_SUPER_HDMI
#include <v99x8-super.h>
#endif

void vdp_set_graphic_5(void) {
  uint8_t *r = registers_mirror;

  *r++ = 0x08; // R0: N/A, DG = 0, IE2 =0, IE1 =0, M5 = 1, M4 = 0, M3 = 0, N/A
  r++;         // R1: N/A, BL(ENABLE SCREEN) = 1, IE0(HORZ_INT) = 0, M1 = 0, M2 = 0, N/A, SI(SPRITE SIZE) = 0, MA(SPRITE EXPAN.) = 0
  *r++ = 0x1F; // R2: N/A, A16 = 0, A15 = 0, 1, 1, 1, 1, 1
  *r++ = 0x00; // R3 - NO COLOR TABLE
  *r++ = 0x00; // R4 - N/A???
  *r++ = 0xF0; // R5 - SPRITE ATTRIBUTE TABLE -> 7800
  *r++ = 0x0E; // R6 - SPRITE PATTERN => 7000
  r++;         // 0x00 R7 - a background colour?
  r++;         // 0x8A R8 - COLOUR BUS INPUT, DRAM 64K, DISABLE SPRITE
  r++;         // 0x00 R9 LN = 1(212 lines), S1, S0 = 0, IL = 0, EO = 0, NT = 1 (PAL), DC = 0
  r++;         // 0x00 R10 - color table - n/a
  *r++ = 0x00; // R11 - SPRITE ATTRIBUTE TABLE -> 7800

  set_base_registers();
  vdp_current_mode = 5;

#ifdef VDP_SUPER_HDMI
  register_31_mirror = 0;
  vdp_reg_write(31, 0);
#endif
}
