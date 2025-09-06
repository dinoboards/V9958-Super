#ifndef __V9958
#define __V9958

/**
 * @file v99x8.h
 * @brief Functions and supporting structures to access the V9958/V9938 on-chip functions.
 *
 * The V9958 and V9938 Video Display Process from YAMAHA has many on chip features.  It
 * is recommended you familiarise yourself with the V9958/V9938 spec docs from YAMAHA.
 *
 * * [V9938 Datasheet](https://github.com/dinoboards/yellow-msx-series-for-rc2014/blob/main/datasheets/yamaha_v9938.pdf)
 * * [V9938 Datasheet](https://github.com/dinoboards/yellow-msx-series-for-rc2014/blob/main/datasheets/yamaha_v9958.pdf)
 */

#include <ez80.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#define PAL  1
#define NTSC 2

#ifdef _EZ80_CLANG
typedef uint24_t screen_size_t;
typedef uint24_t screen_addr_t;
#define MAX_SCREEN_BYTES 0x20000
#else
typedef uint16_t screen_size_t;
typedef uint32_t screen_addr_t;
#define MAX_SCREEN_BYTES 0x20000
#endif

/**
 * @brief an 8Bit per color RGB colour code
 *
 */
typedef struct {
  uint8_t red;
  uint8_t green;
  uint8_t blue;
} RGB;

#ifdef _EZ80_CLANG

extern uint16_t VDP_IO_DATA;
extern uint16_t VDP_IO_ADDR;
extern uint16_t VDP_IO_PALT;
extern uint16_t VDP_IO_REGS;

#define VDP_DATA PORT_IO(VDP_IO_DATA)
#define VDP_ADDR PORT_IO(VDP_IO_ADDR)
#define VDP_PALT PORT_IO(VDP_IO_PALT)
#define VDP_REGS PORT_IO(VDP_IO_REGS)
#else

#define VDP_IO_DATA 0xFF98
#define VDP_IO_ADDR 0xFF99
#define VDP_IO_PALT 0xFF9A
#define VDP_IO_REGS 0xFF9B

__sfr __banked __at VDP_IO_DATA VDP_DATA;
__sfr __banked __at VDP_IO_ADDR VDP_ADDR;
__sfr __banked __at VDP_IO_PALT VDP_PALT;
__sfr __banked __at VDP_IO_REGS VDP_REGS;
#endif

extern uint8_t vdp_current_mode; /* private */

#define REGISTER_COUNT 12
extern uint8_t registers_mirror[REGISTER_COUNT]; /* private */

/**
 * @brief Write byte to the VDP's COMMAND port
 *
 * @param v byte to be sent to the COMMAND port
 */
static inline void vdp_out_cmd(const uint8_t v) { port_out(VDP_IO_ADDR, v); }

#define vdp_out_dat(v)      port_out(VDP_IO_DATA, v)
#define vdp_out_pal(v)      port_out(VDP_IO_PALT, v)
#define vdp_out_reg_byte(v) port_out(VDP_IO_REGS, v)

#define VDP_TMS   1
#define VDP_V9938 2
#define VDP_V9958 3
#define VDP_SUPER 4

/**
 * @brief Discover version of VDP and initialise its internal registers
 *
 * @note does not enable any specific graphics mode
 * @note should be called before any vdp operations
 */
extern uint8_t vdp_init(void);

extern void set_base_registers(void); /* private */

extern void vdp_clear_all_memory(void);

/**
 * @brief Sets the VDP palette registers
 *
 * Updates all 16 palette registers with new RGB color values. Each color component
 * (red, green, blue) can have a value from 0-7, giving 512 possible colors.
 *
 * Palette organization:
 * - 16 palette entries total
 * - Each entry contains RGB values
 * - Used by graphics modes 4-6
 *
 * @param palette Pointer to an array of 16 RGB structures containing the new palette colors
 *
 * @note For Graphics Mode 7, the palette is fixed and cannot be changed
 */
extern void vdp_set_palette(RGB *palette);

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

