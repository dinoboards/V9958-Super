
## Super high res modes

In addition to supporting the capabilities of the V9958, this module also supports additional capabilities - higher resolutions, more colours and flexible viewport control.  To access these extended capabilities new registers and extended registers have been added.

This document describes the additional registers over the stock V9958 registers.  It assumes some familiarity with the register access of the V9958 VDP chip.

* Change identity response returned from status register `S#1`
* The additional registers (`R#29`, `R#30` and `R#31`)
* The super extended registers - accessed indirectly through `R#29` and `R#30`

The [eZ80 for RC](https://www.dinoboards.com.au/ez80-for-rc)'s clang tool chain has support for the V9958 and the extended register capabilities of this module.  See

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

BIT 1: ***SUPER_MID*** graphics mode:

* 1 byte per pixel
* colour from palette register
* resolution at 50Hz:360x288 (103680 Bytes)
* resolution at 60Hz:360x240 (86400 bytes)

BIT 2: ***SUPER_RES*** graphics mode:

* 1 byte per pixel
* colour from palette register
* resolution at 50Hz:720x576 (414720 Bytes)
* resolution at 60Hz:720x480 (345600 bytes)

> Bit 1 and Bit 2 enabled at the same time is undefined and not supported.

BIT 3: ***EXTENDED PALETTE***
* If set, enables 8 bits per colour for each colour entry in the colour palette (24bits in total).  Modifies the behaviour
  of the palette data port - instead of expecting one byte per entry, 3 bytes are expected for each of the RGB colour codes.
* up to 256 palette entries can be stored - but only the super res modes support the full palette set.

## Extended Register (View Port Registers)

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
