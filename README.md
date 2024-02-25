# Tang Nano 20K V9958 128K

This repo contains the virlog and vhdl code for the Tang Nano 20K FPGA development board to enable it to emulate a Yamaha V9958 chip with 128K of RAM; With HDMI output of the video signal.

Its designed specifically for a [Yellow MSX System](https://www.tindie.com/stores/dinotron/).  The actualy board is still under development.

The FPGA code is based on the V3 version of the MSX VDP replacement modules at the github project https://github.com/lfantoniosi/tn_vdp

## Key differences to the lfantoniosi/tn_vdp

1. Code only for the Tang Nano 20K 128 image.
2. Not designed to be inserted into the original VDP socket, but to be placed on a PCB that slots into the Yellow MSX Backplane.
3. Internally decodes its own IO Address - does not need the CSR and CSW signals of the original VDP.
4. Additional pins assigned to the FPGA now includes other Z80 signals (address A0-A7, RD, WR, IORQ)

