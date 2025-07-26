`define DISPLAYED_PIXEL_WIDTH 720
`define DISPLAYED_PIXEL_HEIGHT PIXEL_HEIGHT(pal_mode)

/*

REG_R9_Y_DOTS: 1
 super res @50hz 720x576
 super res @60hz 720x480

 super mid @50hz 360x288
 super mid @60hz 360x240

REG_R9_Y_DOTS: 0
 super res @50hz 640x480 (offsets: 40, 48)
 super res @60hz 640x400 (offsets: 40, 0)

 super mid @50hz 320x200 (offsets: 15, 40)
 super mid @60hz 320x166 (offsets: 15, 37)
*/


module VDP_SUPER_MID_RES (
    input bit reset,
    input bit clk,
    input bit vdp_super,
    input bit last_line,
    input bit on_a_visible_line,
    input bit [9:0] ext_reg_view_port_start_x,
    input bit [9:0] ext_reg_view_port_end_x,
    input bit [16:0] ext_reg_super_res_page_addr,
    input bit [7:0] REG_R7_FRAME_COL,
    input bit super_res_visible,
    input bit [31:0] vrm_32,
    input bit [9:0] cx,
    input bit [9:0] cy,
    input bit REG_R1_DISP_ON,

    output bit [17:0] super_mid_res_vram_addr,
    output bit [ 7:0] super_mid_res_palette_addr
);

  import custom_timings::*;

  bit [7:0] first_pixel;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer
  bit [7:0] line_buffer[720];
  bit [9:0] line_buffer_index;
  bit odd_phase;
  bit [31:0] mvrm_32_1;
  bit [31:0] mvrm_32_2;
  assign active_line = (cy[0] == 0);

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_mid_res_vram_addr <= 0;
      super_mid_res_palette_addr <= '{default: 0};

    end else begin
      case (cx)
        720: begin
          if (last_line) begin
            super_mid_res_vram_addr <= ext_reg_super_res_page_addr;
          end
          line_buffer_index <= 0;
        end

        724: begin  // cycle cx[1:0] == 0
          if (last_line) begin
            super_mid_res_vram_addr <= 18'(super_mid_res_vram_addr + 1);
          end
        end

        725: begin  //cycle cx[1:0] == 1
          if (last_line) begin
            mvrm_32_1 <= vrm_32;
          end
        end

        856: begin  //cycle cx[1:0] == 2
          //LOAD super_mid_res_palette_addr for first pixel of each row
          if (!active_line || last_line) begin
            super_mid_res_palette_addr <= mvrm_32_1[7:0];
            first_pixel <= mvrm_32_1[7:0];

            line_buffer[line_buffer_index] <= mvrm_32_1[7:0];
          end else begin
            super_mid_res_palette_addr <= line_buffer[line_buffer_index];
            first_pixel <= line_buffer[line_buffer_index];

          end
          line_buffer_index <= 10'(line_buffer_index + 1);
          odd_phase <= 0;
        end

        ext_reg_view_port_start_x: begin  //default: frame-width -1
          if (on_a_visible_line) super_mid_res_palette_addr <= first_pixel;
        end

        ext_reg_view_port_end_x: begin
          super_mid_res_palette_addr <= REG_R7_FRAME_COL;
        end

        default begin
          if (!super_res_visible) begin
            super_mid_res_palette_addr <= REG_R7_FRAME_COL;

          end else begin
            case ({
              odd_phase, cx[1:0]
            })
              3'b000: begin
                if (active_line) begin
                  mvrm_32_2 <= REG_R1_DISP_ON ? mvrm_32_1 : 0;
                  super_mid_res_vram_addr <= 18'(super_mid_res_vram_addr + 1);
                end
              end
              3'b001: begin
                if (active_line) begin
                  super_mid_res_palette_addr <= mvrm_32_1[15:8];
                  line_buffer[line_buffer_index] <= mvrm_32_1[15:8];
                  mvrm_32_1 <= vrm_32;  //capture next 4 bytes
                end else begin
                  super_mid_res_palette_addr <= line_buffer[line_buffer_index];
                end
                line_buffer_index <= 10'(line_buffer_index + 1);
              end
              3'b010: begin
              end
              3'b011: begin
                if (active_line) begin
                  super_mid_res_palette_addr <= mvrm_32_2[23:16];
                  line_buffer[line_buffer_index] <= mvrm_32_2[23:16];
                end else begin
                  super_mid_res_palette_addr <= line_buffer[line_buffer_index];
                end
                line_buffer_index <= 10'(line_buffer_index + 1);
                odd_phase <= 1;
              end
              3'b100: begin
              end
              3'b101: begin
                if (active_line) begin
                  super_mid_res_palette_addr <= mvrm_32_2[31:24];
                  line_buffer[line_buffer_index] <= mvrm_32_2[31:24];
                end else begin
                  super_mid_res_palette_addr <= line_buffer[line_buffer_index];
                end
                line_buffer_index <= 10'(line_buffer_index + 1);
              end
              3'b110: begin
              end
              3'b111: begin
                if (active_line) begin
                  super_mid_res_palette_addr <= mvrm_32_1[7:0];
                  line_buffer[line_buffer_index] <= mvrm_32_1[7:0];
                end else begin
                  super_mid_res_palette_addr <= line_buffer[line_buffer_index];
                end
                line_buffer_index <= 10'(line_buffer_index + 1);
                odd_phase <= 0;
              end
            endcase
          end
        end
      endcase
    end
  end


endmodule
