//
//  converted from vdp_interrupt.vhd
//   Interrupt controller of ESE-VDP.
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

`include "vdp_constants.vh"

module VDP_INTERRUPT (
    input wire RESET,
    input wire CLK21M,
    input bit [10:0] cx,
    input bit [9:0] cy,
    input wire [7:0] Y_CNT,
    input wire ACTIVE_LINE,
    input wire V_BLANKING_START,
    input wire CLR_VSYNC_INT,
    input wire CLR_HSYNC_INT,
    output wire REQ_VSYNC_INT_N,
    output wire REQ_HSYNC_INT_N,
    input wire [7:0] REG_R19_HSYNC_INT_LINE
);


  reg  FF_VSYNC_INT_N;
  reg  FF_HSYNC_INT_N;
  wire W_VSYNC_INTR_TIMING;

  assign REQ_VSYNC_INT_N = FF_VSYNC_INT_N;
  assign REQ_HSYNC_INT_N = FF_HSYNC_INT_N;

  //---------------------------------------------------------------------------
  // VSYNC INTERRUPT REQUEST
  //---------------------------------------------------------------------------
  assign W_VSYNC_INTR_TIMING = (cx == `LEFT_BORDER) && cy[0] == 0;
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_VSYNC_INT_N <= 1'b1;

    end else begin
      if ((CLR_VSYNC_INT == 1'b1)) begin
        // V-BLANKING INTERRUPT CLEAR
        FF_VSYNC_INT_N <= 1'b1;
      end else if ((W_VSYNC_INTR_TIMING == 1'b1 && V_BLANKING_START == 1'b1)) begin
        // V-BLANKING INTERRUPT REQUEST
        FF_VSYNC_INT_N <= 1'b0;
      end
    end
  end

  //------------------------------------------------------------------------
  //  W_HSYNC INTERRUPT REQUEST
  //------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_HSYNC_INT_N <= 1'b1;
    end else begin
      if((CLR_HSYNC_INT == 1'b1 || (W_VSYNC_INTR_TIMING == 1'b1 && V_BLANKING_START == 1'b1))) begin
        // H-BLANKING INTERRUPT CLEAR
        FF_HSYNC_INT_N <= 1'b1;
      end else if ((ACTIVE_LINE == 1'b1 && Y_CNT == REG_R19_HSYNC_INT_LINE)) begin
        // H-BLANKING INTERRUPT REQUEST
        FF_HSYNC_INT_N <= 1'b0;
      end
    end
  end

endmodule
