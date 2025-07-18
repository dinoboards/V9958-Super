
## Key differences to the lfantoniosi/tn_vdp

1. Only targets the Tang Nano 20K.
2. Not designed to be inserted into the original VDP socket, but to be placed on a PCB that slots into the Yellow MSX Backplane.
3. Internally decodes its own IO Address - does not need the CSR and CSW signals of the original VDP.
4. Additional pins assigned to the FPGA now includes other Z80 signals (address A0-A7, RD | IORQ, WR | IORQ)
5. With the implementation of additional registers, new display modes are now available.
6. All VDHL code has been converted to Verilog.

## Other changes

1. Now outputs DVI signal -- works with standard HDMI to DVI converters. If Pin 25 is left disconnected the system will output a DVI compatible output with no audio.  If its grounded, then the system will include an audio stream with the HDMI signal.  (Some monitors or passive HDMI-to-DVI converters may reject a signal that has audio stream).
2. Data lines assignment have been inverted. (The Data lines appeared to have been accidentally inverted in the original system).
3. Outputs a CS (chip select) when IORQ and IO ADDRESS $98 TO $9B

4. The original tn_vdp solution was designed to integrate into an existing V99x8 socket, this limited in its ability to access other Z80/MSX bus signals.  For example, it only had access to A0/A1 (mode lines for the VDP) and the CSR/CSW for chip select reading and writing.  As this solution is designed for a compatible RC2014 bus, it can be directly connected to relevant Z80 bus signals.  The inputs for the module now include the following assignments:

*    `input [7:2] A`   # The lower 8 Address lines from the Z80
*    `input rd_iorq_n,`     # The Z80 RD & IOREQ combined
*    `input wr_iorq_n,`     # The Z80 WR & IOREQ combined

> Given the full access to the IO signals, the solution can perform its own chip-select.  And allow for possible future expansion for other hardware emulation.

## New 'Super' Display modes

### **SUPER_MID*** graphics mode:

* 1 byte per pixel
* colour from palette register
* resolution at 50Hz:360x288 (103680 Bytes)
* resolution at 60Hz:360x240 (86400 bytes)

### ***SUPER_RES*** graphics mode:

* 1 byte per pixel
* colour from palette register
* resolution at 50Hz:720x576 (414720 Bytes)
* resolution at 60Hz:720x480 (345600 bytes)

See [docs/vdp_super_res.md](./vdp_super_res.md) for more current details
