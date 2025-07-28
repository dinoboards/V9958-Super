`define DISPLAYED_PIXEL_WIDTH 720
`define DISPLAYED_PIXEL_HEIGHT PIXEL_HEIGHT(pal_mode)

/*

256 colours

 super res @50hz 720x288
 super res @60hz 720x240

*/


module VDP_SUPER_HALF_RES (
    input bit reset,
    input bit clk,
    input bit last_line,
    input bit vdp_super,
    input bit on_a_visible_line,
    input bit [9:0] ext_reg_view_port_start_x,
    input bit [9:0] ext_reg_view_port_end_x,
    input bit [16:0] ext_reg_super_res_page_addr,
    input bit [7:0] REG_R7_FRAME_COL,
    input bit super_res_visible,
    input bit [31:0] vrm_32,
    input bit [9:0] cx,
    input bit [9:0] cy,

    output bit [17:0] super_half_res_vram_addr,
    output bit [ 7:0] super_half_res_palette_addr
);

  import custom_timings::*;

  bit [31:0] vrm_32_1;
  bit [7:0] first_pixel;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer
  bit [7:0] line_buffer[720];
  bit [9:0] line_buffer_index;

  assign active_line = (cy[0] == 0);

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_half_res_vram_addr <= 0;
      vrm_32_1 <= '{default: 0};

    end else begin
      case (cx)
        720: begin
          if (last_line) begin
            super_half_res_vram_addr <= ext_reg_super_res_page_addr;
            //reset address to start
            //data read at 725 into vrm_32_1
          end
          line_buffer_index <= 0;
        end

        724: begin  // cycle cx[1:0] == 0
          if (last_line) begin
            super_half_res_vram_addr <= 18'(super_half_res_vram_addr + 1);
            //request 2nd set of pixels : equiv of addr <= 1
            //read in state 3 straight into super_half_res_palette_addr
          end
        end

        725: begin  //cycle cx[1:0] == 1
          if (last_line) begin
            vrm_32_1 <= vrm_32;  //pixels 0..3
            // for the last line of frame (not visible)
            //capture the data - assume this for first pixels
            //top/left corner
            // this is not 'apparently' impacted by addr change in 724
          end
        end

        856: begin  //cycle cx[1:0] == 2
          if (!active_line || last_line) begin
            super_half_res_palette_addr <= vrm_32_1[7:0];
            first_pixel <= vrm_32_1[7:0];
            line_buffer[line_buffer_index] <= vrm_32_1[7:0];

          end else begin
            super_half_res_palette_addr <= line_buffer[line_buffer_index];
            first_pixel <= line_buffer[line_buffer_index];

          end
          line_buffer_index <= 10'(line_buffer_index + 1);
        end

        ext_reg_view_port_start_x: begin  //default: frame-width -1
          if (on_a_visible_line) begin
            super_half_res_palette_addr <= first_pixel;  //vrm_32_1[7:0];
          end
          //first pixel of each row, including first row???
        end

        ext_reg_view_port_end_x: begin
          super_half_res_palette_addr <= REG_R7_FRAME_COL;
          if (active_line) begin
            vrm_32_1 <= vrm_32;  //load next 4 bytes for start of next row??
          end
        end

        default begin
          if (!super_res_visible) begin
            super_half_res_palette_addr <= REG_R7_FRAME_COL;
            // standard background border

          end else begin
            case (cx[1:0])
              0: begin
                if (active_line) begin
                  super_half_res_vram_addr <= 18'(super_half_res_vram_addr + 1);
                  //request 12, 16, 20.. pixel sets

                  super_half_res_palette_addr <= vrm_32_1[15:8];
                  line_buffer[line_buffer_index] <= vrm_32_1[15:8];

                end else begin
                  super_half_res_palette_addr <= line_buffer[line_buffer_index];
                end

                line_buffer_index <= 10'(line_buffer_index + 1);
                //pixels 1, 5, 9, 13, ...
              end

              // During clock cycle 1:
              //   super_res: super_half_res_palette_addr is loaded pixel indexes [2, 6, 10, 14, ...]
              // Request for next double word is initiated at during this clock cycle (vrm_32_1)
              1: begin
                if (active_line) begin
                  super_half_res_palette_addr <= vrm_32_1[23:16];
                  line_buffer[line_buffer_index] <= vrm_32_1[23:16];

                end else begin
                  super_half_res_palette_addr <= line_buffer[line_buffer_index];
                end

                line_buffer_index <= 10'(line_buffer_index + 1);
              end

              // During clock cycle 2:
              //   super_res: super_half_res_palette_addr is loaded pixel indexes [3, 7, 11, 15, ...]
              2: begin
                if (active_line) begin
                  super_half_res_palette_addr <= vrm_32_1[31:24];
                  line_buffer[line_buffer_index] <= vrm_32_1[31:24];

                end else begin
                  super_half_res_palette_addr <= line_buffer[line_buffer_index];
                end

                line_buffer_index <= 10'(line_buffer_index + 1);
              end

              // During clock cycle 3:
              //   super_res: super_half_res_palette_addr is loaded pixel indexes [4, 8, 12, 16, ...]
              3: begin
                //new data request is ready (requested in state 0)
                if (active_line) begin
                  vrm_32_1 <= vrm_32;  //load next 4 bytes
                  super_half_res_palette_addr <= vrm_32[7:0];  // for pixel 4, this is as per addr in state 724
                  line_buffer[line_buffer_index] <= vrm_32[7:0];
                end else begin
                  super_half_res_palette_addr <= line_buffer[line_buffer_index];
                end
                //on state 3, load next pixels requested at state 0
                //this might be pixels for new row

                line_buffer_index <= 10'(line_buffer_index + 1);
              end
            endcase
          end
        end
      endcase
    end
  end

endmodule
