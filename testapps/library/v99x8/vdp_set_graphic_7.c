#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>
#ifdef VDP_SUPER_HDMI
#include <v99x8-super.h>
#endif

void vdp_set_graphic_7(void) {
  uint8_t *r = registers_mirror;

  *r++ = 0x0E; // R0 - M5 = 1, M4 = 1, M3 = 1
  r++;         // 0x40 R1 - ENABLE SCREEN, DISABLE INTERRUPTS, M1 = 0, M2 = 0
  *r++ = 0x1F; // R2 - PATTERN NAME TABLE := 0, A16 = 0
  *r++ = 0x00; // R3 - NO COLOR TABLE
  *r++ = 0x00; // R4 - N/A???
  *r++ = 0xF7; // R5 - SPRITE ATTRIBUTE TABLE -> FA00
  *r++ = 0x1E; // R6 - SPRITE PATTERN => F000
  r++;         // 0x00 R7 - background colour?
  r++;         // 0x8A R8 - COLOUR BUS INPUT, DRAM 64K, DISABLE SPRITE
  r++;         // 0x00 R9 LN = 1(212 lines), S1, S0 = 0, IL = 0, EO = 0, NT = 1 (PAL), DC = 0
  r++;         // 0x00 R10 - color table - n/a
  *r = 0x01;   // R11 - SPRITE ATTRIBUTE TABLE -> FA00

  set_base_registers();
  vdp_current_mode = 7;

#ifdef VDP_SUPER_HDMI
  register_31_mirror = 0;
  vdp_reg_write(31, 0);
#endif
}
