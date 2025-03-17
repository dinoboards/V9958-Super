//
//  converted from vdp_hvcounter.vhd
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
    input bit RESET,
    input bit CLK21M,
    input bit [9:0] cx,
    input bit [9:0] cy,
    output bit [9:0] V_CNT_IN_FIELD,
    input bit [9:0] V_CNT_IN_FRAME,
    output bit FIELD,
    output bit H_BLANK,
    output bit V_BLANK,
    input bit PAL_MODE,
    input bit INTERLACE_MODE,
    input bit Y212_MODE,
    input bit BLANKING_START,
    input bit BLANKING_END
);

  import custom_timings::*;

  bit [9:0] FF_V_CNT_IN_FIELD;
  bit FF_FIELD;
  bit [9:0] FF_V_CNT_IN_FRAME;
  bit FF_H_BLANK;
  bit FF_V_BLANK;
  bit [9:0] FF_FIELD_END_CNT;
  bit FF_FIELD_END;
  bit W_FIELD;
  bit W_H_CNT_HALF;
  bit W_H_CNT_END;
  bit [9:0] W_FIELD_END_CNT;
  bit W_FIELD_END;
  bit [1:0] W_DISPLAY_MODE;
  bit [1:0] W_LINE_MODE;
  bit W_H_BLANK_START;
  bit W_H_BLANK_END;
  bit [8:0] W_V_SYNC_INTR_START_LINE;

  assign V_CNT_IN_FIELD = V_CNT_IN_FRAME;
  assign FIELD = FF_FIELD;
  assign FF_V_CNT_IN_FRAME = V_CNT_IN_FRAME;
  assign H_BLANK = FF_H_BLANK;
  assign V_BLANK = FF_V_BLANK;


  //------------------------------------------------------------------------
  //  HORIZONTAL COUNTER
  //------------------------------------------------------------------------
  assign W_H_CNT_HALF = (cy[0] == 0 && cx == ((CLOCKS_PER_HALF_LINE(PAL_MODE)) - 1));
  assign W_H_CNT_END = (cy[0] == 1 && cx == ((CLOCKS_PER_HALF_LINE(PAL_MODE)) - 1));

  //------------------------------------------------------------------------
  //  VERTICAL COUNTER
  //------------------------------------------------------------------------
  assign W_FIELD_END = FF_FIELD_END;
  always_ff @(posedge RESET or posedge CLK21M) begin
    if (RESET) begin
      FF_FIELD_END <= 1'b0;
    end else begin
      if ((PAL_MODE == 1'b0 && FF_V_CNT_IN_FIELD == 10'd524) || (PAL_MODE == 1'b1 && FF_V_CNT_IN_FIELD == 10'd624)) begin
        FF_FIELD_END <= 1'b1;
      end else begin
        FF_FIELD_END <= 1'b0;
      end
    end
  end

  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_V_CNT_IN_FIELD <= 0;
    end else begin
      if (((W_H_CNT_HALF | W_H_CNT_END) == 1'b1)) begin
        if ((W_FIELD_END == 1'b1)) begin
          FF_V_CNT_IN_FIELD <= 0;
        end else begin
          FF_V_CNT_IN_FIELD <= 10'(FF_V_CNT_IN_FIELD + 1);
        end
      end
    end
  end

  //------------------------------------------------------------------------
  //  FIELD ID
  //------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_FIELD <= 1'b0;
    end else begin
      if (((W_H_CNT_HALF | W_H_CNT_END) == 1'b1)) begin
        if ((W_FIELD_END == 1'b1)) begin
          FF_FIELD <= ~FF_FIELD;
        end
      end
    end
  end

  //---------------------------------------------------------------------------
  // H BLANKING
  //---------------------------------------------------------------------------
  assign W_H_BLANK_START = W_H_CNT_END;
  assign W_H_BLANK_END   = cy[0] == 0 && cx == `LEFT_BORDER;
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_H_BLANK <= 1'b0;
    end else begin
      if (W_H_BLANK_START) begin
        FF_H_BLANK <= 1'b1;
      end else if (W_H_BLANK_END) begin
        FF_H_BLANK <= 1'b0;
      end
    end
  end

  //---------------------------------------------------------------------------
  // V BLANKING
  //---------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_V_BLANK <= 1'b0;
    end else begin
      if (W_H_BLANK_END) begin
        if (BLANKING_END) begin
          FF_V_BLANK <= 1'b0;
        end else if (BLANKING_START) begin
          FF_V_BLANK <= 1'b1;
        end
      end
    end
  end

endmodule
