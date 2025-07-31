#include "wait_for_key.h"
#include <stdio.h>
#include <v99x8-super.h>
#include <v99x8.h>

void pause_a_bit(void) {
  for (volatile int32_t i = 0; i < 70000; i++)
    ;
}

void log_mode(void) {
  uint8_t mode = vdp_get_graphic_mode();
  if (mode >= 0x80)
    printf("Super Graphics Mode %d (%d x %d), %d Colours, @ %dHz\n", mode & 0x7f, vdp_get_screen_width(), vdp_get_screen_height(),
           vdp_get_screen_max_unique_colours(), vdp_get_refresh());
  else
    printf("Graphics Mode %d (%d x %d), %d Colours, @ %dHz\n", mode, vdp_get_screen_width(), vdp_get_screen_height(),
           vdp_get_screen_max_unique_colours(), vdp_get_refresh());
}

uint8_t get_pixel_per_byte(void) {
  const uint16_t r = vdp_get_screen_max_unique_colours();
  switch (r) {
  case 256:
    return 1;

  case 16:
    return 2;

  case 4:
    return 4;

  default:
    return 1;
  }
}

static RGB palette_4[16] = {
    {0, 0, 0},       // Black
    {255, 0, 0},     // Bright Red
    {0, 255, 0},     // Bright Green
    {255, 255, 255}, // White
};

static RGB palette_16[16] = {
    {0, 0, 0},       // Black
    {255, 0, 0},     // Bright Red
    {0, 255, 0},     // Bright Green
    {0, 0, 255},     // Bright Blue
    {255, 255, 255}, // White
    {146, 0, 0},     // Medium Red
    {0, 146, 0},     // Medium Green
    {0, 0, 146},     // Medium Blue
    {109, 109, 109}, // Gray
    {255, 255, 0},   // Yellow
    {255, 0, 255},   // Magenta
    {0, 255, 255},   // Cyan
    {182, 73, 0},    // Brown
    {73, 182, 73},   // Light Green
    {73, 73, 182},   // Light Blue
    {182, 182, 182}  // Light Gray
};

