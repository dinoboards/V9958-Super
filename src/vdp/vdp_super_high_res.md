
## Super high res modes

If Bit 0 of REG31 is set, then super high res
* 8 bit RGB colours - 3 bytes per pixel - resolution of 50Hz:180x144 (77750Bytes), 60Hz:180x120 (64800bytes)

## Video Timing

The main clock aligns with the pixel clock. That is each clock tick is a pixel tick.

the SDRAM memory controller can not return data at each tick.

The V9958 implementation of DOT_STATE follows:

Loading from ram, must align with the 'DOTSTATE' of the V9958 implementation.  This is a 4 ticks cycle, to prepare and return stored data.  It also aligns with the DRAM refresh cycle

```
00: DL -> Data loading (Memory controller is retFSeving request memory data)
01: DR -> Data ready (vrm_32 has the data for latching)
02: AL -> Address Load (update address for next read)
03: FS -> DRAM Refresh
```
Not that the DOTSTATE within the SSG is not ordered from 0 to 3.  Step 3 happens on the clock proceeding step 2.  After Step 2, it returns to step 00.  But dot_state here is a normal order.

TODO: perhaps look at revising DOTSTATE's order to be 0, 1, 2, 3

### Sequence of memory load and pixel rendering

```

== last line ===
720
721
722 (AP) addr <= 0, bufindex <= 1
723 (FS)

724 (DL) read underway
725 (DR) NextRGB <= vrm_32
726 (AP) addr <= addr + 2 # (2)
727 (FS)


== line 1 ===

0 (DL)  RGB <= (NextRGB), cy = 0, line_buffer[0] = (NextRGB)
1 (DR)  NextRGB <= vrm_32  # RGB for next pixel (from addr 2)
2 (AP)  addr <= addr + 2 #(4)
3 (FS)

4 (DL) RGB <= (NextRGB), cy = 0, line_buffer[1] = (NextRGB)
5 (DR) NextRGB <= vrm32
6 (AP) addr <= addr + 2 #(6)
7 (FS)

8  (DL) RGB <= (NextRGB), cy = 0, line_buffer[2] = (NextRGB)
9  (DR) NextRGB <= vrm32
10  (AP) addr <= addr + 2 #(8)
11 (FS)

12 (DL) RGB <= (NextRGB), cy = 0, line_buffer[3] = (NextRGB)
13 (DR) NextRGB <= vrm32
14 (AP) addr <= addr + 2 #(10)
15 (FS)

16 (DL) RGB <= (NextRGB), cy = 0, line_buffer[4] = (NextRGB)
17 (DR) NextRGB <= vrm32
18 (AP) addr <= addr + 2 #(12)
19 (FS)

20 (DL) RGB <= (NextRGB), cy = 0, line_buffer[5] = (NextRGB)
21 (DR) NextRGB <= vrm32
22 (AP) addr <= addr + 2 #(14)
23 (FS)

24 (DL) RGB <= (NextRGB), cy = 0, line_buffer[6] = (NextRGB)
25 (DR) NextRGB <= vrm32
26 (AP) addr <= addr + 2 #(16)
27 (FS)

28 (DL) RGB <= (NextRGB), cy = 0, line_buffer[7] = (NextRGB)
29 (DR) NextRGB <= vrm32  (first pixel for next line, addr 16)
30 (AP) addr <= addr + 2 #(18)
31 (FS)


== line 2 ===

0 (DL) RGB <= line_buffer[0], cy=1
1 (DR) NextRGB <= vrm_32  # redundant
2 (AP)
3 (FS)

4 (DL) RGB <= line_buffer[1], cy=1
5 (DR) NextRGB <= vrm_32  # redundant
6 (AP)
7 (FS)

8  (DL) RGB <= line_buffer[2], cy=1
9  (DR) NextRGB <= vrm_32  # redundant
10 (AP)
11 (FS)

12 (DL) RGB <= line_buffer[3], cy=1
13 (DR) NextRGB <= vrm_32  # redundant
14 (AP)
15 (FS)

16 (DL) RGB <= line_buffer[4], cy=1
17 (DR) NextRGB <= vrm_32  # redundant
18 (AP)
19 (FS)

20 (DL) RGB <= line_buffer[5], cy=1
21 (DR) NextRGB <= vrm_32  # redundant
22 (AP)
23 (FS)

24 (DL) RGB <= line_buffer[6], cy=1
25 (DR) NextRGB <= vrm_32  # redundant
26 (AP)
27 (FS)

28 (DL) RGB <= line_buffer[7], cy=1
29 (DR) NextRGB <= vrm_32  # redundant
30 (AP)
31 (FS)

....

== line 4 ===

0 (DL)  RGB <= (NextRGB), cy = 4, line_buffer[0] = (NextRGB)
1 (DR)  NextRGB <= vrm_32  # RGB for next pixel (from addr 2)
2 (AP)  addr <= addr + 2 #(4)
3 (FS)
