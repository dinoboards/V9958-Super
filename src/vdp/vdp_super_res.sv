`define DISPLAYED_PIXEL_WIDTH 720
`define DISPLAYED_PIXEL_HEIGHT PIXEL_HEIGHT(pal_mode)

module VDP_SUPER_RES (
    input bit reset,
    input bit clk,
    input bit vdp_super,
    input bit super_color,
    input bit super_mid,
    input bit super_res,
    input bit [10:0] cx,
    input bit [9:0] cy,
    input bit pal_mode,
    input bit REG_R1_DISP_ON,

    input bit [31:0] vrm_32,

    output bit [3:0] PALETTE_ADDR2,
    input bit[3:0] PALETTE_DATA_R2_OUT,
    input bit[3:0] PALETTE_DATA_G2_OUT,
    input bit[3:0] PALETTE_DATA_B2_OUT,

    output logic [16:0] super_res_vram_addr,
    output bit [7:0] high_res_red,
    output bit [7:0] high_res_green,
    output bit [7:0] high_res_blue,
    output bit super_res_drawing
);

  import custom_timings::*;

  bit [31:0] high_res_data;
  bit [31:0] next_rgb;
  bit super_high_res_visible_x;
  bit super_high_res_visible_y;
  bit last_line;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer
  bit super_res_visible;
  bit [31:0] line_buffer[`MAX_PIXEL_WIDTH];
  bit [7:0] line_buffer_index;

  // pixel format for super_mid: RRRR RGGG GGGB BBBB
  // all red would be            1111 1000 0000 0000 -> 0xF800 (248, 0)
  // all green would be          0000 0111 1110 0000 -> 0x07E0 (7, 224)
  // all blue would be           0000 0000 0001 1111 -> 0x001F (0, 31)

  bit [4:0] high_mid_pixel_red;
  bit [5:0] high_mid_pixel_green;
  bit [4:0] high_mid_pixel_blue;

  assign high_mid_pixel_red = high_res_data[15:11];
  assign high_mid_pixel_green = high_res_data[10:5];
  assign high_mid_pixel_blue = high_res_data[4:0];

  // assign PALETTE_ADDR2 = high_res_data[3:0];

  assign high_res_red = {PALETTE_DATA_R2_OUT, 4'b0};
  assign high_res_green = {PALETTE_DATA_G2_OUT, 4'b0};
  assign high_res_blue = {PALETTE_DATA_B2_OUT, 4'b0};

  // assign high_res_red = {high_res_data[7:5], 5'b0};
  // assign high_res_green = {high_res_data[4:2], 5'b0};
  // assign high_res_blue = {high_res_data[1:0], 6'b0};

  assign super_res_visible = super_high_res_visible_x & super_high_res_visible_y;
  assign active_line = (super_color && cy[1:0] == 2'b00) || (super_mid && cy[0] == 0) || super_res;
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
      next_rgb <= '{default: 0};
      high_res_data <= '{default: 0};
      line_buffer_index <= 0;

    end else begin
      case (cx)
        720: begin  //(DL)
          if (last_line) begin
            super_res_vram_addr <= 0;
          end
        end

        //721: (DA) - super_res_vram_addr will be latched into VRAM access by `ADDRESS_BUS

        722: begin  //(DW)
          line_buffer_index <= 0;
        end

        //723 (FS) VRAM refreshing

        724: begin  //(DL)
          if (last_line) begin
            super_res_vram_addr <= 1;
          end
        end

        725: begin  //(DA)
          // super_res_vram_addr will be latched into VRAM access by `ADDRESS_BUS
          if (last_line) begin
            next_rgb <= vrm_32;
          end
        end

        726: begin  //(DW)
        end

        default begin
          if (~super_res_visible) begin
            high_res_data <= {8'd0, 8'd0, 8'd255, 8'd0};

          end else begin
            case (cx[1:0])
              // During clock cycle 0, the last pixel of the double word is rendered
              0: begin  // (DL)
                if (active_line) begin
                  line_buffer[line_buffer_index] <= REG_R1_DISP_ON ? next_rgb : 0;
                  high_res_data <= REG_R1_DISP_ON ? next_rgb : 0;
                  PALETTE_ADDR2 = REG_R1_DISP_ON ? next_rgb[3:0] : 0; // should move to 3?

                end else begin
                  high_res_data <= line_buffer[line_buffer_index];
                end

                line_buffer_index <= 8'(line_buffer_index + 1);

                if (active_line) begin
                  super_res_vram_addr <= 17'(super_res_vram_addr + 1);
                end

              end

              // During clock cycle 1, the first pixel of the double word is rendered
              // Request for next double word is initiated at during this clock cycle (next_rgb)
              1: begin  // (DA)
                if(super_res) begin
                  high_res_data <= {8'd0, high_res_data[31:8]};
                  PALETTE_ADDR2 = high_res_data[11:8]; //should move to 0
                end
                if (active_line) begin
                  next_rgb <= vrm_32; // when will data be ready - 4 clocks later (ie the previous cycle)
                end
              end

              // During clock cycle 2, the second pixel of the double word is rendered
              2: begin  // (AP)
                if(super_res) begin
                  high_res_data <= {8'd0, high_res_data[31:8]};
                  PALETTE_ADDR2 = high_res_data[11:8]; //should move to 1
                end
                if (super_mid) begin
                  high_res_data <= {16'b0, high_res_data[31:16]};
                end
              end

              // During clock cycle 3, the third pixel of the double word is rendered
              3: begin  // (FS)
                if(super_res) begin
                  high_res_data <= {8'd0, high_res_data[31:8]};
                  PALETTE_ADDR2 = high_res_data[11:8]; //should move to 2
                end
              end
            endcase
          end
        end
      endcase
    end
  end

endmodule
