
## Super high res modes

If bit 0 of REG31 is set, then VDP's super modes are activated.
There are 3 modes.  The specific super mode is determined by bits 2:1 or REG31

* 00: 8 bit RGB colours - 3 bytes per pixel - resolution of 50Hz:180x144 (77760/103680 Bytes), 60Hz:180x120 (64800/86400 bytes)*
* 01: 2 bytes per pixel `GGGG GGRR RRRB BBBB` - resolution of 50Hz:360x288 (207360 Bytes), 60Hz:360x240 (172800 bytes)**
* 10: 1 byte per pixel into palette lookup 50Hz:720x576 (414720 Bytes), 60Hz:720x480 (345600 bytes)**
* 11: Unused

\* WIP

\** Not implemented yet.

## New Registers

### S#1 - VDP ID CHANGED

BIT 5:1 - VDP ID

  10010 -> BIT 2 indicate V9958 and BIT 5 set indicates extra SUPER FEATURES

### R#31

BIT 0: When in GRAPHICS MODE 7 (SCREEN 8), and this bit set, then SUPER MODE active

BIT 2:1: SUPER MODE TYPE:
  00 -> SUPER_COLOR: 4 bytes per pixel (RGB, the 4th byte is not used) - 8 bit RGB colours - - resolution of 50Hz:180x144 (77760/103680 Bytes), 60Hz:180x120 (64800/86400 bytes)
  01 -> SUPER_MID:   2 bytes per pixel - RRRR RGGG GGGB BBBB - resolution of 50Hz:360x288 (207360 Bytes), 60Hz:360x240 (172800 bytes)
  02 -> SUPER_RES:   1 byte per pixel into palette lookup 50Hz:720x576 (414720 Bytes), 60Hz:720x480 (345600 bytes)

### R#30

BIT 6: active indicates a valid 24 bit RGB colour in super_rgb_colour_reg
BIT 7: active when RGBs are being loaded into R#30


## Video Timing

The main clock aligns with the pixel clock. That is each clock tick is a pixel tick.

the SDRAM memory controller can not return data at each tick.

The V9958 implementation of DOT_STATE follows:

Loading from ram, must align with the 'DOTSTATE' of the V9958 implementation.  This is a 4 ticks cycle, to prepare and return stored data.  It also aligns with the DRAM refresh cycle

```
00: DL -> Data Loading.   Memory controller is retrieving request memory data
01: DA -> Data Latching.  Read data ready.  Address to be latched at end of
                          this clock for initiating next read or write.
                          `vrm_32` has the data for latching for previously assigned address
02: DW -> Data Waiting.   Data wait for read/write operation**
03: FS -> DRAM Refresh    DRAM Refresh happening.
```
In summary, read data is available for reading during this cycle, and the address must be latched for the next DA's read.

Not that the DOTSTATE within the SSG is not ordered from 0 to 3.  Step 3 happens on the clock proceeding step 2.  After Step 2, it returns to step 00.  But dot_state here is a normal order.

\** Not sure why, but when rendering in 50Hz, can set address in this cycle.  But when running on 60Hz refresh rate, we get odd pixel misalignment (`vrm_32` will be behind - for the first row only)

> As VRAM address is selected by the `ADDRESS_BUS` component, the `VDP_SUPER_RES` component needs to have the the `super_res_vram_addr` loaded with the appropriate pixel address in the clock tick prior to the the DA step.

### Sequence of memory load and pixel rendering

```

== last line ===
720 (DL) `super_res_vram_addr` <= 0
721 (DA) **
722 (DW) bufindex <= 1
723 (FS)

724 (DL) read underway, `super_res_vram_addr` <= 2
725 (DA) `next_rgb` <= `vrm_32`, **
726 (DW)
727 (FS)

** `ADDRESS_BUS`' loads the `super_res_vram_addr` register into the `IRAMADR` register

== line 1 ===

0 (DL)  RGB <= `next_rgb`, cy = 0, line_buffer[0] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 # (4)
1 (DA)  `next_rgb` <= `vrm_32`  # RGB for next pixel (from addr 2), **
2 (DW)
3 (FS)

4 (DL) RGB <= `next_rgb`, cy = 0, line_buffer[1] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 #(6)
5 (DA) `next_rgb` <= `vrm_32`, **
6 (DW)
7 (FS)

8  (DL) RGB <= `next_rgb`, cy = 0, line_buffer[2] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 #(8)
9  (DA) `next_rgb` <= `vrm_32`, **
10 (DW)
11 (FS)

12 (DL) RGB <= `next_rgb`, cy = 0, line_buffer[3] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 #(10)
13 (DA) `next_rgb` <= `vrm_32`, **
14 (DW)
15 (FS)

16 (DL) RGB <= `next_rgb`, cy = 0, line_buffer[4] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 #(12)
17 (DA) `next_rgb` <= `vrm_32`, **
18 (DW)
19 (FS)

20 (DL) RGB <= `next_rgb`, cy = 0, line_buffer[5] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 #(14)
21 (DA) `next_rgb` <= `vrm_32`, **
22 (DW)
23 (FS)

24 (DL) RGB <= `next_rgb`, cy = 0, line_buffer[6] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 #(16)
25 (DA) `next_rgb` <= `vrm_32`, **
26 (DW)
27 (FS)

28 (DL) RGB <= `next_rgb`, cy = 0, line_buffer[7] = `next_rgb`, `super_res_vram_addr` <= `super_res_vram_addr` + 2 #(18)
29 (DA) `next_rgb` <= `vrm_32`  (first pixel for next line, addr 16)
30 (DW)
31 (FS)


== line 2 ===

0 (DL) RGB <= line_buffer[0], cy=1, `super_res_vram_addr` <= `super_res_vram_addr` + 2
1 (DA) `next_rgb` <= `vrm_32`  # redundant
2 (DW)
3 (FS)

....

```
