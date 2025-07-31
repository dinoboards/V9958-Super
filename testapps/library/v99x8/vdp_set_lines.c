#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>

void vdp_set_lines(const uint8_t lines) {
  switch (lines) {
  case 212:
    registers_mirror[9] |= 0x80;
    break;

  case 192:
    registers_mirror[9] &= ~0x80;
    break;
  }
}
