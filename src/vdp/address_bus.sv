module ADDRESS_BUS #(
) (
    input bit          CLK21M,
    input bit          RESET,
    input bit   [ 1:0] DOTSTATE,
    input bit          PREWINDOW,
    input bit          REG_R1_DISP_ON,
    input bit   [ 2:0] EIGHTDOTSTATE,
    input bit          TXVRAMREADEN,
    input bit          PREWINDOW_X,
    input bit          PREWINDOW_Y_SP,
    input bit          SPVRAMACCESSING,
    input bit          TEXT_MODE,               // TEXT MODE 1, 2 or 1Q
    input bit          VDPMODETEXT1,            // TEXT MODE 1      (SCREEN0 WIDTH 40)
    input bit          VDPMODETEXT1Q,           // TEXT MODE 1      (??)
    input bit          VDPMODEMULTI,            // MULTICOLOR MODE  (SCREEN3)
    input bit          VDPMODEMULTIQ,           // MULTICOLOR MODE  (??)
    input bit          VDPMODEGRAPHIC1,         // GRAPHIC MODE 1   (SCREEN1)
    input bit          VDPMODEGRAPHIC2,         // GRAPHIC MODE 2   (SCREEN2)
    input bit          VDPMODEGRAPHIC3,         // GRAPHIC MODE 2   (SCREEN4)
    input bit          VDPMODEGRAPHIC4,         // GRAPHIC MODE 4   (SCREEN5)
    input bit          VDPMODEGRAPHIC5,         // GRAPHIC MODE 5   (SCREEN6)
    input bit          VDPMODEGRAPHIC6,         // GRAPHIC MODE 6   (SCREEN7)
    input bit          VDPMODEGRAPHIC7,         // GRAPHIC MODE 7   (SCREEN8,10,11,12)
    input bit          VDPMODEISHIGHRES,        // TRUE WHEN MODE GRAPHIC5, 6
    input bit   [ 7:0] VDPVRAMACCESSDATA,
    input bit          VDPVRAMADDRSETREQ,
    input bit   [16:0] VDPVRAMACCESSADDRTMP,
    input bit          VDPVRAMWRREQ,
    input bit          VDPVRAMRDREQ,
    input bit          VDP_COMMAND_ACTIVE,
    input bit          vdp_cmd_vram_wr_req,
    input bit   [ 1:0] vdp_cmd_vram_wr_size,
    input bit          VDPCMDVRAMRDREQ,
    input bit          VDPVRAMREADINGA,
    input bit          VDPCMDVRAMRDACK,
    input bit   [16:0] VDPCMDVRAMACCESSADDR,
    input bit   [ 7:0] VDP_CMD_VRAM_WR_DATA_8,
    input bit   [16:0] PRAMADRT12,
    input bit   [31:0] VDPCMDVRAMWRDATA_32,
    input bit   [15:0] VDPCMDVRAMWRDATA_16,
    input bit   [16:0] PRAMADRSPRITE,
    input bit   [16:0] PRAMADRG123M,
    input bit   [16:0] PRAMADRG4567,
    input bit          VDPCMDVRAMREADINGA,
    input logic [16:0] super_vram_addr,
    input bit          vdp_super,
    input bit          super_color,
    input bit          super_mid,

    input bit super_res_drawing,

    output bit        vdp_cmd_vram_wr_ack,
    output bit        VDPCMDVRAMREADINGR,
    output bit        VDP_COMMAND_DRIVE,
    output bit [16:0] IRAMADR,
    output bit [ 7:0] PRAMDBO_8,
    output bit        PRAMWE_N,
    output bit [ 1:0] PRAM_RD_SIZE,
    output bit [ 1:0] PRAM_WR_SIZE,
    output bit        VDPVRAMREADINGR,
    output bit        VDPVRAMRDACK,
    output bit        VDPVRAMWRACK,
    output bit        VDPVRAMADDRSETACK,

    output logic [31:0] PRAMDBO_32,
    output logic [15:0] PRAMDBO_16
);

  localparam VRAM_ACCESS_IDLE = 0;
  localparam VRAM_ACCESS_DRAW = 1;
  localparam VRAM_ACCESS_CPUW = 2;
  localparam VRAM_ACCESS_CPUR = 3;
  localparam VRAM_ACCESS_SPRT = 4;
  localparam VRAM_ACCESS_VDPW = 5;
  localparam VRAM_ACCESS_VDPR = 6;
  localparam VRAM_ACCESS_VDPS = 7;

  bit [16:0] VDPVRAMACCESSADDR;

  always_ff @(posedge RESET, posedge CLK21M) begin : P1
    bit [16:0] VDPVRAMACCESSADDRV;
    bit [31:0] VRAMACCESSSWITCH;

    if ((RESET == 1'b1)) begin
      IRAMADR <= {17{1'b1}};
      PRAMDBO_8 <= {8{1'bZ}};
      PRAMWE_N <= 1'b1;
      PRAM_RD_SIZE <= `MEMORY_WIDTH_16;
      PRAM_WR_SIZE <= `MEMORY_WIDTH_8;
      VDPVRAMREADINGR <= 1'b0;
      VDPVRAMRDACK <= 1'b0;
      VDPVRAMWRACK <= 1'b0;
      VDPVRAMADDRSETACK <= 1'b0;
      VDPVRAMACCESSADDR <= {17{1'b0}};
      vdp_cmd_vram_wr_ack <= 1'b0;
      VDPCMDVRAMREADINGR <= 1'b0;
      VDP_COMMAND_DRIVE <= 1'b0;
    end else begin
      // MAIN STATE
      //----------------------------------------
      //
      // VRAM ACCESS ARBITER.
      //
      // (The VRAM access timing is controlled by EIGHTDOTSTATE)
      if (DOTSTATE == 2'b10) begin

        if (vdp_super && super_res_drawing && REG_R1_DISP_ON) begin
          VRAMACCESSSWITCH = VRAM_ACCESS_DRAW;

        end else if(!vdp_super && ((PREWINDOW && REG_R1_DISP_ON) && (EIGHTDOTSTATE == 3'b000 || EIGHTDOTSTATE == 3'b001 || EIGHTDOTSTATE == 3'b010 || EIGHTDOTSTATE == 3'b011 || EIGHTDOTSTATE == 3'b100))) begin
          //EIGHTDOTSTATE is 0 to 4, and displayed
          VRAMACCESSSWITCH = VRAM_ACCESS_DRAW;

        end else if (~vdp_super && (PREWINDOW && REG_R1_DISP_ON && TXVRAMREADEN)) begin
          // EIGHTDOTSTATE is 5 to 7, and displayed, and it is in text mode
          VRAMACCESSSWITCH = VRAM_ACCESS_DRAW;

        end else if (((PREWINDOW_X == 1'b1) && (PREWINDOW_Y_SP == 1'b1) && (SPVRAMACCESSING == 1'b1) && (EIGHTDOTSTATE == 3'b101) && (TEXT_MODE == 1'b0))) begin
          // FOR SPRITE Y-TESTING
          VRAMACCESSSWITCH = VRAM_ACCESS_SPRT;

        end else if(((PREWINDOW_X == 1'b0) && (PREWINDOW_Y_SP == 1'b1) && (SPVRAMACCESSING == 1'b1) && (TEXT_MODE == 1'b0) && ((EIGHTDOTSTATE == 3'b000) || (EIGHTDOTSTATE == 3'b001) || (EIGHTDOTSTATE == 3'b010) || (EIGHTDOTSTATE == 3'b011) || (EIGHTDOTSTATE == 3'b100) || (EIGHTDOTSTATE == 3'b101)))) begin
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
            if ((vdp_cmd_vram_wr_req != vdp_cmd_vram_wr_ack)) begin
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
        //DOTSTATE != 2'b10
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
        PRAMDBO_8 <= VDPVRAMACCESSDATA;
        PRAMWE_N <= 1'b0;
        PRAM_WR_SIZE <= `MEMORY_WIDTH_8;  //write an 8 bit value
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
        PRAMDBO_8 <= 8'bZ;
        PRAMDBO_32 <= 32'bZ;
        PRAMDBO_16 <= 16'bZ;
        PRAMWE_N <= 1'b1;
        PRAM_RD_SIZE <= `MEMORY_WIDTH_16;  // I think this only reads a single 8 bit value for the 16bit word
        VDPVRAMRDACK <= ~VDPVRAMRDACK;
        VDPVRAMREADINGR <= ~VDPVRAMREADINGA;

      end else if ((VRAMACCESSSWITCH == VRAM_ACCESS_VDPW)) begin
        IRAMADR <= VDPCMDVRAMACCESSADDR;
        PRAMDBO_8 <= VDP_CMD_VRAM_WR_DATA_8;
        PRAMDBO_16 <= VDPCMDVRAMWRDATA_16;
        PRAMDBO_32 <= VDPCMDVRAMWRDATA_32;
        PRAMWE_N <= 1'b0;
        PRAM_WR_SIZE <= vdp_cmd_vram_wr_size;

        vdp_cmd_vram_wr_ack <= ~vdp_cmd_vram_wr_ack;

      end else if ((VRAMACCESSSWITCH == VRAM_ACCESS_VDPR)) begin
        IRAMADR <= VDPCMDVRAMACCESSADDR;
        PRAMDBO_8 <= 8'bZ;
        PRAMDBO_32 <= 32'bZ;
        PRAMDBO_16 <= 16'bZ;
        PRAMWE_N <= 1'b1;
        PRAM_RD_SIZE <= `MEMORY_WIDTH_16;  // I think this only reads a single 8 bit value for the 16bit word
        VDPCMDVRAMREADINGR <= ~VDPCMDVRAMREADINGA;

      end else if ((VRAMACCESSSWITCH == VRAM_ACCESS_SPRT)) begin
        // VRAM READ BY SPRITE MODULE
        IRAMADR <= PRAMADRSPRITE;
        PRAMWE_N <= 1'b1;
        PRAM_RD_SIZE <= `MEMORY_WIDTH_16;
        PRAMDBO_8 <= 8'bZ;
        PRAMDBO_16 <= 8'bZ;
        PRAMDBO_32 <= 32'bZ;

      end else begin
        // VRAM_ACCESS_DRAW
        // VRAM READ FOR SCREEN DRAWING

        if (vdp_super) begin
          IRAMADR <= super_vram_addr;
          PRAMDBO_8 <= 8'bZ;
          PRAMDBO_16 <= 8'bZ;
          PRAMDBO_32 <= 32'bZ;
          PRAMWE_N <= 1'b1;

          if (super_color) begin
            PRAM_RD_SIZE <= `MEMORY_WIDTH_32;
          end else begin
            PRAM_RD_SIZE <= `MEMORY_WIDTH_16;
          end


        end else begin

          case (DOTSTATE)
            2'b10: begin
              PRAMDBO_8 <= 8'bZ;
              PRAMDBO_32 <= 32'bZ;
              PRAMWE_N <= 1'b1;
              PRAM_RD_SIZE <= `MEMORY_WIDTH_16;
              if ((TEXT_MODE == 1'b1)) begin
                IRAMADR <= PRAMADRT12;
              end else if (((VDPMODEGRAPHIC1 == 1'b1) || (VDPMODEGRAPHIC2 == 1'b1) || (VDPMODEGRAPHIC3 == 1'b1) || (VDPMODEMULTI == 1'b1) || (VDPMODEMULTIQ == 1'b1))) begin
                IRAMADR <= PRAMADRG123M;
              end else if (((VDPMODEGRAPHIC4 == 1'b1) || (VDPMODEGRAPHIC5 == 1'b1) || (VDPMODEGRAPHIC6 == 1'b1) || (VDPMODEGRAPHIC7 == 1'b1))) begin
                IRAMADR <= PRAMADRG4567;
              end
            end
            2'b01: begin
              PRAMDBO_8 <= 8'bZ;
              PRAMDBO_32 <= 32'bZ;
              PRAMWE_N <= 1'b1;
              PRAM_RD_SIZE <= `MEMORY_WIDTH_16;
              if (((VDPMODEGRAPHIC6 == 1'b1) || (VDPMODEGRAPHIC7 == 1'b1))) begin
                IRAMADR <= PRAMADRG4567;
              end
            end
            default: begin
            end
          endcase
        end

        if (((DOTSTATE == 2'b11) && (VDPVRAMADDRSETREQ != VDPVRAMADDRSETACK))) begin
          VDPVRAMACCESSADDR <= VDPVRAMACCESSADDRTMP;
          VDPVRAMADDRSETACK <= ~VDPVRAMADDRSETACK;
        end
      end
    end
  end

endmodule
