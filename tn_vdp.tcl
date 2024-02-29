add_file src\\clockdiv.v
add_file src\\interpo_mul.v
add_file src\\interpo.v
add_file src\\lpf1.v
add_file src\\lpf2.v
add_file src\\memory_controller.v
add_file src\\palette_g.v
add_file src\\palette_rb.v
add_file src\\pinfilter.v
add_file src\\ram.v
add_file src\\sdram.v
add_file src\\SPI_MCP3202.v
add_file src\\v9958_top.v
add_file src\\vram.v

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

add_file src\\vdp\\vdp_colordec.v
add_file src\\vdp\\vdp_command.v
add_file src\\vdp\\vdp_doublebuf.v
add_file src\\vdp\\vdp_graphic123m.v
add_file src\\vdp\\vdp_graphic4567.v
add_file src\\vdp\\vdp_hvcounter.v
add_file src\\vdp\\vdp_interrupt.v
add_file src\\vdp\\vdp_linebuf.v
add_file src\\vdp\\vdp_ntsc_pal.v
add_file src\\vdp\\vdp_package.v
add_file src\\vdp\\vdp_register.v
add_file src\\vdp\\vdp_spinforam.v
add_file src\\vdp\\vdp_sprite.v
add_file src\\vdp\\vdp_ssg.v
add_file src\\vdp\\vdp_text12.v
add_file src\\vdp\\vdp_vga.v
add_file src\\vdp\\vdp_wait_control.v
add_file src\\vdp\\vdp.v
add_file src\\vdp\\vencode.v

add_file src\\gowin\\clk_108p.v
add_file src\\gowin\\clk_135.v

add_file src\\v9958.cst
add_file src\\v9958.sdc

set_device -device_version C GW2AR-LV18QN88C8/I7

set_option -top_module v9958_top
set_option -loading_rate 250/10
set_option -place_option 1
set_option -route_option 1
set_option -bit_compress 1
set_option -bit_crc_check 1
set_option -bit_security 1
set_option -power_on_reset_monitor 1
set_option -use_sspi_as_gpio 1
set_option -use_mspi_as_gpio 1
set_option -verilog_std sysv2017
set_option -vhdl_std vhd2008

run syn
run pnr
