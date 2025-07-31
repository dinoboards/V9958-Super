#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>

screen_size_t vdp_get_screen_width(void) {
  switch (vdp_current_mode) {
  case 1:
  case 2:
  case 3:
  case 4:
  case 7:
    return 256;

  case 5:
  case 6:
    return 512;

  case 0x80 | 0x01:
    return 320;

  case 0x80 | 0x02:
    return 320;

  case 0x80 | 0x03:
    return 360;

  case 0x80 | 0x04:
    return 360;

  case 0x80 | 0x05:
    return 640;

  case 0x80 | 0x06:
    return 640;

  case 0x80 | 0x07:
    return 720;

  case 0x80 | 0x08:
    return 720;

  case 0x80 | 0x09:
    return 640;

  case 0x80 | 0x0A:
    return 640;

  case 0x80 | 0x0B:
    return 720;

  case 0x80 | 0x0C:
    return 720;

  case 0x80 | 0x10 | 0x05:
    return 640;

  case 0x80 | 0x10 | 0x06:
    return 640;

  case 0x80 | 0x10 | 0x07:
    return 720;

  case 0x80 | 0x10 | 0x08:
    return 720;

  case 0x80 | 0x10 | 0x09:
    return 640;

  case 0x80 | 0x10 | 0x0A:
    return 640;

  case 0x80 | 0x10 | 0x0B:
    return 720;

  case 0x80 | 0x10 | 0x0C:
    return 720;

  default:
    return 256;
  }
}
