//  converted from vdp_ssg.vhd
//   Synchronous Signal Generator of ESE-VDP.
//
//  Copyright (C) 2000-2006 Kunihiko Ohnaka
//  All rights reserved.
//                                     http://www.ohnaka.jp/ese-vdp/
//
//  本ソフトウェアおよび本ソフトウェアに基づいて作成された派生物は、以下の条件を
//  満たす場合に限り、再頒布および使用が許可されます。
//
//  1.ソースコード形式で再頒布する場合、上記の著作権表示、本条件一覧、および下記
//    免責条項をそのままの形で保持すること。
//  2.バイナリ形式で再頒布する場合、頒布物に付属のドキュメント等の資料に、上記の
//    著作権表示、本条件一覧、および下記免責条項を含めること。
//  3.書面による事前の許可なしに、本ソフトウェアを販売、および商業的な製品や活動
//    に使用しないこと。
//
//  本ソフトウェアは、著作権者によって「現状のまま」提供されています。著作権者は、
//  特定目的への適合性の保証、商品性の保証、またそれに限定されない、いかなる明示
//  的もしくは暗黙な保証責任も負いません。著作権者は、事由のいかんを問わず、損害
//  発生の原因いかんを問わず、かつ責任の根拠が契約であるか厳格責任であるか（過失
//  その他の）不法行為であるかを問わず、仮にそのような損害が発生する可能性を知ら
//  されていたとしても、本ソフトウェアの使用によって発生した（代替品または代用サ
//  ービスの調達、使用の喪失、データの喪失、利益の喪失、業務の中断も含め、またそ
//  れに限定されない）直接損害、間接損害、偶発的な損害、特別損害、懲罰的損害、ま
//  たは結果損害について、一切責任を負わないものとします。
//
//  Note that above Japanese version license is the formal document.
//  The following translation is only for reference.
//
//  Redistribution and use of this software or any derivative works,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above
//     copyright notice, this list of conditions and the following
//     disclaimer in the documentation and/or other materials
//     provided with the distribution.
//  3. Redistributions may not be sold, nor may they be used in a
//     commercial product or activity without specific prior written
//     permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//-----------------------------------------------------------------------------

