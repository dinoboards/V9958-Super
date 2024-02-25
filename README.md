# Tang Nano 20K V9958 128K

This repo contains the virlog and vhdl code for the Tang Nano 20K FPGA development board to enable it to emulate a Yamaha V9958 chip with 128K of RAM; With HDMI output of the video signal.

Its designed specifically for a [Yellow MSX System](https://www.tindie.com/stores/dinotron/).  The actualy board is still under development.

The FPGA code is based on the V3 version of the MSX VDP replacement modules at the github project https://github.com/lfantoniosi/tn_vdp

## Key differences to the lfantoniosi/tn_vdp

1. Code only for the Tang Nano 20K 128 image.
2. Not designed to be inserted into the original VDP socket, but to be placed on a PCB that slots into the Yellow MSX Backplane.
3. Internally decodes its own IO Address - does not need the CSR and CSW signals of the original VDP.
4. Additional pins assigned to the FPGA now includes other Z80 signals (address A0-A7, RD, WR, IORQ)

## Other changes

1. Now outputs DVI signal -- works with standard HDMI to DVI converters. TODO to make this configurable with an onboard jumper.
2. Data lines assignment have been inverted. (The Data lines appeared to have been accidentally inverted in the original system).
3. Outputs a CS (chip select) when IORQ and IO ADDRESS $98 TO $9B

## Building using the Command Line

There is a TCL script that mirrors the GUI project config.  To build the file stream (fs).

Current scripts assume a specific install path for Gowin and only supports running under windows

Make sure you have Gowin IDE install to `C:\Gowin64`.  This should include the cli tool at: `C:\Gowin64\Gowin_V1.9.9.01_x64\IDE\bin\gw_sh.exe`

If in WSL , you can use the build.sh script to shell to windows to build:

```
build.sh
```

In in windows, run the BAT file:

```
build.bat
```

> The project can also be built using Gowin GUI IDE, by opening the file `tn_vdp.gprj`
