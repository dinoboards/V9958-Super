//
//  converted from vdp_command.vhd
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

`include "..\features.vh"

module VDP_COMMAND (
    input bit reset,
    input bit clk,
    input bit mode_graphic_4,
    input bit mode_graphic_5,
    input bit mode_graphic_6,
    input bit mode_graphic_7,
    input bit mode_high_res,
    input bit vram_wr_ack,
    input bit vram_rd_ack,
    input bit [7:0] vram_rd_data,
    input bit reg_wr_req,
    input bit tr_clr_req,
    input bit [3:0] reg_num,
    input bit [7:0] reg_data,

    output bit p_reg_wr_ack,
    output bit p_tr_clr_ack,
    output bit vram_wr_req,
    output bit p_vram_rd_req,
    output bit [19:0] p_vram_access_addr,
    output bit [7:0] p_vram_wr_data_8,
    output bit [7:0] p_clr,
    output bit p_ce,
    output bit p_bd,
    output bit p_tr,
    output bit [10:0] p_sx_tmp,
    output bit [7:4] current_command

`ifdef ENABLE_SUPER_RES
    ,
    input bit mode_graphic_super_mid,
    input bit mode_graphic_super_mid2,
    input bit mode_graphic_super_res,
    input bit[9:0] view_port_width,
    input bit pal_mode,
    input bit[16:0] ext_reg_super_res_page_command_addr

`endif
);

  // R44, S#7
  // S#2 (BIT 0)
  // S#2 (BIT 4)
  // S#2 (BIT 7)
  // S#8, S#9

  // VDP COMMAND SIGNALS - CAN BE SET BY CPU
  bit [ 9:0] SX;  // R33,32
  bit [ 10:0] SY;  // R35,34
  bit [ 9:0] DX;  // R37,36
  bit [ 10:0] DY;  // R39,38
  bit [ 9:0] NX;  // R41,40
  bit [ 10:0] NY;  // R43,42
  bit        MM;  // R45 BIT 0
  bit        EQ;  // R45 BIT 1
  bit        DIX;  // R45 BIT 2
  bit        DIY;  // R45 BIT 3

  bit [ 7:0] CMR;  // R46

  // VDP COMMAND SIGNALS - INTERNAL REGISTERS
  bit [ 9:0] dx_tmp;
  bit [ 9:0] nx_tmp;
  bit        reg_wr_ack;
  bit        tr_clr_ack;
  bit        cmr_wr;

  // VDP COMMAND SIGNALS - COMMUNICATION BETWEEN COMMAND PROCESSOR
  // AND MEMORY INTERFACE (WHICH IS IN THE COLOR GENERATOR)
  bit        internal_vram_wr_req;
  bit        vram_rd_req;
  bit [19:0] vram_access_addr;
  bit [ 7:0] vram_wr_data_8;
  bit [15:0] vram_wr_data_16;
  bit [31:0] vram_wr_data_32;
  bit [ 7:0] CLR;  // R44, S#7

  // VDP COMMAND SIGNALS - CAN BE READ BY CPU
  bit        CE;  // S#2 (BIT 0)
  bit        BD;  // S#2 (BIT 4)
  bit        TR;  // S#2 (BIT 7)
  bit [10:0] sx_tmp;  // S#8, S#9
  bit        cmd_enable;  // VDP COMMAND state REGISTER

  //??
  bit [ 1:0] rd_x_low;
  bit [ 10:0] vram_access_y;
  bit [ 9:0] vram_access_x;

  typedef enum logic [3:0] {
    IDLE,
    CHK_LOOP,
    RD_CPU,
    WAIT_CPU,
    RD_VRAM,
    WAIT_RD_VRAM,
    POINT_WAIT_RD_VRAM,
    SRCH_WAIT_RD_VRAM,
    PRE_RD_VRAM,
    WAIT_PRE_RD_VRAM,
    WR_VRAM,
    WAIT_WR_VRAM,
    LINE_NEW_POS,
    LINE_CHK_LOOP,
    SRCH_CHK_LOOP,
    EXEC_END
  } type_state;

  type_state state;

  parameter HMMC = 4'b1111;  //CPU to VRAM
  parameter YMMM = 4'b1110;  //VRAM to VRAM y only
  parameter HMMM = 4'b1101;  //VRAM to VRAM
  parameter HMMV = 4'b1100;  //VDP to VRAM
  parameter LMMC = 4'b1011;  //Logical CPU to VRAM
  parameter LMCM = 4'b1010;  //Logical VRAM to CPU
  parameter LMMM = 4'b1001;  //Logical VRAM to VRAM
  parameter LMMV = 4'b1000;  //Logical VDP to VRAM
  parameter LINE = 4'b0111;  //Draw line
  parameter SRCH = 4'b0110;  //search
  parameter PSET = 4'b0101;  //pset apply logical operation to pixel
  parameter POINT = 4'b0100;  //point retrieve colour of pixel
  parameter STOP = 4'b0000;  //stop

  parameter IMPB210 = 3'b000;  //IMP DC=SC
  parameter ANDB210 = 3'b001;  //AND DC=SC AND DC
  parameter ORB210 = 3'b010;  //OR DC=SC OR DC
  parameter EORB210 = 3'b011;  //XOR DC=SC XOR DC
  parameter NOTB210 = 3'b100;  //NOT DC=SC NOT DC

  assign p_reg_wr_ack = reg_wr_ack;
  assign p_tr_clr_ack = tr_clr_ack;
  assign vram_wr_req = cmd_enable ? internal_vram_wr_req : vram_wr_ack;
  assign p_vram_rd_req = vram_rd_req;
  assign p_vram_access_addr = vram_access_addr;
  assign p_vram_wr_data_8 = vram_wr_data_8;
  assign p_clr = CLR;
  assign p_ce = CE;
  assign p_bd = BD;
  assign p_tr = TR;
  assign p_sx_tmp = sx_tmp;
  assign current_command = CMR[7:4];

`ifdef ENABLE_SUPER_RES
  assign cmd_enable = mode_graphic_4 | mode_graphic_5 | mode_graphic_6 | mode_graphic_7 | mode_graphic_super_mid | mode_graphic_super_res;
