# V9958 - Super

This repo contains the Verilog code to emulate Yamaha's V9958 Video Display Processor.  Its was forked from the project [tn_vdp](https://github.com/lfantoniosi/tn_vdp) (derived from V3).

Its designed specifically for the [Yellow MSX System](https://github.com/vipoo/yellow-msx-series-for-rc2014?tab=readme-ov-file#yellow-msx-series-for-rc2014) kit, based on the Tang Nano 20K FPGA module.

(Board is still under development)

## Objective

1. To provide the RC2014 (specifically the Yellow MSX series) to have HDMI output of an emulated Yamaha V9958 Graphic Video Display Processor
2. Provide enhanced graphics modes with more colours and resolution that the original V9958 supported.

## Key Features

* Compatible with RC2014 (enhanced bus required)
* HDMI output
* Onboard ADC for HDMI audio delivery
* Extended Video modes (supported by a patched MSX-BASIC ROM for the Yellow MSX platform)
* WS2812 RGB LEDs

<img src="./docs/pcb-render.png" width="50%"/>

## Schematic

The current version of the schematic can be found here

* [Schematic](./docs/SCHEMATIC.pdf)
* [PCB IMAGE](./docs/PCB-IMAGE.pdf)

### Difference with [tn_vdp](https://github.com/lfantoniosi/tn_vdp)

* See [derived-notes.md](./docs/derived-notes.md)

### New Graphics Modes

New 'Super' Display modes -- New hardware registers available for applications to enable higher (super) resolution and colour modes.

A MSX-BASIC patches and extensions are available for the Embedded ROM of the [Yellow MSX System](https://github.com/vipoo/yellow-msx-series-for-rc2014) (Work in progress 2024-04-21).

The new Resolutions under development are:

* 01 -> SUPER_MID:   1 byte per pixel - colour from palette register - resolution of 50Hz:360x288 (103680 Bytes), 60Hz:360x240 (86400 bytes)
* 10 -> SUPER_RES:   1 byte per pixel - colour from palette register - resolution of 50Hz:720x576 (414720 Bytes), 60Hz:720x480 (345600 bytes)
*
See [docs/vdp_super_res.md](./docs/vdp_super_res.md) for more details.

## Building using the Command Line (windows)

> Requires the gowin IDE to be installed at `C:\Gowin64`
> Make sure you have Gowin IDE install to `C:\Gowin64`.  This should include the cli tool at: `C:\Gowin64\Gowin_V1.9.9.01_x64\IDE\bin\gw_sh.exe`

There is a TCL script that contains the required configuration to build the file stream (fs) for the Tang Nano.

Current scripts assume a specific install path for Gowin and only supports running under windows

Within *Windows Subsystem for Linux* (WSL), you can use the `buildwsl.sh` script to shell to windows to build:

```
buildwsl.sh
```

In in windows, run the BAT file:

```
build.bat
```

> The project may also be built using Gowin GUI IDE, by opening the file `tn_vdp.gprj`.  But please note that the GUI project may not be kept in sync with the tcl file and may be missing files or attempts to included files since deleted.


## Building using command line (wine)

Download and install the education version (so no need to worry about licence activation process)

Then run (adjusting path to `gw_shl.exe` as per your version)

```
c:\Gowin64\Gowin_V1.9.11.01_Education_x64\IDE\bin\gw_sh.exe" tn_vdp.tcl
```

To flash/program device, use the opensource programmer

use: openFPGALoader -> https://github.com/trabucayre/openFPGALoader

```
openFPGALoader -b tangnano20k -f ./impl/pnr/project.fs
```
