// File src/vdp/vdp_vga.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
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

//
//  vdp_vga.vhd
//   VGA up-scan converter.
//
//  Copyright (C) 2006 Kunihiko Ohnaka
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
// Memo
//   Japanese comment lines are starts with "JP:".
//   JP: 日本語のコメント行は JP:を頭に付ける事にする
//
//-----------------------------------------------------------------------------
// Revision History
//
// 3rd,June,2018 modified by KdL
//  - Added a trick to help set a pixel ratio 1:1
//    on an LED display at 60Hz (not guaranteed on all displays)
//
// 29th,October,2006 modified by Kunihiko Ohnaka
//  - Inserted the license text
//  - Added the document part below
//
// ??th,August,2006 modified by Kunihiko Ohnaka
//  - Moved the equalization pulse generator from vdp.vhd
//
// 20th,August,2006 modified by Kunihiko Ohnaka
//  - Changed field mapping algorithm when interlace mode is enabled
//        even field  -> even line (odd  line is black)
//        odd  field  -> odd line  (even line is black)
//
// 13th,October,2003 created by Kunihiko Ohnaka
// JP: VDPのコアの実装と表示デバイスへの出力を別ソースにした．
//
//-----------------------------------------------------------------------------
// Document
//
// JP: ESE-VDPコア(vdp.vhd)が生成したビデオ信号を、VGAタイミングに
// JP: 変換するアップスキャンコンバータです。
// JP: NTSCは水平同期周波数が15.7kHz、垂直同期周波数が60Hzですが、
// JP: VGAの水平同期周波数は31.5kHz、垂直同期周波数は60Hzであり、
// JP: ライン数だけがほぼ倍になったようなタイミングになります。
// JP: そこで、vdpを ntscモードで動かし、各ラインを倍の速度で
// JP: 二度描画することでスキャンコンバートを実現しています。
// (The video signal generated by the ESE-VDP core vdp.vhd)
// (is converted to VGA timing by this up-scan converter.)
// (NTSC has a horizontal sync frequency of 15.7kHz and a vertical sync frequency of 60Hz,)
// (the horizontal sync frequency of VGA is 31.5kHz and the vertical sync frequency is 60Hz,)
// (so the timing is almost doubled in the number of lines.)
// (Therefore, the vdp is operated in ntsc mode, and each line is)
// (realized by drawing twice at double speed.)
// no timescale needed

