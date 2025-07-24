===================================================

Start at cx == 720 && last line (call this cycle 0)

Cycle: 0
  addr <= 0 (pixels: 0..3)

Cycle 4:
  addr <= 1 (pixels: 4..7)

cycle 5:
  vrm_32_1 < vrm_32  ; this is for pixels (0..3)

; lost of free cylces until line actually starts

cycle 99: (cx == framewidth-1)
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




