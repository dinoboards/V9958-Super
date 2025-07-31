#include <v99x8-super.h>

void vdp_set_super_graphic_mode(uint8_t mode) {
  switch (mode) {
  case 0x01:
    vdp_set_super_graphic_1();
    return;
  case 0x02:
    vdp_set_super_graphic_2();
    return;
  case 0x03:
    vdp_set_super_graphic_3();
    return;
  case 0x04:
    vdp_set_super_graphic_4();
    return;
  case 0x05:
    vdp_set_super_graphic_5();
    return;
  case 0x06:
    vdp_set_super_graphic_6();
    return;
  case 0x07:
    vdp_set_super_graphic_7();
    return;
  case 0x08:
    vdp_set_super_graphic_8();
    return;
  case 0x09:
    vdp_set_super_graphic_9();
    return;
  case 0x0A:
    vdp_set_super_graphic_10();
    return;
  case 0x0B:
    vdp_set_super_graphic_11();
    return;
  case 0x0C:
    vdp_set_super_graphic_12();
    return;
  case 0x15:
    vdp_set_super_graphic_21();
    return;
  case 0x16:
    vdp_set_super_graphic_22();
    return;
  case 0x17:
    vdp_set_super_graphic_23();
    return;
  case 0x18:
    vdp_set_super_graphic_24();
    return;
  case 0x19:
    vdp_set_super_graphic_25();
    return;
  case 0x1A:
    vdp_set_super_graphic_26();
    return;
  case 0x1B:
    vdp_set_super_graphic_27();
    return;
  case 0x1C:
    vdp_set_super_graphic_28();
    return;

  default:
    return;
  }
}
