
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}] -add
create_generated_clock -name clk_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 1 -add [get_nets {clocks/clk_w}]

create_generated_clock -name clk_135 -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 5 -add [get_nets {clocks/clk_135}]
create_generated_clock -name clk_135_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 5 -add [get_nets {clocks/clk_135_w}]

create_generated_clock -name clk_sdramp -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_nets {clocks/clk_sdramp}]
create_generated_clock -name clk_sdramp_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_nets {clocks/clk_sdramp_w}]
create_generated_clock -name clk_sdram -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -add [get_nets {clocks/clk_sdram}]
# create_generated_clock -name clk_sdram_w -source [get_ports {clk}] -master_clock clk -divide_by 1 -multiply_by 4 -add [get_nets {clocks/clk_sdram_w}]

create_generated_clock -name clk_audio -source [get_ports {clk}] -master_clock clk -divide_by 612 -multiply_by 1 -duty_cycle 50 -add [get_nets {clocks/clk_audio}]

# report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
# report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
# report_high_fanout_nets -slr -max_nets 10 -min_fanout 1 -max_fanout 15
# Report the top 10 fanout nets: report_high_fanout_Nets -max_nets
# report_route_congestion -max_grids 5 -min_route_congestion 0 -max_route_congestion 0.5

# ignore some paths between sdram and the v9958 units.  At the video circuits limit their rate of read/writes
# I dont think any meatastability will occur
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DH_CLK*}] -to [get_regs {vram/u_sdram/FF_SDRAM_nRAS*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DH_CLK*}] -to [get_regs {vram/u_sdram/FF_SDRAM_nCAS*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DH_CLK*}] -to [get_regs {vram/u_sdram/cycle*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DH_CLK*}] -to [get_regs {vram/u_sdram/FF_SDRAM_A*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DH_CLK*}] -to [get_regs {vram/u_sdram/state*}]

set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/u_sdram/FF_SDRAM_nRAS*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/u_sdram/FF_SDRAM_nCAS*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/u_sdram/cycle*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/u_sdram/FF_SDRAM_A*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/requested_din32*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/u_sdram/ff_busy*}]
set_false_path -from [get_regs {u_v9958/U_SSG/FF_VIDEO_DL_CLK*}] -to [get_regs {vram/u_sdram/state*}]

set_false_path -from [get_regs {u_v9958/address_bus/IRAMADR*}] -to [get_regs {vram/u_sdram/FF_SDRAM_DQM*}]
set_false_path -from [get_regs {u_v9958/address_bus/IRAMADR*}] -to [get_regs {vram/u_sdram/FF_SDRAM_A*}]
set_false_path -from [get_regs {u_v9958/address_bus/PRAMWE_N*}] -to [get_regs {vram/u_sdram/stat*}]
set_false_path -from [get_regs {u_v9958/address_bus/PRAMWE_N*}] -to [get_regs {vram/requested_word_wr_size*}]
set_false_path -from [get_regs {u_v9958/address_bus/*}] -to [get_regs {vram/requested_din32*}]

set_false_path -from [get_regs {vram/data16*}] -to [get_regs {u_v9958/U_SPRITE/*}]

# as audio only changes at maximum rate of upto 50khz, we can safely
# ignore the setup and hold time of the audio clock to the
# double flip-flop synchronizer
set_false_path -from [get_regs {audio/adc_sample*}] -to [get_regs {audio/audio_sample_word_sync*}]
