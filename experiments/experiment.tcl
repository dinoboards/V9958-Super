add_file top.sv

add_file pinout.cst
add_file constraint.sdc

set_device -device_version C GW2AR-LV18QN88C8/I7

set_option -top_module top
set_option -loading_rate 250/10
set_option -timing_driven 1
set_option -place_option 2
set_option -route_option 2
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
set_option -replicate_resources 1
# set_option -ireg_in_iob 0
# set_option -oreg_in_iob 0
# set_option -ioreg_in_iob 0
set_option -replicate_resources 1

run pnr