`else
  assign cmd_enable = mode_graphic_4 | mode_graphic_5 | mode_graphic_6 | mode_graphic_7;
`endif

  bit graphic_4_or_6;
  assign graphic_4_or_6 = mode_graphic_4 || mode_graphic_6;

  bit [9:0] NXCOUNT;
  assign NXCOUNT = CMR[7:6] == 2'b11 && graphic_4_or_6 ? {1'b0, NX[9:1]} :
                   CMR[7:6] == 2'b11 && mode_graphic_5 ? {2'b00, NX[9:2]} :
                   NX;

  bit [10:0] YCOUNTDELTA;
  assign YCOUNTDELTA = (DIY == 1'b0) ? 11'b0000000001 : 11'b11111111111;

  bit [1:0] MAXXMASK;
  assign MAXXMASK = mode_high_res ? 2'b10 : 2'b01;  // GRAPHIC 5,6

  bit [ 7:0] RDPOINT;
  always_comb begin
    // RETRIEVE THE 'POINT' OUT OF THE BYTE THAT WAS MOST RECENTLY READ
    if (graphic_4_or_6) begin
      RDPOINT = rd_x_low[0] ? {4'b0000, vram_rd_data[3:0]} : {4'b0000, vram_rd_data[7:4]};

    end else if (mode_graphic_5) begin
      case (rd_x_low)
        2'b00: RDPOINT = {6'b000000, vram_rd_data[7:6]};
        2'b01: RDPOINT = {6'b000000, vram_rd_data[5:4]};
        2'b10: RDPOINT = {6'b000000, vram_rd_data[3:2]};
        2'b11: RDPOINT = {6'b000000, vram_rd_data[1:0]};
      endcase
    end else begin
      RDPOINT = vram_rd_data;
    end
  end

  bit [7:0] COLMASK;
  always_comb begin
    case (CMR[7:6])
      2'b11: begin  //commands: HMMC, YMMM, HMMM, HMMV
        COLMASK = 8'b11111111;
      end

      default: begin
        if (graphic_4_or_6) begin
          COLMASK = 8'b00001111;
        end else if (mode_graphic_5) begin
          COLMASK = 8'b00000011;
        end else begin
          COLMASK = 8'b11111111;
        end
      end
    endcase
  end


  bit [7:0] logical_operation_dest_colour;
  always_comb begin
    // PERFORM LOGICAL OPERATION ON MOST RECENTLY READ POINT AND
    // ON THE POINT TO BE WRITTEN.
    // original 8 bit operations
    if (((CMR[3] == 1'b0) || ((vram_wr_data_8 & COLMASK) != 8'b00000000))) begin
      case (CMR[2:0])
        IMPB210: logical_operation_dest_colour = vram_wr_data_8 & COLMASK;
        ANDB210: logical_operation_dest_colour = (vram_wr_data_8 & COLMASK) & RDPOINT;
        ORB210:  logical_operation_dest_colour = (vram_wr_data_8 & COLMASK) | RDPOINT;
        EORB210: logical_operation_dest_colour = (vram_wr_data_8 & COLMASK) ^ RDPOINT;
        NOTB210: logical_operation_dest_colour = ~(vram_wr_data_8 & COLMASK);
        default: logical_operation_dest_colour = RDPOINT;
      endcase

    end else begin
      logical_operation_dest_colour = RDPOINT;
    end
  end

  bit nx_loop_end;

  always_comb begin
    // DETERMINE IF X-LOOP IS FINISHED
    case (CMR[7:4])
      LINE: begin
