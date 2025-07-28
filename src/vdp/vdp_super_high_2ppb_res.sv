`define DISPLAYED_PIXEL_WIDTH 720
`define DISPLAYED_PIXEL_HEIGHT PIXEL_HEIGHT(pal_mode)

/*

16 colours

 super res @50hz 720x576
 super res @60hz 720x480

*/

// 2 pixels per byte (4 bits per pixel)
module VDP_SUPER_HIGH_2PPB_RES (
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

    output bit [17:0] super_high_res_vram_addr,
    output bit [ 7:0] super_high_res_palette_addr
);

  import custom_timings::*;

  bit [31:0] vrm_32_1;
  bit [31:0] vrm_32_2;
  bit odd_phase;

  /*
  Pixel sets
  7:4
  3:0

  15:12
  11:8

  23:20
  19:16

  31:28
  27:24
  */

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_high_res_vram_addr <= 0;
      vrm_32_1 <= '{default: 0};
      odd_phase <= 0;

    end else begin
      case (cx)
        720: begin
          if (last_line) begin
            super_high_res_vram_addr <= ext_reg_super_res_page_addr;
            //reset address to start
            //data read at 725 into vrm_32_1
          end
        end

        724: begin  // cycle cx[1:0] == 0
          if (last_line) begin
            super_high_res_vram_addr <= 18'(super_high_res_vram_addr + 1);
            //request 2nd set of pixels : equiv of addr <= 1
            //read in state 3 straight into super_high_res_palette_addr
          end
        end

        725: begin  //cycle cx[1:0] == 1
          if (last_line) begin
            vrm_32_1 <= vrm_32;
            // for the last line of frame (not visible)
            //capture the data - assume this for first pixels
            //top/left corner
            // this is not 'apparently' impacted by addr change in 724
          end
        end

        ext_reg_view_port_start_x: begin  //default: frame-width -1
          if (on_a_visible_line) super_high_res_palette_addr <= vrm_32_1[7:4];
          //first pixel of each row, including first row???
          odd_phase <= 0;
        end

        ext_reg_view_port_end_x: begin
          super_high_res_palette_addr <= REG_R7_FRAME_COL;
          odd_phase <= 0;
        end

        default begin
          if (!super_res_visible) begin
            super_high_res_palette_addr <= REG_R7_FRAME_COL;
            // standard background border

          end else begin
            case ({
              odd_phase, cx[1:0]
            })
              0: begin
                vrm_32_2 <= vrm_32_1;
                super_high_res_palette_addr <= vrm_32_1[3:0];
                super_high_res_vram_addr <= 18'(super_high_res_vram_addr + 1);
              end

              1: begin
                super_high_res_palette_addr <= vrm_32_1[15:12];
                vrm_32_1 <= vrm_32;  //capture next 4 bytes
              end

              2: begin
                super_high_res_palette_addr <= vrm_32_2[11:8];
              end

              3: begin
                super_high_res_palette_addr <= vrm_32_2[23:20];
                odd_phase <= 1;
              end

              4: begin
                super_high_res_palette_addr <= vrm_32_2[19:16];
              end

              5: begin
                super_high_res_palette_addr <= vrm_32_2[31:28];
              end

              6: begin
                super_high_res_palette_addr <= vrm_32_2[27:24];
              end

              7: begin
                super_high_res_palette_addr <= vrm_32_1[7:4];
                odd_phase <= 0;
              end

            endcase
          end
        end
      endcase
    end
  end

endmodule