RGB palette_256[256] = {
    {0, 0, 0},       {128, 0, 0},     {0, 128, 0},     {128, 128, 0},   {0, 0, 128},     {128, 0, 128},   {0, 128, 128},
    {192, 192, 192}, {128, 128, 128}, {255, 0, 0},     {0, 255, 0},     {255, 255, 0},   {0, 0, 255},     {255, 0, 255},
    {0, 255, 255},   {255, 255, 255}, {0, 0, 0},       {0, 0, 95},      {0, 0, 135},     {0, 0, 175},     {0, 0, 215},
    {0, 0, 255},     {0, 95, 0},      {0, 95, 95},     {0, 95, 135},    {0, 95, 175},    {0, 95, 215},    {0, 95, 255},
    {0, 135, 0},     {0, 135, 95},    {0, 135, 135},   {0, 135, 175},   {0, 135, 215},   {0, 135, 255},   {0, 175, 0},
    {0, 175, 95},    {0, 175, 135},   {0, 175, 175},   {0, 175, 215},   {0, 175, 255},   {0, 215, 0},     {0, 215, 95},
    {0, 215, 135},   {0, 215, 175},   {0, 215, 215},   {0, 215, 255},   {0, 255, 0},     {0, 255, 95},    {0, 255, 135},
    {0, 255, 175},   {0, 255, 215},   {0, 255, 255},   {95, 0, 0},      {95, 0, 95},     {95, 0, 135},    {95, 0, 175},
    {95, 0, 215},    {95, 0, 255},    {95, 95, 0},     {95, 95, 95},    {95, 95, 135},   {95, 95, 175},   {95, 95, 215},
    {95, 95, 255},   {95, 135, 0},    {95, 135, 95},   {95, 135, 135},  {95, 135, 175},  {95, 135, 215},  {95, 135, 255},
    {95, 175, 0},    {95, 175, 95},   {95, 175, 135},  {95, 175, 175},  {95, 175, 215},  {95, 175, 255},  {95, 215, 0},
    {95, 215, 95},   {95, 215, 135},  {95, 215, 175},  {95, 215, 215},  {95, 215, 255},  {95, 255, 0},    {95, 255, 95},
    {95, 255, 135},  {95, 255, 175},  {95, 255, 215},  {95, 255, 255},  {135, 0, 0},     {135, 0, 95},    {135, 0, 135},
    {135, 0, 175},   {135, 0, 215},   {135, 0, 255},   {135, 95, 0},    {135, 95, 95},   {135, 95, 135},  {135, 95, 175},
    {135, 95, 215},  {135, 95, 255},  {135, 135, 0},   {135, 135, 95},  {135, 135, 135}, {135, 135, 175}, {135, 135, 215},
    {135, 135, 255}, {135, 175, 0},   {135, 175, 95},  {135, 175, 135}, {135, 175, 175}, {135, 175, 215}, {135, 175, 255},
    {135, 215, 0},   {135, 215, 95},  {135, 215, 135}, {135, 215, 175}, {135, 215, 215}, {135, 215, 255}, {135, 255, 0},
    {135, 255, 95},  {135, 255, 135}, {135, 255, 175}, {135, 255, 215}, {135, 255, 255}, {175, 0, 0},     {175, 0, 95},
    {175, 0, 135},   {175, 0, 175},   {175, 0, 215},   {175, 0, 255},   {175, 95, 0},    {175, 95, 95},   {175, 95, 135},
    {175, 95, 175},  {175, 95, 215},  {175, 95, 255},  {175, 135, 0},   {175, 135, 95},  {175, 135, 135}, {175, 135, 175},
    {175, 135, 215}, {175, 135, 255}, {175, 175, 0},   {175, 175, 95},  {175, 175, 135}, {175, 175, 175}, {175, 175, 215},
    {175, 175, 255}, {175, 215, 0},   {175, 215, 95},  {175, 215, 135}, {175, 215, 175}, {175, 215, 215}, {175, 215, 255},
    {175, 255, 0},   {175, 255, 95},  {175, 255, 135}, {175, 255, 175}, {175, 255, 215}, {175, 255, 255}, {215, 0, 0},
    {215, 0, 95},    {215, 0, 135},   {215, 0, 175},   {215, 0, 215},   {215, 0, 255},   {215, 95, 0},    {215, 95, 95},
    {215, 95, 135},  {215, 95, 175},  {215, 95, 215},  {215, 95, 255},  {215, 135, 0},   {215, 135, 95},  {215, 135, 135},
    {215, 135, 175}, {215, 135, 215}, {215, 135, 255}, {215, 175, 0},   {215, 175, 95},  {215, 175, 135}, {215, 175, 175},
    {215, 175, 215}, {215, 175, 255}, {215, 215, 0},   {215, 215, 95},  {215, 215, 135}, {215, 215, 175}, {215, 215, 215},
    {215, 215, 255}, {215, 255, 0},   {215, 255, 95},  {215, 255, 135}, {215, 255, 175}, {215, 255, 215}, {215, 255, 255},
    {255, 0, 0},     {255, 0, 95},    {255, 0, 135},   {255, 0, 175},   {255, 0, 215},   {255, 0, 255},   {255, 95, 0},
    {255, 95, 95},   {255, 95, 135},  {255, 95, 175},  {255, 95, 215},  {255, 95, 255},  {255, 135, 0},   {255, 135, 95},
    {255, 135, 135}, {255, 135, 175}, {255, 135, 215}, {255, 135, 255}, {255, 175, 0},   {255, 175, 95},  {255, 175, 135},
    {255, 175, 175}, {255, 175, 215}, {255, 175, 255}, {255, 215, 0},   {255, 215, 95},  {255, 215, 135}, {255, 215, 175},
    {255, 215, 215}, {255, 215, 255}, {255, 255, 0},   {255, 255, 95},  {255, 255, 135}, {255, 255, 175}, {255, 255, 215},
    {255, 255, 255}, {8, 8, 8},       {18, 18, 18},    {28, 28, 28},    {38, 38, 38},    {48, 48, 48},    {58, 58, 58},
    {68, 68, 68},    {78, 78, 78},    {88, 88, 88},    {98, 98, 98},    {108, 108, 108}, {118, 118, 118}, {128, 128, 128},
    {138, 138, 138}, {148, 148, 148}, {158, 158, 158}, {168, 168, 168}, {178, 178, 178}, {188, 188, 188}, {198, 198, 198},
    {208, 208, 208}, {218, 218, 218}, {228, 228, 228}, {238, 238, 238}};

uint8_t super_graphic_60hz_modes[] = {0x01, 0x03, 0x05, 0x07, 0x0B, 0x15, 0x17, 0x1B};