extern void vdp_set_mode(const uint8_t mode, const uint8_t lines, const uint8_t refresh_rate);

static inline uint8_t vdp_get_mode(void) { return vdp_current_mode; }

/**
 * @brief Switches between VRAM pages in supported graphics modes
 *
 * @param page The VRAM page number to be used.
 *
 * Changes the active VRAM page for graphics modes that support page flipping (G6 and G7).
 * Each page represents a complete screen buffer of 128KB. Switching pages allows for
 * double-buffering techniques.
 *
 * The number of pages available are dependant on the available memory and the mode selected
 *
 * @note Only works in Graphics modes 6 and 7 and (super graphics modes if available)
 */
extern void vdp_set_page(const uint8_t page);

extern void vdp_erase_bank0(uint8_t color);
extern void vdp_erase_bank1(uint8_t color);
extern void _vdp_reg_write(uint16_t rd);
extern void vdp_out_reg_int16(uint16_t b);

extern uint8_t vdp_get_status(uint8_t r);

#define vdp_reg_write(reg_num, value) _vdp_reg_write((reg_num) * 256 + (value))

/**
 * @brief Get the current screen width
 *
 * Returns the width in pixels of the current video mode:
 * - Standard modes: 256 or 512 pixels
 * - Super Graphics Mode 1: 360 pixels
 * - Super Graphics Mode 2: 720 pixels
 *
 * @return uint24_t The current screen width in pixels
 */
extern screen_size_t vdp_get_screen_width(void);

/**
 * @brief Get the current screen height
 *
 * Returns the height in pixels of the current video mode:
 * - Standard modes: 192 (60Hz) or 212 (50Hz) lines
 * - Super Graphics Mode 1: 240 (60Hz) or 288 (50Hz) lines
 * - Super Graphics Mode 2: 480 (60Hz) or 576 (50Hz) lines
 *
 * @return uint24_t The current screen height in pixels
 */
extern screen_size_t vdp_get_screen_height(void);

/**
 * @brief Return current maximum number of unique colours that can be displayed
 *
 * For all modes other than Graphics Mode 7, return the palette depth look up - typically
 * 256, 16 or 4 unique colours
 *
 * For Graphics mode 7, return 256
 *
 * @return uint24_t the max number of unique colours
 */
extern uint16_t vdp_get_screen_max_unique_colours(void);

/**
 * @brief copy data from CPU to VRAM
 *
 * @param source the byte data to be copied
 * @param vdp_address to destination address in VRAM
 * @param length the number of bytes to be copied
 */
extern void vdp_cpu_to_vram(const uint8_t *const source, screen_addr_t vdp_address, uint16_t length);

/**
 * @brief copy data from CPU to VRAM address 0x000000
 *
 *
 * @param source the byte data to be copied
 * @param length the number of bytes to be copied
 */
extern void vdp_cpu_to_vram0(const uint8_t *const source, uint16_t length);

#define DIX_RIGHT 0
#define DIX_LEFT  4
#define DIY_DOWN  0
#define DIY_UP    8

/**
 * @brief VDP command 'High-speed move VDP to VRAM'
 *
 * Command Code: CMD_HMMV 0xC0
 *
 * The HMMV command is used to paint in a specified rectangular area of the VRAM or the expansion RAM.
 * Since the data to be transferred is done in units of one byte, there is a limitation due to the display mode, on the value for x.
 *
 * @note that in the G4 and G6 modes, the lower one bit, and in the G5 mode, the lower two bits of x and width, are lost.
 *
 * @param x the starting x-coordinate of the rectangle
 * @param y the starting y-coordinate of the rectangle
 * @param width the width of the rectangle in pixels
 * @param height the height of the rectangle in pixels
 * @param colour the colour code to be painted (as per the current graphics mode)
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 */
extern void vdp_cmd_vdp_to_vram(uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t colour, uint8_t direction);

