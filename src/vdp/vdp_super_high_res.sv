
`define WIDTH 64
`define HEIGHT 64

module vdp_super_high_res (
    input bit reset,
    input bit clk,
    input bit super_high_res,
    input bit [10:0] cx,
    input bit [9:0] cy,
    input bit [1:0] dot_state,
    input bit pal_mode,

    input bit [31:0] vrm_32,

    output bit [16:0] high_res_vram_addr,
    output bit [ 7:0] high_res_red,
    output bit [ 7:0] high_res_green,
    output bit [ 7:0] high_res_blue
);

  import custom_timings::*;

  bit [23:0] high_res_data;
  bit [23:0] next_rgb;
  bit super_high_res_visible_x;
  bit super_high_res_visible_y;
  bit last_line;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer

  bit [23:0] line_buffer[`WIDTH];
  bit [7:0] line_buffer_index;

  assign high_res_red = high_res_data[23:16];
  assign high_res_green = high_res_data[15:8];
  assign high_res_blue = high_res_data[7:0];

  assign super_high_res_visible = super_high_res_visible_x & super_high_res_visible_y;

  assign last_line = cy == (FRAME_HEIGHT(pal_mode) - 1);

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~super_high_res) begin
      super_high_res_visible_x <= 0;
    end else begin
      if (cx == CLOCKS_PER_HALF_LINE(pal_mode) - 1) begin
        super_high_res_visible_x <= 1;
      end else if (cx == (`WIDTH * 4) - 1) super_high_res_visible_x <= 0;
    end
  end

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~super_high_res) begin
      super_high_res_visible_y <= 0;
    end else begin
      if (cx == 0 && cy == 0) super_high_res_visible_y <= 1;
      else if (last_line) super_high_res_visible_y <= 1;
      else if (cy == (`HEIGHT * 4) - 1 && cx == (`WIDTH * 4)) super_high_res_visible_y <= 0;
    end
  end


  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~super_high_res) begin
      high_res_vram_addr <= 0;
      next_rgb <= '{default: 0};
      high_res_data <= '{default: 0};
      line_buffer_index <= 0;
      active_line <= 0;

    end else begin
      if (cx == 722 && last_line) begin
        //(AP)
        high_res_vram_addr <= 0;
        line_buffer_index  <= 0;

      end else begin
        if (cx == 722) begin
          line_buffer_index <= 0;

          //723 (FS) read initiated
          //724 (DL) data loading
        end else begin
          if (cx == 725 && last_line) begin
            //(DR)
            next_rgb <= vrm_32[23:0];

          end else begin
            if (cx == 726 && last_line) begin
              //(AP)
              high_res_vram_addr <= 17'(high_res_vram_addr + 2);

            end else begin
              if (~super_high_res_visible) begin
                high_res_data <= '{default: 0};

              end else begin
                case (dot_state)
                  0: begin
                    // (DL)

                    active_line <= cy[1:0] == 2'b00;
                    if (cy[1:0] == 2'b00) begin
                      line_buffer[line_buffer_index] <= next_rgb;
                      high_res_data <= next_rgb;
                    end else begin
                      high_res_data <= line_buffer[line_buffer_index];
                    end

                    line_buffer_index <= 6'(line_buffer_index + 1);

                  end

                  1: begin
                    // (DR)
                    if (active_line) next_rgb <= vrm_32[23:0];
                  end

                  3: begin
                    // (AP)
                    if (active_line) high_res_vram_addr <= 17'(high_res_vram_addr + 2);
                  end

                  2: begin
                    // (FS)
                  end
                endcase
              end
            end
          end
        end
      end
    end
  end

endmodule
