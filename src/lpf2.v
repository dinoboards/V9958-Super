// lpf2.v
//   low pass filter
//   LPF [1:1:1:1:1:1:1:1]/8
//   Revision 1.00
//
// Copyright (c) 2007 Takayuki Hara.
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//    product or activity without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//

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
