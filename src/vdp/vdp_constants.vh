`define LEFT_BORDER 255

// display start position ( when adjust=(0,0) )
// [from V9938 Technical Data Book]
// Horizontal Display Parameters
//  [non TEXT]
//   * Total Display      1368 clks  - a
//   * Right Border         59 clks  - b
//   * Right Blanking       27 clks  - c
//   * H-Sync Pulse Width  100 clks  - d
//   * Left Blanking       102 clks  - e
//   * Left Border          56 clks  - f
// OFFSET_X is the position when preDotCounter_x is -8. So,
//    => (d+e+f-8*4-8*4)/4 => (100+102+56)/4 - 16 => 48 + 1 = 49
`define OFFSET_X 7'd49
`define LED_TV_X_NTSC -20
`define LED_TV_X_PAL -20


// Vertical Display Parameters (NTSC)
//                            [192 Lines]  [212 Lines]
//                            [Even][Odd]  [Even][Odd]
//   * V-Sync Pulse Width          3    3       3    3 lines - g
//   * Top Blanking               13 13.5      13 13.5 lines - h
//   * Top Border                 26   26      16   16 lines - i
//   * Display Time              192  192     212  212 lines - j
//   * Bottom Border            25.5   25    15.5   15 lines - k
//   * Bottom Blanking             3    3       3    3 lines - l
// OFFSET_Y is the start line of Top Border (192 Lines Mode)
//    => l+g+h => 3 + 3 + 13 = 19
`define OFFSET_Y 7'd16
`define LED_TV_Y_NTSC 1
`define LED_TV_Y_PAL 3

`ifdef ENABLE_SUPER_RES
`define VDP_ID 5'b10010  // V9958 - SUPER
`else
`define VDP_ID 5'b00010  // V9958
`endif

`define V_BLANKING_START_192_NTSC 240
`define V_BLANKING_START_212_NTSC 250
`define V_BLANKING_START_192_PAL 263
`define V_BLANKING_START_212_PAL 273

`define MEMORY_WIDTH_8 (2'b00)
`define MEMORY_WIDTH_16 (2'b01)
`define MEMORY_WIDTH_32 (2'b10)
