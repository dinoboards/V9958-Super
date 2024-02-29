//
//  vdp_hvcounter.vhd
//   horizontal and vertical counter of ESE-VDP.
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
//

`include "vdp_constants.vh"

module VDP_HVCOUNTER (
    input wire RESET,
    input wire CLK21M,
    output wire [10:0] H_CNT,
    output wire [10:0] H_CNT_IN_FIELD,
    output wire [9:0] V_CNT_IN_FIELD,
    output wire [10:0] V_CNT_IN_FRAME,
    output wire FIELD,
    output wire H_BLANK,
    output wire V_BLANK,
    input wire PAL_MODE,
    input wire INTERLACE_MODE,
    input wire Y212_MODE,
    input wire [6:0] OFFSET_Y,
    output wire HDMI_RESET,
    input wire BLANKING_START,
    input wire BLANKING_END
);

import custom_timings::*;

  reg [10:0] FF_H_CNT;
  reg [10:0] FF_H_CNT_IN_FIELD;
  reg [9:0] FF_V_CNT_IN_FIELD;
  reg FF_FIELD;
  reg [10:0] FF_V_CNT_IN_FRAME;
  reg FF_H_BLANK;
  reg FF_V_BLANK;
  reg FF_PAL_MODE;
  reg FF_INTERLACE_MODE;
  wire [9:0] FF_FIELD_END_CNT;
  reg FF_FIELD_END;
  reg FF_HDMI_RESET;  // WIRE
  wire W_FIELD;
  wire W_H_CNT_HALF;
  wire W_H_CNT_END;
  wire [9:0] W_FIELD_END_CNT;
  wire W_FIELD_END;
  wire [1:0] W_DISPLAY_MODE;
  wire [1:0] W_LINE_MODE;
  wire W_H_BLANK_START;
  wire W_H_BLANK_END;
  wire [8:0] W_V_SYNC_INTR_START_LINE;

  assign H_CNT = FF_H_CNT;
  assign H_CNT_IN_FIELD = FF_H_CNT_IN_FIELD;
  assign V_CNT_IN_FIELD = FF_V_CNT_IN_FIELD;
  assign FIELD = FF_FIELD;
  assign V_CNT_IN_FRAME = FF_V_CNT_IN_FRAME;
  assign H_BLANK = FF_H_BLANK;
  assign V_BLANK = FF_V_BLANK;
  assign HDMI_RESET = FF_HDMI_RESET;

  //------------------------------------------------------------------------
  //  V SYNCHRONIZE MODE CHANGE
  //------------------------------------------------------------------------
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_PAL_MODE <= 1'b0;
      FF_INTERLACE_MODE <= 1'b0;
      FF_HDMI_RESET <= 1'b0;
    end else begin
      if ((((W_H_CNT_HALF | W_H_CNT_END) & W_FIELD_END & FF_FIELD) == 1'b1)) begin
        FF_PAL_MODE <= PAL_MODE;
        FF_INTERLACE_MODE <= INTERLACE_MODE;
        if ((FF_PAL_MODE == PAL_MODE)) begin
          FF_HDMI_RESET <= 1'b0;
        end else begin
          FF_HDMI_RESET <= 1'b1;
        end
      end else begin
        FF_HDMI_RESET <= 1'b0;
      end
    end
  end

  //------------------------------------------------------------------------
  //  HORIZONTAL COUNTER
  //------------------------------------------------------------------------
  assign W_H_CNT_HALF = (FF_H_CNT == ((CLOCKS_PER_HALF_LINE(PAL_MODE)) - 1)) ? 1'b1 : 1'b0;
  assign W_H_CNT_END  = (FF_H_CNT == (CLOCKS_PER_LINE(PAL_MODE) - 1)) ? 1'b1 : 1'b0;
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_H_CNT <= {11{1'b0}};
    end else begin
      if((W_H_CNT_END == 1'b1 || (W_FIELD_END == 1'b1 && W_H_CNT_HALF == 1'b1 && FF_INTERLACE_MODE == 1'b0))) begin
        FF_H_CNT <= {11{1'b0}};
      end else begin
        FF_H_CNT <= FF_H_CNT + 1;
      end
    end
  end

  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_H_CNT_IN_FIELD <= {11{1'b0}};
    end else begin
      if ((W_H_CNT_END == 1'b1 || W_H_CNT_HALF == 1'b1)) begin
        FF_H_CNT_IN_FIELD <= {11{1'b0}};
      end else begin
        FF_H_CNT_IN_FIELD <= FF_H_CNT_IN_FIELD + 1;
      end
    end
  end

  //------------------------------------------------------------------------
  //  VERTICAL COUNTER
  //------------------------------------------------------------------------
  assign W_FIELD_END = FF_FIELD_END;
  always @(posedge RESET or posedge CLK21M) begin
    if (RESET) begin
      FF_FIELD_END <= 1'b0;
    end else if (CLK21M) begin
      if (
            (FF_FIELD == 1'b0 && FF_INTERLACE_MODE == 1'b0 && FF_PAL_MODE == 1'b0 && FF_V_CNT_IN_FIELD == 10'd524) ||
            (FF_FIELD == 1'b0 && FF_INTERLACE_MODE == 1'b0 && FF_PAL_MODE == 1'b1 && FF_V_CNT_IN_FIELD == 10'd624) ||
            (FF_FIELD == 1'b1 && FF_INTERLACE_MODE == 1'b0 && FF_PAL_MODE == 1'b0 && FF_V_CNT_IN_FIELD == 10'd524) ||
            (FF_FIELD == 1'b1 && FF_INTERLACE_MODE == 1'b0 && FF_PAL_MODE == 1'b1 && FF_V_CNT_IN_FIELD == 10'd624) ||
            (FF_FIELD == 1'b0 && FF_INTERLACE_MODE == 1'b1 && FF_PAL_MODE == 1'b0 && FF_V_CNT_IN_FIELD == 10'd524) ||
            (FF_FIELD == 1'b0 && FF_INTERLACE_MODE == 1'b1 && FF_PAL_MODE == 1'b1 && FF_V_CNT_IN_FIELD == 10'd624) ||
            (FF_FIELD == 1'b1 && FF_INTERLACE_MODE == 1'b1 && FF_PAL_MODE == 1'b0 && FF_V_CNT_IN_FIELD == 10'd524) ||
            (FF_FIELD == 1'b1 && FF_INTERLACE_MODE == 1'b1 && FF_PAL_MODE == 1'b1 && FF_V_CNT_IN_FIELD == 10'd624)
        ) begin
        FF_FIELD_END <= 1'b1;
      end else begin
        FF_FIELD_END <= 1'b0;
      end
    end
  end

  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_V_CNT_IN_FIELD <= {10{1'b0}};
    end else begin
      if (((W_H_CNT_HALF | W_H_CNT_END) == 1'b1)) begin
        if ((W_FIELD_END == 1'b1)) begin
          FF_V_CNT_IN_FIELD <= {10{1'b0}};
        end else begin
          FF_V_CNT_IN_FIELD <= FF_V_CNT_IN_FIELD + 1;
        end
      end
    end
  end

  //------------------------------------------------------------------------
  //  FIELD ID
  //------------------------------------------------------------------------
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_FIELD <= 1'b0;
    end else begin
      // GENERATE FF_FIELD SIGNAL
      if (((W_H_CNT_HALF | W_H_CNT_END) == 1'b1)) begin
        if ((W_FIELD_END == 1'b1)) begin
          FF_FIELD <= ~FF_FIELD;
        end
      end
    end
  end

  //------------------------------------------------------------------------
  //  VERTICAL COUNTER IN FRAME
  //------------------------------------------------------------------------
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_V_CNT_IN_FRAME <= {11{1'b0}};
    end else begin
      if (((W_H_CNT_HALF | W_H_CNT_END) == 1'b1)) begin
        if ((W_FIELD_END == 1'b1 && (FF_FIELD == 1'b1 || FF_INTERLACE_MODE == 1'b0))) begin
          FF_V_CNT_IN_FRAME <= {11{1'b0}};
        end else begin
          FF_V_CNT_IN_FRAME <= FF_V_CNT_IN_FRAME + 1;
        end
      end
    end
  end

  //---------------------------------------------------------------------------
  // H BLANKING
  //---------------------------------------------------------------------------
  assign W_H_BLANK_START = W_H_CNT_END;
  assign W_H_BLANK_END   = (FF_H_CNT == `LEFT_BORDER) ? 1'b1 : 1'b0;
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_H_BLANK <= 1'b0;
    end else begin
      if ((W_H_BLANK_START == 1'b1)) begin
        FF_H_BLANK <= 1'b1;
      end else if ((W_H_BLANK_END == 1'b1)) begin
        FF_H_BLANK <= 1'b0;
      end
    end
  end

  //---------------------------------------------------------------------------
  // V BLANKING
  //---------------------------------------------------------------------------
  always @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_V_BLANK <= 1'b0;
    end else begin
      if ((W_H_BLANK_END == 1'b1)) begin
        if ((BLANKING_END == 1'b1)) begin
          FF_V_BLANK <= 1'b0;
        end else if ((BLANKING_START == 1'b1)) begin
          FF_V_BLANK <= 1'b1;
        end
      end
    end
  end

endmodule
