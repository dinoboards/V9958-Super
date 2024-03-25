# V9958 - Super

This repo contains the Verilog code to emulate Yamaha's V9958 Video Display Processor.  Its was forked from the project [tn_vdp](https://github.com/lfantoniosi/tn_vdp) (derived from V3).

Its designed specifically for a [Yellow MSX System](https://www.tindie.com/stores/dinotron/) kit module, based on the Tang Nano 20K FPGA module.  (Board is still under development)

## Key differences to the lfantoniosi/tn_vdp

1. Only targets file-stream image for the for the Tang Nano 20K.
2. Not designed to be inserted into the original VDP socket, but to be placed on a PCB that slots into the Yellow MSX Backplane.
3. Internally decodes its own IO Address - does not need the CSR and CSW signals of the original VDP.
4. Additional pins assigned to the FPGA now includes other Z80 signals (address A0-A7, RD | IORQ, WR | IORQ)
5. With the implementation of additional registers, new display modes are now available.
6. All VDHL code has been converted to Verilog.

## Other changes

1. Now outputs DVI signal -- works with standard HDMI to DVI converters. If Pin 25 is left disconnected the system will output a DVI compatible output with no audio.  If its grounded, then the system will include an audio stream with the HDMI signal.  (Some monitors or passive HDMI-to-DVI converters may reject a signal that has audio stream).

2. Data lines assignment have been inverted. (The Data lines appeared to have been accidentally inverted in the original system).
3. Outputs a CS (chip select) when IORQ and IO ADDRESS $98 TO $9B

4. The original tn_vdp solution was designed to integrate into an existing V99x8 socket, it was limited in its ability to access other Z80/MSX bus signals.  For example, it only had access to A0/A1 (mode lines for the VDP) and the CSR/CSW for chip select reading and writing.  As this solution is designed for a compatible RC2014 bus, it can, subject to the pin limits of the Tang Nano module receive all relevant bus signals.  As such, the inputs for the module include the following assignments:

*    `input [7:2] A`  # The lower 8 Address lines from the Z80
*    `input rd_n,`     # The Z80 RD signal
*    `input wr_n,`     # The Z80 WR signal
*    `input iorq_n,`    # The Z80 IOREQ signal

> Given the full access to the IO signals, the solution can perform its own chip-select.  And allow for possible future expansion for other hardware emulation.

5. New 'Super' Display modes -- The new registers available in Assembly or by using the new MSX-BASIC extensions developed for the Embedded ROM of the [Yellow MSX System](https://github.com/vipoo/yellow-msx-series-for-rc2014) (Work in progress 2024-03-26). New Resolutions being developed are:

* 24 bit RGB colour - 3 bytes per pixel - resolution of 50Hz:180x144 (77760/103680 Bytes), 60Hz:180x120 (64800/86400 bytes)
* 16 bit RGB colour - 2 bytes per pixel - resolution of 50Hz:360x288 (207360 Bytes), 60Hz:360x240 (172800 bytes)
* ?? bit RGB palette colour - 1 byte per pixel - resolution of 50Hz:720x576 (414720 Bytes), 60Hz:720x480 (345600 bytes)

See [src/vdp/vdp_super_high_res.md](./src/vdp/vdp_super_high_res.md) for more current details

## Building using the Command Line

There is a TCL script that contains the required configuration to build the file stream (fs) for the Tang Nano.

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

> The project may also be built using Gowin GUI IDE, by opening the file `tn_vdp.gprj`.  But please note that the GUI project may not be kept in sync with the tcl file and may be missing files or attempts to included files since deleted.
