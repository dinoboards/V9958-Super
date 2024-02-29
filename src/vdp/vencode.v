// vencode.vhd
//   RGB to NTSC video encoder
//   Revision 1.00
//
// Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
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

module VENCODE (
    input wire CLK21M,
    input wire RESET,
    input wire [5:0] VIDEOR,
    input wire [5:0] VIDEOG,
    input wire [5:0] VIDEOB,
    input wire VIDEOHS_N,
    input wire VIDEOVS_N,
    output wire [5:0] VIDEOY,
    output wire [5:0] VIDEOC,
    output wire [5:0] VIDEOV
);

  // VDP CLOCK ... 21.477MHZ
  // VIDEO INPUT
  // VIDEO OUTPUT

  reg [5:0] FF_VIDEOY;
  reg [5:0] FF_VIDEOC;
  reg [5:0] FF_VIDEOV;
  reg [2:0] FF_SEQ;
  reg FF_BURPHASE;
  reg [8:0] FF_VCOUNTER;
  reg [11:0] FF_HCOUNTER;
  reg FF_WINDOW_V;
  reg FF_WINDOW_H;
  reg FF_WINDOW_C;
  reg [4:0] FF_TABLEADR;
  reg [7:0] FF_TABLEDAT;
  reg [8:0] FF_PAL_DET_CNT;
  reg FF_PAL_MODE;
  reg [5:0] FF_IVIDEOR;
  reg [5:0] FF_IVIDEOG;
  reg [5:0] FF_IVIDEOB;
  wire [7:0] Y;
  wire [7:0] C;
  wire [7:0] V;
  wire [7:0] C0;
  wire [13:0] Y1;
  wire [13:0] Y2;
  wire [13:0] Y3;
  wire [13:0] U1;
  wire [13:0] U2;
  wire [13:0] U3;
  wire [13:0] V1;
  wire [13:0] V2;
  wire [13:0] V3;
  wire [13:0] W1;
  wire [13:0] W2;
  wire [13:0] W3;
  reg FF_IVIDEOVS_N;
  reg FF_IVIDEOHS_N;
  parameter VREF = 8'h3B;
  parameter CENT = 8'h80;
  parameter [31:0] TABLE = {
    8'h00,
    8'hFA,
    8'h0C,
    8'hEE,
    8'h18,
    8'hE7,
    8'h18,
    8'hE7,
    8'h18,
    8'hE7,
    8'h18,
    8'hE7,
    8'h18,
    8'hE7,
    8'h18,
    8'hE7,
    8'h18,
    8'hE7,
    8'h18,
    8'hEE,
    8'h0C,
    8'hFA,
    8'h00,
    8'h00,
    8'h00,
    8'h00,
    8'h00,
    8'h00,
    8'h00,
    8'h00,
    8'h00,
    8'h00
  };

  assign VIDEOY = FF_VIDEOY;
  assign VIDEOC = FF_VIDEOC;
  assign VIDEOV = FF_VIDEOV;

  //  Y = +0.299R +0.587G +0.114B
  // +U = +0.615R -0.518G -0.097B (  0)
  // +V = +0.179R -0.510G +0.331B ( 60)
  // +W = -0.435R +0.007G +0.428B (120)
  // -U = -0.615R +0.518G +0.097B (180)
  // -V = -0.179R +0.510G -0.331B (240)
  // -W = +0.435R -0.007G -0.428B (300)

  assign Y = ({1'b0, Y1[11:5]}) + (({1'b0, Y2[11:5]}) + ({1'b0, Y3[11:5]})) + VREF;

  assign V = FF_SEQ == 3'b110 ? Y[7:0] + C0[7:0] :  // +U
      FF_SEQ == 3'b101 ? Y[7:0] + C0[7:0] :  // +V
      FF_SEQ == 3'b100 ? Y[7:0] + C0[7:0] :  // +W
      FF_SEQ == 3'b010 ? Y[7:0] - C0[7:0] :  // -U
      FF_SEQ == 3'b001 ? Y[7:0] - C0[7:0] :  // -V
      Y[7:0] - C0[7:0];  //  -W

  assign C = FF_SEQ == 3'b110 ? CENT + C0[7:0] :  // +U
      FF_SEQ == 3'b101 ? CENT + C0[7:0] :  // +V
      FF_SEQ == 3'b100 ? CENT + C0[7:0] :  // +W
      FF_SEQ == 3'b010 ? CENT - C0[7:0] :  // -U
      FF_SEQ == 3'b001 ? CENT - C0[7:0] :  // -V
      CENT - C0[7:0];  //  -W

  assign C0 = FF_SEQ[1] == 1'b1 ? 8'h00 + ({1'b0,U1[11:5]}) - ({1'b0,U2[11:5]}) - ({1'b0,U3[11:5]}) :
    FF_SEQ[0] == 1'b1 ? 8'h00 + ({1'b0,V1[11:5]}) - ({1'b0,V2[11:5]}) + ({1'b0,V3[11:5]}) :
    8'h00 - ({1'b0,W1[11:5]}) + ({1'b0,W2[11:5]}) + ({1'b0,W3[11:5]});

  assign Y1 = 8'h18 * FF_IVIDEOR;  // HEX(0.299*(2*0.714*256/3.3)*0.72*16) = $17.D
  assign Y2 = 8'h2F * FF_IVIDEOG;  // HEX(0.587*(2*0.714*256/3.3)*0.72*16) = $2E.D
  assign Y3 = 8'h09 * FF_IVIDEOB;  // HEX(0.114*(2*0.714*256/3.3)*0.72*16) = $09.1

  assign U1 = 8'h32 * FF_IVIDEOR;  // HEX(0.615*(2*0.714*256/3.3)*0.72*16) = $31.0
  assign U2 = 8'h29 * FF_IVIDEOG;  // HEX(0.518*(2*0.714*256/3.3)*0.72*16) = $29.5
  assign U3 = 8'h08 * FF_IVIDEOB;  // HEX(0.097*(2*0.714*256/3.3)*0.72*16) = $07.B

  assign V1 = 8'h0F * FF_IVIDEOR;  // HEX(0.179*(2*0.714*256/3.3)*0.72*16) = $0E.4
  assign V2 = 8'h28 * FF_IVIDEOG;  // HEX(0.510*(2*0.714*256/3.3)*0.72*16) = $28.A
  assign V3 = 8'h1A * FF_IVIDEOB;  // HEX(0.331*(2*0.714*256/3.3)*0.72*16) = $1A.6

  assign W1 = 8'h24 * FF_IVIDEOR;  // HEX(0.435*(2*0.714*256/3.3)*0.72*16) = $22.B
  assign W2 = 8'h01 * FF_IVIDEOG;  // HEX(0.007*(2*0.714*256/3.3)*0.72*16) = $00.8
  assign W3 = 8'h22 * FF_IVIDEOB;  // HEX(0.428*(2*0.714*256/3.3)*0.72*16) = $22.2

  always @(posedge CLK21M) begin
    FF_IVIDEOVS_N <= VIDEOVS_N;
    FF_IVIDEOHS_N <= VIDEOHS_N;
  end

  //------------------------------------------------------------------------
  // CLOCK PHASE : 3.58MHZ(1FSC) = 21.48MHZ(6FSC) / 6
  // FF_SEQ : (7) 654 (3) 210
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if (((VIDEOHS_N == 1'b0 && FF_IVIDEOHS_N == 1'b1))) begin
      FF_SEQ <= 3'b110;
    end else if ((FF_SEQ[1:0] == 2'b00)) begin
      FF_SEQ <= FF_SEQ - 2;
    end else begin
      FF_SEQ <= FF_SEQ - 1;
    end
  end

  //------------------------------------------------------------------------
  // HORIZONTAL COUNTER : MSX_X=0[FF_HCOUNTER=100H], MSX_X=511[FF_HCOUNTER=4FF]
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if ((VIDEOHS_N == 1'b0 && FF_IVIDEOHS_N == 1'b1)) begin
      FF_HCOUNTER <= 12'h000;
    end else begin
      FF_HCOUNTER <= FF_HCOUNTER + 1;
    end
  end

  //------------------------------------------------------------------------
  // VERTICAL COUNTER : MSX_Y=0[FF_VCOUNTER=22H], MSX_Y=211[FF_VCOUNTER=F5H]
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if ((VIDEOVS_N == 1'b1 && FF_IVIDEOVS_N == 1'b0)) begin
      FF_VCOUNTER <= {9{1'b0}};
      FF_BURPHASE <= 1'b0;
    end else if ((VIDEOHS_N == 1'b0 && FF_IVIDEOHS_N == 1'b1)) begin
      FF_VCOUNTER <= FF_VCOUNTER + 1;
      FF_BURPHASE <= FF_BURPHASE ^ (~FF_HCOUNTER[1]);   // FF_HCOUNTER:1364/1367
    end
  end

  //------------------------------------------------------------------------
  // VERTICAL DISPLAY WINDOW
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if ((FF_VCOUNTER == (8'h22 - 8'h10 - 1))) begin
      FF_WINDOW_V <= 1'b1;
    end else if ((((FF_VCOUNTER == (262 - 7)) && (FF_PAL_MODE == 1'b0)) || ((FF_VCOUNTER == (312 - 7)) && (FF_PAL_MODE == 1'b1)))) begin
      // JP: -7という数字にあまり根拠は無い。オリジナルのソースが
      // JP:  FF_VCOUNTER = X"FF"
      // JP: という条件判定をしていたのでそれを 262-7と表現し直した。
      // JP: 恐らく、オリジナルのソースはカウンタが8ビットだっため、
      // JP: 255が最大値だったのだろう。
      // JP: 大中的には 262-3= 259くらいで良いと思う(ボトムボーダ領域は
      // JP: 3ラインだから)
      // Translation
      //   There isn't much basis for the number -7. The original source had FF_VCOUNTER = X"FF"
      //   as a condition, so I re-expressed it as 262-7. Probably, the original source had an 8-bit counter,
      //   so 255 was the maximum value.  Personally, I think around 262-3=259 would be fine (since the
      //   bottom border area is 3 lines).
      FF_WINDOW_V <= 1'b0;
    end
  end

  //------------------------------------------------------------------------
  // HORIZONTAL DISPLAY WINDOW
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if ((FF_HCOUNTER == (12'h100 - 12'h030 - 1))) begin
      FF_WINDOW_H <= 1'b1;
    end else if ((FF_HCOUNTER == (12'h4FF + 12'h030 - 1))) begin
      FF_WINDOW_H <= 1'b0;
    end
  end

  //------------------------------------------------------------------------
  // COLOR BURST WINDOW
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if (((FF_WINDOW_V == 1'b0) || (FF_HCOUNTER == 12'h0CC))) begin
      FF_WINDOW_C <= 1'b0;
    end else if ((FF_WINDOW_V == 1'b1 && (FF_HCOUNTER == 12'h06C))) begin
      FF_WINDOW_C <= 1'b1;
    end
  end

  //------------------------------------------------------------------------
  // COLOR BURST TABLE POINTER
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if ((FF_WINDOW_C == 1'b0)) begin
      FF_TABLEADR <= {5{1'b0}};
    end else if ((FF_SEQ == 3'b101 || FF_SEQ == 3'b001)) begin
      FF_TABLEADR <= FF_TABLEADR + 1;
    end
  end

  always @(posedge CLK21M) begin
    FF_TABLEDAT <= TABLE[FF_TABLEADR];
  end

  //------------------------------------------------------------------------
  // VIDEO ENCODE
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if (((VIDEOVS_N ^ VIDEOHS_N) == 1'b1)) begin
      FF_VIDEOY <= {6{1'b0}};
      FF_VIDEOC <= CENT[7:2];
      FF_VIDEOV <= {6{1'b0}};
    end else if ((FF_WINDOW_V == 1'b1 && FF_WINDOW_H == 1'b1)) begin
      FF_VIDEOY <= Y[7:2];
      FF_VIDEOC <= C[7:2];
      FF_VIDEOV <= V[7:2];
    end else begin
      FF_VIDEOY <= VREF[7:2];
      if ((FF_SEQ[1:0] == 2'b10)) begin
        FF_VIDEOC <= CENT[7:2];
        FF_VIDEOV <= VREF[7:2];
      end else if ((FF_BURPHASE == 1'b1)) begin
        FF_VIDEOC <= CENT[7:2] + FF_TABLEDAT[7:2];
        FF_VIDEOV <= VREF[7:2] + FF_TABLEDAT[7:2];
      end else begin
        FF_VIDEOC <= CENT[7:2] - FF_TABLEDAT[7:2];
        FF_VIDEOV <= VREF[7:2] - FF_TABLEDAT[7:2];
      end
    end
  end

  always @(posedge CLK21M) begin
    if (((VIDEOVS_N ^ VIDEOHS_N) == 1'b1)) begin
      // HOLD
    end else if ((FF_WINDOW_V == 1'b1 && FF_WINDOW_H == 1'b1)) begin
      if ((FF_HCOUNTER[0] == 1'b0)) begin
        FF_IVIDEOR <= VIDEOR;
        FF_IVIDEOG <= VIDEOG;
        FF_IVIDEOB <= VIDEOB;
      end
    end
  end

  //------------------------------------------------------------------------
  // PAL AUTO DETECTION
  //------------------------------------------------------------------------
  always @(posedge CLK21M) begin
    if ((VIDEOVS_N == 1'b1 && FF_IVIDEOVS_N == 1'b0)) begin
      FF_PAL_DET_CNT <= {9{1'b0}};
    end else if ((VIDEOHS_N == 1'b0 && FF_IVIDEOHS_N == 1'b1)) begin
      FF_PAL_DET_CNT <= FF_PAL_DET_CNT + 1;
    end
  end

  always @(posedge CLK21M) begin
    if ((VIDEOVS_N == 1'b1 && FF_IVIDEOVS_N == 1'b0)) begin
      if ((FF_PAL_DET_CNT > 300)) begin
        FF_PAL_MODE <= 1'b1;
      end else begin
        FF_PAL_MODE <= 1'b0;
      end
    end
  end

endmodule