/**
 * @brief VDP command 'High-speed move CPU to VRAM'
 *
 * Command Code: CMD_HMMC 0xF0
 *
 * The HMMC command is used to transfer data from the CPU to the VRAM or the expansion RAM.
 * Since the data to be transferred is done in units of one byte, there is a limitation due to the display mode, on the value for x.
 *
 * @note that in the G4 and G6 modes, the lower one bit, and in the G5 mode, the lower two bits of x and width, are lost.
 *
 * @param source the byte data to be copied to the VDP's VRAM
 * @param x the starting x-coordinate of the rectangle
 * @param y the starting y-coordinate of the rectangle
 * @param width the width of the rectangle in pixels
 * @param height the height of the rectangle in pixels
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param length the number of bytes to be copied (width * height)
 */
extern void vdp_cmd_move_cpu_to_vram(
    const uint8_t *source, uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t direction, screen_addr_t length);

/**
 * @brief Prepare VDP command 'High-speed move CPU to VRAM'
 *
 * This function issues the same command as vdp_cmd_move_cpu_to_vram. The difference is that it expects
 * the data to be sent via the vdp_cmd_send_byte function.
 *
 * @param first_byte the first data byte to be sent to the VDP
 * @param x the starting x-coordinate of the rectangle
 * @param y the starting y-coordinate of the rectangle
 * @param width the width of the rectangle in pixels
 * @param height the height of the rectangle in pixels
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param length the number of bytes to be copied (width * height)
 */
extern void vdp_cmd_move_data_to_vram(
    uint8_t first_byte, uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t direction, screen_addr_t length);

#ifdef VDP_SUPER_HDMI
/**
 * @hide
 * @brief transmit the next data byte to the VDP for the current pending command
 *
 * @param next_byte the data to be sent to the VDP
 */
static inline void vdp_cmd_send_byte(uint8_t next_byte) { VDP_REGS = next_byte; }
#else

/**
 * @brief transmit the next data byte to the VDP for the current pending command
 *
 * @param next_byte the data to be sent to the VDP
 */
void vdp_cmd_send_byte(uint8_t next_byte);
#endif

/**
 * @brief VDP command 'High-speed move VRAM to VRAM, y only'
 *
 * Command Code: CMD_YMMM 0xE0
 *
 * The YMMM command transfers data from the area specified by x, y, to_y, height and the right (or left) edge of the Video RAM, in
 * the y-direction.
 *
 * @param x the starting x-coordinate of the rectangle
 * @param from_y the starting y-coordinate of the rectangle
 * @param to_y the y-coordinate of the top-left corner of the destination rectangle
 * @param height the number of pixels to be copied in the y-direction
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 */
extern void vdp_cmd_move_vram_to_vram_y(uint16_t x, uint16_t from_y, uint16_t to_y, uint16_t height, uint8_t direction);

/**
 * @brief VDP command 'High-speed move VRAM to VRAM'
 *
 * Command Code: CMD_HMMM 0xD0
 *
 * The HMMM command transfers data in a specified rectangular area from the VRAM or the expansion RAM to the VRAM or the expansion
 * RAM. Since the data to be transferred is done in units of one byte, there is a limitation due to the display mode, on the value
 * for x.
 *
 * @param x the starting x-coordinate of the source rectangle
 * @param y the starting y-coordinate of the source rectangle
 * @param to_x the starting x-coordinate of the destination rectangle
 * @param to_y the starting y-coordinate of the destination rectangle
 * @param width the width of the rectangle in pixels to be copied
 * @param height the height of the rectangle in pixels to be copied
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 */
extern void
vdp_cmd_move_vram_to_vram(uint16_t x, uint16_t y, uint16_t to_x, uint16_t to_y, uint16_t width, uint16_t height, uint8_t direction);

