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
    output reg [18:0] VDPVRAMACCESSADDRTMP,
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
    input bit [7:0] PALETTE_ADDR_OUT,
    output wire [7:0] PALETTE_DATA_R_OUT,
    output wire [7:0] PALETTE_DATA_B_OUT,
    output wire [7:0] PALETTE_DATA_G_OUT,
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
    output wire SPMODE2

`ifdef ENABLE_SUPER_RES
    ,
    output bit vdp_super,
    output bit super_mid,
    output bit super_res,

    input bit [7:0] PALETTE_ADDR2,
    output bit[7:0] PALETTE_DATA_R2_OUT,
    output bit[7:0] PALETTE_DATA_G2_OUT,
    output bit[7:0] PALETTE_DATA_B2_OUT,

    output bit[9:0] ext_reg_bus_arb_start_x,
    output bit[9:0] ext_reg_bus_arb_50hz_end_x,
    output bit[9:0] ext_reg_bus_arb_50hz_start_y,
    output bit[9:0] ext_reg_bus_arb_50hz_end_y, //not used
    output bit[9:0] ext_reg_bus_arb_60hz_end_x,
    output bit[9:0] ext_reg_bus_arb_60hz_start_y,
    output bit[9:0] ext_reg_bus_arb_60hz_end_y, //not used

    output bit[9:0] ext_reg_view_port_start_x,
    output bit[9:0] ext_reg_view_port_end_x,
    output bit[9:0] ext_reg_view_port_start_y,
    output bit[9:0] ext_reg_view_port_end_y,

    output bit[9:0] view_port_width

`endif
);

    import custom_timings::*;

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

  // IN STANDARD MODE, 1 -> LOAD RED/BLUE BYTE, 0 -> LOAD GREEN BYTE
  // IN EXTENDED MODE, 1 -> LOAD RED, 2 -> LOAD GREEN, 0 -> LOAD BLUE
  bit[1:0] VDP_PALETTE_LOADING_STATE;

  wire [7:0] VDPP0DATA;
  reg [7:0] VDPP1DATA;
  reg [5:0] VDPREGPTR;
  reg VDPREGWRPULSE;
  reg [3:0] VDPR15STATUSREGNUM;
  wire VSYNCINTACK;
  wire HSYNCINTACK;
  reg [7:0] VDP_R16_PAL_NUM;
  reg [5:0] VDPR17REGNUM;
  reg VDPR17INCREGNUM;
  bit [7:0] PALETTE_ADDR;
  wire PALETTEWE;
  reg [7:0] PALETTE_DATA_R_IN;
  reg [7:0] PALETTE_DATA_B_IN;
  reg [7:0] PALETTE_DATA_G_IN;
  reg [7:0] PALETTE_WR_NUM;
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

`ifdef ENABLE_SUPER_RES
  bit [7:0] FF_REG_R31;

  bit [7:0] extended_reg_index;
  bit [7:0] extended_super_regs[64];
  bit [9:0] _ext_reg_view_port_start_x;
  bit [9:0] _ext_reg_view_port_end_x;
  bit [9:0] _ext_reg_view_port_start_y;
  bit [9:0] _ext_reg_view_port_end_y;

  assign ext_reg_bus_arb_50hz_end_x = {extended_super_regs[3][1:0], extended_super_regs[2]};
  assign ext_reg_bus_arb_50hz_start_y = {extended_super_regs[5][1:0], extended_super_regs[4]};
  assign ext_reg_bus_arb_50hz_end_y = {extended_super_regs[7][1:0], extended_super_regs[6]};//not used
  assign _ext_reg_view_port_start_x = {extended_super_regs[9][1:0], extended_super_regs[8]};
  assign _ext_reg_view_port_end_x = {extended_super_regs[11][1:0], extended_super_regs[10]};
  assign _ext_reg_view_port_start_y = {extended_super_regs[13][1:0], extended_super_regs[12]};
  assign _ext_reg_view_port_end_y = {extended_super_regs[15][1:0], extended_super_regs[14]};

  assign ext_reg_bus_arb_60hz_end_x = {extended_super_regs[23][1:0], extended_super_regs[22]};
  assign ext_reg_bus_arb_60hz_start_y = {extended_super_regs[25][1:0], extended_super_regs[24]};
  assign ext_reg_bus_arb_60hz_end_y = {extended_super_regs[27][1:0], extended_super_regs[26]}; //not used

  bit mode_graphic_7_base;
  bit mode_graphic_super_base;
  bit mode_extended_palette;

  assign mode_graphic_7_base = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b11100);
  assign mode_extended_palette = FF_REG_R31[3];  //if true, then we are in extended palette mode
`endif

  assign ACK = FF_ACK;
  assign SPVDPS0RESETREQ = FF_SPVDPS0RESETREQ;

