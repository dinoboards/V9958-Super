#ifndef __V9958_SUPER
#define __V9958_SUPER

#include "v99x8.h"

/**
 * @file v99x8-super.h
 * @brief Functions to support extended feature beyond stock V9958 interface of the HDMI for RC kit
 *
 * The HDMI for RC kit supports, if flashed with appropriate firmware, it will support extended graphics modes
 * and the ability to manage a WS8212 LED strip.
 *
 * **Extended Graphics**
 *
 * The *HDMI for RC* offers three base graphics modes, with modifiers for viewport sizing, colour palette depth and refresh rate.
 *
 * The 3 base modes are as follows:
 *
 * | Base Mode | Native HDMI Resolution | Rendered Resolution | Refresh Rate |
 * | :-------: | :--------:             | :-----------------: | :----------: |
 * |   Half    |   720x480              | 720x240             |      60Hz    |
 * |   Half    |   720x576              | 720x288             |      50Hz    |
 * |   Mid     |   720x480              | 360x240             |      60Hz    |
 * |   Mid     |   720x576              | 360x288             |      50Hz    |
 * |   High    |   720x480              | 720x480             |      60Hz    |
 * |   High    |   720x576              | 720x576             |      50Hz    |
 *
 * Each of the above base modes can be adjusted to have a border applied, reducing the effective rendered resolution.
 * Modes with lower resolutions have reduced memory needs and offer faster command processing.
 *
 * **Super Graphics Modes**
 *
 * One of the following pre-configured Super Graphics Modes can be selected by invoking the appropriate library
 * function: `vdp_set_super_graphic_XX` or  `vdp_set_super_graphic(mode)`.
 *
 *
 * | Super Mode | Resolution | Memory Size (bytes) | Refresh Rate | Palette Size | Base Mode | Full/Bordered |
 * | :--------: | :--------: | :-----------------: | :----------: | :----------: | :-------: | :-----------: |
 * |  1  (0x01)   | 320x200    | 64000             |     60Hz     |     256      |   mid     |   Bordered    |
 * |  2  (0x02)   | 320x240    | 76800             |     50Hz     |     256      |   mid     |   Bordered    |
 * |  3  (0x03)   | 360x240    | 86400             |     60Hz     |     256      |   mid     |  Full screen  |
 * |  4  (0x04)   | 360x288    | 103780            |     50Hz     |     256      |   mid     |  Full Screen  |
 * |  5  (0x05)   | 640x400    | 256000            |     60Hz     |     256      |   high    |   Bordered    |
 * |  6  (0x06)   | 640x480    | 307200            |     50Hz     |     256      |   high    |   Bordered    |
 * |  7  (0x07)   | 720x480    | 345600            |     60Hz     |     256      |   high    |  Full Screen  |
 * |  8  (0x08)   | 720x576    | 414720            |     50Hz     |     256      |   high    |  Full Screen  |
 * |  9  (0x09)   | 640x512    | 327680            |     50Hz     |     256      |   high    |   Bordered    |
 * |  10 (0x0A)   | 640x256    | 163840            |     50Hz     |     256      |   half    |   Bordered    |
 * |  11 (0x0B)   | 720x240    | 172800            |     60Hz     |     256      |   half    |  Full Screen  |
 * |  12 (0x0C)   | 720x288    | 207360            |     50Hz     |     256      |   half    |  Full Screen  |
 * |  21 (0x15)   | 640x400    | 128000            |     60Hz     |      16      |   high    |   Bordered    |
 * |  22 (0x16)   | 640x480    | 153600            |     50Hz     |      16      |   high    |   Bordered    |
 * |  23 (0x17)   | 720x480    | 172800            |     60Hz     |      16      |   high    |  Full Screen  |
 * |  24 (0x18)   | 720x576    | 172800            |     50Hz     |      16      |   high    |  Full Screen  |
 * |  25 (0x19)   | 640x512    | 172800            |     50Hz     |      16      |   high    |   Bordered    |
 * |  26 (0x1A)   | 640x256    | 81920             |     50Hz     |      16      |   half    |   Bordered    |
 * |  27 (0x1B)   | 720x240    | 86400             |     60Hz     |      16      |   half    |  Full Screen  |
 * |  28 (0x1C)   | 720x288    | 103680            |     50Hz     |      16      |   half    |  Full Screen  |

 */

#ifdef _EZ80_CLANG
/**
 * @brief Assign LED strip pixel read/write zero based index
 *
 * Assign to this port the index of an RGB pixel you wish to write,
 * or read the discrete RGB values. Values are exchanged with the
 * `WS2812_LEDVAL` port.
 *
 * > Writable only
 *
 */
