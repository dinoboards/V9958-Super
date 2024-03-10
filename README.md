# Tang Nano 20K V9958 128K

This repo contains the Verilog and VHDL code for the Tang Nano 20K FPGA development board to enable it to emulate a Yamaha V9958 chip with 128K of RAM; With HDMI output of the video signal.

Its designed specifically for a [Yellow MSX System](https://www.tindie.com/stores/dinotron/).  The actualy board is still under development.

The FPGA code is based on the V3 version of the MSX VDP replacement modules at the github project https://github.com/lfantoniosi/tn_vdp

## Key differences to the lfantoniosi/tn_vdp

1. Code only for the Tang Nano 20K 128 image.
2. Not designed to be inserted into the original VDP socket, but to be placed on a PCB that slots into the Yellow MSX Backplane.
3. Internally decodes its own IO Address - does not need the CSR and CSW signals of the original VDP.
4. Additional pins assigned to the FPGA now includes other Z80 signals (address A0-A7, RD, WR, IORQ)

## Other changes

1. Now outputs DVI signal -- works with standard HDMI to DVI converters. If Pin 25 is left disconnected the system to output a DVI compatible output with no audio.  If its grounded, then the system will output the audio.  Not all monitors or passive HDMI-to-DVI converters, will support a signal that has audio.

2. Data lines assignment have been inverted. (The Data lines appeared to have been accidentally inverted in the original system).
3. Outputs a CS (chip select) when IORQ and IO ADDRESS $98 TO $9B

4. The original tn_vdp solution was designed to integrate into an existing V99x8 socket, it was limited in its ability to access other Z80/MSX bus signals.  For example, it only had access to A0/A1 (mode lines for the VDP) and the CSR/CSW for chip select reading and writing.  As this solution is designed for a compatible RC2014 bus, it can, subject to the pin limits of the Tang Nano module receive all relevant bus signals.  As such, the inputs for the module include the following assignments:

*    `input [7:2] A`  # The lower 8 Address lines from the Z80
*    `input rd_n,`     # The Z80 RD signal
*    `input wr_n,`     # The Z80 WR signal
*    `input iorq_n,`    # The Z80 IOREQ signal

Given the full access to the IO signals, the solution can perform its own chip-select.  And allow for possible future expansion for other hardware emulation.


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