void test_pattern(uint8_t col_row_count, uint8_t white_colour_index) {

  vdp_cmd_wait_completion();
  vdp_cmd_logical_move_vdp_to_vram(0, 0, vdp_get_screen_width(), vdp_get_screen_height() + 30, 3, 0, 0);

  vdp_cmd_wait_completion();
  vdp_cmd_logical_move_vdp_to_vram(0, 0, vdp_get_screen_width(), vdp_get_screen_height(), white_colour_index, 0, 0);

  // Calculate box dimensions
  float box_width  = (float)vdp_get_screen_width() / (float)col_row_count;
  float box_height = (float)vdp_get_screen_height() / (float)col_row_count;
  float border     = 1.0; // Border thickness

  // grid of col_row_count
  uint8_t color = 0;

  for (uint8_t row = 0; row < col_row_count; row++) {
    for (uint8_t col = 0; col < col_row_count; col++) {
      float x = (float)col * box_width;
      float y = (float)row * box_height;

      // // Draw inner colored box
      vdp_cmd_wait_completion();
      vdp_cmd_logical_move_vdp_to_vram(x + border, y + border, box_width - (2.0 * border), box_height - (2.0 * border), color++, 0,
                                       0);
    }
  }

  for (int i = 0; i < 100; i++) {
    vdp_cmd_wait_completion();
    vdp_cmd_logical_move_vdp_to_vram(i + 10, i + 10, 100, 100, i, 0, 0);
    test_for_escape();
  }

  vdp_cmd_wait_completion();
  vdp_cmd_logical_move_vdp_to_vram(0, 0, 1, vdp_get_screen_height(), 3, 0, 0);
  test_for_escape();

  vdp_cmd_wait_completion();
  vdp_cmd_logical_move_vdp_to_vram(vdp_get_screen_width() - 1, 0, 1, vdp_get_screen_height(), 5, 0, 0);
  test_for_escape();

  pause_a_bit();

  // scroll the image up 8 pixels
  vdp_cmd_wait_completion();
  vdp_cmd_move_vram_to_vram(0, 8, 0, 0, vdp_get_screen_width(), vdp_get_screen_height() - 8, DIX_RIGHT | DIY_DOWN);
  vdp_cmd_wait_completion();
  test_for_escape();

  // fill bottom 8 rows with black
  vdp_cmd_logical_move_vdp_to_vram(0, vdp_get_screen_height() - 8, vdp_get_screen_width(), 8, 0, 0, 0);
  vdp_cmd_wait_completion();

  // now scroll all up using vram_y
  screen_size_t remaining_height = vdp_get_screen_height() - 8;
  for (int i = 0; i < vdp_get_screen_height() / 8 - 1; i++) {
    vdp_cmd_move_vram_to_vram_y(0, 8, 0, remaining_height, DIX_RIGHT | DIY_DOWN);
    remaining_height -= 8;
    vdp_cmd_wait_completion();
    test_for_escape();
  }
}

void graphics_mode_test_pattern(uint8_t mode, uint8_t refresh_rate, RGB *palette) {
  vdp_set_refresh(refresh_rate);
  for (int l = 192; l <= 212; l += 20) {
    vdp_set_lines(l);
    vdp_set_graphic_mode(mode);
    vdp_set_palette(palette);

    log_mode();

    test_pattern(8, 1);
  }
}

void super_graphics_mode_test_pattern(uint8_t mode) {
  vdp_set_super_graphic_mode(mode);
  vdp_set_extended_palette(get_pixel_per_byte() == 2 ? palette_16 : palette_256);

  log_mode();

  test_pattern(16, 1);
}

void main_patterns(void) {
  graphics_mode_test_pattern(4, 60, palette_16);
  graphics_mode_test_pattern(5, 60, palette_4);

  for (uint8_t m = 0; m < sizeof(super_graphic_60hz_modes); m++)
    super_graphics_mode_test_pattern(super_graphic_60hz_modes[m]);
}

void missing_super_hdmi(void) {
  printf("This demo is for the Super HDMI only.\n");
  exit(1);
}

int main(void) {
  uint8_t r = vdp_init();
  switch (r) {
  case VDP_TMS:
    printf("VDP Detected: TMS\r\n");
    missing_super_hdmi();
    break;

  case VDP_V9938:
    printf("VDP Detected: V9938\r\n");
    missing_super_hdmi();
    break;

  case VDP_V9958:
    printf("VDP Detected: V9958\r\n");
    missing_super_hdmi();
    break;

  case VDP_SUPER:
    printf("VDP Detected: SUPER HDMI\r\n");
    break;
  }

  printf("Press ESC to abort\n");
  while (true) {
    main_patterns();
    test_for_escape();
  }
}