#define WS2812_LEDIDX PORT_IO(0xFF30)

/**
 * @brief Read or Write the 3 separate RGB values for current pixel
 *
 * After assigning the index with port `WS2812_LEDIDX`, three bytes
 * are expected to be written or read on this port.
 *
 * The three bytes represent the current pixel's Red, Green and Blue 8 bit values.
 *
 * After the 3 bytes are exchanged, the index is auto incremented.
 *
 * > Readable and Writable
 *
 */
#define WS2812_LEDVAL PORT_IO(0xFF31)

/**
 * @brief Define the current maximum number of pixels available on the attached strip.
 *
 *  When auto indexing reaches the end (as per this setting), the index is automatically reset back to 0.
 *
 * > Writable only
 */
#define WS2812_LEDCNT PORT_IO(0xFF32)

#else
__sfr __banked __at 0xFF30 WS2812_LEDIDX;
__sfr __banked __at 0xFF31 WS2812_LEDVAL;
__sfr __banked __at 0xFF32 WS2812_LEDCNT;
#endif

/**
 * @brief Set a specific WS2812 LED strip pixel's RGB colour
 *
 * @param index index of pixel
 * @param rgb the red, green, and blue components of the LEDs
 */
static inline void ws2812_set_pixel(const uint8_t index, const RGB rgb) {
  WS2812_LEDIDX = index;

  WS2812_LEDVAL = rgb.red;
  WS2812_LEDVAL = rgb.green;
  WS2812_LEDVAL = rgb.blue;
}

extern uint8_t register_31_mirror;

/**
 * @brief Sets the base VRAM page for VDP command operations
 *
 * Defines the base VRAM address (page) that will be used for all VDP command
 * operations (vdp_cmd_XXXX functions). This allows command operations to target
 * different VRAM pages without changing the display page.
 *
 * @param page The VRAM page number to used.
 *
 * @note This feature is only available with the Super HDMI Tang Nano FPGA module
 * @note Does not change which page is being displayed
 * @see vdp_set_page
 */
extern void vdp_set_command_page(const uint8_t page);

/**
 * @brief Sets the VDP extended palette registers
 *
 * Updates all 256 palette registers with new RGB color values. Each color component
 * (red, green, blue) can have a value from 0-255.
 *
 * Extended Palette features:
 * - 256 palette entries total
 * - Each entry contains RGB values
 * - Used by super graphics modes
 *
 * @param pPalette Pointer to an array of 256 RGB structures containing the new palette colors
 *
 * @note This feature is only available with the Super HDMI Tang Nano FPGA module
 */
extern void vdp_set_extended_palette(RGB *pPalette);

/**
 * @brief Sets a single entry in the VDP extended palette
 *
 * Updates a single palette register with new RGB color values in the 256-color
 * extended palette. Each color component (red, green, blue) can have a value
 * from 0-255.
 *
 * @param index The palette entry to update (0-255)
 * @param palette_entry RGB structure containing the new color values
 *
 * @note This feature is only available with the Super HDMI Tang Nano FPGA module
 * @see vdp_set_extended_palette
 */
extern void vdp_set_extended_palette_entry(uint8_t index, RGB palette_entry);

/*
  Super Graphics Modes:
   1: 320x200 @ 60hz
   2: 320x240 @ 50hz
   3: 360x240 @ 60hz
   4: 360x288 @ 50hz
   5: 640x400 @ 60hz
   6: 640x480 @ 50hz
   7: 720x480 @ 60Hz
   8: 720x576 @ 50Hz
   9: 720x240 @ 60Hz
  10: 720x288 @ 50Hz

  //TODO MODES
  11: 640x240 @ 60hz (720-80)*(480/2)
  12: 640x256 @ 50hz (720-80)*(576/2-32)
*/

