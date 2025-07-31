#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>

void vdp_set_refresh(const uint8_t refresh_rate) {
  switch (refresh_rate) {
  case PAL:
  case 50:
    registers_mirror[9] |= 0x02;
    break;

  case NTSC:
  case 60:
    registers_mirror[9] &= ~0x02;
    break;
  }
}
