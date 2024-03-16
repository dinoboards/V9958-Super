//  converted from vdp.vhd
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
//  The module to emulate the V9958 VDP
//

`include "vdp_constants.vh"

module VDP (
    input wire CLK21M,
    input wire RESET,
    input wire REQ,
    output wire ACK,
    input wire WRT,
    input wire [1:0] mode,
    output wire [7:0] DBI,
    input wire [7:0] DBO,
    output wire INT_N,
    output reg PRAMWE_N,
    output wire [16:0] PRAMADR,
    input wire [15:0] PRAMDBI,
    output reg [7:0] PRAMDBO,
    input wire VDPSPEEDMODE,
    output wire [5:0] PVIDEOR,
    output wire [5:0] PVIDEOG,
    output wire [5:0] PVIDEOB,
    output wire PVIDEODHCLK,
    output wire PVIDEODLCLK,
    output wire PAL_MODE,
    input wire SPMAXSPR,
    input wire [10:0] CX,
    input wire [9:0] CY,

    output bit super_high_res,  //true when running super high res HDMI/DVI native resolutions
    output bit [7:0] REG_R31
);

  import custom_timings::*;

  // DISPLAY POSITIONS, ADAPTED FOR ADJUST(X,Y)
  wire [ 6:0] ADJUST_X;

  // DOT STATE REGISTER
  wire [ 1:0] DOTSTATE;
  wire [ 2:0] EIGHTDOTSTATE;

  // DISPLAY FIELD SIGNAL
  wire        FIELD;
  wire        HD;
  wire        VD;
  reg         ACTIVE_LINE;
  wire        V_BLANKING_START;

  // FOR VSYNC INTERRUPT
  wire        VSYNCINT_N;
  wire        CLR_VSYNC_INT;
  wire        REQ_VSYNC_INT_N;

  // FOR HSYNC INTERRUPT
  wire        HSYNCINT_N;
  wire        CLR_HSYNC_INT;
  wire        REQ_HSYNC_INT_N;
  wire        DVIDEOHS_N;

  // DISPLAY AREA FLAGS
  wire        WINDOW;
  wire        WINDOW_X;
  reg         PREWINDOW_X;
  wire        PREWINDOW_Y;
  wire        PREWINDOW_Y_SP;
  wire        PREWINDOW;
  wire        PREWINDOW_SP;

  // FOR FRAME ZONE
  reg         BWINDOW_Y;

  // DOT COUNTER - 8 ( READING ADDR )
  wire [ 8:0] PREDOTCOUNTER_X;
  wire [ 8:0] PREDOTCOUNTER_Y;

  // Y COUNTERS INDEPENDENT OF VERTICAL SCROLL REGISTER
  wire [ 8:0] PREDOTCOUNTER_YP;

  // VDP REGISTER ACCESS
  reg  [16:0] VDPVRAMACCESSADDR;
  reg         VDPVRAMREADINGR;
  reg         VDPVRAMREADINGA;
  wire [ 3:1] VDPR0DISPNUM;
  wire [ 7:0] VDPVRAMACCESSDATA;
  wire [16:0] VDPVRAMACCESSADDRTMP;
  wire        VDPVRAMADDRSETREQ;
  reg         VDPVRAMADDRSETACK;
  wire        VDPVRAMWRREQ;
  reg         VDPVRAMWRACK;
  reg  [ 7:0] VDPVRAMRDDATA;
  wire        VDPVRAMRDREQ;
  reg         VDPVRAMRDACK;
  wire        VDPR9PALMODE;

  wire        REG_R0_HSYNC_INT_EN;
  wire        REG_R1_SP_SIZE;
  wire        REG_R1_SP_ZOOM;
  wire        REG_R1_BL_CLKS;
  wire        REG_R1_VSYNC_INT_EN;
  wire        REG_R1_DISP_ON;
  wire [ 6:0] REG_R2_PT_NAM_ADDR;
  wire [ 5:0] REG_R4_PT_GEN_ADDR;
  wire [10:0] REG_R10R3_COL_ADDR;
  wire [ 9:0] REG_R11R5_SP_ATR_ADDR;
  wire [ 5:0] REG_R6_SP_GEN_ADDR;
  wire [ 7:0] REG_R7_FRAME_COL;
  wire        REG_R8_SP_OFF;
  wire        REG_R8_COL0_ON;
  wire        REG_R9_PAL_MODE;
  wire        REG_R9_INTERLACE_MODE;
  wire        REG_R9_Y_DOTS;
  wire [ 7:0] REG_R12_BLINK_MODE;
  wire [ 7:0] REG_R13_BLINK_PERIOD;
  wire [ 7:0] REG_R18_ADJ;
  wire [ 7:0] REG_R19_HSYNC_INT_LINE;
  wire [ 7:0] REG_R23_VSTART_LINE;
  wire        REG_R25_CMD;
  wire        REG_R25_YAE;
  wire        REG_R25_YJK;
  wire        REG_R25_MSK;
  wire        REG_R25_SP2;
  wire [ 8:3] REG_R26_H_SCROLL;
  wire [ 2:0] REG_R27_H_SCROLL;

  wire        TEXT_MODE;  // TEXT MODE 1, 2 or 1Q
  wire        VDPMODETEXT1;  // TEXT MODE 1      (SCREEN0 WIDTH 40)
  wire        VDPMODETEXT1Q;  // TEXT MODE 1      (??)
  wire        VDPMODETEXT2;  // TEXT MODE 2      (SCREEN0 WIDTH 80)
  wire        VDPMODEMULTI;  // MULTICOLOR MODE  (SCREEN3)
  wire        VDPMODEMULTIQ;  // MULTICOLOR MODE  (??)
  wire        VDPMODEGRAPHIC1;  // GRAPHIC MODE 1   (SCREEN1)
  wire        VDPMODEGRAPHIC2;  // GRAPHIC MODE 2   (SCREEN2)
  wire        VDPMODEGRAPHIC3;  // GRAPHIC MODE 2   (SCREEN4)
  wire        VDPMODEGRAPHIC4;  // GRAPHIC MODE 4   (SCREEN5)
  wire        VDPMODEGRAPHIC5;  // GRAPHIC MODE 5   (SCREEN6)
  wire        VDPMODEGRAPHIC6;  // GRAPHIC MODE 6   (SCREEN7)
  wire        VDPMODEGRAPHIC7;  // GRAPHIC MODE 7   (SCREEN8,10,11,12)
  wire        VDPMODEISHIGHRES;  // TRUE WHEN MODE GRAPHIC5, 6

  // FOR TEXT 1 AND 2
  wire [16:0] PRAMADRT12;
  wire [ 3:0] COLORCODET12;
  wire        TXVRAMREADEN;

  // FOR GRAPHIC 1,2,3 AND MULTI COLOR
  wire [16:0] PRAMADRG123M;
  wire [ 3:0] COLORCODEG123M;

  // FOR GRAPHIC 4,5,6,7
  wire [16:0] PRAMADRG4567;
  wire [ 7:0] COLORCODEG4567;
  wire [ 5:0] YJK_R;
  wire [ 5:0] YJK_G;
  wire [ 5:0] YJK_B;
  wire        YJK_EN;

  // SPRITE
  wire        SPMODE2;
  wire        SPVRAMACCESSING;
  wire [16:0] PRAMADRSPRITE;
  wire        SPRITECOLOROUT;
  wire [ 3:0] COLORCODESPRITE;
  wire        VDPS0SPCOLLISIONINCIDENCE;
  wire        VDPS0SPOVERMAPPED;
  wire [ 4:0] VDPS0SPOVERMAPPEDNUM;
  wire [ 8:0] VDPS3S4SPCOLLISIONX;
  wire [ 8:0] VDPS5S6SPCOLLISIONY;
  wire        SPVDPS0RESETREQ;
  wire        SPVDPS0RESETACK;
  wire        SPVDPS5RESETREQ;
  wire        SPVDPS5RESETACK;

  // PALETTE REGISTERS
  wire [ 3:0] PALETTEADDR_OUT;
  wire [ 7:0] PALETTEDATARB_OUT;
  wire [ 7:0] PALETTEDATAG_OUT;

  // VDP COMMAND SIGNALS - CAN BE READ & SET BY CPU
  wire [ 7:0] VDPCMDCLR;  // R44, S#7

  // VDP COMMAND SIGNALS - CAN BE READ BY CPU
  wire        VDPCMDCE;  // S#2 (BIT 0)
  wire        VDPCMDBD;  // S#2 (BIT 4)
  wire        VDPCMDTR;  // S#2 (BIT 7)
  wire [10:0] VDPCMDSXTMP;  // S#8, S#9

  wire [ 3:0] VDPCMDREGNUM;
  wire [ 7:0] VDPCMDREGDATA;
  wire        VDPCMDREGWRACK;
  wire        VDPCMDTRCLRACK;
  reg         VDPCMDVRAMWRACK;
  reg         VDPCMDVRAMRDACK;
  reg         VDPCMDVRAMREADINGR;
  reg         VDPCMDVRAMREADINGA;
  reg  [ 7:0] VDPCMDVRAMRDDATA;
  wire        VDPCMDREGWRREQ;
  wire        VDPCMDTRCLRREQ;
  wire        VDPCMDVRAMWRREQ;
  wire        VDPCMDVRAMRDREQ;
  wire [16:0] VDPCMDVRAMACCESSADDR;
  wire [ 7:0] VDPCMDVRAMWRDATA;

  reg         VDP_COMMAND_DRIVE;
  wire        VDP_COMMAND_ACTIVE;
  wire [ 7:4] CUR_VDP_COMMAND;

  // VIDEO OUTPUT SIGNALS
  wire [ 5:0] IVIDEOR;
  wire [ 5:0] IVIDEOG;
  wire [ 5:0] IVIDEOB;

  wire [ 5:0] IVIDEOR_VDP;
  wire [ 5:0] IVIDEOG_VDP;
  wire [ 5:0] IVIDEOB_VDP;
  wire        IVIDEOVS_N;

  wire [ 5:0] IVIDEOR_VGA;
  wire [ 5:0] IVIDEOG_VGA;
  wire [ 5:0] IVIDEOB_VGA;

  reg  [16:0] IRAMADR;
  wire [ 7:0] PRAMDAT;
  wire        XRAMSEL;
  wire [ 7:0] PRAMDATPAIR;

  wire        ENAHSYNC;
  wire        FF_BWINDOW_Y_DL;

  parameter VRAM_ACCESS_IDLE = 0;
  parameter VRAM_ACCESS_DRAW = 1;
  parameter VRAM_ACCESS_CPUW = 2;
  parameter VRAM_ACCESS_CPUR = 3;
  parameter VRAM_ACCESS_SPRT = 4;
  parameter VRAM_ACCESS_VDPW = 5;
  parameter VRAM_ACCESS_VDPR = 6;
  parameter VRAM_ACCESS_VDPS = 7;
  parameter VRAM_ACCESS_SUPER_HIGHRES_DRAW = 8;

  assign PAL_MODE = VDPR9PALMODE;

  assign PRAMADR = IRAMADR;
  assign XRAMSEL = IRAMADR[0];
  assign PRAMDAT = (XRAMSEL == 1'b0) ? PRAMDBI[7:0] : PRAMDBI[15:8];
  assign PRAMDATPAIR = (XRAMSEL == 1'b1) ? PRAMDBI[7:0] : PRAMDBI[15:8];

  //--------------------------------------------------------------
  // DISPLAY COMPONENTS
  //--------------------------------------------------------------
  assign VDPR9PALMODE = REG_R9_PAL_MODE;

  assign IVIDEOR = IVIDEOR_VDP;
  assign IVIDEOG = IVIDEOG_VDP;
  assign IVIDEOB = IVIDEOB_VDP;

  VDP_VGA U_VDP_VGA (
      .CLK21M(CLK21M),
      .RESET(RESET),
      .cx(CX),
      .cy(CY),
      .VIDEORIN(IVIDEOR),
      .VIDEOGIN(IVIDEOG),
      .VIDEOBIN(IVIDEOB),
      .VIDEOVSIN_N(IVIDEOVS_N),
      .PALMODE(VDPR9PALMODE),
      .INTERLACEMODE(REG_R9_INTERLACE_MODE),
      .VIDEOROUT(IVIDEOR_VGA),
      .VIDEOGOUT(IVIDEOG_VGA),
      .VIDEOBOUT(IVIDEOB_VGA)
  );

  // CHANGE DISPLAY MODE BY EXTERNAL INPUT PORT.
  assign PVIDEOR = IVIDEOR_VGA;
  assign PVIDEOG = IVIDEOG_VGA;
  assign PVIDEOB = IVIDEOB_VGA;


  //---------------------------------------------------------------------------
  // INTERRUPT
  //---------------------------------------------------------------------------

  // VSYNC INTERRUPT
  assign VSYNCINT_N = (REG_R1_VSYNC_INT_EN == 1'b0) ? 1'b1 : REQ_VSYNC_INT_N;

  // HSYNC INTERRUPT
  assign HSYNCINT_N = (REG_R0_HSYNC_INT_EN == 1'b0 || ENAHSYNC == 1'b0) ? 1'b1 : REQ_HSYNC_INT_N;

  assign INT_N = (VSYNCINT_N == 1'b0 || HSYNCINT_N == 1'b0) ? 1'b0 : 1'b1;

  VDP_INTERRUPT U_INTERRUPT (
      .RESET(RESET),
      .CLK21M(CLK21M),
      .cx(CX),
      .cy(CY),
      .Y_CNT(PREDOTCOUNTER_Y[7:0]),
      .ACTIVE_LINE(ACTIVE_LINE),
      .V_BLANKING_START(V_BLANKING_START),
      .CLR_VSYNC_INT(CLR_VSYNC_INT),
      .CLR_HSYNC_INT(CLR_HSYNC_INT),
      .REQ_VSYNC_INT_N(REQ_VSYNC_INT_N),
      .REQ_HSYNC_INT_N(REQ_HSYNC_INT_N),
      .REG_R19_HSYNC_INT_LINE(REG_R19_HSYNC_INT_LINE)
  );

  always_ff @(posedge CLK21M) begin
    if ((PREDOTCOUNTER_X == 255)) begin
      ACTIVE_LINE <= 1'b1;
    end else begin
      ACTIVE_LINE <= 1'b0;
    end
  end

  //---------------------------------------------------------------------------
  // SYNCHRONOUS SIGNAL GENERATOR
  //---------------------------------------------------------------------------
  VDP_SSG U_SSG (
      .RESET(RESET),
      .CLK21M(CLK21M),
      .cx(CX),
      .cy(CY),
      .DOTSTATE(DOTSTATE),
      .EIGHTDOTSTATE(EIGHTDOTSTATE),
      .PREDOTCOUNTER_X(PREDOTCOUNTER_X),
      .PREDOTCOUNTER_Y(PREDOTCOUNTER_Y),
      .PREDOTCOUNTER_YP(PREDOTCOUNTER_YP),
      .PREWINDOW_Y(PREWINDOW_Y),
      .PREWINDOW_Y_SP(PREWINDOW_Y_SP),
      .FIELD(FIELD),
      .WINDOW_X(WINDOW_X),
      .PVIDEODHCLK(PVIDEODHCLK),
      .PVIDEODLCLK(PVIDEODLCLK),
      .IVIDEOVS_N(IVIDEOVS_N),

      .HD(HD),
      .VD(VD),
      .HSYNC(HSYNC),
      .ENAHSYNC(ENAHSYNC),
      .V_BLANKING_START(V_BLANKING_START),

      .VDPR9PALMODE(VDPR9PALMODE),
      .REG_R9_INTERLACE_MODE(REG_R9_INTERLACE_MODE),
      .REG_R9_Y_DOTS(REG_R9_Y_DOTS),
      .REG_R18_ADJ(REG_R18_ADJ),
      .REG_R23_VSTART_LINE(REG_R23_VSTART_LINE),
      .REG_R25_MSK(REG_R25_MSK),
      .REG_R27_H_SCROLL(REG_R27_H_SCROLL),
      .REG_R25_YJK(REG_R25_YJK)
  );

  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      BWINDOW_Y <= 1'b0;
    end else begin
      if ((REG_R9_INTERLACE_MODE == 1'b0)) begin
        // NON-INTERLACE
        // 3+3+16 = 19
        if (((CY == (20 * 2)) || ((CY == (524 + 20 * 2)) && (VDPR9PALMODE == 1'b0)) || ((CY == (626 + 20 * 2)) && (VDPR9PALMODE == 1'b1)))) begin
          BWINDOW_Y <= 1'b1;
        end else if ((((CY == 524) && (VDPR9PALMODE == 1'b0)) || ((CY == 626) && (VDPR9PALMODE == 1'b1)) || (CY == 0))) begin
          BWINDOW_Y <= 1'b0;
        end
      end else begin
        // INTERLACE
        // +1 SHOULD BE NEEDED.
        // BECAUSE ODD FIELD'S START IS DELAYED HALF LINE.
        // SO THE START POSITION OF DISPLAY TIME SHOULD BE
        // DELAYED MORE HALF LINE.
        if (((CY == (20 * 2)) || ((CY == (525 + 20 * 2 + 1)) && (VDPR9PALMODE == 1'b0)) || ((CY == (625 + 20 * 2 + 1)) && (VDPR9PALMODE == 1'b1)))) begin
          BWINDOW_Y <= 1'b1;
        end else if ((((CY == 525) && (VDPR9PALMODE == 1'b0)) || ((CY == 625) && (VDPR9PALMODE == 1'b1)) || (CY == 0))) begin
          BWINDOW_Y <= 1'b0;
        end
      end
    end
  end

  // GENERATE PREWINDOW, WINDOW
  assign WINDOW = WINDOW_X & PREWINDOW_Y;
  assign PREWINDOW = PREWINDOW_X & PREWINDOW_Y;
  always_ff @(posedge RESET, posedge CLK21M) begin
    bit CX_FOR_NTSC;
    bit CX_FOR_PAL;

    if (RESET) begin
      PREWINDOW_X <= 1'b0;
    end else begin
      CX_FOR_NTSC = CY[0] == 0 && CX == {2'b000, `OFFSET_X + `LED_TV_X_NTSC - {3'b100}, 1'b1};
      CX_FOR_PAL  = CY[0] == 0 && CX == {2'b000, `OFFSET_X + `LED_TV_X_PAL - {3'b100}, 1'b1};

      if (!REG_R25_YJK && ((CX_FOR_NTSC && !VDPR9PALMODE) || (CX_FOR_PAL && VDPR9PALMODE))) begin
        // why is there this hold?  doesnt seem to break anything if removed.

      end else if (CX[1:0] == 2'b10) begin
        if ((PREDOTCOUNTER_X == 9'b111111111)) begin
          // JP: PREDOTCOUNTER_X が -1から0にカウントアップする時にWINDOWを1にする
          // (PREDOTCOUNTER_X is set to 0 when it counts up from -1 to 0)
          PREWINDOW_X <= 1'b1;
        end else if ((PREDOTCOUNTER_X == 9'b011111111)) begin
          PREWINDOW_X <= 1'b0;
        end
      end
    end
  end

  //----------------------------------------------------------------------------
  // main process
  //----------------------------------------------------------------------------
  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      VDPVRAMRDDATA   <= {8{1'b0}};
      VDPVRAMREADINGA <= 1'b0;
    end else begin
      if ((DOTSTATE == 2'b01)) begin
        if ((VDPVRAMREADINGR != VDPVRAMREADINGA)) begin
          VDPVRAMRDDATA   <= PRAMDAT;
          VDPVRAMREADINGA <= ~VDPVRAMREADINGA;
        end
      end
    end
  end

  always_ff @(posedge RESET, posedge CLK21M) begin
    if ((RESET == 1'b1)) begin
      VDPCMDVRAMRDDATA <= {8{1'b0}};
      VDPCMDVRAMRDACK <= 1'b0;
      VDPCMDVRAMREADINGA <= 1'b0;
    end else begin
      if ((DOTSTATE == 2'b01)) begin
        if ((VDPCMDVRAMREADINGR != VDPCMDVRAMREADINGA)) begin
          VDPCMDVRAMRDDATA <= PRAMDAT;
          VDPCMDVRAMRDACK <= ~VDPCMDVRAMRDACK;
          VDPCMDVRAMREADINGA <= ~VDPCMDVRAMREADINGA;
        end
      end
    end
  end

  assign TEXT_MODE = VDPMODETEXT1 | VDPMODETEXT1Q | VDPMODETEXT2;
  bit super_high_res_on_screen;

  always_ff @(posedge RESET, posedge CLK21M) begin : P1
    reg [16:0] VDPVRAMACCESSADDRV;
    reg [31:0] VRAMACCESSSWITCH;

    if ((RESET == 1'b1)) begin
      IRAMADR <= {17{1'b1}};
      PRAMDBO <= {8{1'bZ}};
      PRAMWE_N <= 1'b1;
      VDPVRAMREADINGR <= 1'b0;
      VDPVRAMRDACK <= 1'b0;
      VDPVRAMWRACK <= 1'b0;
      VDPVRAMADDRSETACK <= 1'b0;
      VDPVRAMACCESSADDR <= {17{1'b0}};
      VDPCMDVRAMWRACK <= 1'b0;
      VDPCMDVRAMREADINGR <= 1'b0;
      VDP_COMMAND_DRIVE <= 1'b0;
      super_high_res_on_screen <= 0;
    end else begin
      // MAIN STATE
      //----------------------------------------
      //
      // VRAM ACCESS ARBITER.
      //
      // VRAMアクセスタイミングを、EIGHTDOTSTATE によって制御している
      // (The VRAM access timing is controlled by EIGHTDOTSTATE)
      if ((DOTSTATE == 2'b10)) begin
        if(((PREWINDOW == 1'b1) && (REG_R1_DISP_ON == 1'b1) && ((EIGHTDOTSTATE == 3'b000) || (EIGHTDOTSTATE == 3'b001) || (EIGHTDOTSTATE == 3'b010) || (EIGHTDOTSTATE == 3'b011) || (EIGHTDOTSTATE == 3'b100)))) begin
          //  EIGHTDOTSTATE が 0～4 で、表示中の場合
          //  (EIGHTDOTSTATE is 0 to 4, and it is displayed)
          VRAMACCESSSWITCH = VRAM_ACCESS_DRAW;
        end else if (((PREWINDOW == 1'b1) && (REG_R1_DISP_ON == 1'b1) && (TXVRAMREADEN == 1'b1))) begin
          //  EIGHTDOTSTATE が 5～7 で、表示中で、テキストモードの場合
          //  (EIGHTDOTSTATE is 5 to 7, and it is displayed, and it is in text mode)
          VRAMACCESSSWITCH = VRAM_ACCESS_DRAW;
        end else if (((PREWINDOW_X == 1'b1) && (PREWINDOW_Y_SP == 1'b1) && (SPVRAMACCESSING == 1'b1) && (EIGHTDOTSTATE == 3'b101) && (TEXT_MODE == 1'b0))) begin
          // FOR SPRITE Y-TESTING
          VRAMACCESSSWITCH = VRAM_ACCESS_SPRT;
        end
        else if(((PREWINDOW_X == 1'b0) && (PREWINDOW_Y_SP == 1'b1) && (SPVRAMACCESSING == 1'b1) && (TEXT_MODE == 1'b0) && ((EIGHTDOTSTATE == 3'b000) || (EIGHTDOTSTATE == 3'b001) || (EIGHTDOTSTATE == 3'b010) || (EIGHTDOTSTATE == 3'b011) || (EIGHTDOTSTATE == 3'b100) || (EIGHTDOTSTATE == 3'b101)))) begin
          // FOR SPRITE PREPAREING
          VRAMACCESSSWITCH = VRAM_ACCESS_SPRT;
        end else if ((VDPVRAMWRREQ != VDPVRAMWRACK)) begin
          // VRAM WRITE REQUEST BY CPU
          VRAMACCESSSWITCH = VRAM_ACCESS_CPUW;
        end else if ((VDPVRAMRDREQ != VDPVRAMRDACK)) begin
          // VRAM READ REQUEST BY CPU
          VRAMACCESSSWITCH = VRAM_ACCESS_CPUR;
        end else begin
          // VDP COMMAND
          if ((VDP_COMMAND_ACTIVE == 1'b1)) begin
            if ((VDPCMDVRAMWRREQ != VDPCMDVRAMWRACK)) begin
              VRAMACCESSSWITCH = VRAM_ACCESS_VDPW;
            end else if ((VDPCMDVRAMRDREQ != VDPCMDVRAMRDACK)) begin
              VRAMACCESSSWITCH = VRAM_ACCESS_VDPR;
            end else begin
              VRAMACCESSSWITCH = VRAM_ACCESS_VDPS;
            end
          end else begin
            VRAMACCESSSWITCH = VRAM_ACCESS_VDPS;
          end
        end
      end else begin
        VRAMACCESSSWITCH = VRAM_ACCESS_DRAW;
      end

      if ((VRAMACCESSSWITCH == VRAM_ACCESS_VDPW || VRAMACCESSSWITCH == VRAM_ACCESS_VDPR || VRAMACCESSSWITCH == VRAM_ACCESS_VDPS)) begin
        VDP_COMMAND_DRIVE <= 1'b1;
      end else begin
        VDP_COMMAND_DRIVE <= 1'b0;
      end

      //
      // VRAM ACCESS ADDRESS SWITCH
      //
      if ((VRAMACCESSSWITCH == VRAM_ACCESS_CPUW)) begin
        IRAMADR <= VDPVRAMACCESSADDR;

        if(((VDPMODETEXT1 == 1'b1) || (VDPMODETEXT1Q == 1'b1) || (VDPMODEMULTI == 1'b1) || (VDPMODEMULTIQ == 1'b1) || (VDPMODEGRAPHIC1 == 1'b1) || (VDPMODEGRAPHIC2 == 1'b1))) begin
          VDPVRAMACCESSADDR[13:0] <= 14'(VDPVRAMACCESSADDR[13:0] + 1);
        end else begin
          VDPVRAMACCESSADDR <= 17'(VDPVRAMACCESSADDR + 1);
        end
        PRAMDBO <= VDPVRAMACCESSDATA;
        PRAMWE_N <= 1'b0;
        VDPVRAMWRACK <= ~VDPVRAMWRACK;
      end else if ((VRAMACCESSSWITCH == VRAM_ACCESS_CPUR)) begin
        // VRAM READ BY CPU
        if ((VDPVRAMADDRSETREQ != VDPVRAMADDRSETACK)) begin
          VDPVRAMACCESSADDRV = VDPVRAMACCESSADDRTMP;
          // CLEAR VRAM ADDRESS SET REQUEST SIGNAL
          VDPVRAMADDRSETACK <= ~VDPVRAMADDRSETACK;
        end else begin
          VDPVRAMACCESSADDRV = VDPVRAMACCESSADDR;
        end

        IRAMADR <= VDPVRAMACCESSADDRV;

        if(((VDPMODETEXT1 == 1'b1) || (VDPMODETEXT1Q == 1'b1) || (VDPMODEMULTI == 1'b1) || (VDPMODEMULTIQ == 1'b1) || (VDPMODEGRAPHIC1 == 1'b1) || (VDPMODEGRAPHIC2 == 1'b1))) begin
          VDPVRAMACCESSADDR[13:0] <= 14'(VDPVRAMACCESSADDRV[13:0] + 1);
        end else begin
          VDPVRAMACCESSADDR <= 17'(VDPVRAMACCESSADDRV + 1);
        end
        PRAMDBO <= {8{1'bZ}};
        PRAMWE_N <= 1'b1;
        VDPVRAMRDACK <= ~VDPVRAMRDACK;
        VDPVRAMREADINGR <= ~VDPVRAMREADINGA;
      end else if ((VRAMACCESSSWITCH == VRAM_ACCESS_VDPW)) begin
        IRAMADR <= VDPCMDVRAMACCESSADDR;
        PRAMDBO <= VDPCMDVRAMWRDATA;
        PRAMWE_N <= 1'b0;
        VDPCMDVRAMWRACK <= ~VDPCMDVRAMWRACK;
      end else if ((VRAMACCESSSWITCH == VRAM_ACCESS_VDPR)) begin
        IRAMADR <= VDPCMDVRAMACCESSADDR;
        PRAMDBO <= {8{1'bZ}};
        PRAMWE_N <= 1'b1;
        VDPCMDVRAMREADINGR <= ~VDPCMDVRAMREADINGA;
      end else if ((VRAMACCESSSWITCH == VRAM_ACCESS_SPRT)) begin
        // VRAM READ BY SPRITE MODULE
        IRAMADR  <= PRAMADRSPRITE;
        PRAMWE_N <= 1'b1;
        PRAMDBO  <= {8{1'bZ}};
      end else begin
        // VRAM_ACCESS_DRAW
        // VRAM READ FOR SCREEN IMAGE BUILDING
        case (DOTSTATE)
          2'b10: begin
            PRAMDBO  <= {8{1'bZ}};
            PRAMWE_N <= 1'b1;
            if ((TEXT_MODE == 1'b1)) begin
              IRAMADR <= PRAMADRT12;
            end else if (((VDPMODEGRAPHIC1 == 1'b1) || (VDPMODEGRAPHIC2 == 1'b1) || (VDPMODEGRAPHIC3 == 1'b1) || (VDPMODEMULTI == 1'b1) || (VDPMODEMULTIQ == 1'b1))) begin
              IRAMADR <= PRAMADRG123M;
            end else if (((VDPMODEGRAPHIC4 == 1'b1) || (VDPMODEGRAPHIC5 == 1'b1) || (VDPMODEGRAPHIC6 == 1'b1) || (VDPMODEGRAPHIC7 == 1'b1))) begin
              IRAMADR <= PRAMADRG4567;
            end
          end
          2'b01: begin
            PRAMDBO  <= {8{1'bZ}};
            PRAMWE_N <= 1'b1;
            if (((VDPMODEGRAPHIC6 == 1'b1) || (VDPMODEGRAPHIC7 == 1'b1))) begin
              IRAMADR <= PRAMADRG4567;
            end
          end
          default: begin
          end
        endcase
        if (((DOTSTATE == 2'b11) && (VDPVRAMADDRSETREQ != VDPVRAMADDRSETACK))) begin
          VDPVRAMACCESSADDR <= VDPVRAMACCESSADDRTMP;
          VDPVRAMADDRSETACK <= ~VDPVRAMADDRSETACK;
        end
      end
    end
  end

  //---------------------------------------------------------------------
  // COLOR DECODING
  //-----------------------------------------------------------------------
  VDP_COLORDEC U_VDP_COLORDEC (
      .RESET(RESET),
      .CLK21M(CLK21M),
      .DOTSTATE(DOTSTATE),
      .PPALETTEADDR_OUT(PALETTEADDR_OUT),
      .PALETTEDATARB_OUT(PALETTEDATARB_OUT),
      .PALETTEDATAG_OUT(PALETTEDATAG_OUT),
      .VDPMODETEXT1(VDPMODETEXT1),
      .VDPMODETEXT1Q(VDPMODETEXT1Q),
      .VDPMODETEXT2(VDPMODETEXT2),
      .VDPMODEMULTI(VDPMODEMULTI),
      .VDPMODEMULTIQ(VDPMODEMULTIQ),
      .VDPMODEGRAPHIC1(VDPMODEGRAPHIC1),
      .VDPMODEGRAPHIC2(VDPMODEGRAPHIC2),
      .VDPMODEGRAPHIC3(VDPMODEGRAPHIC3),
      .VDPMODEGRAPHIC4(VDPMODEGRAPHIC4),
      .VDPMODEGRAPHIC5(VDPMODEGRAPHIC5),
      .VDPMODEGRAPHIC6(VDPMODEGRAPHIC6),
      .VDPMODEGRAPHIC7(VDPMODEGRAPHIC7),
      .WINDOW(WINDOW),
      .SPRITECOLOROUT(SPRITECOLOROUT),
      .COLORCODET12(COLORCODET12),
      .COLORCODEG123M(COLORCODEG123M),
      .COLORCODEG4567(COLORCODEG4567),
      .COLORCODESPRITE(COLORCODESPRITE),
      .P_YJK_R(YJK_R),
      .P_YJK_G(YJK_G),
      .P_YJK_B(YJK_B),
      .P_YJK_EN(YJK_EN),
      .PVIDEOR_VDP(IVIDEOR_VDP),
      .PVIDEOG_VDP(IVIDEOG_VDP),
      .PVIDEOB_VDP(IVIDEOB_VDP),
      .REG_R1_DISP_ON(REG_R1_DISP_ON),
      .REG_R7_FRAME_COL(REG_R7_FRAME_COL),
      .REG_R8_COL0_ON(REG_R8_COL0_ON),
      .REG_R25_YJK(REG_R25_YJK)
  );

  //---------------------------------------------------------------------------
  // MAKE COLOR CODE
  //---------------------------------------------------------------------------
  VDP_TEXT12 U_VDP_TEXT12 (
      .CLK21M(CLK21M),
      .RESET(RESET),
      .DOTSTATE(DOTSTATE),
      .DOTCOUNTERX(PREDOTCOUNTER_X),
      .DOTCOUNTERY(PREDOTCOUNTER_Y),
      .DOTCOUNTERYP(PREDOTCOUNTER_YP),
      .VDPMODETEXT1(VDPMODETEXT1),
      .VDPMODETEXT1Q(VDPMODETEXT1Q),
      .VDPMODETEXT2(VDPMODETEXT2),
      .REG_R1_BL_CLKS(REG_R1_BL_CLKS),
      .REG_R7_FRAME_COL(REG_R7_FRAME_COL),
      .REG_R12_BLINK_MODE(REG_R12_BLINK_MODE),
      .REG_R13_BLINK_PERIOD(REG_R13_BLINK_PERIOD),
      .REG_R2_PT_NAM_ADDR(REG_R2_PT_NAM_ADDR),
      .REG_R4_PT_GEN_ADDR(REG_R4_PT_GEN_ADDR),
      .REG_R10R3_COL_ADDR(REG_R10R3_COL_ADDR),
      .PRAMDAT(PRAMDAT),
      .PRAMADR(PRAMADRT12),
      .TXVRAMREADEN(TXVRAMREADEN),
      .PCOLORCODE(COLORCODET12)
  );

  VDP_GRAPHIC123M U_VDP_GRAPHIC123M (
      .CLK21M(CLK21M),
      .RESET(RESET),
      .DOTSTATE(DOTSTATE),
      .EIGHTDOTSTATE(EIGHTDOTSTATE),
      .DOTCOUNTERX(PREDOTCOUNTER_X),
      .DOTCOUNTERY(PREDOTCOUNTER_Y),
      .VDPMODEMULTI(VDPMODEMULTI),
      .VDPMODEMULTIQ(VDPMODEMULTIQ),
      .VDPMODEGRAPHIC1(VDPMODEGRAPHIC1),
      .VDPMODEGRAPHIC2(VDPMODEGRAPHIC2),
      .VDPMODEGRAPHIC3(VDPMODEGRAPHIC3),
      .REG_R2_PT_NAM_ADDR(REG_R2_PT_NAM_ADDR),
      .REG_R4_PT_GEN_ADDR(REG_R4_PT_GEN_ADDR),
      .REG_R10R3_COL_ADDR(REG_R10R3_COL_ADDR),
      .REG_R26_H_SCROLL(REG_R26_H_SCROLL),
      .REG_R27_H_SCROLL(REG_R27_H_SCROLL),
      .PRAMDAT(PRAMDAT),
      .PRAMADR(PRAMADRG123M),
      .PCOLORCODE(COLORCODEG123M)
  );

  VDP_GRAPHIC4567 U_VDP_GRAPHIC4567 (
      .CLK21M(CLK21M),
      .RESET(RESET),
      .DOTSTATE(DOTSTATE),
      .EIGHTDOTSTATE(EIGHTDOTSTATE),
      .DOTCOUNTERX(PREDOTCOUNTER_X),
      .DOTCOUNTERY(PREDOTCOUNTER_Y),
      .VDPMODEGRAPHIC4(VDPMODEGRAPHIC4),
      .VDPMODEGRAPHIC5(VDPMODEGRAPHIC5),
      .VDPMODEGRAPHIC6(VDPMODEGRAPHIC6),
      .VDPMODEGRAPHIC7(VDPMODEGRAPHIC7),
      .REG_R1_BL_CLKS(REG_R1_BL_CLKS),
      .REG_R2_PT_NAM_ADDR(REG_R2_PT_NAM_ADDR),
      .REG_R13_BLINK_PERIOD(REG_R13_BLINK_PERIOD),
      .REG_R26_H_SCROLL(REG_R26_H_SCROLL),
      .REG_R27_H_SCROLL(REG_R27_H_SCROLL),
      .REG_R25_YAE(REG_R25_YAE),
      .REG_R25_YJK(REG_R25_YJK),
      .REG_R25_SP2(REG_R25_SP2),
      .PRAMDAT(PRAMDAT),
      .PRAMDATPAIR(PRAMDATPAIR),
      .PRAMADR(PRAMADRG4567),
      .PCOLORCODE(COLORCODEG4567),
      .P_YJK_R(YJK_R),
      .P_YJK_G(YJK_G),
      .P_YJK_B(YJK_B),
      .P_YJK_EN(YJK_EN)
  );

  //---------------------------------------------------------------------------
  // SPRITE MODULE
  //---------------------------------------------------------------------------
  VDP_SPRITE U_SPRITE (
      .CLK21M(CLK21M),
      .RESET(RESET),
      .DOTSTATE(DOTSTATE),
      .EIGHTDOTSTATE(EIGHTDOTSTATE),
      .DOTCOUNTERX(PREDOTCOUNTER_X),
      .DOTCOUNTERYP(PREDOTCOUNTER_YP),
      .BWINDOW_Y(BWINDOW_Y),
      .PVDPS0SPCOLLISIONINCIDENCE(VDPS0SPCOLLISIONINCIDENCE),
      .PVDPS0SPOVERMAPPED(VDPS0SPOVERMAPPED),
      .PVDPS0SPOVERMAPPEDNUM(VDPS0SPOVERMAPPEDNUM),
      .PVDPS3S4SPCOLLISIONX(VDPS3S4SPCOLLISIONX),
      .PVDPS5S6SPCOLLISIONY(VDPS5S6SPCOLLISIONY),
      .PVDPS0RESETREQ(SPVDPS0RESETREQ),
      .PVDPS0RESETACK(SPVDPS0RESETACK),
      .PVDPS5RESETREQ(SPVDPS5RESETREQ),
      .PVDPS5RESETACK(SPVDPS5RESETACK),
      .REG_R1_SP_SIZE(REG_R1_SP_SIZE),
      .REG_R1_SP_ZOOM(REG_R1_SP_ZOOM),
      .REG_R11R5_SP_ATR_ADDR(REG_R11R5_SP_ATR_ADDR),
      .REG_R6_SP_GEN_ADDR(REG_R6_SP_GEN_ADDR),
      .REG_R8_COL0_ON(REG_R8_COL0_ON),
      .REG_R8_SP_OFF(REG_R8_SP_OFF),
      .REG_R23_VSTART_LINE(REG_R23_VSTART_LINE),
      .REG_R27_H_SCROLL(REG_R27_H_SCROLL),
      .SPMODE2(SPMODE2),
      .SPVRAMACCESSING(SPVRAMACCESSING),
      .PRAMDAT(PRAMDAT),
      .PRAMADR(PRAMADRSPRITE),
      .SPCOLOROUT(SPRITECOLOROUT),
      .SPCOLORCODE(COLORCODESPRITE),
      .REG_R9_Y_DOTS(REG_R9_Y_DOTS),
      .SPMAXSPR(SPMAXSPR)
  );

  //---------------------------------------------------------------------------
  // VDP REGISTER ACCESS
  //---------------------------------------------------------------------------
  VDP_REGISTER U_VDP_REGISTER (
      .RESET(RESET),
      .CLK21M(CLK21M),
      .REQ(REQ),
      .ACK(ACK),
      .WRT(WRT),
      .mode(mode),
      .DBI(DBI),
      .DBO(DBO),
      .DOTSTATE(DOTSTATE),
      .VDPCMDTRCLRACK(VDPCMDTRCLRACK),
      .VDPCMDREGWRACK(VDPCMDREGWRACK),
      .HSYNC(HSYNC),
      .VDPS0SPCOLLISIONINCIDENCE(VDPS0SPCOLLISIONINCIDENCE),
      .VDPS0SPOVERMAPPED(VDPS0SPOVERMAPPED),
      .VDPS0SPOVERMAPPEDNUM(VDPS0SPOVERMAPPEDNUM),
      .SPVDPS0RESETREQ(SPVDPS0RESETREQ),
      .SPVDPS0RESETACK(SPVDPS0RESETACK),
      .SPVDPS5RESETREQ(SPVDPS5RESETREQ),
      .SPVDPS5RESETACK(SPVDPS5RESETACK),
      .VDPCMDTR(VDPCMDTR),
      .VD(VD),
      .HD(HD),
      .VDPCMDBD(VDPCMDBD),
      .FIELD(FIELD),
      .VDPCMDCE(VDPCMDCE),
      .VDPS3S4SPCOLLISIONX(VDPS3S4SPCOLLISIONX),
      .VDPS5S6SPCOLLISIONY(VDPS5S6SPCOLLISIONY),
      .VDPCMDCLR(VDPCMDCLR),
      .VDPCMDSXTMP(VDPCMDSXTMP),
      .VDPVRAMACCESSDATA(VDPVRAMACCESSDATA),
      .VDPVRAMACCESSADDRTMP(VDPVRAMACCESSADDRTMP),
      .VDPVRAMADDRSETREQ(VDPVRAMADDRSETREQ),
      .VDPVRAMADDRSETACK(VDPVRAMADDRSETACK),
      .VDPVRAMWRREQ(VDPVRAMWRREQ),
      .VDPVRAMWRACK(VDPVRAMWRACK),
      .VDPVRAMRDDATA(VDPVRAMRDDATA),
      .VDPVRAMRDREQ(VDPVRAMRDREQ),
      .VDPVRAMRDACK(VDPVRAMRDACK),
      .VDPCMDREGNUM(VDPCMDREGNUM),
      .VDPCMDREGDATA(VDPCMDREGDATA),
      .VDPCMDREGWRREQ(VDPCMDREGWRREQ),
      .VDPCMDTRCLRREQ(VDPCMDTRCLRREQ),
      .PALETTEADDR_OUT(PALETTEADDR_OUT),
      .PALETTEDATARB_OUT(PALETTEDATARB_OUT),
      .PALETTEDATAG_OUT(PALETTEDATAG_OUT),
      .CLR_VSYNC_INT(CLR_VSYNC_INT),
      .CLR_HSYNC_INT(CLR_HSYNC_INT),
      .REQ_VSYNC_INT_N(REQ_VSYNC_INT_N),
      .REQ_HSYNC_INT_N(REQ_HSYNC_INT_N),
      .REG_R0_HSYNC_INT_EN(REG_R0_HSYNC_INT_EN),
      .REG_R1_SP_SIZE(REG_R1_SP_SIZE),
      .REG_R1_SP_ZOOM(REG_R1_SP_ZOOM),
      .REG_R1_BL_CLKS(REG_R1_BL_CLKS),
      .REG_R1_VSYNC_INT_EN(REG_R1_VSYNC_INT_EN),
      .REG_R1_DISP_ON(REG_R1_DISP_ON),
      .REG_R2_PT_NAM_ADDR(REG_R2_PT_NAM_ADDR),
      .REG_R4_PT_GEN_ADDR(REG_R4_PT_GEN_ADDR),
      .REG_R10R3_COL_ADDR(REG_R10R3_COL_ADDR),
      .REG_R11R5_SP_ATR_ADDR(REG_R11R5_SP_ATR_ADDR),
      .REG_R6_SP_GEN_ADDR(REG_R6_SP_GEN_ADDR),
      .REG_R7_FRAME_COL(REG_R7_FRAME_COL),
      .REG_R8_SP_OFF(REG_R8_SP_OFF),
      .REG_R8_COL0_ON(REG_R8_COL0_ON),
      .REG_R9_PAL_MODE(REG_R9_PAL_MODE),
      .REG_R9_INTERLACE_MODE(REG_R9_INTERLACE_MODE),
      .REG_R9_Y_DOTS(REG_R9_Y_DOTS),
      .REG_R12_BLINK_MODE(REG_R12_BLINK_MODE),
      .REG_R13_BLINK_PERIOD(REG_R13_BLINK_PERIOD),
      .REG_R18_ADJ(REG_R18_ADJ),
      .REG_R19_HSYNC_INT_LINE(REG_R19_HSYNC_INT_LINE),
      .REG_R23_VSTART_LINE(REG_R23_VSTART_LINE),
      .REG_R25_CMD(REG_R25_CMD),
      .REG_R25_YAE(REG_R25_YAE),
      .REG_R25_YJK(REG_R25_YJK),
      .REG_R25_MSK(REG_R25_MSK),
      .REG_R25_SP2(REG_R25_SP2),
      .REG_R26_H_SCROLL(REG_R26_H_SCROLL),
      .REG_R27_H_SCROLL(REG_R27_H_SCROLL),
      .VDPMODETEXT1(VDPMODETEXT1),
      .VDPMODETEXT1Q(VDPMODETEXT1Q),
      .VDPMODETEXT2(VDPMODETEXT2),
      .VDPMODEMULTI(VDPMODEMULTI),
      .VDPMODEMULTIQ(VDPMODEMULTIQ),
      .VDPMODEGRAPHIC1(VDPMODEGRAPHIC1),
      .VDPMODEGRAPHIC2(VDPMODEGRAPHIC2),
      .VDPMODEGRAPHIC3(VDPMODEGRAPHIC3),
      .VDPMODEGRAPHIC4(VDPMODEGRAPHIC4),
      .VDPMODEGRAPHIC5(VDPMODEGRAPHIC5),
      .VDPMODEGRAPHIC6(VDPMODEGRAPHIC6),
      .VDPMODEGRAPHIC7(VDPMODEGRAPHIC7),
      .VDPMODEISHIGHRES(VDPMODEISHIGHRES),
      .super_high_res(super_high_res),
      .SPMODE2(SPMODE2),
      .REG_R31(REG_R31)
  );

  //---------------------------------------------------------------------------
  // VDP COMMAND
  //---------------------------------------------------------------------------
  VDP_COMMAND U_VDP_COMMAND (
      .RESET(RESET),
      .CLK21M(CLK21M),
      .VDPMODEGRAPHIC4(VDPMODEGRAPHIC4),
      .VDPMODEGRAPHIC5(VDPMODEGRAPHIC5),
      .VDPMODEGRAPHIC6(VDPMODEGRAPHIC6),
      .VDPMODEGRAPHIC7(VDPMODEGRAPHIC7),
      .VDPMODEISHIGHRES(VDPMODEISHIGHRES),
      .VRAMWRACK(VDPCMDVRAMWRACK),
      .VRAMRDACK(VDPCMDVRAMRDACK),
      .VRAMREADINGR(VDPCMDVRAMREADINGR),
      .VRAMREADINGA(VDPCMDVRAMREADINGA),
      .VRAMRDDATA(VDPCMDVRAMRDDATA),
      .REGWRREQ(VDPCMDREGWRREQ),
      .TRCLRREQ(VDPCMDTRCLRREQ),
      .REGNUM(VDPCMDREGNUM),
      .REGDATA(VDPCMDREGDATA),
      .PREGWRACK(VDPCMDREGWRACK),
      .PTRCLRACK(VDPCMDTRCLRACK),
      .PVRAMWRREQ(VDPCMDVRAMWRREQ),
      .PVRAMRDREQ(VDPCMDVRAMRDREQ),
      .PVRAMACCESSADDR(VDPCMDVRAMACCESSADDR),
      .PVRAMWRDATA(VDPCMDVRAMWRDATA),
      .PCLR(VDPCMDCLR),
      .PCE(VDPCMDCE),
      .PBD(VDPCMDBD),
      .PTR(VDPCMDTR),
      .PSXTMP(VDPCMDSXTMP),
      .CUR_VDP_COMMAND(CUR_VDP_COMMAND),
      .REG_R25_CMD(REG_R25_CMD)
  );

  VDP_WAIT_CONTROL U_VDP_WAIT_CONTROL (
      .RESET(RESET),
      .CLK21M(CLK21M),
      .VDP_COMMAND(CUR_VDP_COMMAND),
      .VDPR9PALMODE(VDPR9PALMODE),
      .REG_R1_DISP_ON(REG_R1_DISP_ON),
      .REG_R8_SP_OFF(REG_R8_SP_OFF),
      .REG_R9_Y_DOTS(REG_R9_Y_DOTS),
      .VDPSPEEDMODE(VDPSPEEDMODE),
      .DRIVE(VDP_COMMAND_DRIVE),
      .ACTIVE(VDP_COMMAND_ACTIVE)
  );

endmodule