/**
 * @brief VDP Command 'Logical Move CPU to VRAM'
 *
 * Command Code: CMD_LMMC 0xB0
 *
 * The LMMC command transfers data from the CPU to the Video or expansion RAM in a specified rectangular area (in x-y coordinates).
 *
 * @param source the byte data to be copied to the VDP's VRAM
 * @param x the starting x-coordinate of the rectangle
 * @param y the starting y-coordinate of the rectangle
 * @param width the width of the rectangle in pixels
 * @param height the height of the rectangle in pixels
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param length the number of bytes to be copied (width * height)
 * @param operation the logical operation to be performed (CMD_LOGIC_IMP, CMD_LOGIC_AND, ...)
 */
extern void vdp_cmd_logical_move_cpu_to_vram(const uint8_t *const source,
                                             uint16_t             x,
                                             uint16_t             y,
                                             uint16_t             width,
                                             uint16_t             height,
                                             uint8_t              direction,
                                             screen_addr_t        length,
                                             uint8_t              operation);

extern void vdp_cmd_logical_move_data_to_vram(uint8_t       first_byte,
                                              uint16_t      x,
                                              uint16_t      y,
                                              uint16_t      width,
                                              uint16_t      height,
                                              uint8_t       direction,
                                              screen_addr_t length,
                                              uint8_t       operation);

/**
 * @brief VDP Command 'Logical Move VRAM to CPU'
 *
 * Command Code: CMD_LMCM 0xA0
 *
 * The LMCM command transfers data from the Video or expansion RAM to the CPU in a specified rectangular area (in x-y coordinates).
 *
 * @param destination the location to store the retrieve data from VRAM
 * @param x the starting x-coordinate of the rectangle
 * @param y the starting y-coordinate of the rectangle
 * @param width the width of the rectangle in pixels
 * @param height the height of the rectangle in pixels
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param length the number of bytes to be copied (width * height)
 */
extern void vdp_cmd_logical_move_vram_to_cpu(
    uint8_t *destination, uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t direction, screen_addr_t length);

/**
 * @brief VDP Command 'Logical Move VRAM to VRAM'
 *
 * Command Code: CMD_LMMM 0x90
 *
 * The LMMM command transfers data in a specified rectangular area from the VRAM or the expansion RAM to the VRAM or the expansion.
 * Since the data to be transferred is done in units of dots, logical operations may be done on the destination data.
 *
 * @param x the starting x-coordinate of the source rectangle
 * @param y the starting y-coordinate of the source rectangle
 * @param to_x the starting x-coordinate of the destination rectangle
 * @param to_y the starting y-coordinate of the destination rectangle
 * @param width the width of the rectangle in pixels to be copied
 * @param height the height of the rectangle in pixels to be copied
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param operation the logical operation to be performed (CMD_LOGIC_IMP, CMD_LOGIC_AND, ...)
 */
extern void vdp_cmd_logical_move_vram_to_vram(
    uint16_t x, uint16_t y, uint16_t to_x, uint16_t to_y, uint16_t width, uint16_t height, uint8_t direction, uint8_t operation);

/**
 * @brief VDP Command 'Logical Move VDP to VRAM'
 *
 * Command Code: CMD_LMMV 0x80
 *
 * The LMMV command paints in a specified rectangular area of the Video or Expansion RAM according to a specified color code.
 * The data is transferred in units of one dot, and a logical operation may be done on the destination data.
 *
 * @param x the starting x-coordinate of the rectangle
 * @param y the starting y-coordinate of the rectangle
 * @param width the width of the rectangle in pixels
 * @param height the height of the rectangle in pixels
 * @param colour the colour code to be painted
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param operation the logical operation to be performed (CMD_LOGIC_IMP, CMD_LOGIC_AND, ...)
 */
extern void vdp_cmd_logical_move_vdp_to_vram(
    uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t colour, uint8_t direction, uint8_t operation);

/**
 * @brief VDP LINE drawing command
 *
 * The LINE command draws a straight line in the Video or Expansion RAM. The line drawn is the hypotenuse that results after the
 * long and short sides of a triangle are defined. The two sides are defined as distances from a single point.
 *
 * @param x the starting x-coordinate of the rectangle
 * @param y the starting y-coordinate of the rectangle
 * @param long_length the number of pixels on the long side
 * @param short_length the number of pixels on the short side
 * @param colour the colour code to be painted
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param operation the logical operation to be performed (CMD_LOGIC_IMP, CMD_LOGIC_AND, ...)
 */
