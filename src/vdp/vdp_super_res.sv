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

    output logic [16:0] super_res_vram_addr,
    output bit [7:0] high_res_red,
    output bit [7:0] high_res_green,
    output bit [7:0] high_res_blue,
    output bit super_res_drawing
);

  import custom_timings::*;

  // bit super_high_res;
  bit [31:0] high_res_data;
  bit [31:0] next_rgb;
  bit super_high_res_visible_x;
  bit super_high_res_visible_y;
  bit last_line;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer
  bit super_res_visible;
  bit [31:0] line_buffer[`MAX_PIXEL_WIDTH];
  bit [7:0] line_buffer_index;

  // assign super_high_res = (vdp_super & super_color) | (vdp_super & super_mid);

  // pixel format for super_mid: RRRR RGGG GGGB BBBB
  bit [4:0] high_mid_pixel_red;
  bit [5:0] high_mid_pixel_green;
  bit [4:0] high_mid_pixel_blue;

  assign high_mid_pixel_red = high_res_data[15:11];
  assign high_mid_pixel_green = high_res_data[10:5];
  assign high_mid_pixel_blue = high_res_data[4:0];

  assign high_res_red = super_color ? high_res_data[23:16] : {high_mid_pixel_red, 3'b0};
  assign high_res_green = super_color ? high_res_data[15:8] : {high_mid_pixel_green, 2'b0};
  assign high_res_blue = super_color ? high_res_data[7:0] : {high_mid_pixel_blue, 3'b0};

  assign super_res_visible = super_high_res_visible_x & super_high_res_visible_y;
  assign active_line = (super_color && cy[1:0] == 2'b00) || (super_mid && cy[0] == 0);
  assign last_line = cy == (FRAME_HEIGHT(pal_mode) - 1);

  assign super_res_drawing = last_line || (super_res_visible && active_line);

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
      super_res_vram_addr <= {17{1'b0}};
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
          if (last_line && super_color) begin
            super_res_vram_addr <= 4;
          end else if (last_line && super_mid) begin
            super_res_vram_addr <= 2;
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
              0: begin  // (DL)
                if (active_line) begin
                  line_buffer[line_buffer_index] <= REG_R1_DISP_ON ? next_rgb : 0;
                  high_res_data <= REG_R1_DISP_ON ? next_rgb : 0;

                end else begin
                  high_res_data <= line_buffer[line_buffer_index];
                end

                line_buffer_index <= 8'(line_buffer_index + 1);

                if (active_line && super_color) begin
                  super_res_vram_addr <= 17'(super_res_vram_addr + 4);
                end else if (active_line && super_mid) begin
                  super_res_vram_addr <= 17'(super_res_vram_addr + 2);
                end

              end

              1: begin  // (DA)
                if (active_line) begin
                  next_rgb <= vrm_32;
                end
              end

              2: begin  // (AP)
              end

              3: begin  // (FS)
              end
            endcase
          end
        end
      endcase
    end
  end

endmodule
