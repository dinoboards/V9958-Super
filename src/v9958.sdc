
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}] -add
create_generated_clock -name clk_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 1 -add [get_nets {clocks/clk_w}]

# create_clock -name clk_50 -period 20 -waveform {0 10} [get_ports {clk_50}] -add

create_generated_clock -name clk_135 -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 5 -add [get_nets {clocks/clk_135}]
create_generated_clock -name clk_135_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 5 -add [get_nets {clocks/clk_135_w}]

create_generated_clock -name clk_900k -source [get_nets {clocks/clk_135_w}] -master_clock clk_135_w -divide_by 150 -multiply_by 1 -add [get_nets {clocks/clk_900k}]
# create_generated_clock -name clk_900k_w -source [get_nets {clocks/clk_135_w}] -master_clock clk_135_w -divide_by 150 -multiply_by 1 -add [get_nets {clocks/clk_900k_w}]

create_generated_clock -name clk_sdramp -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_nets {clocks/clk_sdramp}]
create_generated_clock -name clk_sdramp_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_nets {clocks/clk_sdramp_w}]
create_generated_clock -name clk_sdram -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -add [get_nets {clocks/clk_sdram}]
# create_generated_clock -name clk_sdram_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -add [get_nets {clocks/clk_sdram_w}]

# report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
# report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1

#Report nets that have fanout between 1 and 15, report 10 nets at most:
# report_high_fanout_nets -slr -max_nets 10 -min_fanout 1 -max_fanout 15

#Report the top 10 fanout nets: report_high_fanout_Nets -max_nets

# report_route_congestion -max_grids 5 -min_route_congestion 0 -max_route_congestion 0.5

# set_multicycle_path -setup -from [get_regs {vram/data16*}] -to [get_regs {u_v9958/U_SPRITE/*}] 4
# set_multicycle_path -hold -from [get_regs {vram/data16*}] -to [get_regs {u_v9958/U_SPRITE/*}] 1

# sdram routes produces lots of setup/hold violations - but I dont think they
# are actually impacting the function, due to the way DOTSTATE is used for reading/writing to the sdram
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DH_CLK*}] -to [get_regs {vram/u_sdram/*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/u_sdram/*}]
set_false_path -from [get_regs {vram/data16*}] -to [get_regs {u_v9958/U_SPRITE/*}]