extern void vdp_cmd_line(
    uint16_t x, uint16_t y, uint16_t long_length, uint16_t short_length, uint8_t direction, uint8_t colour, uint8_t operation);

extern int16_t vdp_cmd_search(uint16_t x, uint16_t y, uint8_t colour, uint8_t operation);

extern void vdp_cmd_pset(uint16_t x, uint16_t y, uint8_t colour, uint8_t operation);

extern uint8_t vdp_cmd_point(uint16_t x, uint16_t y);

#define CMD_POINT 0x40
#define CMD_PSET  0x50
#define CMD_SRCH  0x60
#define _CMD_LINE 0x70
#define CMD_LMMV  0x80
#define CMD_LMMM  0x90
#define CMD_LMCM  0xA0
#define CMD_LMMC  0xB0
#define CMD_HMMV  0xC0
#define CMD_HMMM  0xD0
#define CMD_YMMM  0xE0
#define CMD_HMMC  0xF0

#define CMD_LOGIC_IMP       0x00 /* DC =  SC */
#define CMD_LOGIC_AND       0x01 /* DC &= SC */
#define CMD_LOGIC_OR        0x02 /* DC |= SC */
#define CMD_LOGIC_EOR       0x03 /* DC ^= SC */
#define CMD_LOGIC_NOT       0x04 /* DC = !SC */
#define CMD_LOGIC_REMAP     0x05 /* DC = (SC == 0) ? REMAP_BACK_COLOUR : REMAP_FORE_COLOUR */
#define CMD_LOGIC_REMAP_XOR 0x06 /* DC = (SC == 0) ? DC ^ REMAP_BACK_COLOUR : DC ^ REMAP_FORE_COLOUR */

#define CMD_LOGIC_TIMP 0x08 /* if SC != 0 then DC =  SC */
#define CMD_LOGIC_TAND 0x09 /* if SC != 0 then DC &= SC*/
#define CMD_LOGIC_TOR  0x10 /* if SC != 0 then DC |= SC*/
#define CMD_LOGIC_TEOR 0x11 /* if SC != 0 then DC ^= SC*/
#define CMD_LOGIC_TNOT 0x12 /* if SC != 0 then DC != SC*/

// deprecated
extern void vdp_cmd(void);

extern void vdp_cmd_wait_completion(void);

extern uint16_t vdp_cmdp_r36;
extern uint16_t vdp_cmdp_r38;
extern uint16_t vdp_cmdp_r40;
extern uint16_t vdp_cmdp_r42;
extern uint8_t  vdp_cmdp_r44;
extern uint8_t  vdp_cmdp_r45;
extern uint8_t  vdp_cmdp_r46;

#define vdp_cmdp_dx        vdp_cmdp_r36
#define vdp_cmdp_dy        vdp_cmdp_r38
#define vdp_cmdp_nx        vdp_cmdp_r40
#define vdp_cmdp_ny        vdp_cmdp_r42
#define vdp_cmdp_color     vdp_cmdp_r44
#define vdp_cmdp_dir       vdp_cmdp_r45
#define vdp_cmdp_operation vdp_cmdp_r46

extern void vdp_draw_line(uint16_t from_x, uint16_t from_y, uint16_t to_x, uint16_t to_y, uint8_t colour, uint8_t operation);

// deprecated
#define pointSet(x, y, color, operation)                                                                                           \
  vdp_cmdp_dx        = (x);                                                                                                        \
  vdp_cmdp_dy        = (y);                                                                                                        \
  vdp_cmdp_color     = (color);                                                                                                    \
  vdp_cmdp_operation = CMD_PSET((operation));                                                                                      \
  vdp_cmd()

extern void vdp_set_lines(const uint8_t lines);

