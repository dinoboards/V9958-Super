`define DISPLAYED_PIXEL_WIDTH 720
`define DISPLAYED_PIXEL_HEIGHT PIXEL_HEIGHT(pal_mode)

module VDP_SUPER_RES (
    input bit reset,
    input bit clk,
    input bit vdp_super,
    input bit super_mid,
    input bit super_res,
    input bit [10:0] cx,
    input bit [9:0] cy,
    input bit pal_mode,
    input bit REG_R1_DISP_ON,

    input bit [31:0] vrm_32,

    output bit [7:0] PALETTE_ADDR2,
    input  bit [7:0] PALETTE_DATA_R2_OUT,
    input  bit [7:0] PALETTE_DATA_G2_OUT,
    input  bit [7:0] PALETTE_DATA_B2_OUT,

    output logic [16:0] super_res_vram_addr,
    output bit [7:0] high_res_red,
    output bit [7:0] high_res_green,
    output bit [7:0] high_res_blue,
    output bit super_res_drawing
);

  import custom_timings::*;

  bit odd_phase;
  bit [31:0] current_vram_data;
  bit [31:0] next_vram_data;
  bit super_high_res_visible_x;
  bit super_high_res_visible_y;
  bit last_line;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer
  bit super_res_visible;
  bit [7:0] line_buffer[360];
  bit [8:0] line_buffer_index;

  assign high_res_red = PALETTE_DATA_R2_OUT;
  assign high_res_green = PALETTE_DATA_G2_OUT;
  assign high_res_blue = PALETTE_DATA_B2_OUT;

  assign super_res_visible = super_high_res_visible_x & super_high_res_visible_y;
  assign active_line = (super_mid && cy[0] == 0) || super_res;
  assign last_line = cy == (FRAME_HEIGHT(pal_mode) - 1);

  // cx > 720 and cx < 840 - turn on @700, off @ 180
  // cy > 620 and cy < 576

  bit super_res_drawing_x;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_res_drawing_x <= 0;
    end else begin
      if (cx == 840) super_res_drawing_x <= 1;
      else if (cx == 720) super_res_drawing_x <= 0;
    end
  end

  bit super_res_drawing_y;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_res_drawing_y <= 0;
    end else begin
      if (cy == 620) super_res_drawing_y <= 1;
      else if (cy == 576) super_res_drawing_y <= 0;
    end
  end

  assign super_res_drawing = (super_res_drawing_x & super_res_drawing_y && active_line);

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_high_res_visible_x <= 0;
    end else begin
      if (cx == FRAME_WIDTH(pal_mode) - 1) super_high_res_visible_x <= 1;
      else if (cx == `DISPLAYED_PIXEL_WIDTH - 1) super_high_res_visible_x <= 0;
    end
  end

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_high_res_visible_y <= 0;
    end else begin
      if (cx == (FRAME_WIDTH(pal_mode) - 1) && last_line) super_high_res_visible_y <= 1;
      else if (cy == (`DISPLAYED_PIXEL_HEIGHT - 1) && cx == (`DISPLAYED_PIXEL_WIDTH)) super_high_res_visible_y <= 0;
    end
  end

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_res_vram_addr <= 0;
      next_vram_data <= '{default: 0};
      current_vram_data <= '{default: 0};
      line_buffer_index <= 0;
      odd_phase <= 0;

    end else begin
      case (cx)
        720: begin  //(DL)
          if (last_line) begin
            super_res_vram_addr <= 0;
          end
        end

        //721: super_res_vram_addr will be latched into VRAM access by `ADDRESS_BUS

        722: begin
          line_buffer_index <= 0;
        end

        //723 VRAM refreshing

        724: begin  // cycle cx[1:0] == 0
          if (last_line) begin
            super_res_vram_addr <= 1;
          end
        end

        725: begin  //cycle cx[1:0] == 1
          // super_res_vram_addr will be latched into VRAM access by `ADDRESS_BUS
          if (last_line) begin
            next_vram_data <= vrm_32;
          end
        end

        726: begin  //cycle cx[1:0] == 2
        end

        727: begin  //cycle cx[1:0] == 2
          //LOAD PALETTE_ADDR2 for first pixel of each row
          if (super_res) begin
            PALETTE_ADDR2 <= next_vram_data[3:0];
          end else begin
            if (!active_line || last_line) begin
              PALETTE_ADDR2 <= next_vram_data[7:0];
              line_buffer[line_buffer_index] <= next_vram_data[7:0];
            end else begin
              PALETTE_ADDR2 <= line_buffer[line_buffer_index];
            end
            line_buffer_index <= 9'(line_buffer_index + 1);
            odd_phase <= 0;
          end
        end

        default begin
          if (~super_res_visible) begin
            current_vram_data <= {8'd0, 8'd0, 8'd0, 8'd0};

          end else begin
            if (super_mid) begin
              case ({
                odd_phase, cx[1:0]
              })
                3'b000: begin
                  if (active_line) begin
                    current_vram_data   <= REG_R1_DISP_ON ? next_vram_data : 0;
                    super_res_vram_addr <= 17'(super_res_vram_addr + 1);
                  end
                end
                3'b001: begin
                  if (active_line) begin
                    PALETTE_ADDR2 <= next_vram_data[15:8];
                    line_buffer[line_buffer_index] <= next_vram_data[15:8];
                    next_vram_data <= vrm_32;  //load next 4 bytes
                  end else begin
                    PALETTE_ADDR2 <= line_buffer[line_buffer_index];
                  end
                  line_buffer_index <= 9'(line_buffer_index + 1);
                end
                3'b010: begin
                end
                3'b011: begin
                  if (active_line) begin
                    PALETTE_ADDR2 <= current_vram_data[23:16];
                    line_buffer[line_buffer_index] <= current_vram_data[23:16];
                  end else begin
                    PALETTE_ADDR2 <= line_buffer[line_buffer_index];
                  end
                  line_buffer_index <= 9'(line_buffer_index + 1);
                  odd_phase <= 1;
                end
                3'b100: begin
                end
                3'b101: begin
                  if (active_line) begin
                    PALETTE_ADDR2 <= current_vram_data[31:24];
                    line_buffer[line_buffer_index] <= current_vram_data[31:24];
                  end else begin
                    PALETTE_ADDR2 <= line_buffer[line_buffer_index];
                  end
                  line_buffer_index <= 9'(line_buffer_index + 1);
                end
                3'b110: begin
                end
                3'b111: begin
                  if (active_line) begin
                    PALETTE_ADDR2 <= next_vram_data[7:0];
                    line_buffer[line_buffer_index] <= next_vram_data[7:0];
                  end else begin
                    PALETTE_ADDR2 <= line_buffer[line_buffer_index];
                  end
                  line_buffer_index <= 9'(line_buffer_index + 1);
                  odd_phase <= 0;
                end
              endcase
            end else if (super_res) begin
              case (cx[1:0])
                // During clock cycle 0:
                //   super_res: PALETTE_ADDR2 is loaded pixel indexes [1, 5, 9, 13, ...]
                0: begin
                  current_vram_data <= REG_R1_DISP_ON ? next_vram_data : 0;
                  PALETTE_ADDR2 <= next_vram_data[15:8];
                  super_res_vram_addr <= 17'(super_res_vram_addr + 1);
                end

                // During clock cycle 1:
                //   super_res: PALETTE_ADDR2 is loaded pixel indexes [2, 6, 10, 14, ...]
                // Request for next double word is initiated at during this clock cycle (next_vram_data)
                1: begin
                  PALETTE_ADDR2  <= current_vram_data[23:16];
                  next_vram_data <= vrm_32;  //load next 4 bytes
                end

                // During clock cycle 2:
                //   super_res: PALETTE_ADDR2 is loaded pixel indexes [3, 7, 11, 15, ...]
                2: begin
                  PALETTE_ADDR2 <= current_vram_data[31:24];
                end

                // During clock cycle 3:
                //   super_res: PALETTE_ADDR2 is loaded pixel indexes [4, 8, 12, 16, ...]
                3: begin
                  PALETTE_ADDR2 <= next_vram_data[7:0];
                end
              endcase
            end
          end
        end
      endcase
    end
  end

endmodule
