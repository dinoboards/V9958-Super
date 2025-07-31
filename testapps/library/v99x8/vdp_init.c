#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>
#ifdef VDP_SUPER_HDMI
#include <v99x8-super.h>
#endif

uint8_t vdp_init(void) {
  uint8_t r = vdp_get_status(1);

  if (r & (32 + 4)) {
    vdp_reg_write(29, 255);
    vdp_reg_write(30, 255); // reset viewport and base addr and palette depth
    vdp_reg_write(31, 0);   // disable SUPER_RES mode

    return VDP_SUPER;
  }

  if (r & 4)
    return VDP_V9958;

  return VDP_V9938;
}