`ifdef ENABLE_SUPER_RES
        if (mode_graphic_super_mid || mode_graphic_super_res) begin
          nx_loop_end = (nx_tmp == NX) || dx_tmp == view_port_width;
        end else begin
`endif
          nx_loop_end = (nx_tmp == NX) || ((dx_tmp[9:8] & MAXXMASK) == MAXXMASK);
`ifdef ENABLE_SUPER_RES
        end
`endif
      end

      HMMV, HMMC, LMMV, LMMC: begin
`ifdef ENABLE_SUPER_RES
        if (mode_graphic_super_mid || mode_graphic_super_res) begin
          nx_loop_end = (nx_tmp == 0) || dx_tmp == view_port_width;
        end else begin
`endif
          nx_loop_end = (nx_tmp == 0) || ((dx_tmp[9:8] & MAXXMASK) == MAXXMASK);
`ifdef ENABLE_SUPER_RES
        end
`endif
      end

      YMMM: begin
        nx_loop_end = (dx_tmp[9:8] & MAXXMASK) == MAXXMASK;
      end

      HMMM, LMMM: begin
`ifdef ENABLE_SUPER_RES
        if (mode_graphic_super_mid || mode_graphic_super_res) begin
          nx_loop_end = (nx_tmp == 0) || dx_tmp == view_port_width;
        end else begin
`endif
        nx_loop_end = ((nx_tmp == 0) || ((sx_tmp[9:8] & MAXXMASK) == MAXXMASK) || ((dx_tmp[9:8] & MAXXMASK) == MAXXMASK));
`ifdef ENABLE_SUPER_RES
        end
`endif
      end

      LMCM: begin
        nx_loop_end = ((nx_tmp == 0) || ((sx_tmp[9:8] & MAXXMASK) == MAXXMASK));
      end

      SRCH: begin
        nx_loop_end = ((sx_tmp[9:8] & MAXXMASK) == MAXXMASK);
      end

      default: begin
        nx_loop_end = 1'b1;
      end
    endcase
  end

  bit [10:0] XCOUNTDELTA;

  always_comb begin
    case (CMR[7:6])
      2'b11: begin
        // BYTE COMMAND
        if (graphic_4_or_6) begin
          XCOUNTDELTA = DIX ? 11'b11111111110  /*-2*/ : 11'b00000000010;  /*+2*/

        end else if (mode_graphic_5) begin
          XCOUNTDELTA = DIX ? 11'b11111111100  /*-4*/ : 11'b00000000100;  /*+4*/

        end else begin
          XCOUNTDELTA = DIX ? 11'b11111111111  /*-1*/ : 11'b00000000001;  /*+1*/
        end
      end

      default: begin
        // DOT COMMAND
        XCOUNTDELTA = DIX ? 11'b11111111111  /*-1*/ : 11'b00000000001;  /*+1*/
      end
    endcase
  end

  always_comb begin
    if (mode_graphic_4) begin
      vram_access_addr = {vram_access_y[9:0], vram_access_x[7:1]};

    end else if (mode_graphic_5) begin
      vram_access_addr = {vram_access_y[9:0], vram_access_x[8:2]};

    end else if (mode_graphic_6) begin
      vram_access_addr = {vram_access_y[8:0], vram_access_x[8:1]};