/**
 * @brief Set the refresh rate of the display output
 *
 * Refresh can be set to 50Hz or 60Hz
 *
 * Apply this setting before setting a standard graphics mode
 *
 * This function is not applicable for super res modes as
 * each super graphics mode already configures a specific refresh
 * rate
 *
 * Possible values are:
 * `PAL` or 50 to select 50Hz, and `NTSC` or 60 to select 60Hz
 *
 * @param refresh_rate to be applied
 */
extern void vdp_set_refresh(const uint8_t refresh_rate);

/**
 * @brief Return the current refresh rate
 *
 * @note the return value is one of 50 or 60
 * @note will never equate to PAL or NTSC
 *
 * @param refresh_rate the actual refresh rate
 */
static inline uint8_t vdp_get_refresh(void) { return registers_mirror[9] & 0x02 ? 50 : 60; }

/**
 * @brief Sets the VDP to Graphics Mode 7 (G7)
 *
 * Graphics Mode 7 characteristics:
 * - Resolution: 256 x 212 pixels (50Hz) or 256 x 192 pixels (60Hz)
 * - Colors: 256 colors per screen from a fixed color space
 * - VRAM Usage: 128KB (supports two screens)
 * - Sprite Mode: 2
 *
 * Color encoding:
 * Each pixel is represented by 1 byte with the following bit layout:
 * - Bits 7-6: Green (2 bits)
 * - Bits 5-3: Red (3 bits)
 * - Bits 2-0: Blue (3 bits)
 *
 * The pattern name table contains one byte per pixel that directly
 * specifies its color (not a palette index).
 *
 * Controls
 * - Graphics - VRAN pattern name table
 * - Background color: Set by low-order four bits of Register 7
 * - Sprites: Uses VRAM sprite attribute table and sprite pattern table
 *
 */
extern void vdp_set_graphic_7(void);

/**
 * @brief Sets the VDP to Graphics Mode 6 (G6)
 *
 * Graphics Mode 6 characteristics:
 * - Resolution: 512 x 212 pixels (50Hz) or 512 x 192 pixels (60Hz)
 * - Colors: 16 colors per screen from a palette of 512 colors
 * - VRAM Usage: 128KB (supports two screens)
 * - Sprite Mode: 2
 *
 * Pattern name table characteristics:
 * - One byte represents two horizontal pixels
 * - Each pixel can be assigned one of 16 colors
 * - Colors are selected from a palette of 512 possible colors
 *
 * Controls:
 * - Background color: Set by low-order four bits of Register 7
 * - Sprites: Uses VRAM sprite attribute table and sprite pattern table
 */
extern void vdp_set_graphic_6(void);

/**
 * @brief Sets the VDP to Graphics Mode 5 (G5)
 *
 * Graphics Mode 5 characteristics:
 * - Resolution: 512 x 212 pixels (50Hz) or 512 x 192 pixels (60Hz)
 * - Colors: 4 colors per screen from a palette of 512 colors
 * - VRAM Usage: 32KB per screen
 * - Sprite Mode: 2
 *
 * Pattern name table characteristics:
 * - One byte represents four horizontal pixels
 * - Each pixel can be assigned one of 4 colors
 * - Colors are selected from a palette of 512 possible colors
 *
 * Hardware tiling features:
 * - Separate color control for even/odd dots
 * - Higher-order two bits specify even dot colors
 * - Lower-order two bits specify odd dot colors
 * - Applies to both sprite and background colors
 * - Sprite dots can display two colors when using tiling
 *
 * Controls:
 * - Background color: Set by low-order four bits of Register 7
 * - Sprite attributes: Set in Register 5 and Register 11
 * - Sprite patterns: Set in Register 6
 * - Sprites: Uses VRAM sprite attribute table and pattern table
 *
 * @note Sprites in this mode are twice the width of graphics dots but can
 *       show two colors per dot when using the tiling function
 */
extern void vdp_set_graphic_5(void);

