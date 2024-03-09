//
//  vdp_command.vhd
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
//  20th,March,2008
//      JP: VDP.VHD から分離 by t.hara
//      Translation: VDP.VHD extracted by t.hara
//

module VDP_COMMAND (
    input wire RESET,
    input wire CLK21M,
    input wire VDPMODEGRAPHIC4,
    input wire VDPMODEGRAPHIC5,
    input wire VDPMODEGRAPHIC6,
    input wire VDPMODEGRAPHIC7,
    input wire VDPMODEISHIGHRES,
    input wire VRAMWRACK,
    input wire VRAMRDACK,
    input wire VRAMREADINGR,
    input wire VRAMREADINGA,
    input wire [7:0] VRAMRDDATA,
    input wire REGWRREQ,
    input wire TRCLRREQ,
    input wire [3:0] REGNUM,
    input wire [7:0] REGDATA,
    output wire PREGWRACK,
    output wire PTRCLRACK,
    output wire PVRAMWRREQ,
    output wire PVRAMRDREQ,
    output wire [16:0] PVRAMACCESSADDR,
    output wire [7:0] PVRAMWRDATA,
    output wire [7:0] PCLR,
    output wire PCE,
    output wire PBD,
    output wire PTR,
    output wire [10:0] PSXTMP,
    output wire [7:4] CUR_VDP_COMMAND,
    input wire REG_R25_CMD
);

  // R44, S#7
  // S#2 (BIT 0)
  // S#2 (BIT 4)
  // S#2 (BIT 7)
  // S#8, S#9

  // VDP COMMAND SIGNALS - CAN BE SET BY CPU
  reg  [ 8:0] SX;  // R33,32
  reg  [ 9:0] SY;  // R35,34
  reg  [ 8:0] DX;  // R37,36
  reg  [ 9:0] DY;  // R39,38
  reg  [ 9:0] NX;  // R41,40
  reg  [ 9:0] NY;  // R43,42
  reg         MM;  // R45 BIT 0
  reg         EQ;  // R45 BIT 1
  reg         DIX;  // R45 BIT 2
  reg         DIY;  // R45 BIT 3

  reg  [ 7:0] CMR;  // R46

  // VDP COMMAND SIGNALS - INTERNAL REGISTERS
  reg  [ 9:0] DXTMP;
  reg  [ 9:0] NXTMP;
  reg         REGWRACK;
  reg         TRCLRACK;
  reg         CMRWR;

  // VDP COMMAND SIGNALS - COMMUNICATION BETWEEN COMMAND PROCESSOR
  // AND MEMORY INTERFACE (WHICH IS IN THE COLOR GENERATOR)
  reg         VRAMWRREQ;
  reg         VRAMRDREQ;
  reg  [16:0] VRAMACCESSADDR;
  reg  [ 7:0] VRAMWRDATA;
  reg  [ 7:0] CLR;  // R44, S#7

  // VDP COMMAND SIGNALS - CAN BE READ BY CPU
  reg         CE;  // S#2 (BIT 0)
  reg         BD;  // S#2 (BIT 4)
  reg         TR;  // S#2 (BIT 7)
  reg  [10:0] SXTMP;  // S#8, S#9
  wire        W_VDPCMD_EN;  // VDP COMMAND STATE REGISTER

  //??
  reg  [ 1:0] RDXLOW;

  typedef enum logic [3:0] {
    STIDLE,
    STCHKLOOP,
    STRDCPU,
    STWAITCPU,
    STRDVRAM,
    STWAITRDVRAM,
    STPOINTWAITRDVRAM,
    STSRCHWAITRDVRAM,
    STPRERDVRAM,
    STWAITPRERDVRAM,
    STWRVRAM,
    STWAITWRVRAM,
    STLINENEWPOS,
    STLINECHKLOOP,
    STSRCHCHKLOOP,
    STEXECEND
  } type_state;

  type_state STATE;
  parameter HMMC = 4'b1111;
  parameter YMMM = 4'b1110;
  parameter HMMM = 4'b1101;
  parameter HMMV = 4'b1100;
  parameter LMMC = 4'b1011;
  parameter LMCM = 4'b1010;
  parameter LMMM = 4'b1001;
  parameter LMMV = 4'b1000;
  parameter LINE = 4'b0111;
  parameter SRCH = 4'b0110;
  parameter PSET = 4'b0101;
  parameter POINT = 4'b0100;
  parameter STOP = 4'b0000;
  parameter IMPB210 = 3'b000;
  parameter ANDB210 = 3'b001;
  parameter ORB210 = 3'b010;
  parameter EORB210 = 3'b011;
  parameter NOTB210 = 3'b100;

  assign PREGWRACK = REGWRACK;
  assign PTRCLRACK = TRCLRACK;
  assign PVRAMWRREQ = (W_VDPCMD_EN == 1'b1) ? VRAMWRREQ : VRAMWRACK;
  assign PVRAMRDREQ = VRAMRDREQ;
  assign PVRAMACCESSADDR = VRAMACCESSADDR;
  assign PVRAMWRDATA = VRAMWRDATA;
  assign PCLR = CLR;
  assign PCE = CE;
  assign PBD = BD;
  assign PTR = TR;
  assign PSXTMP = SXTMP;
  assign CUR_VDP_COMMAND = CMR[7:4];

  // R25 CMD BIT
  // 0 = NORMAL
  // 1 = VDP COMMAND ON TEXT/GRAPHIC1/GRAPHIC2/GRAPHIC3/MOSAIC MODE
  assign W_VDPCMD_EN = ((VDPMODEGRAPHIC4 | VDPMODEGRAPHIC5 | VDPMODEGRAPHIC6) == 1'b0) ? VDPMODEGRAPHIC7 | REG_R25_CMD : VDPMODEGRAPHIC4 | VDPMODEGRAPHIC5 | VDPMODEGRAPHIC6;

  reg GRAPHIC4_OR_6;
  always_comb begin
    if (((VDPMODEGRAPHIC4 == 1'b1) || (VDPMODEGRAPHIC6 == 1'b1))) begin
      GRAPHIC4_OR_6 = 1'b1;
    end else begin
      GRAPHIC4_OR_6 = 1'b0;
    end
  end

  reg [9:0] NXCOUNT;
  assign NXCOUNT = CMR[7:6] == 2'b11 && GRAPHIC4_OR_6 == 1'b1 ? {1'b0, NX[9:1]} : CMR[7:6] == 2'b11 && VDPMODEGRAPHIC5 == 1'b1 ? {2'b00, NX[9:2]} : NX;

  reg [9:0] YCOUNTDELTA;
  assign YCOUNTDELTA = (DIY == 1'b0) ? 10'b0000000001 : 10'b1111111111;

  reg [1:0] MAXXMASK;
  assign MAXXMASK = (VDPMODEISHIGHRES == 1'b1) ? 2'b10 : 2'b01;  // GRAPHIC 5,6 (SCREEN 6, 7)


  reg [7:0] RDPOINT;
  always_comb begin
    // RETRIEVE THE 'POINT' OUT OF THE BYTE THAT WAS MOST RECENTLY READ
    if ((GRAPHIC4_OR_6 == 1'b1)) begin
      // SCREEN 5, 7
      if ((RDXLOW[0] == 1'b0)) begin
        RDPOINT = {4'b0000, VRAMRDDATA[7:4]};
      end else begin
        RDPOINT = {4'b0000, VRAMRDDATA[3:0]};
      end

    end else if ((VDPMODEGRAPHIC5 == 1'b1)) begin
      // SCREEN 6
      case (RDXLOW)
        2'b00: begin
          RDPOINT = {6'b000000, VRAMRDDATA[7:6]};
        end
        2'b01: begin
          RDPOINT = {6'b000000, VRAMRDDATA[5:4]};
        end
        2'b10: begin
          RDPOINT = {6'b000000, VRAMRDDATA[3:2]};
        end
        default: begin
          // 2'b11:
          RDPOINT = {6'b000000, VRAMRDDATA[1:0]};
          // NULL; -- SHOULD NEVER OCCUR
        end
      endcase
    end else begin
      // SCREEN 8 AND OTHER MODES
      RDPOINT = VRAMRDDATA;
    end
  end

  reg [7:0] COLMASK;
  always_comb begin
    case (CMR[7:6])
      2'b11: begin
        COLMASK = 8'b000000001;
      end

      default: begin
        if ((GRAPHIC4_OR_6 == 1'b1)) begin
          COLMASK = 8'b00001111;
        end else if ((VDPMODEGRAPHIC5 == 1'b1)) begin
          COLMASK = 8'b00000011;
        end else begin
          COLMASK = 8'b00000001;
        end
      end
    endcase
  end

  reg [7:0] LOGOPDESTCOL;
  always_comb begin
    // PERFORM LOGICAL OPERATION ON MOST RECENTLY READ POINT AND
    // ON THE POINT TO BE WRITTEN.
    if (((CMR[3] == 1'b0) || ((VRAMWRDATA & COLMASK) != 8'b00000000))) begin
      case (CMR[2:0])
        IMPB210: begin
          LOGOPDESTCOL = VRAMWRDATA & COLMASK;
        end
        ANDB210: begin
          LOGOPDESTCOL = (VRAMWRDATA & COLMASK) & RDPOINT;
        end
        ORB210: begin
          LOGOPDESTCOL = (VRAMWRDATA & COLMASK) | RDPOINT;
        end
        EORB210: begin
          LOGOPDESTCOL = (VRAMWRDATA & COLMASK) ^ RDPOINT;
        end
        NOTB210: begin
          LOGOPDESTCOL = ~(VRAMWRDATA & COLMASK);
        end
        default: begin
          LOGOPDESTCOL = RDPOINT;
        end
      endcase
    end else begin
      LOGOPDESTCOL = RDPOINT;
    end
  end

  reg NXLOOPEND;
  always_comb begin
    // DETERMINE IF X-LOOP IS FINISHED
    case (CMR[7:4])
      HMMV, HMMC, LMMV, LMMC: begin
        if (((NXTMP == 0) || ((DXTMP[9:8] & MAXXMASK) == MAXXMASK))) begin
          NXLOOPEND = 1'b1;
        end else begin
          NXLOOPEND = 1'b0;
        end
      end
      YMMM: begin
        if (((DXTMP[9:8] & MAXXMASK) == MAXXMASK)) begin
          NXLOOPEND = 1'b1;
        end else begin
          NXLOOPEND = 1'b0;
        end
      end
      HMMM, LMMM: begin
        if (((NXTMP == 0) || ((SXTMP[9:8] & MAXXMASK) == MAXXMASK) || ((DXTMP[9:8] & MAXXMASK) == MAXXMASK))) begin
          NXLOOPEND = 1'b1;
        end else begin
          NXLOOPEND = 1'b0;
        end
      end
      LMCM: begin
        if (((NXTMP == 0) || ((SXTMP[9:8] & MAXXMASK) == MAXXMASK))) begin
          NXLOOPEND = 1'b1;
        end else begin
          NXLOOPEND = 1'b0;
        end
      end
      SRCH: begin
        if (((SXTMP[9:8] & MAXXMASK) == MAXXMASK)) begin
          NXLOOPEND = 1'b1;
        end else begin
          NXLOOPEND = 1'b0;
        end
      end
      default: begin
        NXLOOPEND = 1'b1;
      end
    endcase
  end

  always @(posedge RESET, posedge CLK21M) begin
    reg INITIALIZING;
    reg [10:0] XCOUNTDELTA;
    reg DYEND;
    reg SYEND;
    reg NYLOOPEND;
    reg [9:0] NX_MINUS_ONE;
    reg SRCHEQRSLT;
    reg [9:0] VDPVRAMACCESSY;
    reg [8:0] VDPVRAMACCESSX;

    if ((RESET == 1'b1)) begin
      STATE <= STIDLE;
      // VERY IMPORTANT FOR XILINX SYNTHESIS TOOL(XST)
      INITIALIZING = 1'b0;
      XCOUNTDELTA  = {1{1'b0}};
      RDXLOW <= 2'b00;
      SX             = {9{1'b0}};  // R32
      SY             = {10{1'b0}};  // R34
      DX             = {9{1'b0}};  // R36
      DY             = {10{1'b0}};  // R38
      NX             = {10{1'b0}};  // R40
      NY             = {10{1'b0}};  // R42
      CLR            = {8{1'b0}};  // R44
      MM             = 1'b0;  // R45 BIT 0
      EQ             = 1'b0;  // R45 BIT 1
      DIX            = 1'b0;  // R45 BIT 2
      DIY            = 1'b0;  // R45 BIT 3
      CMR            = {8{1'b0}};  // R46
      SXTMP          = {11{1'b0}};
      DXTMP          = {10{1'b0}};
      CMRWR          = 1'b0;
      REGWRACK       = 1'b0;
      VRAMWRREQ      = 1'b0;
      VRAMRDREQ      = 1'b0;
      VRAMWRDATA     = {8{1'b0}};
      TR             = 1'b1;  // TRANSFER READY
      CE             = 1'b0;  // COMMAND EXECUTING
      BD             = 1'b0;  // BORDER COLOR FOUND
      TRCLRACK       = 1'b0;
      VDPVRAMACCESSY = {1{1'b0}};
      VDPVRAMACCESSX = {1{1'b0}};
      VRAMACCESSADDR = {17{1'b0}};

    end else begin
      case (CMR[7:6])
        2'b11: begin
          // BYTE COMMAND
          if ((GRAPHIC4_OR_6 == 1'b1)) begin
            // GRAPHIC4,6 (SCREEN 5, 7)
            if ((DIX == 1'b0)) begin
              XCOUNTDELTA = 11'b00000000010;  // +2
            end else begin
              XCOUNTDELTA = 11'b11111111110;  // -2
            end

          end else if ((VDPMODEGRAPHIC5 == 1'b1)) begin
            // GRAPHIC5 (SCREEN 6)
            if ((DIX == 1'b0)) begin
              XCOUNTDELTA = 11'b00000000100;  // +4
            end else begin
              XCOUNTDELTA = 11'b11111111100;  // -4;
            end

          end else begin
            // GRAPHIC7 (SCREEN 8) AND OTHER
            if ((DIX == 1'b0)) begin
              XCOUNTDELTA = 11'b00000000001;  // +1
            end else begin
              XCOUNTDELTA = 11'b11111111111;  // -1
            end
          end
        end

        default: begin
          // DOT COMMAND
          if ((DIX == 1'b0)) begin
            XCOUNTDELTA = 11'b00000000001;  // +1;
          end else begin
            XCOUNTDELTA = 11'b11111111111;  // -1;
          end
        end
      endcase




      // PROCESS REGISTER UPDATE REQUEST, CLEAR 'TRANSFER READY' REQUEST
      // OR PROCESS ANY ONGOING COMMAND.
      if ((REGWRREQ != REGWRACK)) begin
        REGWRACK <= ~REGWRACK;
        case (REGNUM)
          4'b0000: begin  // #32
            SX[7:0] <= REGDATA;
          end
          4'b0001: begin  // #33
            SX[8] <= REGDATA[0];
          end
          4'b0010: begin  // #34
            SY[7:0] <= REGDATA;
          end
          4'b0011: begin  // #35
            SY[9:8] <= REGDATA[1:0];
          end
          4'b0100: begin  // #36
            DX[7:0] <= REGDATA;
          end
          4'b0101: begin  // #37
            DX[8] <= REGDATA[0];
          end
          4'b0110: begin  // #38
            DY[7:0] <= REGDATA;
          end
          4'b0111: begin  // #39
            DY[9:8] <= REGDATA[1:0];
          end
          4'b1000: begin  // #40
            NX[7:0] <= REGDATA;
          end
          4'b1001: begin  // #41
            NX[9:8] <= REGDATA[1:0];
          end
          4'b1010: begin  // #42
            NY[7:0] <= REGDATA;
          end
          4'b1011: begin  // #43
            NY[9:8] <= REGDATA[1:0];
          end
          4'b1100: begin  // #44
            if ((CE == 1'b1)) begin
              CLR <= REGDATA & COLMASK;
            end else begin
              CLR <= REGDATA;
            end
            TR <= 1'b0;
            // DATA IS TRANSFERRED FROM CPU TO VDP COLOR REGISTER
          end
          4'b1101: begin  // #45
            MM  <= REGDATA[0];
            EQ  <= REGDATA[1];
            DIX <= REGDATA[2];
            DIY <= REGDATA[3];
            //                      MXD <= REGDATA(5);
          end
          4'b1110: begin  // #46
            // INITIALIZE THE NEW COMMAND
            // NOTE THAT THIS WILL ABORT ANY ONGOING COMMAND!
            CMR   <= REGDATA;
            CMRWR <= W_VDPCMD_EN;
            STATE <= STIDLE;
          end
          default: begin
          end
        endcase

      end else if ((TRCLRREQ != TRCLRACK)) begin
        // RESET THE DATA TRANSFER REGISTER (CPU HAS JUST READ THE COLOR REGISTER)
        TRCLRACK <= ~TRCLRACK;
        TR <= 1'b0;

      end else begin
        // PROCESS THE VDP COMMAND STATE
        case (STATE)
          STIDLE: begin
            if ((CMRWR == 1'b0)) begin
              CE <= 1'b0;
              CE <= 1'b0;
            end else begin
              // EXEC NEW VDP COMMAND
              CMRWR <= 1'b0;
              CE <= 1'b1;
              BD <= 1'b0;
              if (CMR[7:4] == LINE) begin
                // LINE COMMAND REQUIRES SPECIAL SXTMP AND NXTMP SET-UP
                NX_MINUS_ONE = NX - 1;
                SXTMP <= {2'b00, NX_MINUS_ONE[9:1]};
                NXTMP <= {10{1'b0}};
              end else begin
                if (CMR[7:4] == YMMM) begin
                  // FOR YMMM, SXTMP = DXTMP = DX
                  SXTMP <= {2'b00, DX};
                end else begin
                  // FOR ALL OTHERS, SXTMP IS BUSINES AS USUAL
                  SXTMP <= {2'b00, SX};
                end
                // NXTMP IS BUSINESS AS USUAL FOR ALL BUT THE LINE COMMAND
                NXTMP <= NXCOUNT;
              end
              DXTMP <= {1'b0, DX};
              INITIALIZING = 1'b1;  //if !RESET && REGWRREQ != REGWRACK && TRCLRREQ != TRCLRACK && STATE == STIDLE && CMRWR != 1'b0
              STATE <= STCHKLOOP;
            end
          end

          STRDCPU: begin
            // APPLICABLE TO HMMC, LMMC
            if ((TR == 1'b0)) begin
              // CPU HAS TRANSFERRED DATA TO (OR FROM) THE COLOR REGISTER
              TR <= 1'b1;
              // VDP IS READY TO RECEIVE THE NEXT TRANSFER.
              VRAMWRDATA <= CLR;
              if ((CMR[6] == 1'b0)) begin
                // IT IS LMMC
                STATE <= STPRERDVRAM;
              end else begin
                // IT IS HMMC
                STATE <= STWRVRAM;
              end
            end
          end

          STWAITCPU: begin
            // APPLICABLE TO LMCM
            if ((TR == 1'b0)) begin
              // CPU HAS TRANSFERRED DATA FROM (OR TO) THE COLOR REGISTER
              // VDP MAY READ THE NEXT VALUE INTO THE COLOR REGISTER
              STATE <= STRDVRAM;
            end
          end

          STRDVRAM: begin
            // APPLICABLE TO YMMM, HMMM, LMCM, LMMM, SRCH, POINT
            VDPVRAMACCESSY = SY;
            VDPVRAMACCESSX = SXTMP[8:0];
            RDXLOW <= SXTMP[1:0];
            VRAMRDREQ <= ~VRAMRDACK;
            case (CMR[7:4])
              POINT: begin
                STATE <= STPOINTWAITRDVRAM;
              end
              SRCH: begin
                STATE <= STSRCHWAITRDVRAM;
              end
              default: begin
                STATE <= STWAITRDVRAM;
              end
            endcase
          end

          STPOINTWAITRDVRAM: begin
            // APPLICABLE TO POINT
            if ((VRAMRDREQ == VRAMRDACK)) begin
              CLR   <= RDPOINT;
              STATE <= STEXECEND;
            end
          end

          STSRCHWAITRDVRAM: begin
            // APPLICABLE TO SRCH
            if ((VRAMRDREQ == VRAMRDACK)) begin
              if ((RDPOINT == CLR)) begin
                SRCHEQRSLT = 1'b0;
              end else begin
                SRCHEQRSLT = 1'b1;
              end
              if ((EQ == SRCHEQRSLT)) begin
                BD <= 1'b1;
                STATE <= STEXECEND;
              end else begin
                SXTMP <= SXTMP + XCOUNTDELTA;
                STATE <= STSRCHCHKLOOP;
              end
            end
          end

          STWAITRDVRAM: begin
            // APPLICABLE TO YMMM, HMMM, LMCM, LMMM
            if ((VRAMRDREQ == VRAMRDACK)) begin
              SXTMP <= SXTMP + XCOUNTDELTA;
              case (CMR[7:4])
                LMMM: begin
                  VRAMWRDATA <= RDPOINT;
                  STATE <= STPRERDVRAM;
                end
                LMCM: begin
                  CLR <= RDPOINT;
                  TR <= 1'b1;
                  NXTMP <= NXTMP - 1;
                  STATE <= STCHKLOOP;
                end
                default: begin
                  // REMAINING: YMMM, HMMM
                  VRAMWRDATA <= VRAMRDDATA;
                  STATE <= STWRVRAM;
                end
              endcase
            end
          end

          STPRERDVRAM: begin
            // APPLICABLE TO LMMC, LMMM, LMMV, LINE, PSET
            VDPVRAMACCESSY = DY;
            VDPVRAMACCESSX = DXTMP[8:0];
            RDXLOW <= DXTMP[1:0];
            VRAMRDREQ <= ~VRAMRDACK;
            STATE <= STWAITPRERDVRAM;
          end

          STWAITPRERDVRAM: begin
            // APPLICABLE TO LMMC, LMMM, LMMV, LINE, PSET
            if ((VRAMRDREQ == VRAMRDACK)) begin
              if ((GRAPHIC4_OR_6 == 1'b1)) begin
                // SCREEN 5, 7
                if ((RDXLOW[0] == 1'b0)) begin
                  VRAMWRDATA <= {LOGOPDESTCOL[3:0], VRAMRDDATA[3:0]};
                end else begin
                  VRAMWRDATA <= {VRAMRDDATA[7:4], LOGOPDESTCOL[3:0]};
                end
              end else if ((VDPMODEGRAPHIC5 == 1'b1)) begin
                // SCREEN 6
                case (RDXLOW)
                  2'b00: begin
                    VRAMWRDATA <= {LOGOPDESTCOL[1:0], VRAMRDDATA[5:0]};
                  end
                  2'b01: begin
                    VRAMWRDATA <= {VRAMRDDATA[7:6], LOGOPDESTCOL[1:0], VRAMRDDATA[3:0]};
                  end
                  2'b10: begin
                    VRAMWRDATA <= {VRAMRDDATA[7:4], LOGOPDESTCOL[1:0], VRAMRDDATA[1:0]};
                  end
                  default: begin
                    // 2'b11:
                    VRAMWRDATA <= {VRAMRDDATA[7:2], LOGOPDESTCOL[1:0]};
                    // NULL; -- SHOULD NEVER OCCUR
                  end
                endcase
              end else begin
                // SCREEN 8 AND OTHER MODES
                VRAMWRDATA <= LOGOPDESTCOL;
              end
              STATE <= STWRVRAM;
            end
          end

          STWRVRAM: begin
            // APPLICABLE TO HMMC, YMMM, HMMM, HMMV, LMMC, LMMM, LMMV, LINE, PSET
            VDPVRAMACCESSY = DY;
            VDPVRAMACCESSX = DXTMP[8:0];
            VRAMWRREQ <= ~VRAMWRACK;
            STATE <= STWAITWRVRAM;
          end

          STWAITWRVRAM: begin
            // APPLICABLE TO HMMC, YMMM, HMMM, HMMV, LMMC, LMMM, LMMV, LINE, PSET
            if ((VRAMWRREQ == VRAMWRACK)) begin
              case (CMR[7:4])
                PSET: begin
                  STATE <= STEXECEND;
                end
                LINE: begin
                  SXTMP <= SXTMP - NY;
                  if (MM == 1'b0) begin
                    DXTMP <= DXTMP + XCOUNTDELTA[9:0];
                  end else begin
                    DY <= DY + YCOUNTDELTA;
                  end
                  STATE <= STLINENEWPOS;
                end
                default: begin
                  DXTMP <= DXTMP + XCOUNTDELTA[9:0];
                  NXTMP <= NXTMP - 1;
                  STATE <= STCHKLOOP;
                end
              endcase
            end
          end

          STLINENEWPOS: begin
            // APPLICABLE TO LINE
            if ((SXTMP[10] == 1'b1)) begin
              SXTMP <= {1'b0, SXTMP[9:0] + NX};
              if ((MM == 1'b0)) begin
                DY <= DY + YCOUNTDELTA;
              end else begin
                DXTMP <= DXTMP + XCOUNTDELTA[9:0];
              end
            end
            STATE <= STLINECHKLOOP;
          end

          STLINECHKLOOP: begin
            // APPLICABLE TO LINE
            if (((NXTMP == NX) || ((DXTMP[9:8] & MAXXMASK) == MAXXMASK))) begin
              STATE <= STEXECEND;
            end else begin
              VRAMWRDATA <= CLR;
              // COLOR MUST BE RE-MASKED, JUST IN CASE THAT SCREENMODE WAS CHANGED
              CLR <= CLR & COLMASK;
              STATE <= STPRERDVRAM;
            end
            NXTMP <= NXTMP + 1;
          end

          STSRCHCHKLOOP: begin
            // APPLICABLE TO SRCH
            if ((NXLOOPEND == 1'b1)) begin
              STATE <= STEXECEND;
            end else begin
              // COLOR MUST BE RE-MASKED, JUST IN CASE THAT SCREENMODE WAS CHANGED
              CLR   <= CLR & COLMASK;
              STATE <= STRDVRAM;
            end
          end

          STCHKLOOP: begin
            // WHEN INITIALIZING = '1':
            //   APPLICABLE TO ALL COMMANDS
            // WHEN INITIALIZING = '0':
            //   APPLICABLE TO HMMC, YMMM, HMMM, HMMV, LMMC, LMCM, LMMM, LMMV
            //   DETERMINE NYLOOPEND
            DYEND = 1'b0;
            SYEND = 1'b0;
            if ((DIY == 1'b1)) begin
              if (((DY == 0) && (CMR[7:4] != LMCM))) begin
                DYEND = 1'b1;
              end
              if (((SY == 0) && (CMR[5] != CMR[4]))) begin
                // BIT5 /= BIT4 IS TRUE FOR COMMANDS YMMM, HMMM, LMCM, LMMM
                SYEND = 1'b1;
              end
            end
            if (((NY == 1) || (DYEND == 1'b1) || (SYEND == 1'b1))) begin
              NYLOOPEND = 1'b1;
            end else begin
              NYLOOPEND = 1'b0;
            end
            if (((INITIALIZING == 1'b0) && (NXLOOPEND == 1'b1) && (NYLOOPEND == 1'b1))) begin
              STATE <= STEXECEND;
            end else begin
              // COMMAND NOT YET FINISHED OR COMMAND INITIALIZING. DETERMINE NEXT/FIRST STEP
              // COLOR MUST BE (RE-)MASKED, JUST IN CASE THAT SCREENMODE WAS CHANGED
              CLR <= CLR & COLMASK;
              case (CMR[7:4])
                HMMC: begin
                  STATE <= STRDCPU;
                end
                YMMM: begin
                  STATE <= STRDVRAM;
                end
                HMMM: begin
                  STATE <= STRDVRAM;
                end
                HMMV: begin
                  VRAMWRDATA <= CLR;
                  STATE <= STWRVRAM;
                end
                LMMC: begin
                  STATE <= STRDCPU;
                end
                LMCM: begin
                  STATE <= STWAITCPU;
                end
                LMMM: begin
                  STATE <= STRDVRAM;
                end
                LMMV, LINE, PSET: begin
                  VRAMWRDATA <= CLR;
                  STATE <= STPRERDVRAM;
                end
                SRCH: begin
                  STATE <= STRDVRAM;
                end
                POINT: begin
                  STATE <= STRDVRAM;
                end
                default: begin
                  STATE <= STEXECEND;
                end
              endcase
            end
            if (((INITIALIZING == 1'b0) && (NXLOOPEND == 1'b1))) begin
              NXTMP <= NXCOUNT;
              if (CMR[7:4] == YMMM) begin
                SXTMP <= {2'b00, DX};
              end else begin
                SXTMP <= {2'b00, SX};
              end
              DXTMP <= {1'b0, DX};
              NY <= NY - 1;
              if ((CMR[5] != CMR[4])) begin
                // BIT5 /= BIT4 IS TRUE FOR COMMANDS YMMM, HMMM, LMCM, LMMM
                SY <= SY + YCOUNTDELTA;
              end
              if ((CMR[7:4] != LMCM)) begin
                DY <= DY + YCOUNTDELTA;
              end
            end else begin
              SXTMP[10] <= 1'b0;
            end
            INITIALIZING = 1'b0;  // STATE == STCHKLOOP
          end
          default: begin
            STATE <= STIDLE;
            CE <= 1'b0;
            CMR <= {8{1'b0}};
          end
        endcase
      end

      if ((VDPMODEGRAPHIC4 == 1'b1)) begin
        VRAMACCESSADDR <= {VDPVRAMACCESSY[9:0], VDPVRAMACCESSX[7:1]};

      end else if ((VDPMODEGRAPHIC5 == 1'b1)) begin
        VRAMACCESSADDR <= {VDPVRAMACCESSY[9:0], VDPVRAMACCESSX[8:2]};

      end else if ((VDPMODEGRAPHIC6 == 1'b1)) begin
        VRAMACCESSADDR <= {VDPVRAMACCESSY[8:0], VDPVRAMACCESSX[8:1]};

      end else begin
        VRAMACCESSADDR <= {VDPVRAMACCESSY[8:0], VDPVRAMACCESSX[7:0]};
      end
    end
  end


endmodule
