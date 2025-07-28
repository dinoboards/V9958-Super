
## Super high res modes

In addition to supporting the capabilities of the V9958, this module also supports additional capabilities - higher resolutions, more colours and flexible viewport control.  To access these extended capabilities new registers and extended registers have been added.

This document describes the additional registers over the stock V9958 registers.  It assumes some familiarity with the register access of the V9958 VDP chip.

* Change identity response returned from status register `S#1`
* The additional registers (`R#29`, `R#30` and `R#31`)
* The super extended registers - accessed indirectly through `R#29` and `R#30`

The [eZ80 for RC](https://www.dinoboards.com.au/ez80-for-rc)'s clang tool chain has support for the V9958 and the extended register capabilities of this module.  See

> Please note, the higher resolution PORTS are only effective, when the V9958 is configured for GRAPHICS MODE 7.

## Changed Status Register

### `S#1` - VDP ID CHANGED

BIT 5:1 - VDP ID

  10010 -> BIT 2 indicate V9958 and BIT 5 set indicates extra SUPER FEATURES

## Additional registers

The additional registers (29 to 31) are access as per V9958 register access.  See the V9958 documentation details on accessing the chip's registers.

The extended registers, are another set of registers, indexed by the value within `R#29`.

### `R#29`

Index to use for writing to the super extended registers.  Auto incremented as values are written to register `R#30`

### `R#30`

Writes to current super extended register value.

### `R#31`

Bit flags to turn on specific extended graphics modes or capabilities - higher resolutions and 24bit colours.

BIT 0: Reserved

#### BIT 2:1 == 1 ***SUPER_MID*** graphics mode:

##### PALETTE_DEPTH: 0
* colour from palette register
* resolution at 50Hz:360x288 (103680 Bytes)
* resolution at 60Hz:360x240 (86400 bytes)

#### BIT 2:1 == 2 ***SUPER_HIGH*** graphics mode:

##### PALETTE_DEPTH: 0
* 1 pixel per byte
* colour from palette register
* resolution at 50Hz:720x576 (414720 Bytes)
* resolution at 60Hz:720x480 (345600 bytes)

##### PALETTE_DEPTH: 1
* 2 pixels per byte
* colour from palette register
* resolution at 50Hz:720x576 (207360 Bytes)
* resolution at 60Hz:720x480 (172800 bytes)

#### BIT 2:1 == 3 ***SUPER_HALF*** graphics mode:

##### PALETTE_DEPTH: 0
* 1 pixel per byte
* colour from palette register
* resolution at 50Hz:720x288 (207360 Bytes)
* resolution at 60Hz:720x240 (172800 bytes)

##### PALETTE_DEPTH: 1
* 2 pixels per byte
* colour from palette register
* resolution at 50Hz:720x288 (103680 Bytes)
* resolution at 60Hz:720x240 (86400 bytes)

BIT 3: ***EXTENDED PALETTE***
* If set, enables 8 bits per colour for each colour entry in the colour palette (24bits in total).  Modifies the behaviour
  of the palette data port - instead of expecting one byte per entry, 3 bytes are expected for each of the RGB colour codes.
* up to 256 palette entries can be stored - but only the super res modes support the full palette set.

## Extended Register

### View Port Dimensions

Describe in more detail below, the extended registers, `#EXTR0` to `#EXTR7`, can be used to define a boundary
rectangle that will constrain or clip the super res modes.  Smaller rendering rectangles can aid in performance,
as the increase in blanking period grants the CPU/VDP more time for VRAM access.

The values are in units of the relevant native HDMI resolution (50Hz: 720x576, 60Hz: 720x480)

> For example, if a boundary rectangle of 640x400 is defined, and `SUPER_MID` mode is selected, the resulting resolution will be 320x200.

### `EXTR#0` & `EXTR#1` (VIEW_PORT_START_X - #0 LSB, #1 MSB - 10 bits)

Defines the X starting position for rendering.  Default 0.

The value represents the first horizontal pixel that will be displayed.

Must be a value less than `VIEW_PORT_END_X` and greater than or equal to 0.

### `EXTR#2` & `EXTR#3` (VIEW_PORT_END_X - #2 LSB, #3 MSB - 10 bits)

Defines the X ending position for rendering.  Default 720.

The value represents the first horizontal pixel that will not be displayed.

Must be a value greater than `VIEW_PORT_START_X` and less than or equal to 720.

### `EXTR#4` & `EXTR#5` (VIEW_PORT_START_Y - #4 LSB, #5 MSB - 10 bits)

Defines the Y starting position for rendering.  Default 0.

The value represents the first vertical row that will be displayed.

### `EXTR#6` & `EXTR#7` (VIEW_PORT_END_Y - #6 LSB, #7 MSB - 10 bits)

Defines the Y ending position for rendering.  Default -1.

The value represents the first vertical row that will not be displayed.

Must be a value greater than `VIEW_PORT_START_Y` and less than or equal to the current HDMI's horizontal resolution (50Hz: 576, 60Hz: 480).

A value of -1 is special, and indicates that it should use all available height. For 50Hz operation, this is equivalent to 576. For 60Hz operation, this is equivalent to 480

#### VRAM Addressing

### `EXTR#8`..`EXTR#10` (SUPER_BASE_RENDERING_ADDR - #8 LSB, #10 MSB - 20 bits)

Defines the base starting VRAM address for rendering the current super resolution mode.

> As the underlying VRAM address must be on a 4 byte boundary, the address specified in the registers is the VRAM address multiplied by 4. That is, a value of 16 refers to the byte address of 64 (16*4).

> Only when the MSB is written (`EXTR#10`), will the new address be applied to rendering.

### `EXTR#11`..`EXTR#13` (SUPER_BASE_COMMAND_ADDR - #11 LSB, #13 MSB - 20 bits)

Defines the base starting VRAM address to use for all command operations. (Line, Fill, etc)

Not recommend to change this value, until any existing commands have completed.

> As the underlying VRAM address must be on a 4 byte boundary, the address specified in the registers is the VRAM address multiplied by 4. That is, a value of 16 refers to the byte address of 64 (16*4).

> Only when the MSB is written (`EXTR#13`), will the new address be applied to command operations.

Changing these address enables a double buffering process.

To enable double buffering writes, do something along the lines of:

1. Enter the super resolution mode, eg: super_mid @ 50Hz (320x288)
2. Set the `SUPER_BASE_COMMAND_ADDR` to the address of the 2nd page (320x288/4 = 23040)
2. Issue commands to draw on the '2nd page' (box, fills, lines).
3. Once all drawing is complete, update the `SUPER_BASE_RENDERING_ADDR` to 2nd page address 23040.  The 2nd page will now displayed.
2. Set the `SUPER_BASE_COMMAND_ADDR` to the address of the 1st page (0)
5. When ready to switch rendering back to the '1st page', by setting the `SUPER_BASE_RENDERING_ADDR` to 0.
6. Repeat...

### Palette Depth
### `EXTR#14` (PALETTE_DEPTH)

Defines the bits per pixel used for the super res graphics mode.

By default, all super graphics mode use 1 byte (8 bits) for each pixel.  The value of the byte is used to lookup into the palette register.

The `PALETTE_DEPTH` register allows for reducing the number of bits used per pixels.  By reducing the number of bits per pixel, the total memory used by the super graphics modes is reduced, but also reducing the total number of unique colours that can be displayed at once.

| Value | Description | Total Unique Colours |
| ----- | ----------- | -------------------- |
|  00   | 1 byte per pixel aka 8 bits per pixel | 256 |
|  01   | 2 pixels per byte aka 4 bits per pixel | 16 |
|  02*  | 4 pixels per byte aka 2 bits per pixel | 4 |
|  03*  | 8 pixels per byte aka 1 bit per pixel | 2 |

\* Not yet implemented

When less than 8 bits per pixel is selected - the most significant bits represent the left most pixel, and the least signficiate bit will be used for the last pixel represented by the byte.


### `EXTR#255` (RESET)

Super Res Reset flags

This register can be used to reset some or all of the extended registers to their defaults.  If a specific bit of the byte written to this register is set, a corresponding set of extended registers are returned to their defaults.

If the value of 255 is written then all extended registers are returned to their defaults.

| Bit | Registers |
| --- | --------- |
| 0   | `EXTR#0` to `EXTR#7` (VIEW_PORT_xxx) |
| 1   | `EXTR#8` to `EXTR#10` (SUPER_BASE_RENDERING_ADDR) |
| 2   | `EXTR#11` to `EXTR#13` (SUPER_BASE_COMMAND_ADDR) |
| 3   | `EXTR#14` (PALETTE_DEPTH) |

<hr/>

## Some Common Resolution and Colour configurations

### Super Graphics Mode 1

Characteristics:
- Resolution: 320 x 200 pixels @ 60Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 64,000 bytes
- This mode has a small border around the main view

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers
- Border colour as per Register #7

#### Pseudo Code

```
  set_refresh 60
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7       # reset VIEW PORT and BASE ADDR
  reg_write 31, $80+1   # set SUPER_MID mode

  reg_write 29, $00
  reg_write 30, $28    # 0:VIEW_PORT_START_X  Low  byte 40 ($28)
  reg_write 30, $00    # 1:VIEW_PORT_START_X  High byte 40 ($28)
  reg_write 30, $A8    # 2:VIEW_PORT_END_X    Low  byte 680 ($2A8)
  reg_write 30, $02    # 3:VIEW_PORT_END_X    High byte 680 ($2A8)
  reg_write 30, $28    # 4:VIEW_PORT_START_Y  Low  byte 40 ($28)
  reg_write 30, $00    # 5:VIEW_PORT_START_Y  High byte 40 ($0)
  reg_write 30, $B8    # 6:VIEW_PORT_END_Y    Low  byte 440 ($1B0)
  reg_write 30, $01    # 7:VIEW_PORT_END_Y    High byte 440 ($1B0)
```

### Super Graphics Mode 2

Characteristics:
- Resolution: 320 x 240 pixels @ 60Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 76,800 bytes
- This mode has a small border around the main view

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers
- Border colour as per Register #7

#### Pseudo Code

```
  set_refresh 50
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7      # reset VIEW PORT and BASE ADDR
  reg_write 31, $80+2  # set SUPER_MID mode

  reg_write 29, $00
  reg_write 30, $28    # 0:VIEW_PORT_START_X  Low  byte 40 ($28)
  reg_write 30, $00    # 1:VIEW_PORT_START_X  High byte 40 ($28)
  reg_write 30, $A8    # 2:VIEW_PORT_END_X    Low  byte 680 ($2A8)
  reg_write 30, $02    # 3:VIEW_PORT_END_X    High byte 680 ($2A8)
  reg_write 30, $30    # 4:VIEW_PORT_START_Y  Low  byte 48 ($30)
  reg_write 30, $00    # 5:VIEW_PORT_START_Y  High byte 48 ($0)
  reg_write 30, $10    # 6:VIEW_PORT_END_Y    Low  byte 528 ($210)
  reg_write 30, $02    # 7:VIEW_PORT_END_Y    High byte 528 ($210)
```

### Super Graphics Mode 3

Characteristics:
- Resolution: 360 x 240 @ 60Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 86,400
- This mode will fill the entire screen space

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers

#### Pseudo Code

```
  set_refresh 60
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7       # reset VIEW PORT and BASE ADDR
  reg_write 31, $80+3   # set SUPER_MID mode
```

### Super Graphics Mode 4

Characteristics:
- Resolution: 360 x 288 @ 50Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 103,680
- This mode will fill the entire screen space

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers

#### Pseudo Code

```
  set_refresh 50
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7       # reset VIEW PORT and BASE ADDR
  reg_write 31, $80+4   # set SUPER_MID mode
```

### Super Graphics Mode 5

Characteristics:
- Resolution: 640 x 400 @ 60Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 256,000
- This mode has a small border around the main view

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers
- Border colour as per Register #7

#### Pseudo Code

```
  set_refresh 60
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7         # reset viewport and base addr
  reg_write 31, $80+5     # set SUPER_RES mode

  reg_write 29, 0
  reg_write 30, $28     # 0:VIEW_PORT_START_X  Low  byte 40 ($28)
  reg_write 30, $00     # 1:VIEW_PORT_START_X  High byte 40 ($28)
  reg_write 30, $A8     # 2:VIEW_PORT_END_X    Low  byte 680 ($2A8)
  reg_write 30, $02     # 3:VIEW_PORT_END_X    High byte 680 ($2A8)
  reg_write 30, $28     # 4:VIEW_PORT_START_Y  Low  byte 40 ($28)
  reg_write 30, $00     # 5:VIEW_PORT_START_Y  High byte 40 ($0)
  reg_write 30, $B8     # 6:VIEW_PORT_END_Y    Low  byte 440 ($1B0)
  reg_write 30, $01     # 7:VIEW_PORT_END_Y    High byte 440 ($1B0)
```

### Super Graphics Mode 6

Characteristics:
- Resolution: 640 x 480 @ 50Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 307,200
- This mode has a small border around the main view

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers
- Border colour as per Register #7

#### Pseudo Code

```
  set_refresh 50
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7       # reset viewport and base addr
  reg_write 31, $80+6   # set SUPER_RES mode

  reg_write 29, 0
  reg_write 30, $28    # 0:VIEW_PORT_START_X  Low  byte 40 ($28)
  reg_write 30, $00    # 1:VIEW_PORT_START_X  High byte 40 ($28)
  reg_write 30, $A8    # 2:VIEW_PORT_END_X    Low  byte 680 ($2A8)
  reg_write 30, $02    # 3:VIEW_PORT_END_X    High byte 680 ($2A8)
  reg_write 30, $30    # 4:VIEW_PORT_START_Y  Low  byte 48 ($30)
  reg_write 30, $00    # 5:VIEW_PORT_START_Y  High byte 48 ($0)
  reg_write 30, $10    # 6:VIEW_PORT_END_Y    Low  byte 528 ($210)
  reg_write 30, $02    # 7:VIEW_PORT_END_Y    High byte 528 ($210)
```

### Super Graphics Mode 7

Characteristics:
- Resolution: 720 x 480 @ 60Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 345,600
- This mode will fill the entire screen space

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers

#### Pseudo Code

```
  set_refresh 60
  set_graphic 7

  vdp_reg_write(29, 255);
  vdp_reg_write(30, 7);   # reset viewport and base addr
  vdp_reg_write(31, $80+7);
```


### Super Graphics Mode 8

Characteristics:
- Resolution: 720 x 576 @ 50Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 414,720
- This mode will fill the entire screen space

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers

#### Pseudo Code

```
  set_refresh 50
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 8     # reset viewport and base addr
  reg_write 31, $80+8
```

### Super Graphics Mode 9

- Resolution: 640 x 512 @ 50Hz
- Colors: Uses 256 palette colors
- VRAM Usage: 327, 680 bytes

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers

#### Pseudo Code

```
  set_refresh 50
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7       # reset viewport and base addr
  reg_write 31, $80+9

  reg_write 29, 0
  reg_write 30, $28    # 0:VIEW_PORT_START_X  Low  byte  40 ($28)
  reg_write 30, $00    # 1:VIEW_PORT_START_X  High byte  40 ($28)
  reg_write 30, $A8    # 2:VIEW_PORT_END_X    Low  byte 680 ($2A8)
  reg_write 30, $02    # 3:VIEW_PORT_END_X    High byte 680 ($2A8)
  reg_write 30, $20    # 4:VIEW_PORT_START_Y  Low  byte  32 ($20)
  reg_write 30, $00    # 5:VIEW_PORT_START_Y  High byte  32 ($20)
  reg_write 30, $20    # 6:VIEW_PORT_END_Y    Low  byte 544 ($220)
  reg_write 30, $02    # 7:VIEW_PORT_END_Y    High byte 544 ($220)
```

### Super Graphics Mode 10

Characteristics:
- Resolution: 640 x 256 @ 50Hz
- Colors: Uses 256 palette colors
- VRAM Usage:  bytes

Memory organization:
- Each pixel uses one byte to specify its color
- Colors are selected from palette registers

#### Pseudo Code

```
  set_refresh 50
  set_graphic 7

  reg_write 29, 255
  reg_write 30, 7         # reset viewport and base addr
  reg_write 31, $80+10

  reg_write 29, 0
  reg_write 30, $28      # 0:VIEW_PORT_START_X  Low  byte 40 ($28)
  reg_write 30, $00      # 1:VIEW_PORT_START_X  High byte 40 ($28)
  reg_write 30, $A8      # 2:VIEW_PORT_END_X    Low  byte 680 ($2A8)
  reg_write 30, $02      # 3:VIEW_PORT_END_X    High byte 680 ($2A8)
  reg_write 30, $70      # 4:VIEW_PORT_START_Y  Low  byte 112 ($70)
  reg_write 30, $00      # 5:VIEW_PORT_START_Y  High byte 112 ($70)
  reg_write 30, $70      # 6:VIEW_PORT_END_Y    Low  byte 368 ($170)
  reg_write 30, $01      # 7:VIEW_PORT_END_Y    High byte 368 ($170)
```