`include "vdp_constants.vh"

module VDP_VGA (
    input wire CLK21M,
    input wire RESET,
    input wire [5:0] VIDEORIN,
    input wire [5:0] VIDEOGIN,
    input wire [5:0] VIDEOBIN,
    input wire VIDEOVSIN_N,
    input wire [10:0] HCOUNTERIN,
    input wire [10:0] VCOUNTERIN,
    input wire PALMODE,
    input wire INTERLACEMODE,
    input wire LEGACY_VGA,
    output wire [5:0] VIDEOROUT,
    output wire [5:0] VIDEOGOUT,
    output wire [5:0] VIDEOBOUT,
    output wire VIDEOHSOUT_N,
    output wire VIDEOVSOUT_N,
    output wire BLANK_O,
    input wire [2:0] RATIOMODE
);

  // VDP CLOCK ... 21.477MHZ
  // VIDEO INPUT
  // MODE
  // Added by caro
  // VIDEO OUTPUT
  // HDMI SUPPORT
  // SWITCHED I/O SIGNALS



  reg FF_HSYNC_N;
  reg FF_VSYNC_N;  // VIDEO OUTPUT ENABLE
  reg VIDEOOUTX;  // DOUBLE BUFFER SIGNAL
  wire [9:0] XPOSITIONW;
  reg [9:0] XPOSITIONR;
  wire EVENODD;
  wire WE_BUF;
  wire [5:0] DATAROUT;
  wire [5:0] DATAGOUT;
  wire [5:0] DATABOUT;  // DISP_START_X + DISP_WIDTH < `CLOCKS_PER_HALF_LINE = 684
  parameter DISP_WIDTH = 720;  //    SHARED VARIABLE DISP_START_X    : INTEGER := 0; --684 - DISP_WIDTH - 2;          -- 106
  parameter DISP_START_X = 0;  // 106

  assign VIDEOROUT = (VIDEOOUTX == 1'b1) ? DATAROUT : {6{1'b0}};
  assign VIDEOGOUT = (VIDEOOUTX == 1'b1) ? DATAGOUT : {6{1'b0}};
  assign VIDEOBOUT = (VIDEOOUTX == 1'b1) ? DATABOUT : {6{1'b0}};
  VDP_DOUBLEBUF DBUF (
      .CLK(CLK21M),
      .XPOSITIONW(XPOSITIONW),
      .XPOSITIONR(XPOSITIONR),
      .EVENODD(EVENODD),
      .WE(WE_BUF),
      .DATARIN(VIDEORIN),
      .DATAGIN(VIDEOGIN),
      .DATABIN(VIDEOBIN),
      .DATAROUT(DATAROUT),
      .DATAGOUT(DATAGOUT),
      .DATABOUT(DATABOUT)
  );

  assign XPOSITIONW = HCOUNTERIN[10:1];
  // - (`CLOCKS_PER_HALF_LINE - DISP_WIDTH - 10);
  assign EVENODD = VCOUNTERIN[1];
  assign WE_BUF = 1'b1;
  //    -- PIXEL RATIO 1:1 FOR LED DISPLAY
  //    PROCESS( CLK21M )
  //        CONSTANT DISP_START_Y   : INTEGER := 3;
  //        CONSTANT PRB_HEIGHT     : INTEGER := 25;
  //        CONSTANT RIGHT_X        : INTEGER := 684 - DISP_WIDTH - 2;              -- 106
  //        CONSTANT PAL_RIGHT_X    : INTEGER := 87;                                -- 87
  //        CONSTANT CENTER_X       : INTEGER := RIGHT_X - 32 - 2;                  -- 72
  //        CONSTANT BASE_LEFT_X    : INTEGER := CENTER_X - 32 - 2 - 3;             -- 35
  //    BEGIN
  //        IF( CLK21M'EVENT AND CLK21M = '1' )THEN
  //            IF( (RATIOMODE = "000" OR INTERLACEMODE = '1' OR PALMODE = '1') AND LEGACY_VGA = '1' )THEN
  //--                 LEGACY OUTPUT
  //                DISP_START_X := RIGHT_X;                                        -- 106
  //            ELSIF( PALMODE = '1' )THEN
  //--                 50HZ
  //                DISP_START_X := PAL_RIGHT_X;                                    -- 87
  //            ELSIF( RATIOMODE = "000" OR INTERLACEMODE = '1' )THEN
  //--                 60HZ
  //                DISP_START_X := CENTER_X;                                       -- 72
  //            ELSIF( (VCOUNTERIN < 38 + DISP_START_Y + PRB_HEIGHT) OR
  //                   (VCOUNTERIN > 526 - PRB_HEIGHT AND VCOUNTERIN < 526 ) OR
  //                   (VCOUNTERIN > 524 + 38 + DISP_START_Y AND VCOUNTERIN < 524 + 38 + DISP_START_Y + PRB_HEIGHT) OR
  //                   (VCOUNTERIN > 524 + 526 - PRB_HEIGHT) )THEN
  //                -- PIXEL RATIO 1:1 (VGA MODE, 60HZ, NOT INTERLACED)
  //--              IF( EVENODD = '0' )THEN                                         -- PLOT FROM TOP-RIGHT
  //                IF( EVENODD = '1' )THEN                                         -- PLOT FROM TOP-LEFT
  //                    DISP_START_X := BASE_LEFT_X + CONV_INTEGER(NOT RATIOMODE);  -- 35 TO 41
  //                ELSE
  //                    DISP_START_X := RIGHT_X;                                    -- 106
  //                END IF;
  //            ELSE
  //                DISP_START_X := CENTER_X;                                       -- 72
  //                  DISP_START_X := 0;
  //            END IF;
  //        END IF;
  //    END PROCESS;
  // GENERATE H-SYNC SIGNAL
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_HSYNC_N <= 1'b1;
    end else begin
      if (((HCOUNTERIN == 0) || (HCOUNTERIN == (`CLOCKS_PER_HALF_LINE)))) begin
        FF_HSYNC_N <= 1'b0;
      end else if (((HCOUNTERIN == 40) || (HCOUNTERIN == ((`CLOCKS_PER_HALF_LINE) + 40)))) begin
        FF_HSYNC_N <= 1'b1;
      end
    end
  end

  // GENERATE V-SYNC SIGNAL
  // THE VIDEOVSIN_N SIGNAL IS NOT USED
  always @(posedge RESET, posedge CLK21M) begin : P1
    parameter CENTER_Y = 12;  // based on HDMI AV output

    if ((RESET == 1'b1)) begin
      FF_VSYNC_N <= 1'b1;
    end else begin
      if ((PALMODE == 1'b0)) begin
        if ((INTERLACEMODE == 1'b0)) begin
          if(((VCOUNTERIN == (3 * 2 + CENTER_Y)) || (VCOUNTERIN == (524 + 3 * 2 + CENTER_Y)))) begin
            FF_VSYNC_N <= 1'b0;
          end
          else if(((VCOUNTERIN == (6 * 2 + CENTER_Y)) || (VCOUNTERIN == (524 + 6 * 2 + CENTER_Y)))) begin
            FF_VSYNC_N <= 1'b1;
          end
        end else begin
          if(((VCOUNTERIN == (3 * 2 + CENTER_Y)) || (VCOUNTERIN == (525 + 3 * 2 + CENTER_Y)))) begin
            FF_VSYNC_N <= 1'b0;
          end
          else if(((VCOUNTERIN == (6 * 2 + CENTER_Y)) || (VCOUNTERIN == (525 + 6 * 2 + CENTER_Y)))) begin
            FF_VSYNC_N <= 1'b1;
          end
        end
      end else begin
        if ((INTERLACEMODE == 1'b0)) begin
          if(((VCOUNTERIN == (3 * 2 + CENTER_Y + 6)) || (VCOUNTERIN == (626 + 3 * 2 + CENTER_Y + 6)))) begin
            FF_VSYNC_N <= 1'b0;
          end
          else if(((VCOUNTERIN == (6 * 2 + CENTER_Y + 6)) || (VCOUNTERIN == (626 + 6 * 2 + CENTER_Y + 6)))) begin
            FF_VSYNC_N <= 1'b1;
          end
        end else begin
          if(((VCOUNTERIN == (3 * 2 + CENTER_Y + 6)) || (VCOUNTERIN == (625 + 3 * 2 + CENTER_Y + 6)))) begin
            FF_VSYNC_N <= 1'b0;
          end
          else if(((VCOUNTERIN == (6 * 2 + CENTER_Y + 6)) || (VCOUNTERIN == (625 + 6 * 2 + CENTER_Y + 6)))) begin
            FF_VSYNC_N <= 1'b1;
          end
        end
      end
    end
  end

  // GENERATE DATA READ TIMING
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      XPOSITIONR <= {10{1'b0}};
    end else begin
      if(((HCOUNTERIN == DISP_START_X) || (HCOUNTERIN == (DISP_START_X + (`CLOCKS_PER_HALF_LINE))))) begin
        XPOSITIONR <= {10{1'b0}};
      end else begin
        XPOSITIONR <= XPOSITIONR + 1;
      end
    end
  end

  // GENERATE VIDEO OUTPUT TIMING
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      VIDEOOUTX <= 1'b0;
    end else begin
      //            IF( (HCOUNTERIN = DISP_START_X) OR
      //                    ((HCOUNTERIN = DISP_START_X + (`CLOCKS_PER_HALF_LINE)) AND INTERLACEMODE = '0') )THEN
      VIDEOOUTX <= 1'b1;
      //            ELSIF( (HCOUNTERIN = DISP_START_X + DISP_WIDTH) OR
      //                    (HCOUNTERIN = DISP_START_X + DISP_WIDTH + (`CLOCKS_PER_HALF_LINE)) )THEN
      //                VIDEOOUTX <= '0';
      //            END IF;
    end
  end

  assign VIDEOHSOUT_N = FF_HSYNC_N;
  assign VIDEOVSOUT_N = FF_VSYNC_N;
  // HDMI SUPPORT
  assign BLANK_O = (VIDEOOUTX == 1'b0 || FF_VSYNC_N == 1'b0) ? 1'b1 : 1'b0;

endmodule