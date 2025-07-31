#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>

screen_size_t vdp_get_screen_height(void) {
  switch (vdp_current_mode) {
  case 0x80 | 0x01:
    return 200;

  case 0x80 | 0x02:
    return 240;

  case 0x80 | 0x03:
    return 240;

  case 0x80 | 0x04:
    return 288;

  case 0x80 | 0x05:
    return 400;

  case 0x80 | 0x06:
    return 480;

  case 0x80 | 0x07:
    return 480;

  case 0x80 | 0x08:
    return 576;

  case 0x80 | 0x09:
    return 512;

  case 0x80 | 0x0A:
    return 256;

  case 0x80 | 0x0B:
    return 240;

  case 0x80 | 0x0C:
    return 288;

  case 0x80 | 0x10 | 0x05:
    return 400;

  case 0x80 | 0x10 | 0x06:
    return 480;

  case 0x80 | 0x10 | 0x07:
    return 480;

  case 0x80 | 0x10 | 0x08:
    return 576;

  case 0x80 | 0x10 | 0x09:
    return 512;

  case 0x80 | 0x10 | 0x0A:
    return 256;

  case 0x80 | 0x10 | 0x0B:
    return 240;

  case 0x80 | 0x10 | 0x0C:
    return 288;

  default:
    return (registers_mirror[9] & 0x80) ? 212 : 192;
  }
}