`ifdef ENABLE_SUPER_RES
    end else if (mode_graphic_super_mid || mode_graphic_super_res) begin
      // Calculate the address of a given pixel for super res modes
      vram_access_addr = 20'((vram_access_y * view_port_width) + (vram_access_x)) + {ext_reg_super_res_page_command_addr, 2'b00};

`endif

    end else begin
      vram_access_addr = {vram_access_y[8:0], vram_access_x[7:0]};
    end
  end

  always @(posedge reset, posedge clk) begin
    bit initializing;
    bit dy_end;
    bit sy_end;
    bit ny_loop_end;
    bit [9:0] nx_minus_one;
    bit srch_eq_result;

    if (reset) begin
      state                <= IDLE;
      initializing         <= 0;
      rd_x_low             <= 0;
      SX                   <= 0;  // R32
      SY                   <= 0;  // R34
      DX                   <= 0;  // R36
      DY                   <= 0;  // R38
      NX                   <= 0;  // R40
      NY                   <= 0;  // R42
      CLR                  <= 0;  // R44
      MM                   <= 0;  // R45 BIT 0
      EQ                   <= 0;  // R45 BIT 1
      DIX                  <= 0;  // R45 BIT 2
      DIY                  <= 0;  // R45 BIT 3
      CMR                  <= 0;  // R46
      sx_tmp               <= 0;
      dx_tmp               <= 0;
      cmr_wr               <= 0;
      reg_wr_ack           <= 0;
      internal_vram_wr_req <= 0;
      vram_rd_req          <= 0;
      vram_wr_data_8       <= 0;
      vram_wr_data_16      <= 0;
      vram_wr_data_32      <= 0;
      TR                   <= 1'b1;  // TRANSFER READY
      CE                   <= 0;  // COMMAND EXECUTING
      BD                   <= 0;  // BORDER COLOR FOUND
      tr_clr_ack           <= 0;
      vram_access_y        <= 0;
      vram_access_x        <= 0;

    end else begin
      // PROCESS REGISTER UPDATE REQUEST, CLEAR 'TRANSFER READY' REQUEST
      // OR PROCESS ANY ONGOING COMMAND.
      if ((reg_wr_req != reg_wr_ack)) begin
        reg_wr_ack <= ~reg_wr_ack;
        case (reg_num)
          4'b0000: SX[7:0] <= reg_data;  // #32
          4'b0001: SX[9:8] <= reg_data[1:0];  // #33
          4'b0010: SY[7:0] <= reg_data;  // #34
`ifdef ENABLE_SUPER_RES
          4'b0011: SY[10:8] <= reg_data[2:0];  // #35
`else
          4'b0011: SY[9:8] <= reg_data[1:0];  // #35
`endif
          4'b0100: DX[7:0] <= reg_data;  // #36
          4'b0101: DX[9:8] <= reg_data[1:0];  // #37
          4'b0110: DY[7:0] <= reg_data;  // #38
`ifdef ENABLE_SUPER_RES
          4'b0111: DY[10:8] <= reg_data[2:0];  // #39
`else
          4'b0111: DY[9:8] <= reg_data[1:0];  // #39
`endif
          4'b1000: NX[7:0] <= reg_data;  // #40
          4'b1001: NX[9:8] <= reg_data[1:0];  // #41
          4'b1010: NY[7:0] <= reg_data;  // #42
`ifdef ENABLE_SUPER_RES
          4'b1011: NY[10:8] <= reg_data[2:0];  // #43
`else
          4'b1011: NY[9:8] <= reg_data[1:0];  // #43
