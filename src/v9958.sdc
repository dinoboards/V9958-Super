
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}] -add
create_generated_clock -name clk_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 1 -add [get_nets {clocks/clk_w}]

# create_clock -name clk_50 -period 20 -waveform {0 10} [get_ports {clk_50}] -add

create_generated_clock -name clk_135 -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 5 -add [get_nets {clocks/clk_135}]
create_generated_clock -name clk_135_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 5 -add [get_nets {clocks/clk_135_w}]

create_generated_clock -name clk_900k -source [get_nets {clocks/clk_135}] -master_clock clk_135 -divide_by 150 -multiply_by 1 -add [get_nets {clocks/clk_900k}]
create_generated_clock -name clk_900k_w -source [get_nets {clocks/clk_135}] -master_clock clk_135 -divide_by 150 -multiply_by 1 -add [get_nets {clocks/clk_900k_w}]

create_generated_clock -name clk_sdramp -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_nets {clocks/clk_sdramp}]
create_generated_clock -name clk_sdramp_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_nets {clocks/clk_sdramp_w}]
create_generated_clock -name clk_sdram -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -add [get_nets {clocks/clk_sdram}]
# create_generated_clock -name clk_sdram_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -add [get_nets {clocks/clk_sdram_w}]
