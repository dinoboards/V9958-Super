// File src/interpo.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
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

// Linear interpolation filter --
// no timescale needed

module INTERPO(
input wire CLK21M,
input wire RESET,
input wire CLKENA,
input wire [MSBI:0] IDATA,
output reg [MSBI:0] ODATA
);

parameter [31:0] MSBI;



reg [MSBI:0] FF_D1;
reg [MSBI:0] FF_D2;
reg [2:0] FF_WEIGHT;
wire [MSBI + 1:0] W_DIFF;
wire [MSBI + 4:0] W_OFF;
wire [MSBI + 6:0] W_MUL5;
wire [MSBI + 1:0] W_OUT;

  //  遅延ライン --
  always @(posedge RESET, posedge CLK21M) begin
    if((RESET == 1'b1)) begin
      FF_D2 <= {((MSBI)-(0)+1){1'b0}};
      FF_D1 <= {((MSBI)-(0)+1){1'b0}};
    end else begin
      if((CLKENA == 1'b1)) begin
        FF_D2 <= IDATA;
        FF_D1 <= FF_D2;
      end
    end
  end

  //  補間係数 --
  always @(posedge RESET, posedge CLK21M) begin
    if((RESET == 1'b1)) begin
      FF_WEIGHT <= {3{1'b0}};
    end else begin
      if((CLKENA == 1'b1)) begin
        FF_WEIGHT <= {3{1'b0}};
      end
      else begin
        FF_WEIGHT <= FF_WEIGHT + 1;
      end
    end
  end

  //  補間 --
  //  O = ((D1 * (6-W)) + D2 * W) / 6 = (D1 * 6 - D1 * W + D2 * W) / 6 = D1 + ((D2 - D1) * W) / 6;
  assign W_DIFF = ({1'b0,FF_D2}) - ({1'b0,FF_D1});
  //  符号付き    --
  INTERPO_MUL #(
      .MSBI(MSBI))
  U_INTERPO_MUL(
      .DIFF(W_DIFF),
    .WEIGHT(FF_WEIGHT),
    .OFF(W_OFF));

  assign W_MUL5 = ({W_OFF,2'b00}) + ({W_OFF[MSBI + 4],W_OFF[MSBI + 4],W_OFF});
  assign W_OUT = ({1'b0,FF_D1}) + W_MUL5[(MSBI + 6):5];
  always @(posedge RESET, posedge CLK21M) begin
    if((RESET == 1'b1)) begin
      ODATA <= {((MSBI)-(0)+1){1'b0}};
    end else begin
      if((W_OUT[(MSBI + 1)] == 1'b0)) begin
        ODATA <= W_OUT[MSBI:0];
      end
      else begin
        ODATA <= {((MSBI)-(0)+1){1'b1}};
        //  飽和
      end
    end
  end


endmodule
