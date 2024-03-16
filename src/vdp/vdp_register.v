//  converted from vdp_register.vhd
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
//----------------------------------------------------------------------------


`include "vdp_constants.vh"

module VDP_REGISTER (
    input wire RESET,
    input wire CLK21M,
    input wire REQ,
    output wire ACK,
    input wire WRT,
    input wire [1:0] mode,
    output reg [7:0] DBI,
    input wire [7:0] DBO,
    input wire [1:0] DOTSTATE,
    input wire VDPCMDTRCLRACK,
    input wire VDPCMDREGWRACK,
    input wire HSYNC,
    input wire VDPS0SPCOLLISIONINCIDENCE,
    input wire VDPS0SPOVERMAPPED,
    input wire [4:0] VDPS0SPOVERMAPPEDNUM,
    output wire SPVDPS0RESETREQ,
    input wire SPVDPS0RESETACK,
    output reg SPVDPS5RESETREQ,
    input wire SPVDPS5RESETACK,
    input wire VDPCMDTR,
    input wire VD,
    input wire HD,
    input wire VDPCMDBD,
    input wire FIELD,
    input wire VDPCMDCE,
    input wire [8:0] VDPS3S4SPCOLLISIONX,
    input wire [8:0] VDPS5S6SPCOLLISIONY,
    input wire [7:0] VDPCMDCLR,
    input wire [10:0] VDPCMDSXTMP,
    output reg [7:0] VDPVRAMACCESSDATA,
    output reg [16:0] VDPVRAMACCESSADDRTMP,
    output reg VDPVRAMADDRSETREQ,
    input wire VDPVRAMADDRSETACK,
    output reg VDPVRAMWRREQ,
    input wire VDPVRAMWRACK,
    input wire [7:0] VDPVRAMRDDATA,
    output reg VDPVRAMRDREQ,
    input wire VDPVRAMRDACK,
    output reg [3:0] VDPCMDREGNUM,
    output reg [7:0] VDPCMDREGDATA,
    output reg VDPCMDREGWRREQ,
    output reg VDPCMDTRCLRREQ,
    input wire [3:0] PALETTEADDR_OUT,
    output wire [7:0] PALETTEDATARB_OUT,
    output wire [7:0] PALETTEDATAG_OUT,
    output reg CLR_VSYNC_INT,
    output reg CLR_HSYNC_INT,
    input wire REQ_VSYNC_INT_N,
    input wire REQ_HSYNC_INT_N,
    output reg REG_R0_HSYNC_INT_EN,
    output reg REG_R1_SP_SIZE,
    output reg REG_R1_SP_ZOOM,
    output reg REG_R1_BL_CLKS,
    output reg REG_R1_VSYNC_INT_EN,
    output reg REG_R1_DISP_ON,
    output reg [6:0] REG_R2_PT_NAM_ADDR,
    output reg [5:0] REG_R4_PT_GEN_ADDR,
    output reg [10:0] REG_R10R3_COL_ADDR,
    output reg [9:0] REG_R11R5_SP_ATR_ADDR,
    output reg [5:0] REG_R6_SP_GEN_ADDR,
    output reg [7:0] REG_R7_FRAME_COL,
    output reg REG_R8_SP_OFF,
    output reg REG_R8_COL0_ON,
    output reg REG_R9_PAL_MODE,
    output reg REG_R9_INTERLACE_MODE,
    output reg REG_R9_Y_DOTS,
    output reg [7:0] REG_R12_BLINK_MODE,
    output reg [7:0] REG_R13_BLINK_PERIOD,
    output wire [7:0] REG_R18_ADJ,
    output reg [7:0] REG_R19_HSYNC_INT_LINE,
    output reg [7:0] REG_R23_VSTART_LINE,
    output reg REG_R25_CMD,
    output reg REG_R25_YAE,
    output reg REG_R25_YJK,
    output reg REG_R25_MSK,
    output reg REG_R25_SP2,
    output reg [8:3] REG_R26_H_SCROLL,
    output reg [2:0] REG_R27_H_SCROLL,
    output wire VDPMODETEXT1,
    output wire VDPMODETEXT1Q,
    output wire VDPMODETEXT2,
    output wire VDPMODEMULTI,
    output wire VDPMODEMULTIQ,
    output wire VDPMODEGRAPHIC1,
    output wire VDPMODEGRAPHIC2,
    output wire VDPMODEGRAPHIC3,
    output wire VDPMODEGRAPHIC4,
    output wire VDPMODEGRAPHIC5,
    output wire VDPMODEGRAPHIC6,
    output wire VDPMODEGRAPHIC7,
    output wire VDPMODEISHIGHRES,
    output wire SPMODE2,

    output bit [7:0] REG_R31,
    output bit vdp_super,
    output bit super_color,
    output bit super_mid,
    output bit super_res
);

  // S#2
  // S#2
  // S#2
  // S#2
  // S#2
  // S#2
  // S#3,S#4
  // S#5,S#6
  // R44,S#7
  // S#8,S#9
  // INTERRUPT
  // REGISTER VALUE
  //  MODE
  // SWITCHED I/O SIGNALS

  reg FF_ACK;
  reg VDPP1IS1STBYTE;
  reg VDPP2IS1STBYTE;
  wire [7:0] VDPP0DATA;
  reg [7:0] VDPP1DATA;
  reg [5:0] VDPREGPTR;
  reg VDPREGWRPULSE;
  reg [3:0] VDPR15STATUSREGNUM;
  wire VSYNCINTACK;
  wire HSYNCINTACK;
  reg [3:0] VDPR16PALNUM;
  reg [5:0] VDPR17REGNUM;
  reg VDPR17INCREGNUM;
  wire [7:0] PALETTEADDR;
  wire PALETTEWE;
  reg [7:0] PALETTEDATARB_IN;
  reg [7:0] PALETTEDATAG_IN;
  reg [3:0] PALETTEWRNUM;
  reg FF_PALETTE_WR_REQ;
  reg FF_PALETTE_WR_ACK;
  reg FF_PALETTE_IN;
  reg [6:0] FF_R2_PT_NAM_ADDR;
  reg FF_R9_2PAGE_MODE;
  reg [1:0] REG_R1_DISP_MODE;
  reg FF_R1_DISP_ON;
  reg [1:0] FF_R1_DISP_MODE;
  reg FF_R25_SP2;
  reg [8:3] FF_R26_H_SCROLL;
  reg [3:0] REG_R18_VERT;
  reg [3:0] REG_R18_HORZ;
  reg [3:1] REG_R0_DISP_MODE;
  reg [3:1] FF_R0_DISP_MODE;
  reg FF_SPVDPS0RESETREQ;
  wire W_EVEN_DOTSTATE;
  wire W_IS_BITMAP_MODE;

  bit [7:0] FF_REG_R31;
  assign REG_R31 = FF_REG_R31;

  assign ACK = FF_ACK;
  assign SPVDPS0RESETREQ = FF_SPVDPS0RESETREQ;
  assign vdp_super = FF_REG_R31[0];  //if 1, activate on of the super graphic modes
  assign super_color = FF_REG_R31[2:1] == 0; // 8 bit RGB colours - 4 bytes per pixel (RGB, the 4th byte is not used) - resolution of 50Hz:180x144 (77760/103680 Bytes), 60Hz:180x120 (64800/86400 bytes)
  assign super_mid = FF_REG_R31[2:1] == 1;  // 2 bytes per pixel gggg ggrr rrrb bbbb - resolution of 50Hz:360x288 (207360 Bytes), 60Hz:360x240 (172800 bytes)
  assign super_res = FF_REG_R31[2:1] == 2;  // 1 byte per pixel into palette lookup 50Hz:720x576 (414720 Bytes), 60Hz:720x480 (345600 bytes)

  assign VDPMODEGRAPHIC1 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00000);
  assign VDPMODETEXT1 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00001);
  assign VDPMODEMULTI = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00010);
  assign VDPMODEGRAPHIC2 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00100);
  assign VDPMODETEXT1Q = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00101);
  assign VDPMODEMULTIQ = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00110);
  assign VDPMODEGRAPHIC3 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b01000);
  assign VDPMODETEXT2 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b01001);
  assign VDPMODEGRAPHIC4 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b01100);
  assign VDPMODEGRAPHIC5 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b10000);
  assign VDPMODEGRAPHIC6 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b10100);
  assign VDPMODEGRAPHIC7 = !vdp_super && (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b11100);
  assign VDPMODEISHIGHRES = !vdp_super && (REG_R0_DISP_MODE[3:2] == 2'b10 && REG_R1_DISP_MODE == 2'b00);
  assign SPMODE2 = (REG_R1_DISP_MODE == 2'b00 && (REG_R0_DISP_MODE[3] | REG_R0_DISP_MODE[2]) == 1'b1);

  //--------------------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_ACK <= 1'b0;
    end else begin
      FF_ACK <= REQ;
    end
  end

  //--------------------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      REG_R1_DISP_ON <= 1'd0;
      REG_R0_DISP_MODE <= 3'd0;
      REG_R1_DISP_MODE <= 2'd0;
      REG_R25_SP2 <= 1'd0;
      REG_R26_H_SCROLL <= 6'd0;

    end else begin
      if ((HSYNC == 1'b1)) begin
        REG_R1_DISP_ON <= FF_R1_DISP_ON;
        REG_R0_DISP_MODE <= FF_R0_DISP_MODE;
        REG_R1_DISP_MODE <= FF_R1_DISP_MODE;
        REG_R25_SP2 <= FF_R25_SP2;
        REG_R26_H_SCROLL <= FF_R26_H_SCROLL;
      end
    end
  end

  //--------------------------------------------------------------------------------------
  assign W_IS_BITMAP_MODE = (REG_R0_DISP_MODE[3] == 1'b1 || REG_R0_DISP_MODE == 3'b011) ? 1'b1 : 1'b0;
  always_ff @(posedge CLK21M) begin
    if ((W_IS_BITMAP_MODE == 1'b1 && FF_R9_2PAGE_MODE == 1'b1)) begin
      REG_R2_PT_NAM_ADDR <= (FF_R2_PT_NAM_ADDR & 7'b1011111) | ({1'b0, FIELD, 5'b00000});
    end else begin
      REG_R2_PT_NAM_ADDR <= FF_R2_PT_NAM_ADDR;
    end
  end

  //------------------------------------------------------------------------
  // PALETTE REGISTER
  //------------------------------------------------------------------------
  assign PALETTEADDR = (FF_PALETTE_IN == 1'b1) ? {4'b0000, PALETTEWRNUM} : {4'b0000, PALETTEADDR_OUT};
  assign PALETTEWE = (FF_PALETTE_IN == 1'b1) ? 1'b1 : 1'b0;
  assign W_EVEN_DOTSTATE = (DOTSTATE == 2'b00 || DOTSTATE == 2'b11) ? 1'b1 : 1'b0;
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_PALETTE_IN <= 1'b0;
    end else begin
      if ((W_EVEN_DOTSTATE == 1'b1)) begin
        FF_PALETTE_IN <= 1'b0;
      end else begin
        if ((FF_PALETTE_WR_REQ != FF_PALETTE_WR_ACK)) begin
          FF_PALETTE_IN <= 1'b1;
        end
      end
    end
  end

  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      FF_PALETTE_WR_ACK <= 1'b0;
    end else begin
      if ((W_EVEN_DOTSTATE == 1'b0)) begin
        if ((FF_PALETTE_WR_REQ != FF_PALETTE_WR_ACK)) begin
          FF_PALETTE_WR_ACK <= ~FF_PALETTE_WR_ACK;
        end
      end
    end
  end

  PALETTE_RB U_PALETTEMEMRB (
      .ADR(PALETTEADDR),
      .CLK(CLK21M),
      .WE (PALETTEWE),
      .DBO(PALETTEDATARB_IN),
      .DBI(PALETTEDATARB_OUT)
  );

  PALETTE_G U_PALETTEMEMG (
      .ADR(PALETTEADDR),
      .CLK(CLK21M),
      .WE (PALETTEWE),
      .DBO(PALETTEDATAG_IN),
      .DBI(PALETTEDATAG_OUT)
  );

  //------------------------------------------------------------------------
  // PROCESS OF CPU READ REQUEST
  //------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      DBI <= 8'd0;
    end else begin
      if ((REQ == 1'b1 && WRT == 1'b0)) begin
        // READ REQUEST
        case (mode[1:0])
          2'b00: begin  // PORT#0 (0x98): READ VRAM
            DBI <= VDPVRAMRDDATA;
          end
          2'b01: begin  // PORT#1 (0x99): READ STATUS REGISTER
            case (VDPR15STATUSREGNUM)
              4'b0000: begin  // READ S#0
                DBI <= {~REQ_VSYNC_INT_N, VDPS0SPOVERMAPPED, VDPS0SPCOLLISIONINCIDENCE, VDPS0SPOVERMAPPEDNUM};
              end
              4'b0001: begin  // READ S#1
                DBI <= {2'b00, `VDP_ID, ~REQ_HSYNC_INT_N};
              end
              4'b0010: begin  // READ S#2
                DBI <= {VDPCMDTR, VD, HD, VDPCMDBD, 2'b11, FIELD, VDPCMDCE};
              end
              4'b0011: begin  // READ S#3
                DBI <= VDPS3S4SPCOLLISIONX[7:0];
              end
              4'b0100: begin  // READ S#4
                DBI <= {7'b0000000, VDPS3S4SPCOLLISIONX[8]};
              end
              4'b0101: begin  // READ S#5
                DBI <= VDPS5S6SPCOLLISIONY[7:0];
              end
              4'b0110: begin  // READ S#6
                DBI <= {7'b0000000, VDPS5S6SPCOLLISIONY[8]};
              end
              4'b0111: begin  // READ S#7: THE COLOR REGISTER
                DBI <= VDPCMDCLR;
              end
              4'b1000: begin  // READ S#8: SXTMP LSB
                DBI <= VDPCMDSXTMP[7:0];
              end
              4'b1001: begin  // READ S#9: SXTMP MSB
                DBI <= {7'b1111111, VDPCMDSXTMP[8]};
              end
              default: begin
                DBI <= 8'd0;
              end
            endcase
          end
          default: begin
            // PORT#2, #3: NOT SUPPORTED IN READ MODE
            DBI <= {8{1'b1}};
          end
        endcase
      end
    end
  end

  //------------------------------------------------------------------------
  // HSYNC INTERRUPT RESET CONTROL
  //------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      CLR_HSYNC_INT <= 1'b0;
    end else begin
      if ((REQ == 1'b1 && WRT == 1'b0)) begin
        // CASE OF READ REQUEST
        if ((mode[1:0] == 2'b01 && VDPR15STATUSREGNUM == 4'b0001)) begin
          // CLEAR HSYNC INTERRUPT BY READ S#1
          CLR_HSYNC_INT <= 1'b1;
        end else begin
          CLR_HSYNC_INT <= 1'b0;
        end
      end else if ((VDPREGWRPULSE == 1'b1)) begin
        if ((VDPREGPTR == 6'b010011 || (VDPREGPTR == 6'b000000 && VDPP1DATA[4] == 1'b1))) begin
          // CLEAR HSYNC INTERRUPT BY WRITE R19, R0
          CLR_HSYNC_INT <= 1'b1;
        end else begin
          CLR_HSYNC_INT <= 1'b0;
        end
      end else begin
        CLR_HSYNC_INT <= 1'b0;
      end
    end
  end

  //------------------------------------------------------------------------
  // VSYNC INTERRUPT RESET CONTROL
  //------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      CLR_VSYNC_INT <= 1'b0;
    end else begin
      if ((REQ == 1'b1 && WRT == 1'b0)) begin
        // CASE OF READ REQUEST
        if ((mode[1:0] == 2'b01 && VDPR15STATUSREGNUM == 4'b0000)) begin
          // CLEAR VSYNC INTERRUPT BY READ S#0
          CLR_VSYNC_INT <= 1'b1;
        end else begin
          CLR_VSYNC_INT <= 1'b0;
        end
      end else begin
        CLR_VSYNC_INT <= 1'b0;
      end
    end
  end

  assign REG_R18_ADJ = {REG_R18_VERT, REG_R18_HORZ};
  //------------------------------------------------------------------------
  // PROCESS OF CPU WRITE REQUEST
  //------------------------------------------------------------------------
  always_ff @(posedge RESET or posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      VDPP1DATA <= 8'd0;
      VDPP1IS1STBYTE <= 1'b1;
      VDPP2IS1STBYTE <= 1'b1;
      VDPREGWRPULSE <= 1'b0;
      VDPREGPTR <= 6'd0;
      VDPVRAMWRREQ <= 1'b0;
      VDPVRAMRDREQ <= 1'b0;
      VDPVRAMADDRSETREQ <= 1'b0;
      VDPVRAMACCESSADDRTMP <= 17'd0;
      VDPVRAMACCESSDATA <= 8'd0;
      FF_R0_DISP_MODE <= 3'd0;
      REG_R0_HSYNC_INT_EN <= 1'b0;
      FF_R1_DISP_MODE <= 2'd0;
      REG_R1_SP_SIZE <= 1'b0;
      REG_R1_SP_ZOOM <= 1'b0;
      REG_R1_BL_CLKS <= 1'b0;
      REG_R1_VSYNC_INT_EN <= 1'b0;
      FF_R1_DISP_ON <= 1'b0;
      FF_R2_PT_NAM_ADDR <= {7{1'b0}};
      REG_R12_BLINK_MODE <= 8'd0;
      REG_R13_BLINK_PERIOD <= 8'd0;
      REG_R7_FRAME_COL <= 8'd0;
      REG_R8_SP_OFF <= 1'b0;
      REG_R8_COL0_ON <= 1'b0;
      REG_R9_PAL_MODE <= 1'b0;
      FF_R9_2PAGE_MODE <= 1'b0;
      REG_R9_INTERLACE_MODE <= 1'b0;
      REG_R9_Y_DOTS <= 1'b0;
      VDPR15STATUSREGNUM <= 4'd0;
      VDPR16PALNUM <= 0;
      VDPR17REGNUM <= 6'd0;
      VDPR17INCREGNUM <= 1'b0;
      REG_R18_VERT <= 4'd0;
      REG_R18_HORZ <= 4'd0;
      REG_R19_HSYNC_INT_LINE <= 8'd0;
      REG_R23_VSTART_LINE <= 8'd0;
      REG_R25_CMD <= 1'd0;
      REG_R25_YAE <= 1'd0;
      REG_R25_YJK <= 1'd0;
      REG_R25_MSK <= 1'd0;
      FF_R25_SP2 <= 1'd0;
      FF_R26_H_SCROLL <= 6'd0;
      REG_R27_H_SCROLL <= 3'd0;
      VDPCMDREGNUM <= 4'd0;
      VDPCMDREGDATA <= 8'd0;
      VDPCMDREGWRREQ <= 1'b0;
      VDPCMDTRCLRREQ <= 1'b0;

      // PALETTE
      PALETTEDATARB_IN <= 8'd0;
      PALETTEDATAG_IN <= 8'd0;
      FF_PALETTE_WR_REQ <= 1'b0;
      PALETTEWRNUM <= 4'd0;

      //extension
      FF_REG_R31 <= 0;
    end else begin
      if ((REQ == 1'b1 && WRT == 1'b0)) begin  // READ REQUEST
        case (mode[1:0])
          2'b00: begin  // PORT#0 (0x98): READ VRAM
            VDPVRAMRDREQ <= ~VDPVRAMRDACK;
          end
          2'b01: begin  // PORT#1 (0x99): READ STATUS REGISTER
            VDPP1IS1STBYTE <= 1'b1;
            case (VDPR15STATUSREGNUM)
              4'b0000: begin  // READ S#0
                FF_SPVDPS0RESETREQ <= ~SPVDPS0RESETACK;
              end
              4'b0001: begin  // READ S#1
              end
              4'b0101: begin  // READ S#5
                SPVDPS5RESETREQ <= ~SPVDPS5RESETACK;
              end
              4'b0111: begin  // READ S#7: THE COLOR REGISTER
                VDPCMDTRCLRREQ <= ~VDPCMDTRCLRACK;
              end
              default: begin
              end
            endcase
          end
          default: begin
            // PORT#3: NOT SUPPORTED IN READ MODE
          end
        endcase
      end else if ((REQ == 1'b1 && WRT == 1'b1)) begin  // WRITE REQUEST
        case (mode[1:0])
          2'b00: begin  // PORT#0 (0x98): WRITE VRAM
            VDPVRAMACCESSDATA <= DBO;
            VDPVRAMWRREQ <= ~VDPVRAMWRACK;
          end
          2'b01: begin  // PORT#1 (0x99): REGISTER WRITE OR VRAM ADDR SETUP
            if ((VDPP1IS1STBYTE == 1'b1)) begin
              // IT IS THE FIRST BYTE; BUFFER IT
              VDPP1IS1STBYTE <= 1'b0;
              VDPP1DATA <= DBO;
            end else begin
              // IT IS THE SECOND BYTE; PROCESS BOTH BYTES
              VDPP1IS1STBYTE <= 1'b1;
              case (DBO[7:6])
                2'b01: begin
                  // SET VRAM ACCESS ADDRESS(WRITE)
                  VDPVRAMACCESSADDRTMP[7:0] <= VDPP1DATA[7:0];
                  VDPVRAMACCESSADDRTMP[13:8] <= DBO[5:0];
                  VDPVRAMADDRSETREQ <= ~VDPVRAMADDRSETACK;
                end
                2'b00: begin
                  // SET VRAM ACCESS ADDRESS(READ)
                  VDPVRAMACCESSADDRTMP[7:0] <= VDPP1DATA[7:0];
                  VDPVRAMACCESSADDRTMP[13:8] <= DBO[5:0];
                  VDPVRAMADDRSETREQ <= ~VDPVRAMADDRSETACK;
                  VDPVRAMRDREQ <= ~VDPVRAMRDACK;
                end
                2'b10: begin
                  // DIRECT REGISTER SELECTION
                  VDPREGPTR <= DBO[5:0];
                  VDPREGWRPULSE <= 1'b1;
                end
                2'b11: begin
                  // DIRECT REGISTER SELECTION ??
                  VDPREGPTR <= DBO[5:0];
                  VDPREGWRPULSE <= 1'b1;
                end
                default: begin
                end
              endcase
            end
          end
          2'b10: begin  // PORT#2: PALETTE WRITE
            if ((VDPP2IS1STBYTE == 1'b1)) begin
              PALETTEDATARB_IN <= DBO;
              VDPP2IS1STBYTE   <= 1'b0;
            end else begin
              // パレットはrgbのデータが揃った時に一度に書き換える。
              // (実機で動作を確認した)
              // (The palette is rewritten all at once when the rgb data is ready. Confirmed operation on the actual machine)
              PALETTEDATAG_IN <= DBO;
              PALETTEWRNUM <= VDPR16PALNUM;
              FF_PALETTE_WR_REQ <= ~FF_PALETTE_WR_ACK;
              VDPP2IS1STBYTE <= 1'b1;
              VDPR16PALNUM <= 4'(VDPR16PALNUM + 1);
            end
          end
          2'b11: begin  // PORT#3: INDIRECT REGISTER WRITE
            if ((VDPR17REGNUM != 6'b010001)) begin
              // REGISTER 17 CAN NOT BE MODIFIED. ALL OTHERS ARE OK
              VDPREGWRPULSE <= 1'b1;
            end
            VDPP1DATA <= DBO;
            VDPREGPTR <= VDPR17REGNUM;
            if ((VDPR17INCREGNUM == 1'b1)) begin
              VDPR17REGNUM <= 6'(VDPR17REGNUM + 1);
            end
          end
          default: begin
          end
        endcase
      end else if ((VDPREGWRPULSE == 1'b1)) begin
        // WRITE TO REGISTER (IF PREVIOUSLY REQUESTED)
        VDPREGWRPULSE <= 1'b0;
        if ((VDPREGPTR[5] == 1'b0)) begin
          // IT IS A NOT A COMMAND ENGINE REGISTER:
          case (VDPREGPTR[4:0])
            5'b00000: begin  // #00
              FF_R0_DISP_MODE <= VDPP1DATA[3:1];
              REG_R0_HSYNC_INT_EN <= VDPP1DATA[4];
            end
            5'b00001: begin  // #01
              REG_R1_SP_ZOOM <= VDPP1DATA[0];
              REG_R1_SP_SIZE <= VDPP1DATA[1];
              REG_R1_BL_CLKS <= VDPP1DATA[2];
              FF_R1_DISP_MODE <= VDPP1DATA[4:3];
              REG_R1_VSYNC_INT_EN <= VDPP1DATA[5];
              FF_R1_DISP_ON <= VDPP1DATA[6];
            end
            5'b00010: begin  // #02
              FF_R2_PT_NAM_ADDR <= VDPP1DATA[6:0];
            end
            5'b00011: begin  // #03
              REG_R10R3_COL_ADDR[7:0] <= VDPP1DATA[7:0];
            end
            5'b00100: begin  // #04
              REG_R4_PT_GEN_ADDR <= VDPP1DATA[5:0];
            end
            5'b00101: begin  // #05
              REG_R11R5_SP_ATR_ADDR[7:0] <= VDPP1DATA;
            end
            5'b00110: begin  // #06
              REG_R6_SP_GEN_ADDR <= VDPP1DATA[5:0];
            end
            5'b00111: begin  // #07
              REG_R7_FRAME_COL <= VDPP1DATA[7:0];
            end
            5'b01000: begin  // #08
              REG_R8_SP_OFF  <= VDPP1DATA[1];
              REG_R8_COL0_ON <= VDPP1DATA[5];
            end
            5'b01001: begin  // #09
              REG_R9_PAL_MODE <= VDPP1DATA[1];
              FF_R9_2PAGE_MODE <= VDPP1DATA[2];
              REG_R9_INTERLACE_MODE <= VDPP1DATA[3];
              REG_R9_Y_DOTS <= VDPP1DATA[7];
            end
            5'b01010: begin  // #10
              REG_R10R3_COL_ADDR[10:8] <= VDPP1DATA[2:0];
            end
            5'b01011: begin  // #11
              REG_R11R5_SP_ATR_ADDR[9:8] <= VDPP1DATA[1:0];
            end
            5'b01100: begin  // #12
              REG_R12_BLINK_MODE <= VDPP1DATA;
            end
            5'b01101: begin  // #13
              REG_R13_BLINK_PERIOD <= VDPP1DATA;
            end
            5'b01110: begin  // #14
              VDPVRAMACCESSADDRTMP[16:14] <= VDPP1DATA[2:0];
              VDPVRAMADDRSETREQ <= ~VDPVRAMADDRSETACK;
            end
            5'b01111: begin  // #15
              VDPR15STATUSREGNUM <= VDPP1DATA[3:0];
            end
            5'b10000: begin  // #16
              VDPR16PALNUM   <= VDPP1DATA[3:0];
              VDPP2IS1STBYTE <= 1'b1;
            end
            5'b10001: begin  // #17
              VDPR17REGNUM <= VDPP1DATA[5:0];
              VDPR17INCREGNUM <= ~VDPP1DATA[7];
            end
            5'b10010: begin  // #18
              REG_R18_VERT <= VDPP1DATA[7:4];
              REG_R18_HORZ <= VDPP1DATA[3:0];
            end
            5'b10011: begin  // #19
              REG_R19_HSYNC_INT_LINE <= VDPP1DATA;
            end
            5'b10111: begin  // #23
              REG_R23_VSTART_LINE <= VDPP1DATA;
            end
            5'b11001: begin  // #25
              REG_R25_CMD <= VDPP1DATA[6];
              REG_R25_YAE <= VDPP1DATA[4];
              REG_R25_YJK <= VDPP1DATA[3];
              REG_R25_MSK <= VDPP1DATA[1];
              FF_R25_SP2  <= VDPP1DATA[0];
            end
            5'b11010: begin  // #26
              FF_R26_H_SCROLL <= VDPP1DATA[5:0];
            end
            5'b11011: begin  // #27
              REG_R27_H_SCROLL <= VDPP1DATA[2:0];
            end

            5'b11111: begin  //#31 - special!
              FF_REG_R31 <= VDPP1DATA;
            end
          endcase
        end else if ((VDPREGPTR[4] == 1'b0)) begin
          // REGISTERS FOR VDP COMMAND
          VDPCMDREGNUM   <= VDPREGPTR[3:0];
          VDPCMDREGDATA  <= VDPP1DATA;
          VDPCMDREGWRREQ <= ~VDPCMDREGWRACK;
        end
      end
    end
  end

endmodule