module VDP_SSG (
    input wire RESET,
    input wire CLK21M,
    input bit [10:0] cx,
    input bit [9:0] cy,
    output wire [1:0] DOTSTATE,
    output wire [2:0] EIGHTDOTSTATE,
    output wire [8:0] PREDOTCOUNTER_X,
    output wire [8:0] PREDOTCOUNTER_Y,
    output wire [8:0] PREDOTCOUNTER_YP,
    output reg PREWINDOW_Y,
    output reg PREWINDOW_Y_SP,
    output wire FIELD,
    output wire WINDOW_X,
    output wire PVIDEODHCLK,
    output wire PVIDEODLCLK,
    output reg IVIDEOVS_N,
    output wire HD,
    output wire VD,
    output wire HSYNC,
    output reg ENAHSYNC,
    output wire V_BLANKING_START,
    input wire VDPR9PALMODE,
    input wire REG_R9_INTERLACE_MODE,
    input wire REG_R9_Y_DOTS,
    input wire [7:0] REG_R18_ADJ,
    input wire [7:0] REG_R23_VSTART_LINE,
    input wire REG_R25_MSK,
    input wire [2:0] REG_R27_H_SCROLL,
    input wire REG_R25_YJK
);

  import custom_timings::*;

  // FLIP FLOP
  reg [1:0] FF_DOTSTATE;
  reg [2:0] FF_EIGHTDOTSTATE;
  reg [8:0] FF_PRE_X_CNT;
  reg [8:0] FF_X_CNT;
  reg [8:0] FF_PRE_Y_CNT;
  reg [8:0] FF_MONITOR_LINE;
  reg FF_VIDEO_DH_CLK;
  reg FF_VIDEO_DL_CLK;
  reg [5:0] FF_PRE_X_CNT_START1;
  reg [8:0] FF_RIGHT_MASK;
  reg FF_WINDOW_X;
  wire [9:0] W_V_CNT_IN_FRAME;
  wire [9:0] W_V_CNT_IN_FIELD;
  wire W_FIELD;
  wire W_H_BLANK;
  wire W_V_BLANK;
  wire [4:0] W_PRE_X_CNT_START0;
  wire [8:0] W_PRE_X_CNT_START2;
  wire [8:0] W_LEFT_MASK;
  wire [8:0] W_Y_ADJ;
  wire [1:0] W_LINE_MODE;
  wire W_V_BLANKING_START;
  wire W_V_BLANKING_END;

  //---------------------------------------------------------------------------
  //  PORT ASSIGNMENT
  //---------------------------------------------------------------------------
  assign W_V_CNT_IN_FRAME = cy;
  assign DOTSTATE = FF_DOTSTATE;
  assign EIGHTDOTSTATE = FF_EIGHTDOTSTATE;
  assign FIELD = W_FIELD;
  assign WINDOW_X = FF_WINDOW_X;
  assign PVIDEODHCLK = FF_VIDEO_DH_CLK;
  assign PVIDEODLCLK = FF_VIDEO_DL_CLK;
  assign PREDOTCOUNTER_X = FF_PRE_X_CNT;
  assign PREDOTCOUNTER_Y = FF_PRE_Y_CNT;
  assign PREDOTCOUNTER_YP = FF_MONITOR_LINE;
  assign HD = W_H_BLANK;
  assign VD = W_V_BLANK;
  assign HSYNC = cx[1:0] == 2'b10 && FF_PRE_X_CNT == 9'b111111111;
  assign V_BLANKING_START = W_V_BLANKING_START;

  //---------------------------------------------------------------------------
  //  SUB COMPONENTS
  //---------------------------------------------------------------------------
  VDP_HVCOUNTER U_HVCOUNTER (
      .RESET(RESET),
      .CLK21M(CLK21M),
      .cx(cx),
      .cy(cy),
      .V_CNT_IN_FIELD(W_V_CNT_IN_FIELD),
      .V_CNT_IN_FRAME(W_V_CNT_IN_FRAME),
      .FIELD(W_FIELD),
      .H_BLANK(W_H_BLANK),
      .V_BLANK(W_V_BLANK),
      .PAL_MODE(VDPR9PALMODE),
      .INTERLACE_MODE(REG_R9_INTERLACE_MODE),
      .Y212_MODE(REG_R9_Y_DOTS),
      .BLANKING_START(W_V_BLANKING_START),
      .BLANKING_END(W_V_BLANKING_END)
  );

  //---------------------------------------------------------------------------
  //  DOT STATE
  //---------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_DOTSTATE <= 2'b00;
      FF_VIDEO_DH_CLK <= 1'b0;
      FF_VIDEO_DL_CLK <= 1'b0;
    end else begin
      if (cy[0] == 1 && cx == CLOCKS_PER_HALF_LINE(VDPR9PALMODE) - 1) begin
        FF_DOTSTATE <= 2'b00;
        FF_VIDEO_DH_CLK <= 1'b1;
        FF_VIDEO_DL_CLK <= 1'b1;
      end else begin
        case (FF_DOTSTATE)
          2'b00: begin
            FF_DOTSTATE <= 2'b01;
            FF_VIDEO_DH_CLK <= 1'b0;
            FF_VIDEO_DL_CLK <= 1'b1;
          end
          2'b01: begin
            FF_DOTSTATE <= 2'b11;
            FF_VIDEO_DH_CLK <= 1'b1;
            FF_VIDEO_DL_CLK <= 1'b0;
          end
          2'b11: begin
            FF_DOTSTATE <= 2'b10;
            FF_VIDEO_DH_CLK <= 1'b0;
            FF_VIDEO_DL_CLK <= 1'b0;
          end
          2'b10: begin
            FF_DOTSTATE <= 2'b00;
            FF_VIDEO_DH_CLK <= 1'b1;
            FF_VIDEO_DL_CLK <= 1'b1;
          end
        endcase
      end
    end
  end

  //---------------------------------------------------------------------------
  //  8DOT STATE
  //---------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_EIGHTDOTSTATE <= 0;
    end else begin
      if ((cx[1:0] == 2'b11)) begin
        if ((FF_PRE_X_CNT == 0)) begin
          FF_EIGHTDOTSTATE <= 0;
        end else begin
          FF_EIGHTDOTSTATE <= 3'(FF_EIGHTDOTSTATE + 1);
        end
      end
    end
  end

  //---------------------------------------------------------------------------
  //  GENERATE DOTCOUNTER
  //---------------------------------------------------------------------------
  assign W_PRE_X_CNT_START0 = {REG_R18_ADJ[3], REG_R18_ADJ[3:0]} + 5'b11000;  //  (-8...7) - 8 = (-16...-1)

  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_PRE_X_CNT_START1 <= {6{1'b0}};
    end else begin
      FF_PRE_X_CNT_START1 <= ({W_PRE_X_CNT_START0[4], W_PRE_X_CNT_START0}) - ({3'b000, REG_R27_H_SCROLL});
      // (-23...-1)
    end
  end

  bit pre_x_count_mark;

  assign pre_x_count_mark = cy[0] == 0 &&
    ((cx == ({2'b00, `OFFSET_X + `LED_TV_X_NTSC - 4, 2'b10}) && !VDPR9PALMODE) ||
    (cx == ({2'b00, `OFFSET_X + `LED_TV_X_PAL - 4, 2'b10}) && VDPR9PALMODE));

  assign W_PRE_X_CNT_START2[8:6] = {3{FF_PRE_X_CNT_START1[5]}};
  assign W_PRE_X_CNT_START2[5:0] = FF_PRE_X_CNT_START1;

  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_PRE_X_CNT <= 0;
    end else begin
      if (pre_x_count_mark) begin
        FF_PRE_X_CNT <= W_PRE_X_CNT_START2;
      end else if ((cx[1:0] == 2'b10)) begin
        FF_PRE_X_CNT <= 9'(FF_PRE_X_CNT + 1);
      end
    end
  end

  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_X_CNT <= 0;
    end else begin
      if (pre_x_count_mark) begin
        // HOLD
      end else if ((cx[1:0] == 2'b10)) begin
        if ((FF_PRE_X_CNT == 9'b111111111)) begin
          // JP: FF_PRE_X_CNT が -1から0にカウントアップする時にFF_X_CNTを-8にする
          // (When FF_PRE_X_CNT counts up from -1 to 0, FF_X_CNT is set to -8.)
          FF_X_CNT <= -8;
        end else begin
          FF_X_CNT <= 9'(FF_X_CNT + 1);
        end
      end
    end
  end

  //---------------------------------------------------------------------------
  // GENERATE V-SYNC PULSE
  //---------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      IVIDEOVS_N <= 1'b1;
    end else begin
      if ((W_V_CNT_IN_FIELD == 6)) begin
        // SSTATE = SSTATE_B
        IVIDEOVS_N <= 1'b0;
      end else if ((W_V_CNT_IN_FIELD == 12)) begin
        // SSTATE = SSTATE_A
        IVIDEOVS_N <= 1'b1;
      end
    end
  end

  //---------------------------------------------------------------------------
  //  DISPLAY WINDOW
  //---------------------------------------------------------------------------
  // LEFT MASK (R25 MSK)
  // H_SCROLL = 0 --> 8
  // H_SCROLL = 1 --> 7
  // H_SCROLL = 2 --> 6
  // H_SCROLL = 3 --> 5
  // H_SCROLL = 4 --> 4
  // H_SCROLL = 5 --> 3
  // H_SCROLL = 6 --> 2
  // H_SCROLL = 7 --> 1
  assign W_LEFT_MASK = (REG_R25_MSK == 1'b0) ? {9{1'b0}} : {5'b00000, {1'b0, ~REG_R27_H_SCROLL} + 1};
  always_ff @(posedge CLK21M) begin
    // MAIN WINDOW
    if ((cx[1:0] == 2'b01 && FF_X_CNT == W_LEFT_MASK)) begin
      // WHEN DOTCOUNTER_X = 0
      FF_RIGHT_MASK <= 9'b100000000 - ({6'b000000, REG_R27_H_SCROLL});
    end
  end

  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_WINDOW_X <= 1'b0;
    end else begin
      // MAIN WINDOW
      if ((cx[1:0] == 2'b01 && FF_X_CNT == W_LEFT_MASK)) begin
        // WHEN DOTCOUNTER_X = 0
        FF_WINDOW_X <= 1'b1;
      end else if ((cx[1:0] == 2'b01 && FF_X_CNT == FF_RIGHT_MASK)) begin
        // WHEN DOTCOUNTER_X = 256
        FF_WINDOW_X <= 1'b0;
      end
    end
  end

  //---------------------------------------------------------------------------
  // Y
  //---------------------------------------------------------------------------

  assign W_Y_ADJ = {REG_R18_ADJ[7], REG_R18_ADJ[7], REG_R18_ADJ[7], REG_R18_ADJ[7], REG_R18_ADJ[7], REG_R18_ADJ[7:4]};

  always_ff @(posedge CLK21M, posedge RESET) begin : P1
    reg [8:0] PREDOTCOUNTER_YP_V;
    reg [8:0] PREDOTCOUNTERYPSTART;

    if ((RESET == 1'b1)) begin
      FF_PRE_Y_CNT <= {9{1'b0}};
      FF_MONITOR_LINE <= {9{1'b0}};
      PREWINDOW_Y <= 1'b0;
    end else begin
      if (HSYNC) begin
        // JP: PREWINDOW_Xが 1になるタイミングと同じタイミングでY座標の計算
        // (Y coordinate calculation at the same timing as when PREWINDOW_X becomes 1)
        if ((W_V_BLANKING_END == 1'b1)) begin
          if ((REG_R9_Y_DOTS == 1'b0 && VDPR9PALMODE == 1'b0)) begin  //NTSC 192 LINES
            PREDOTCOUNTERYPSTART = (-26 / 2);  // TOP BORDER LINES = -26
          end else if ((REG_R9_Y_DOTS == 1'b1 && VDPR9PALMODE == 1'b0)) begin  //NTSC 212 LINES
            PREDOTCOUNTERYPSTART = (-16 / 2);  // TOP BORDER LINES = -16
          end else if ((REG_R9_Y_DOTS == 1'b0 && VDPR9PALMODE == 1'b1)) begin  //pal 192 LINES
            PREDOTCOUNTERYPSTART = (-53 / 2);  // TOP BORDER LINES = -53
          end else if ((REG_R9_Y_DOTS == 1'b1 && VDPR9PALMODE == 1'b1)) begin  //PAL 212 lines
            PREDOTCOUNTERYPSTART = (-43 / 2);  // TOP BORDER LINES = -43
          end
          // TODO: not sure why the border counts needed to be divided by 2.  But unless we do this
          // the main image is seems to have a double border height.
          FF_MONITOR_LINE <= PREDOTCOUNTERYPSTART + W_Y_ADJ;
          PREWINDOW_Y_SP  <= 1'b1;
        end else begin
          if ((PREDOTCOUNTER_YP_V == 255)) begin
            PREDOTCOUNTER_YP_V = FF_MONITOR_LINE;
          end else begin
            PREDOTCOUNTER_YP_V = 9'(FF_MONITOR_LINE + 1);
          end
          if ((PREDOTCOUNTER_YP_V == 0)) begin
            ENAHSYNC <= 1'b1;
            PREWINDOW_Y <= 1'b1;
          end else if (((REG_R9_Y_DOTS == 1'b0 && PREDOTCOUNTER_YP_V == 192) || (REG_R9_Y_DOTS == 1'b1 && PREDOTCOUNTER_YP_V == 212))) begin
            PREWINDOW_Y <= 1'b0;
            PREWINDOW_Y_SP <= 1'b0;
          end
          else if(((REG_R9_Y_DOTS == 1'b0 && VDPR9PALMODE == 1'b0 && PREDOTCOUNTER_YP_V == 235) || (REG_R9_Y_DOTS == 1'b1 && VDPR9PALMODE == 1'b0 && PREDOTCOUNTER_YP_V == 245) || (REG_R9_Y_DOTS == 1'b0 && VDPR9PALMODE == 1'b1 && PREDOTCOUNTER_YP_V == 259) || (REG_R9_Y_DOTS == 1'b1 && VDPR9PALMODE == 1'b1 && PREDOTCOUNTER_YP_V == 269))) begin
            ENAHSYNC <= 1'b0;
          end
          FF_MONITOR_LINE <= PREDOTCOUNTER_YP_V;
        end
      end
      FF_PRE_Y_CNT <= FF_MONITOR_LINE + ({1'b0, REG_R23_VSTART_LINE});
    end
  end

  // -----------------------------------------------------------------------------
  // -- VSYNC INTERRUPT REQUEST
  // -----------------------------------------------------------------------------
  logic [8:0] W_V_SYNC_INTR_START_LINE;

  assign W_LINE_MODE = {REG_R9_Y_DOTS, VDPR9PALMODE};

  always_comb begin
    case (W_LINE_MODE)
      2'b00:   W_V_SYNC_INTR_START_LINE = `V_BLANKING_START_192_NTSC;  // 240
      2'b10:   W_V_SYNC_INTR_START_LINE = `V_BLANKING_START_212_NTSC;  // 250
      2'b01:   W_V_SYNC_INTR_START_LINE = `V_BLANKING_START_192_PAL;  // 263
      2'b11:   W_V_SYNC_INTR_START_LINE = `V_BLANKING_START_212_PAL;  // 273
      default: W_V_SYNC_INTR_START_LINE = 9'bx;
    endcase
  end

  assign W_V_BLANKING_END = ((W_V_CNT_IN_FIELD == {2'b00, `OFFSET_Y + `LED_TV_Y_NTSC, W_FIELD & REG_R9_INTERLACE_MODE} && VDPR9PALMODE == 1'b0) ||
                            (W_V_CNT_IN_FIELD == {2'b00, `OFFSET_Y + `LED_TV_Y_PAL, W_FIELD & REG_R9_INTERLACE_MODE} && VDPR9PALMODE == 1'b1)) ? 1'b1 : 1'b0;

  assign W_V_BLANKING_START = ((W_V_CNT_IN_FIELD == {W_V_SYNC_INTR_START_LINE + `LED_TV_Y_NTSC, W_FIELD & REG_R9_INTERLACE_MODE} && VDPR9PALMODE == 1'b0) ||
                              (W_V_CNT_IN_FIELD == {W_V_SYNC_INTR_START_LINE + `LED_TV_Y_PAL, W_FIELD & REG_R9_INTERLACE_MODE} && VDPR9PALMODE == 1'b1)) ? 1'b1 : 1'b0;

endmodule

