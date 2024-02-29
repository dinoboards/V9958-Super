// File src/interpo_mul.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001-2023 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2023 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

// Signed multiplier for linear interpolation filter --

module INTERPO_MUL(
input wire [MSBI + 1:0] DIFF,
input wire [2:0] WEIGHT,
output wire [MSBI + 4:0] OFF
);

parameter [31:0] MSBI;
//  符号付き
//  符号無し
//  符号付き



wire [MSBI + 5:0] W_OFF;

  assign W_OFF = DIFF * ({1'b0,WEIGHT});
  assign OFF = W_OFF[MSBI + 4:0];

endmodule