`ifdef ENABLE_SUPER_RES
  assign super_mid = FF_REG_R31[2:1] == 1;  // 1 byte per pixel into palette lookup 50Hz:360x288 (103680 Bytes), 60Hz:360x240 (86400 bytes)
  assign super_res = FF_REG_R31[2:1] == 2;  // 1 byte per pixel into palette lookup 50Hz:720x576 (414720 Bytes), 60Hz:720x480 (345600 bytes)
  assign mode_graphic_super_base = super_mid || super_res;  //if true, and mode_Graphic_7_base is true, then we are in super graphic mode
  assign vdp_super = mode_graphic_super_base & mode_graphic_7_base;
`endif

  assign VDPMODEGRAPHIC1 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00000);
  assign VDPMODETEXT1 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00001);
  assign VDPMODEMULTI = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00010);
  assign VDPMODEGRAPHIC2 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00100);
  assign VDPMODETEXT1Q = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00101);
  assign VDPMODEMULTIQ = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b00110);
  assign VDPMODEGRAPHIC3 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b01000);
  assign VDPMODETEXT2 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b01001);
  assign VDPMODEGRAPHIC4 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b01100);
  assign VDPMODEGRAPHIC5 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b10000);
  assign VDPMODEGRAPHIC6 = (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b10100);
