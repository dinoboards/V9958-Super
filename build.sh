#!/bin/bash

rm -rf impl/pnr
rm -rf impl/tmp
rm -rf impl/gwsynthesis

attempt_build() {
  stdbuf -o0 wine "c:\Gowin64\Gowin_V1.9.11.01_Education_x64\IDE\bin\gw_sh.exe" tn_vdp.tcl | \
  stdbuf -o0 grep --color=always -e "Bitstream generation completed" -e ERROR -e completed -e WARN -e "Undeclared symbol" | \
  stdbuf -o0 grep --color=always -v "PA1001" | \
  stdbuf -o0 grep --color=always -v "NL0002" | \
  stdbuf -o0 grep --color=always -v "Generic routing resource will be used to clock signal 'clk_d'" | \
  stdbuf -o0 grep --color=always -v "Can't calculate clocks' relationship between: \"clk_audio\" and \"clk_w\""
}

attempt_build

# wine "c:\Gowin64\Gowin_V1.9.11.01_Education_x64\IDE\bin\gw_sh.exe" tn_vdp.tcl

echo ""
echo "Timing Viloations:"
grep -e "<Numbers of Falling Endpoints>" \
     -e "<Numbers of Setup Violated Endpoints>" \
     -e "<Numbers of Hold Violated Endpoints>" \
     impl/pnr/project.tr | sed 's/<//g; s/>//g'  | sed -r 's/:([0-9]+)/: \x1b[31m\1\x1b[0m/g' | sed 's/^/    /'
