// interpo.v
//   Linear interpolation filter
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

  // 遅延ライン (Delay line)
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

  // 補間係数 (Interpolation coefficient)
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

  // 補間 (Interpolation )
  //  O = ((D1 * (6-W)) + D2 * W) / 6 = (D1 * 6 - D1 * W + D2 * W) / 6 = D1 + ((D2 - D1) * W) / 6;
  assign W_DIFF = ({1'b0,FF_D2}) - ({1'b0,FF_D1}); // 符号付き (Signed)

  INTERPO_MUL #(
    .MSBI(MSBI)
  )

  U_INTERPO_MUL(
    .DIFF(W_DIFF),
    .WEIGHT(FF_WEIGHT),
    .OFF(W_OFF)
  );

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
        ODATA <= {((MSBI)-(0)+1){1'b1}};  // 飽和 (Saturation)
      end
    end
  end

endmodule
