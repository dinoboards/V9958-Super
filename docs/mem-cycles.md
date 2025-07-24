Walkthrough of state transition during video rendering from memory

===================================================
## SUPER HIGH RES CYCLES

Assume:
  ext_reg_view_port_start_x = frame_width-1
  ext_reg_view_port_end_x = 720-1

Cycles start at cx == 720 && last line (call this cycle 0)

Cycle: 0
  addr <= 0 (pixels: 0..3)

Cycle 4:
  addr <= 1 (pixels: 4..7)

cycle 5:
  vrm_32_1 <= vrm_32  ; this is for pixels (0..3)

; lost of free cylces until line actually starts

cycle 99: (Not actually 99 - but after the blanking period) ext_reg_view_port_start_x - aka - (cx == framewidth-1)
  PALETTE_ADDR2 <= vrm_32_1[7:0]; Pixel 0

cycle 100:
  addr <= 2 (pixels: 8..11)
  PALETTE_ADDR2 <= vrm_32_1[15:8]; Pixel 1

cycle 101:
  PALETTE_ADDR2 <= vrm_32_1[23:16]; Pixel 2

cycle 102:
  PALETTE_ADDR2 <= vrm_32_1[31:24]; Pixel 3

cycle 103:
  PALETTE_ADDR2 <= vrm_32[7:0]; Pixel 4 - as per addr of cycle 4
  vrm_32_1 <= vrm_32;  pixels (4..7)

cycle 104:
  addr <= 3 (pixels: 12..15)
  PALETTE_ADDR2 <= vrm_32_1[15:8]; Pixel 5

cycle 105:
  PALETTE_ADDR2 <= vrm_32_1[23:16]; Pixel 6

cycle 106:
  PALETTE_ADDR2 <= vrm_32_1[31:24]; Pixel 7

cycle 107:
  PALETTE_ADDR2 <= vrm_32[7:0]; Pixel 8 - as per addr of cycle 100
  vrm_32_1 <= vrm_32;  pixels (8..11)

cycle 108:
  addr <= 3 (pixels: 16..19)
  PALETTE_ADDR2 <= vrm_32_1[15:8]; Pixel 9


## SUPER MID RES CYCLES

Assume:
  ext_reg_view_port_start_x = frame_width-1
  ext_reg_view_port_end_x = 720-1

Cycles start at cx == 720 && last line (call this cycle 0)

Cycle 0:
  addr <= 0 (bytes: 0..3)
  line_buf_idx <= 0

Cycle 4:
  addr <= 1 (bytes: 4..7)

Cycle 5:
  mvrm_32_1 <= vrm_32 ; this is for bytes (0..3)

Cycle 80: not actual 80 - but many cycles after 5 (cx == 856)
  PALETTE_ADDR2 <= mvrm_32_1[7:0]; Pixel 0
  first_pixel <= mvrm_32_1[7:0]; Pixel 0
  line_buffer[0] <= mvrm_32_1[7:0]; Pixel 0
  line_buf_idx <= line_buf_idx + 1
  odd_phase <= 0;

cycle 99: ext_reg_view_port_start_x - aka - (cx == framewidth-1)
  PALETTE_ADDR2 <= first_pixel[7:0]; Pixel 0


**active_line is true**
cycle 100: State 0
  PALETTE_ADDR2 unchanged - so still Pixel 0
  addr <= 2 (bytes: 8..11)
  mvrm_32_2 <= mvrm_32_1; bytes 0..3

cycle 101: State 1
  PALETTE_ADDR2 <= mvrm_32_1[15:8]; Pixel 1
  line_buffer[1] <= mvrm_32_1[15:8]; Pixel 1
  mvrm_32_1 <= vrm_32; this is for bytes (4..7)
  line_buf_idx <= line_buf_idx + 1

cycle 102: State 2
  PALETTE_ADDR2 unchanged - so still Pixel 1

cycle 103: State 3
  PALETTE_ADDR2 <= mvrm_32_2[23:16]; Pixel 2
  line_buffer[2] <= mvrm_32_2[23:16]; Pixel 2
  line_buf_idx <= line_buf_idx + 1
  odd_phase <= 1;

cycle 104: State 4
  PALETTE_ADDR2 unchanged - so still Pixel 2

cycle 105: State 5
  PALETTE_ADDR2 <= mvrm_32_2[31:24]; Pixel 3
  line_buffer[3] <= mvrm_32_2[31:24]; Pixel 3
  line_buf_idx <= line_buf_idx + 1

cycle 106: State 6
  PALETTE_ADDR2 unchanged - so still Pixel 3

cycle 107: State 7
  PALETTE_ADDR2 <= mvrm_32_1[7:0]; Pixel 4
  line_buffer[4] <= mvrm_32_1[7:0]; Pixel 4
  line_buf_idx <= line_buf_idx + 1
  odd_phase <= 0;

cycle 108: state 0
  PALETTE_ADDR2 unchanged - so still Pixel 4
  addr <= 3 (bytes: 12..15)
  mvrm_32_2 <= mvrm_32_1; bytes 4..7

cycle 109: state 1
  PALETTE_ADDR2 <= mvrm_32_1[15:8]; Pixel 5
  line_buffer[5] <= mvrm_32_1[15:8]; Pixel 5
  mvrm_32_1 <= vrm_32; this is for bytes (8..11)
  line_buf_idx <= line_buf_idx + 1

cycle 110: State 2
  PALETTE_ADDR2 unchanged - so still Pixel 5

cycle 111: State 3
  PALETTE_ADDR2 <= mvrm_32_2[23:16]; Pixel 6
  line_buffer[6] <= mvrm_32_2[23:16]; Pixel 6
  line_buf_idx <= line_buf_idx + 1
  odd_phase <= 1;

cycle 112: State 4
  PALETTE_ADDR2 unchanged - so still Pixel 6

cycle 105: State 5
  PALETTE_ADDR2 <= mvrm_32_2[31:24]; Pixel 7
  line_buffer[7] <= mvrm_32_2[31:24]; Pixel 7
  line_buf_idx <= line_buf_idx + 1

cycle 106: State 6
  PALETTE_ADDR2 unchanged - so still Pixel 7

cycle 107: State 7
  PALETTE_ADDR2 <= mvrm_32_1[7:0]; Pixel 8
  line_buffer[8] <= mvrm_32_1[7:0]; Pixel 8
  line_buf_idx <= line_buf_idx + 1
  odd_phase <= 0;
  ...
