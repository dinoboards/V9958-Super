
//  LPF [1:1:1:1:1:1:1:1]/8

module LPF2 (
  input wire CLK21M,
  input wire RESET,
  input wire CLKENA,
  input wire [MSBI:0] IDATA,
  output wire [MSBI:0] ODATA
);

  parameter [31:0] MSBI;

  reg [MSBI:0] FF_D1;
  reg [MSBI:0] FF_D2;
  reg [MSBI:0] FF_D3;
  reg [MSBI:0] FF_D4;
  reg [MSBI:0] FF_D5;
  reg [MSBI:0] FF_D6;
  reg [MSBI:0] FF_D7;
  reg [MSBI:0] FF_D8;
  reg [MSBI:0] FF_OUT;
  wire [MSBI + 1:0] W_1;
  wire [MSBI + 1:0] W_3;
  wire [MSBI + 1:0] W_5;
  wire [MSBI + 1:0] W_7;
  wire [MSBI + 2:0] W_11;
  wire [MSBI + 2:0] W_13;
  wire [MSBI + 3:0] W_OUT;

  assign ODATA = FF_OUT;
  assign W_1 = ({1'b0,FF_D1}) + ({1'b0,FF_D8});
  assign W_3 = ({1'b0,FF_D2}) + ({1'b0,FF_D7});
  assign W_5 = ({1'b0,FF_D3}) + ({1'b0,FF_D6});
  assign W_7 = ({1'b0,FF_D4}) + ({1'b0,FF_D5});
  assign W_11 = ({1'b0,W_1}) + ({1'b0,W_5});
  assign W_13 = ({1'b0,W_3}) + ({1'b0,W_7});
  assign W_OUT = ({1'b0,W_11}) + ({1'b0,W_13});
  // DELAY LINE
  always @(posedge RESET, posedge CLK21M) begin
    if((RESET == 1'b1)) begin
      FF_D1 <= {((MSBI)-(0)+1){1'b0}};
      FF_D2 <= {((MSBI)-(0)+1){1'b0}};
      FF_D3 <= {((MSBI)-(0)+1){1'b0}};
      FF_D4 <= {((MSBI)-(0)+1){1'b0}};
      FF_D5 <= {((MSBI)-(0)+1){1'b0}};
      FF_D6 <= {((MSBI)-(0)+1){1'b0}};
      FF_D7 <= {((MSBI)-(0)+1){1'b0}};
      FF_D8 <= {((MSBI)-(0)+1){1'b0}};
      FF_OUT <= {((MSBI)-(0)+1){1'b0}};
    end else begin
      if((CLKENA == 1'b1)) begin
        FF_D1 <= IDATA;
        FF_D2 <= FF_D1;
        FF_D3 <= FF_D2;
        FF_D4 <= FF_D3;
        FF_D5 <= FF_D4;
        FF_D6 <= FF_D5;
        FF_D7 <= FF_D6;
        FF_D8 <= FF_D7;
        FF_OUT <= W_OUT[(MSBI + 3):3];
      end
    end
  end

endmodule