`endif
          4'b1100: begin  // #44
            // DATA IS TRANSFERRED FROM CPU TO VDP COLOR REGISTER
            CLR <= (CE == 1'b1) ? reg_data & COLMASK : reg_data;
            TR  <= 1'b0;
          end
          4'b1101: begin  // #45
            MM  <= reg_data[0];
            EQ  <= reg_data[1];
            DIX <= reg_data[2];
            DIY <= reg_data[3];
          end
          4'b1110: begin  // #46
            // INITIALIZE THE NEW COMMAND
            // NOTE THAT THIS WILL ABORT ANY ONGOING COMMAND!
            CMR <= reg_data;
            cmr_wr <= cmd_enable;
            state <= IDLE;
          end
        endcase

      end else if ((tr_clr_req != tr_clr_ack)) begin
        // reset THE DATA TRANSFER REGISTER (CPU HAS JUST READ THE COLOR REGISTER)
        tr_clr_ack <= ~tr_clr_ack;
        TR <= 1'b0;

      end else begin
        // PROCESS THE VDP COMMAND state
        case (state)
          IDLE: begin
            if (cmr_wr == 1'b0) begin
              CE <= 1'b0;
              CE <= 1'b0;
            end else begin
              // EXEC NEW VDP COMMAND
              cmr_wr <= 1'b0;
              CE <= 1'b1;
              BD <= 1'b0;
              if (CMR[7:4] == LINE) begin
                // LINE COMMAND REQUIRES SPECIAL sx_tmp AND nx_tmp SET-UP
                nx_minus_one = 10'(NX - 1);
                sx_tmp <= {2'b00, nx_minus_one[9:1]};
                nx_tmp <= 0;
              end else begin
                if (CMR[7:4] == YMMM) begin
                  // FOR YMMM, sx_tmp = dx_tmp = DX
                  sx_tmp <= {1'b0, DX};
                end else begin
                  // FOR ALL OTHERS, sx_tmp IS BUSINES AS USUAL
                  sx_tmp <= {1'b0, SX};
                end
                // nx_tmp IS BUSINESS AS USUAL FOR ALL BUT THE LINE COMMAND
                nx_tmp <= NXCOUNT;
              end
              dx_tmp <= DX;
              initializing <= 1'b1;
              state <= CHK_LOOP;
            end
          end

          RD_CPU: begin
            // APPLICABLE TO HMMC, LMMC
            if ((TR == 1'b0)) begin
              // CPU HAS TRANSFERRED DATA TO (OR FROM) THE COLOR REGISTER
              TR <= 1'b1;
              // VDP IS READY TO RECEIVE THE NEXT TRANSFER.
              vram_wr_data_8 <= CLR;
              state <= (CMR[6] == 1'b0) ? PRE_RD_VRAM : WR_VRAM;  // LMMC OR HMMC
            end
          end

          WAIT_CPU: begin
            // APPLICABLE TO LMCM
            if ((TR == 1'b0)) begin
              // CPU HAS TRANSFERRED DATA FROM (OR TO) THE COLOR REGISTER
              // VDP MAY READ THE NEXT VALUE INTO THE COLOR REGISTER
              state <= RD_VRAM;
            end
          end

          RD_VRAM: begin
            // APPLICABLE TO YMMM, HMMM, LMCM, LMMM, SRCH, POINT
            vram_access_y <= SY;
            vram_access_x <= sx_tmp[9:0];
            rd_x_low <= sx_tmp[1:0];
            vram_rd_req <= ~vram_rd_ack;
            case (CMR[7:4])
              POINT: begin
                state <= POINT_WAIT_RD_VRAM;
              end
              SRCH: begin
                state <= SRCH_WAIT_RD_VRAM;
              end
              default: begin
                state <= WAIT_RD_VRAM;
              end
            endcase
          end

          POINT_WAIT_RD_VRAM: begin
            // APPLICABLE TO POINT
            if (vram_rd_req == vram_rd_ack) begin
              CLR   <= RDPOINT;
              state <= EXEC_END;
            end
          end

          SRCH_WAIT_RD_VRAM: begin
            // APPLICABLE TO SRCH
            if (vram_rd_req == vram_rd_ack) begin
              if (RDPOINT == CLR) begin
                srch_eq_result = 1'b0;
              end else begin
                srch_eq_result = 1'b1;
              end
              if ((EQ == srch_eq_result)) begin
                BD <= 1'b1;
                state <= EXEC_END;
              end else begin
                sx_tmp <= 10'(sx_tmp + XCOUNTDELTA);
                state  <= SRCH_CHK_LOOP;
              end
            end
          end

          WAIT_RD_VRAM: begin
            // APPLICABLE TO YMMM, HMMM, LMCM, LMMM
            if ((vram_rd_req == vram_rd_ack)) begin
              sx_tmp <= 10'(sx_tmp + XCOUNTDELTA);
              case (CMR[7:4])
                LMMM: begin
                  vram_wr_data_8 <= RDPOINT;
                  state <= PRE_RD_VRAM;
                end
                LMCM: begin
                  CLR <= RDPOINT;
                  TR <= 1'b1;
                  nx_tmp <= 10'(nx_tmp - 1);
                  state <= CHK_LOOP;
                end
                default: begin
                  // REMAINING: YMMM, HMMM
                  vram_wr_data_8 <= vram_rd_data;
                  state <= WR_VRAM;
                end
              endcase
            end
          end

          PRE_RD_VRAM: begin
            // APPLICABLE TO LMMC, LMMM, LMMV, LINE, PSET
            vram_access_y <= DY;
            vram_access_x <= dx_tmp;
            rd_x_low <= dx_tmp[1:0];
            vram_rd_req <= ~vram_rd_ack;
            state <= WAIT_PRE_RD_VRAM;
          end

          WAIT_PRE_RD_VRAM: begin
            // APPLICABLE TO LMMC, LMMM, LMMV, LINE, PSET
            if (vram_rd_req == vram_rd_ack) begin
              if (graphic_4_or_6) begin
                vram_wr_data_8 = rd_x_low[0] ? {vram_rd_data[7:4], logical_operation_dest_colour[3:0]} : {logical_operation_dest_colour[3:0], vram_rd_data[3:0]};

              end else if (mode_graphic_5) begin
                case (rd_x_low)
                  2'b00: vram_wr_data_8 <= {logical_operation_dest_colour[1:0], vram_rd_data[5:0]};
                  2'b01: vram_wr_data_8 <= {vram_rd_data[7:6], logical_operation_dest_colour[1:0], vram_rd_data[3:0]};
                  2'b10: vram_wr_data_8 <= {vram_rd_data[7:4], logical_operation_dest_colour[1:0], vram_rd_data[1:0]};
                  2'b11: vram_wr_data_8 <= {vram_rd_data[7:2], logical_operation_dest_colour[1:0]};
                endcase
              end else begin
                vram_wr_data_8 <= logical_operation_dest_colour;
              end

              state <= WR_VRAM;
            end
          end

          WR_VRAM: begin
            // APPLICABLE TO HMMC, YMMM, HMMM, HMMV, LMMC, LMMM, LMMV, LINE, PSET
            vram_access_y <= DY;
            vram_access_x <= dx_tmp;
            internal_vram_wr_req <= ~vram_wr_ack;
            state <= WAIT_WR_VRAM;
          end

          WAIT_WR_VRAM: begin
            // APPLICABLE TO HMMC, YMMM, HMMM, HMMV, LMMC, LMMM, LMMV, LINE, PSET
            if ((internal_vram_wr_req == vram_wr_ack)) begin
              case (CMR[7:4])
                PSET: begin
                  state <= EXEC_END;
                end
                LINE: begin
                  sx_tmp <= sx_tmp - NY;
                  if (MM == 1'b0) begin
                    dx_tmp <= 10'(dx_tmp + XCOUNTDELTA[9:0]);
                  end else begin
                    DY <= DY + YCOUNTDELTA;
                  end
                  state <= LINE_NEW_POS;
                end
                default: begin
                  dx_tmp <= 10'(dx_tmp + XCOUNTDELTA[9:0]);
                  nx_tmp <= 10'(nx_tmp - 1);
                  state  <= CHK_LOOP;
                end
              endcase
            end
          end

          LINE_NEW_POS: begin
            // APPLICABLE TO LINE
            if ((sx_tmp[10] == 1'b1)) begin
              sx_tmp <= {1'b0, sx_tmp[9:0] + NX};
              if ((MM == 1'b0)) begin
                DY <= DY + YCOUNTDELTA;
              end else begin
                dx_tmp <= dx_tmp + XCOUNTDELTA[9:0];
              end
            end
            state <= LINE_CHK_LOOP;
          end

          LINE_CHK_LOOP: begin
            // APPLICABLE TO LINE
            if (nx_loop_end) begin
              state <= EXEC_END;
            end else begin
              vram_wr_data_8 <= CLR;
              // COLOR MUST BE RE-MASKED, JUST IN CASE THAT SCREENMODE WAS CHANGED
              CLR <= CLR & COLMASK;
              state <= PRE_RD_VRAM;
            end
            nx_tmp <= 10'(nx_tmp + 1);
          end

          SRCH_CHK_LOOP: begin
            // APPLICABLE TO SRCH
            if (nx_loop_end) begin
              state <= EXEC_END;
            end else begin
              // COLOR MUST BE RE-MASKED, JUST IN CASE THAT SCREENMODE WAS CHANGED
              CLR   <= CLR & COLMASK;
              state <= RD_VRAM;
            end
          end

          CHK_LOOP: begin
            // WHEN initializing = '1':
            //   APPLICABLE TO ALL COMMANDS
            // WHEN initializing = '0':
            //   APPLICABLE TO HMMC, YMMM, HMMM, HMMV, LMMC, LMCM, LMMM, LMMV
            //   DETERMINE ny_loop_end
            dy_end = 1'b0;
            sy_end = 1'b0;
            if (DIY == 1'b1) begin
              if (DY == 0 && CMR[7:4] != LMCM) begin
                dy_end = 1'b1;
              end
              if (SY == 0 && CMR[5] != CMR[4]) begin
                // BIT5 /= BIT4 IS TRUE FOR COMMANDS YMMM, HMMM, LMCM, LMMM
                sy_end = 1'b1;
              end
            end
            if (NY == 1 || dy_end == 1 || sy_end == 1) begin
              ny_loop_end = 1'b1;
            end else begin
              ny_loop_end = 1'b0;
            end
            if (initializing == 0 && nx_loop_end && ny_loop_end) begin
              state <= EXEC_END;
            end else begin
              // COMMAND NOT YET FINISHED OR COMMAND initializing. DETERMINE NEXT/FIRST STEP
              // COLOR MUST BE (RE-)MASKED, JUST IN CASE THAT SCREENMODE WAS CHANGED
              CLR <= CLR & COLMASK;
              case (CMR[7:4])
                HMMC: begin
                  state <= RD_CPU;
                end
                YMMM: begin
                  state <= RD_VRAM;
                end
                HMMM: begin
                  state <= RD_VRAM;
                end
                HMMV: begin
                  vram_wr_data_8 <= CLR;
                  state <= WR_VRAM;
                end
                LMMC: begin
                  state <= RD_CPU;
                end
                LMCM: begin
                  state <= WAIT_CPU;
                end
                LMMM: begin
                  state <= RD_VRAM;
                end
                LMMV, LINE, PSET: begin
                  vram_wr_data_8 <= CLR;
                  state <= PRE_RD_VRAM;
                end
                SRCH: begin
                  state <= RD_VRAM;
                end
                POINT: begin
                  state <= RD_VRAM;
                end
                default: begin
                  state <= EXEC_END;
                end
              endcase
            end
            if ((initializing == 1'b0) && nx_loop_end) begin
              nx_tmp <= NXCOUNT;
              if (CMR[7:4] == YMMM) begin
                sx_tmp <= {1'b0, DX};
              end else begin
                sx_tmp <= {1'b0, SX};
              end
              dx_tmp <= DX;
              NY <= 11'(NY - 1);
              if ((CMR[5] != CMR[4])) begin
                // BIT5 /= BIT4 IS TRUE FOR COMMANDS YMMM, HMMM, LMCM, LMMM
                SY <= SY + YCOUNTDELTA;
              end
              if ((CMR[7:4] != LMCM)) begin
                DY <= DY + YCOUNTDELTA;
              end
            end else begin
              sx_tmp[10] <= 1'b0;
            end
            initializing <= 1'b0;
          end
          default: begin
            state <= IDLE;
            CE <= 0;
            CMR <= 0;
          end
        endcase
      end
    end
  end


endmodule