/**
 * @brief Sets the VDP to Super Graphics Mode 1
 *
 * Super Graphics Mode 1 characteristics:
 * - Resolution: 320 x 200 pixels @ 60Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 64,000 bytes
 * - This mode has a small border around the main view
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 * - Border colour as per Register #7
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_1(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 2
 *
 * Super Graphics Mode 2 characteristics:
 * - Resolution: 320 x 240 pixels @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 76,800 bytes
 * - This mode has a small border around the main view
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 * - Border colour as per Register #7
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_2(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 3
 *
 * Super Graphics Mode 3 characteristics:
 * - Resolution: 360 x 240 @ 60Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 86,400
 * - This mode will fill the entire screen space
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_3(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 4
 *
 * Super Graphics Mode 4 characteristics:
 * - Resolution: 360 x 288 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 103,680
 * - This mode will fill the entire screen space
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_4(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 5
 *
 * Super Graphics Mode 5 characteristics:
 * - Resolution: 640 x 400 @ 60Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 256,000
 * - This mode has a small border around the main view
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 * - Border colour as per Register #7
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_5(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 6
 *
 * Super Graphics Mode 6 characteristics:
 * - Resolution: 640 x 480 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 307,200
 * - This mode has a small border around the main view
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 * - Border colour as per Register #7
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_6(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 7
 *
 * Super Graphics Mode 7 characteristics:
 * - Resolution: 720 x 480 @ 60Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 345,600
 * - This mode will fill the entire screen space
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_7(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 8
 *
 * Super Graphics Mode 8 characteristics:
 * - Resolution: 720 x 576 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 414,720
 * - This mode will fill the entire screen space
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_8(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 9
 *
 * Super Graphics Mode 9 characteristics:
 * - Resolution: 640 x 512 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 327, 680 bytes
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_9(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 10
 *
 * Super Graphics Mode 10 characteristics:
 * - Resolution: 640 x 256 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 163,840 bytes
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_10(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 11
 *
 * Super Graphics Mode 11 characteristics:
 * - Resolution: 720 x 240 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 172,800 bytes
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_11(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 12
 *
 * Super Graphics Mode 12 characteristics:
 * - Resolution: 720 x 288 @ 60Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 207,360 bytes
 *
 * Memory organization:
 * - Each pixel uses one byte to specify its color
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_12(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 21
 *
 * Same as Super Graphics Mode 5, but with reduced colour palette size
 *
 * Super Graphics Mode 21 characteristics:
 * - Resolution: 640 x 400 @ 60Hz
 * - Colors: Uses 16 palette colors
 * - VRAM Usage: 256,000
 * - This mode has a small border around the main view
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 * - Border colour as per Register #7
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_21(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 22
 *
 * Super Graphics Mode 22 characteristics:
 * - Resolution: 640 x 480 @ 50Hz
 * - Colors: Uses 16 palette colors
 * - VRAM Usage: 153,600
 * - This mode has a small border around the main view
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 * - Border colour as per Register #7
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_22(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 23
 *
 * Same as Super Graphics Mode 7, but with reduced colour palette size
 *
 * Super Graphics Mode 23 characteristics:
 * - Resolution: 720 x 480 @ 60Hz
 * - Colors: Uses 16 palette colors
 * - VRAM Usage: 172,800
 * - This mode will fill the entire screen space
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_23(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 24
 *
 * Super Graphics Mode 24 characteristics:
 * - Resolution: 720 x 576 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage: 207,360
 * - This mode will fill the entire screen space
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_24(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 25
 *
 * Super Graphics Mode 25 characteristics:
 * - Resolution: 640 x 512 @ 50Hz
 * - Colors: Uses 256 palette colors
 * - VRAM Usage:  bytes
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_25(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 26
 *
 * Super Graphics Mode 26 characteristics:
 * - Resolution: 640 x 256 @ 50Hz
 * - Colors: Uses 16 palette colors
 * - VRAM Usage:  bytes
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_26(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 27
 *
 * Super Graphics Mode 27 characteristics:
 * - Resolution: 720 x 240 @ 60Hz
 * - Colors: Uses 16 palette colors
 * - VRAM Usage:  bytes
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_27(void);

/**
 * @brief Sets the VDP to Super Graphics Mode 28
 *
 * Super Graphics Mode 28 characteristics:
 * - Resolution: 720 x 288 @ 50Hz
 * - Colors: Uses 16 palette colors
 * - VRAM Usage:  bytes
 *
 * Memory organization:
 * - Each pixel uses 4 bits to specify its color - 2 pixels per byte
 * - Most significant 4 bits of each byte represent the left most pixel
 * - Colors are selected from the palette registers
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 */
extern void vdp_set_super_graphic_28(void);

/**
 * @brief Retrieve the current activated super graphics mode
 *
 * If a super graphics mode is not enabled, return 0
 *
 * @return uint8_t the current super graphics mode (1 based)
 */
static inline uint8_t vdp_get_super_graphic_mode(void) { return vdp_current_mode >= 0x80 ? vdp_current_mode & 0x7F : 0; }

/**
 * @brief Set the super graphics mode
 *
 * Delegated to one of the vdp_set_super_graphics_xx function.
 * Should not have the high bit set
 *
 * > Only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 *
 * @param mode super graphics mode to select (1 base)
 */
extern void vdp_set_super_graphic_mode(uint8_t mode);

#endif
