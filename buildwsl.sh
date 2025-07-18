#!/bin/bash

rm -rf impl/pnr
rm -rf impl/tmp
rm -rf impl/gwsynthesis

attempt_build() {
  /mnt/c/Gowin/Gowin_V1.9.10.03_x64/IDE/bin/gw_sh.exe tn_vdp.tcl | \
  grep --line-buffered --color=always -e "Bitstream generation completed" -e ERROR -e completed -e WARN -e "Undeclared symbol" | \
  grep --line-buffered --color=always -v "PA1001" | \
  grep --line-buffered --color=always -v "NL0002" | \
  grep --line-buffered --color=always -v "Generic routing resource will be used to clock signal 'clk_d'" | \
  grep --line-buffered --color=always -v "Can't calculate clocks' relationship between: \"clk_audio\" and \"clk_w\""
}

counter=0
while [[ $counter -lt 4 ]]
do
  counter=$((counter+1))

  attempt_build

  if [ ! -f impl/gwsynthesis/project.log ]; then
    echo "impl/gwsynthesis/project.log does not exists, retrying..."
    continue
  fi

  if grep -q ERROR impl/gwsynthesis/project.log; then
    exit 1
  fi

  if [ ! -f impl/pnr/project.log ]; then
    echo "impl/pnr/project.log does not exists, retrying..."
    continue
  fi

  if grep -q ERROR impl/pnr/project.log; then
    exit 1
  fi

  if [ ! -f impl/pnr/project.tr ]; then
    echo "project.tr does not exists, retrying..."
    continue
  fi

  break

done

if [[ $counter -eq 4 ]]
then
  echo "Build tool has crashed after 3 attempts. Exiting..."
  exit 1
fi

echo ""
echo "Timing Viloations:"
grep -e "<Numbers of Falling Endpoints>" \
     -e "<Numbers of Setup Violated Endpoints>" \
     -e "<Numbers of Hold Violated Endpoints>" \
     impl/pnr/project.tr | sed 's/<//g; s/>//g'  | sed -r 's/:([0-9]+)/: \x1b[31m\1\x1b[0m/g' | sed 's/^/    /'

# will produce a output like:
#
# Numbers of Falling Endpoints:0
# Numbers of Setup Violated Endpoints:15
# Numbers of Hold Violated Endpoints:1

# echo ""
# echo "Max Frequency Summary:"
# echo ""
# echo "   NO.    Clock Name     Constraint    Actual Fmax    Level   Entity"
# echo "  ===== ============== ============== ============== ======= ========"
# awk '/2.3 Max Frequency Summary/{flag=1;next}/2.4 Total Negative Slack Summary/{flag=0}flag' impl/pnr/project.tr | grep -P '^\s*\d'
# will produce a output like:
#   NO.    Clock Name     Constraint    Actual Fmax    Level   Entity
#  ===== ============== ============== ============== ======= ========
#   1     clk_w          27.000(MHz)    66.906(MHz)    14      TOP
#   2     clk_135        135.000(MHz)   229.104(MHz)   6       TOP
#   3     clk_135_w      135.000(MHz)   229.104(MHz)   6       TOP
#   4     clk_sdramp     108.000(MHz)   134.816(MHz)   7       TOP
#   5     clk_sdramp_w   108.000(MHz)   134.816(MHz)   7       TOP
#   6     clk_sdram      108.000(MHz)   787.468(MHz)   2       TOP
#   7     clk_audio      0.044(MHz)     437.607(MHz)   3       TOP