`ifdef ENABLE_SUPER_RES
  assign VDPMODEGRAPHIC7 = !mode_graphic_super_base && mode_graphic_7_base;
`else
  assign VDPMODEGRAPHIC7 =  (({REG_R0_DISP_MODE, REG_R1_DISP_MODE[0], REG_R1_DISP_MODE[1]}) == 5'b11100);
`endif
  assign VDPMODEISHIGHRES = (REG_R0_DISP_MODE[3:2] == 2'b10 && REG_R1_DISP_MODE == 2'b00);
  assign SPMODE2 = (REG_R1_DISP_MODE == 2'b00 && (REG_R0_DISP_MODE[3] | REG_R0_DISP_MODE[2]) == 1'b1);

  //--------------------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_ACK <= 1'b0;
    end else begin
      FF_ACK <= REQ;
    end
  end

  //--------------------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
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
  assign PALETTE_ADDR = FF_PALETTE_IN ? PALETTE_WR_NUM : PALETTE_ADDR_OUT;
  assign PALETTEWE = FF_PALETTE_IN;
  assign W_EVEN_DOTSTATE = (DOTSTATE == 2'b00 || DOTSTATE == 2'b11);
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_PALETTE_IN <= 0;
    end else begin
      if (W_EVEN_DOTSTATE) begin
        FF_PALETTE_IN <= 0;
      end else begin
        if (FF_PALETTE_WR_REQ != FF_PALETTE_WR_ACK) begin
          FF_PALETTE_IN <= 1;
        end
      end
    end
  end

  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      FF_PALETTE_WR_ACK <= 0;
    end else begin
      if (!W_EVEN_DOTSTATE) begin
        if (FF_PALETTE_WR_REQ != FF_PALETTE_WR_ACK) begin
          FF_PALETTE_WR_ACK <= ~FF_PALETTE_WR_ACK;
        end
      end
    end
  end

    PALETTE #(
      .INIT_VALUES({8'h01, 8'h00, 8'h20, 8'h60, 8'h40, 8'h60, 8'hA0, 8'h40, 8'hC0, 8'hC0, 8'hA0, 8'hC0, 8'h20, 8'hA0, 8'hA0, 8'hE0})
  ) U_PALETTE_MEM_R (
      .ADR(PALETTE_ADDR),
      .CLK(CLK21M),
      .WE (PALETTEWE),
      .DBO(PALETTE_DATA_R_IN),
      .DBI(PALETTE_DATA_R_OUT)
`ifdef ENABLE_SUPER_RES
      ,
      .ADR2(PALETTE_ADDR2),
      .DBI2(PALETTE_DATA_R2_OUT)
`endif
  );

  PALETTE #(
      .INIT_VALUES({8'h00, 8'h00, 8'h60, 8'h86, 8'h20, 8'h40, 8'h20, 8'hA0, 8'h20, 8'h40, 8'h80, 8'hA0, 8'h60, 8'h20, 8'h80, 8'hC0})
  ) U_PALETTE_MEM_G (
      .ADR(PALETTE_ADDR),
      .CLK(CLK21M),
      .WE (PALETTEWE),
      .DBO(PALETTE_DATA_G_IN),
      .DBI(PALETTE_DATA_G_OUT)
`ifdef ENABLE_SUPER_RES
      ,
      .ADR2(PALETTE_ADDR2),
      .DBI2(PALETTE_DATA_G2_OUT)
`endif
  );

    PALETTE #(
      .INIT_VALUES({8'h00, 8'h00, 8'h20, 8'h60, 8'hC0, 8'hE0, 8'h40, 8'hE0, 8'h40, 8'h60, 8'h40, 8'h60, 8'h20, 8'hA0, 8'hA0, 8'hE0})
  ) U_PALETTE_MEM_B (
      .ADR(PALETTE_ADDR),
      .CLK(CLK21M),
      .WE (PALETTEWE),
      .DBO(PALETTE_DATA_B_IN),
      .DBI(PALETTE_DATA_B_OUT)
`ifdef ENABLE_SUPER_RES
      ,
      .ADR2(PALETTE_ADDR2),
      .DBI2(PALETTE_DATA_B2_OUT)
`endif
  );

  //------------------------------------------------------------------------
  // PROCESS OF CPU READ REQUEST
  //------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
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

              4'b1101: begin  //READ S#13
                DBI <= 0;
              end
              default: begin
                DBI <= 8'd255;
              end
            endcase
          end

`ifdef ENABLE_SUPER_RES
          2'b10: begin  // PORT#2: 9A NOT SUPPORTED IN READ MODE
            DBI <= {4'b0, VDPREGPTR[4:0]};
          end
          2'b11: begin  // PORT#3: 9B NOT SUPPORTED IN READ MODE
            case (VDPR17REGNUM)
              6'b011110: begin  // #30
                DBI <= 0;
              end
              6'b011111: begin  // #31
                DBI <= FF_REG_R31;
              end
              default: begin
                DBI <= 255;
              end
            endcase
          end
`else
          default: begin
            DBI <= 255;
          end
`endif

        endcase
      end
    end
  end

  //------------------------------------------------------------------------
  // HSYNC INTERRUPT RESET CONTROL
  //------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
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
    if (RESET) begin
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
    if (RESET) begin
      VDPP1DATA <= 8'd0;
      VDPP1IS1STBYTE <= 1'b1;
      VDP_PALETTE_LOADING_STATE <= 1;
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
      VDP_R16_PAL_NUM <= 0;
      VDPR17REGNUM <= 6'd0;
      VDPR17INCREGNUM <= 1'b0;
      REG_R18_VERT <= 4'd0;
      REG_R18_HORZ <= 4'd0;
      REG_R19_HSYNC_INT_LINE <= 8'd0;
      REG_R23_VSTART_LINE <= 8'd0;
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
      PALETTE_DATA_R_IN <= 7'd0;
      PALETTE_DATA_B_IN <= 7'd0;
      PALETTE_DATA_G_IN <= 7'd0;
      FF_PALETTE_WR_REQ <= 1'b0;
      PALETTE_WR_NUM <= 8'd0;

`ifdef ENABLE_SUPER_RES
      FF_REG_R31 <= 0;
      extended_reg_index <= 0;
      extended_super_regs[0] <= 8'h5B; // BUS_ARB_50HZ_START_X     Low  byte 859 (0x35B)
      extended_super_regs[1] <= 8'h03; // BUS_ARB_50HZ_START_X     High byte 859 (0x35B)
      extended_super_regs[2] <= 8'hD0; // BUS_ARB_50HZ_END_X       Low  byte 720 (0x2D0)
      extended_super_regs[3] <= 8'h02; // BUS_ARB_50HZ_END_X       High byte 720 (0x2D0)
      extended_super_regs[4] <= 8'h6C; // BUS_ARB_50HZ_START_Y     Low  byte 620 (0x26C)
      extended_super_regs[5] <= 8'h02; // BUS_ARB_50HZ_START_Y     High byte 620 (0x26C)
      extended_super_regs[6] <= 8'h40; // BUS_ARB_50HZ_END_Y       Low  byte 576 (0x240)
      extended_super_regs[7] <= 8'h02; // BUS_ARB_50HZ_END_Y       High byte 576 (0x240)
      extended_super_regs[8] <= 8'h00; // VIEW_PORT__START_X       Low  byte   0 (0x000)
      extended_super_regs[9] <= 8'h00; // VIEW_PORT__START_X       High byte   0 (0x000)
      extended_super_regs[10] <= 8'hD0; // VIEW_PORT_END_X         Low  byte 720 (0x2D0)
      extended_super_regs[11] <= 8'h02; // VIEW_PORT_END_X         High byte 720 (0x2D0)
      extended_super_regs[12] <= 8'h00; // VIEW_PORT_START_Y       Low  byte   0 (0x000)
      extended_super_regs[13] <= 8'h00; // VIEW_PORT_START_Y       High byte   0 (0x000)
      extended_super_regs[14] <= 8'hFF; // VIEW_PORT_END_Y         Low  byte  -1 (0xFFF)
      extended_super_regs[15] <= 8'hFF; // VIEW_PORT_END_Y         High byte  -1 (0xFFF)

      extended_super_regs[20] <= 8'h55; // BUS_ARB_60HZ_START_X    Low  byte 853 (0x355)
      extended_super_regs[21] <= 8'h03; // BUS_ARB_60HZ_START_X    High byte 853 (0x355)
      extended_super_regs[22] <= 8'hD0; // BUS_ARB_60HZ_END_X      Low  byte 720 (0x2D0)
      extended_super_regs[23] <= 8'h02; // BUS_ARB_60HZ_END_X      High byte 720 (0x2D0)
      extended_super_regs[24] <= 8'h08; // BUS_ARB_60HZ_START_Y    Low  byte 520 (0x208)
      extended_super_regs[25] <= 8'h02; // BUS_ARB_60HZ_START_Y    High byte 520 (0x208)
      extended_super_regs[26] <= 8'hE0; // BUS_ARB_60HZ_END_Y      Low  byte 480 (0x1E0)
      extended_super_regs[27] <= 8'h01; // BUS_ARB_60HZ_END_Y      High byte 480 (0x1E0)

`endif
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

  // if mode_extended_palette, then we expect 3 bytes, one for each R, G, B

            if (mode_extended_palette) begin
              if (VDP_PALETTE_LOADING_STATE == 1) begin
                PALETTE_DATA_R_IN <= DBO;
                VDP_PALETTE_LOADING_STATE <= 2;
              end else begin
                if (VDP_PALETTE_LOADING_STATE == 2) begin
                  PALETTE_DATA_G_IN <= DBO;
                  VDP_PALETTE_LOADING_STATE <= 3;
                end else begin
                  // PALETTE_EXTENDED_BLUE_IN <= DBO;
                  PALETTE_DATA_B_IN <= DBO;
                  PALETTE_WR_NUM <= VDP_R16_PAL_NUM;
                  FF_PALETTE_WR_REQ <= ~FF_PALETTE_WR_ACK;
                  VDP_PALETTE_LOADING_STATE <= 1;
                  VDP_R16_PAL_NUM <= 8'(VDP_R16_PAL_NUM + 1);
                end
              end

            end else begin
              if (VDP_PALETTE_LOADING_STATE == 1) begin
                PALETTE_DATA_R_IN <= {DBO[6:4], 5'b0};
                PALETTE_DATA_B_IN <= {DBO[2:0], 5'b0};
                VDP_PALETTE_LOADING_STATE   <= 0;
              end else begin
                PALETTE_DATA_G_IN <= {DBO[2:0], 5'b0};
                PALETTE_WR_NUM <= VDP_R16_PAL_NUM;
                FF_PALETTE_WR_REQ <= ~FF_PALETTE_WR_ACK;
                VDP_PALETTE_LOADING_STATE <= 1;
                VDP_R16_PAL_NUM <= 8'(VDP_R16_PAL_NUM + 1);
              end
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
`ifdef ENABLE_SUPER_RES
              if (vdp_super) begin
                VDPVRAMACCESSADDRTMP[18:14] <= VDPP1DATA[4:0];
              end else begin
                VDPVRAMACCESSADDRTMP[16:14] <= VDPP1DATA[2:0];
              end
`else
              VDPVRAMACCESSADDRTMP[16:14] <= VDPP1DATA[2:0];
`endif
              VDPVRAMADDRSETREQ <= ~VDPVRAMADDRSETACK;
            end
            5'b01111: begin  // #15
              VDPR15STATUSREGNUM <= VDPP1DATA[3:0];
            end
            5'b10000: begin  // #16
`ifdef ENABLE_SUPER_RES
              VDP_R16_PAL_NUM <= VDPP1DATA[7:0];
`else
              VDP_R16_PAL_NUM <= VDPP1DATA[3:0];
`endif
              VDP_PALETTE_LOADING_STATE <= 1;
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
              // REG_R25_CMD <= VDPP1DATA[6];
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

`ifdef ENABLE_SUPER_RES
            5'b11101: begin  // #29
              extended_reg_index  <= VDPP1DATA;
            end

            5'b11110: begin  //#30
              if (extended_reg_index[7:6] == 0)
                extended_super_regs[extended_reg_index[5:0]] <= VDPP1DATA;
              else
              if (extended_reg_index == 8'd255) begin
                // command register

                if (VDPP1DATA[0]) begin //reset 50HZ mode
                  extended_super_regs[0] <= 8'h5B; // BUS_ARB_50HZ_START_X     Low  byte 859 (0x35B)
                  extended_super_regs[1] <= 8'h03; // BUS_ARB_50HZ_START_X     High byte 859 (0x35B)
                  extended_super_regs[2] <= 8'hD0; // BUS_ARB_50HZ_END_X       Low  byte 720 (0x2D0)
                  extended_super_regs[3] <= 8'h02; // BUS_ARB_50HZ_END_X       High byte 720 (0x2D0)
                  extended_super_regs[4] <= 8'h6C; // BUS_ARB_50HZ_START_Y     Low  byte 620 (0x26C)
                  extended_super_regs[5] <= 8'h02; // BUS_ARB_50HZ_START_Y     High byte 620 (0x26C)
                  extended_super_regs[6] <= 8'h40; // BUS_ARB_50HZ_END_Y       Low  byte 576 (0x240)
                  extended_super_regs[7] <= 8'h02; // BUS_ARB_50HZ_END_Y       High byte 576 (0x240)
                  extended_super_regs[8] <= 8'h00;  // VIEW_PORT_START_X       Low  byte   0 (0x000)
                  extended_super_regs[9] <= 8'h00;  // VIEW_PORT_START_X       High byte   0 (0x000)
                  extended_super_regs[10] <= 8'hD0; // VIEW_PORT_END_X         Low  byte 720 (0x2D0)
                  extended_super_regs[11] <= 8'h02; // VIEW_PORT_END_X         High byte 720 (0x2D0)
                  extended_super_regs[12] <= 8'h00; // VIEW_PORT_START_Y       Low  byte   0 (0x000)
                  extended_super_regs[13] <= 8'h00; // VIEW_PORT_START_Y       High byte   0 (0x000)
                  extended_super_regs[14] <= 8'hFF; // VIEW_PORT_END_Y         Low  byte  -1 (0xFFF)
                  extended_super_regs[15] <= 8'hFF; // VIEW_PORT_END_Y         High byte  -1 (0xFFF)
                end

                if (VDPP1DATA[1]) begin //reset 60HZ mode
                  extended_super_regs[20] <= 8'h55; // BUS_ARB_60HZ_START_X    Low  byte 853 (0x355)
                  extended_super_regs[21] <= 8'h03; // BUS_ARB_60HZ_START_X    High byte 853 (0x355)
                  extended_super_regs[22] <= 8'hD0; // BUS_ARB_60HZ_END_X      Low  byte 720 (0x2D0)
                  extended_super_regs[23] <= 8'h02; // BUS_ARB_60HZ_END_X      High byte 720 (0x2D0)
                  extended_super_regs[24] <= 8'h08; // BUS_ARB_60HZ_START_Y    Low  byte 520 (0x208)
                  extended_super_regs[25] <= 8'h02; // BUS_ARB_60HZ_START_Y    High byte 520 (0x208)
                  extended_super_regs[26] <= 8'hE0; // BUS_ARB_60HZ_END_Y      Low  byte 480 (0x1E0)
                  extended_super_regs[27] <= 8'h01; // BUS_ARB_60HZ_END_Y      High byte 480 (0x1E0)
                end
              end

              extended_reg_index = 8'(extended_reg_index + 1);
            end

            5'b11111: begin  //#31 - special! - super res modes
              FF_REG_R31 <= VDPP1DATA;
            end
`endif
//do we need an `else` here?

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

`ifdef ENABLE_SUPER_RES
  bit [9:0] _view_port_width;
  bit prev_REG_R9_PAL_MODE;
  bit [7:0] prev_extended_reg_index;
  bit [9:0] frame_width_minus_one;
  bit [9:0] view_port_start_x_minus_one;
  bit [7:0] prev_FF_REG_R31;
  bit [9:0] frame_height_minus_one;
  bit [9:0] pixel_height_minus_one;
  bit [9:0] view_port_start_y_minus_one;
  bit [9:0] view_port_end_y_minus_one;
  bit view_port_start_y_wrap;
  bit view_port_end_y_wrap;
  bit [9:0] arb_start_minus_5_wrapped;
  bit [9:0] view_port_start_x_minus_5;
  bit arb_start_has_wrapped;

  //--------------------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if (RESET) begin
      view_port_width <= 0;
      ext_reg_view_port_start_x <= 0;
      ext_reg_view_port_end_x <= 0;
      frame_height_minus_one <= 0;
      view_port_start_y_minus_one <= 0;
      view_port_start_y_wrap <= 1;
      view_port_end_y_wrap <= 1;

    end else begin
      // STAGE 0
      _view_port_width <= (_ext_reg_view_port_end_x - _ext_reg_view_port_start_x);

      frame_width_minus_one <= FRAME_WIDTH(REG_R9_PAL_MODE) - 1;
      frame_height_minus_one <= FRAME_HEIGHT(REG_R9_PAL_MODE) - 1;
      pixel_height_minus_one <= PIXEL_HEIGHT(REG_R9_PAL_MODE) - 1;

      view_port_start_x_minus_one <= 10'(_ext_reg_view_port_start_x - 10'd1);
      view_port_start_y_minus_one <= 10'(_ext_reg_view_port_start_y - 10'd1);
      view_port_end_y_minus_one <= 10'(_ext_reg_view_port_end_y - 10'd1);

      view_port_start_y_wrap <= _ext_reg_view_port_start_y == 10'd0;
      view_port_end_y_wrap <= _ext_reg_view_port_end_y == 10'b1111111111;

    // STAGE 1
      arb_start_minus_5_wrapped <= frame_width_minus_one - (10'd5 - _ext_reg_view_port_start_x);

      view_port_start_x_minus_5 <= _ext_reg_view_port_start_x - 10'd6;
      arb_start_has_wrapped <= (_ext_reg_view_port_start_x < 10'd6) ;

    // STAGE 3
      if (super_mid)
        view_port_width <= {1'b0, _view_port_width[9:1]};
      else
        view_port_width <= _view_port_width;

      ext_reg_view_port_start_x <= _ext_reg_view_port_start_x == 0 ? frame_width_minus_one : view_port_start_x_minus_one;
      ext_reg_view_port_end_x <= 10'(_ext_reg_view_port_end_x - 10'd1);

      ext_reg_view_port_start_y <= view_port_start_y_wrap ? frame_height_minus_one : view_port_start_y_minus_one;;
      ext_reg_view_port_end_y <= view_port_end_y_wrap ? pixel_height_minus_one : view_port_end_y_minus_one;;

      ext_reg_bus_arb_start_x <= arb_start_has_wrapped ? arb_start_minus_5_wrapped : view_port_start_x_minus_5;
    end
  end

`endif

endmodule
