add_file src\\clockdiv.v
add_file src\\clocks.v
add_file src\\audio.sv
add_file src\\memory_controller.sv
add_file src\\ram.v
add_file src\\sdram.v
add_file src\\SPI_MCP3202.v
add_file src\\v9958_top.sv
add_file src\\cpu_io.sv

add_file src\\ws2812\\ws2812.sv
add_file src\\ws2812\\ws2812_transmitter.sv
add_file src\\ws2812\\ws2812_registers.sv

add_file src\\video_output\\hdmi_output.v
add_file src\\video_output\\hdmi_selection.v

add_file src\\hdmi\\audio_clock_regeneration_packet.sv
add_file src\\hdmi\\audio_info_frame.sv
add_file src\\hdmi\\audio_sample_packet.sv
add_file src\\hdmi\\auxiliary_video_information_info_frame.sv
add_file src\\hdmi\\hdmi.sv
add_file src\\hdmi\\packet_assembler.sv
add_file src\\hdmi\\packet_picker.sv
add_file src\\hdmi\\serializer.sv
add_file src\\hdmi\\source_product_description_info_frame.sv
add_file src\\hdmi\\tmds_channel.sv

add_file src\\vdp\\address_bus.sv
add_file src\\vdp\\vdp_colordec.v
add_file src\\vdp\\vdp_command.sv
add_file src\\vdp\\vdp_double_buffer.v
add_file src\\vdp\\vdp_graphic123m.v
add_file src\\vdp\\vdp_graphic4567.v
add_file src\\vdp\\vdp_hvcounter.v
add_file src\\vdp\\vdp_interrupt.v
add_file src\\vdp\\vdp_line_buffer.v
add_file src\\vdp\\vdp_package.v
add_file src\\vdp\\vdp_palette.v
add_file src\\vdp\\vdp_register.sv
add_file src\\vdp\\vdp_spinforam.v
add_file src\\vdp\\vdp_sprite.v
add_file src\\vdp\\vdp_ssg.v
add_file src\\vdp\\vdp_super_high_2ppb_res.sv
add_file src\\vdp\\vdp_super_high_res.sv
add_file src\\vdp\\vdp_super_mid_res.sv
add_file src\\vdp\\vdp_super_res.sv
add_file src\\vdp\\vdp_text12.v
add_file src\\vdp\\vdp_vga.v
add_file src\\vdp\\vdp_wait_control.v
add_file src\\vdp\\vdp.sv

add_file src\\gowin\\clk_108p.v
add_file src\\gowin\\clk_135.v

add_file src\\v9958.cst
add_file src\\v9958.sdc

set_device -device_version C GW2AR-LV18QN88C8/I7

set_option -top_module v9958_top
set_option -loading_rate 250/10

# -timing_driven <0|1>
# Timing driven optimization of the placement and routing is performed,
# and the default is 1.
# 0: No
# 1: Yes
set_option -timing_driven 1

# -place_option <0|1|2|3|4>
# Place algorithm option, and the default is 0.
# 0: default place algorithm, compilation speed priority
# 1: place algorithm 1, routability priority
# 2: place algorithm 2, timing priority
# 3: Unknown
# 4: Unknown
set_option -place_option 2

# -route_option <0|1|2>
# Route algorithm option, and the default is 0.
# 0: default route algorithm, the default route algorithm according to congestion.
# 1: route algorithm 1, routing according to timing.
# 2: route algorithm 2, routing speed will be faster.
set_option -route_option 1
set_option -bit_compress 1
set_option -bit_crc_check 1
set_option -bit_security 1
set_option -power_on_reset_monitor 1
set_option -use_sspi_as_gpio 1
set_option -use_mspi_as_gpio 1
set_option -verilog_std sysv2017
set_option -vhdl_std vhd2008
set_option -print_all_synthesis_warning 1
set_option -show_all_warn 1
# set_option -route_maxfan 40
# set_option -maxfan 4000
set_option -gen_text_timing_rpt 1
set_option -rpt_auto_place_io_info 1


# -replicate_resources <0|1>
# Enable this option, Place & Route will replicate resources with high
# fanout to reduce fanout and get better timing results, and default is 0.
# 0: Disable
# 1: Enable
set_option -replicate_resources 1
set_option -ireg_in_iob 0
set_option -oreg_in_iob 0
set_option -ioreg_in_iob 0

# set_option -correct_hold_violation 1
# set_option inc_place 0
run pnr