/**
 * @brief Sets the VDP to Graphics Mode 4 (G4)
 *
 * Graphics Mode 4 characteristics:
 * - Resolution: 256 x 212 pixels (50Hz) or 256 x 192 pixels (60Hz)
 * - Colors: 16 colors per screen from a palette of 512 colors
 * - VRAM Usage: 32KB per screen
 * - Sprite Mode: 2
 *
 * Pattern name table characteristics:
 * - One byte represents two horizontal pixels
 * - Each pixel can be assigned one of 16 colors
 * - Colors are selected from a palette of 512 possible colors
 *
 * Controls:
 * - Background color: Set by low-order four bits of Register 7
 * - Sprite attributes: Set in Register 5 and Register 11
 * - Sprite patterns: Set in Register 6
 * - Sprites: Uses VRAM sprite attribute table and pattern table
 *
 * @note This is a bit-mapped graphics mode with direct color specification
 *       for each pixel pair
 */
extern void vdp_set_graphic_4(void);

/**
 * @brief Retrieve the current activated graphics mode
 *
 * Super graphics mode are indicated with high bit set
 *
 * @return uint8_t the current graphics mode
 */
static inline uint8_t vdp_get_graphic_mode(void) { return vdp_current_mode; }

/**
 * @brief Set the graphics or super graphics mode
 *
 * If high bit set, then a super graphics mode is selected
 *
 * > Super graphics modes are only supported on the Super HDMI Tang Nano 20K
 * > custom kit with the SUPER_RES extensions enabled.
 *
 * @param mode the graphic mode to enable
 */
extern void vdp_set_graphic_mode(uint8_t mode);

/**
 * @brief Configures the colours applied for logical CMD_LOGIC_REMAP operation
 *
 * @param remap_background_colour the palette index for background (zero) colour
 * @param remap_foreground_colour the palette index for foreground (non zero) colour
 *
 * @see vdp_cmd_move_linear_to_xy
 */
extern void vdp_set_remap(uint8_t remap_background_colour, uint8_t remap_foreground_colour);

/**
 * @brief VDP command 'Byte move to X, Y from Linear'
 *
 * Command Code: CMD_BMXL 0x30
 *
 * The BMXL command transfers data in a specified rectangular area from the linear address in VRAM to the rectangular area.
 *
 * This command is similar to `vdp_cmd_logical_move_vram_to_vram` function, but instead of using a data source of a bounded
 * rectangle, the `vdp_cmd_move_linear_to_xy` function retrieves its source data from the linear address space starting at
 * `src_addr` within the VRAM.
 *
 * When used with logical operation other than `CMD_LOGIC_REMAP_xxx`, the function will read a byte for each destination pixel,
 * regardless of the pixel depths of the destination.  As such, if used on a destination that only support a 4 bit pixel depth, only
 * the lower 4 bits of each byte are applied to the logical operation.
 *
 * When used with logical operation `CMD_LOGIC_REMAP_xxx`, the individual bits of the source data are maps to the individual destination
 * pixels.  As such, the first byte at `src_addr` will be mapped to the first 8 bytes of the destination rectangle.  If the bit is
 * 0, the `remap_background_colour` is applied to the pixel and if the bit is a 1, then the `remap_foreground_colour` value is
 * applied.
 *
 * > This function is only available with the Super HDMI Tang Nano FPGA module
 *
 * @param src_addr the source address in VRAM of bytes to be transferred
 * @param x the starting x-coordinate of the destination rectangle
 * @param y the starting y-coordinate of the destination rectangle
 * @param width the width of the rectangle in pixels to be copied
 * @param height the height of the rectangle in pixels to be copied
 * @param direction the direction of the painting (DIX_RIGHT, DIX_LEFT, DIY_DOWN, DIY_UP)
 * @param operation the logical operation to be performed (CMD_LOGIC_IMP or CMD_LOGIC_REMAP_xxx)
 *
 *
 * @see vdp_set_remap
 * @see vdp_cmd_logical_move_vram_to_vram
 *
 */
extern void vdp_cmd_move_linear_to_xy(
    screen_addr_t src_addr, uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t direction, uint8_t operation);

#endif
