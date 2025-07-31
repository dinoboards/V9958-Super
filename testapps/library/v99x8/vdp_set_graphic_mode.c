#ifdef VDP_SUPER_HDMI
#include <v99x8-super.h>
#endif
#include <v99x8.h>

void vdp_set_graphic_mode(uint8_t mode) {
  switch (mode) {
  case 4:
    vdp_set_graphic_4();
    return;
  case 5:
    vdp_set_graphic_5();
    return;
  case 6:
    vdp_set_graphic_6();
    return;
  case 7:
    vdp_set_graphic_7();
    return;

  default:
#ifdef VDP_SUPER_HDMI
    if (mode >= 128)
      vdp_set_super_graphic_mode(mode - 128);
#endif
    return;
  }
}
