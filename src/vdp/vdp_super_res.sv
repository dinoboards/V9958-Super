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


module VDP_SUPER_RES (
    input bit reset,
    input bit clk,
    input bit vdp_super,
    input bit super_mid,
    input bit super_res,
    input bit [9:0] cx,
    input bit [9:0] cy,
    input bit pal_mode,
    input bit REG_R1_DISP_ON,

    input bit [31:0] vrm_32,

    output bit [7:0] PALETTE_ADDR2,
    input  bit [7:0] REG_R7_FRAME_COL,

    output logic [17:0] super_res_vram_addr,
    output bit super_res_drawing,

    input bit [9:0] ext_reg_bus_arb_start_x,
    input bit [9:0] ext_reg_bus_arb_end_x,
    input bit [9:0] ext_reg_bus_arb_start_y,
    input bit [9:0] ext_reg_view_port_start_x,
    input bit [9:0] ext_reg_view_port_end_x,
    input bit [9:0] ext_reg_view_port_start_y,
    input bit [9:0] ext_reg_view_port_end_y,

    input bit [16:0] ext_reg_super_res_page_addr
);

  import custom_timings::*;

  bit super_high_res_visible_x;
  bit super_high_res_visible_y;
  bit last_line;

  bit [9:0] frame_height_minus_1;
  bit [9:0] frame_height;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      frame_height_minus_1 <= 0;
      frame_height <= 0;
    end else begin
      frame_height <= FRAME_HEIGHT(pal_mode);
      frame_height_minus_1 <= 10'(frame_height - 1);
    end
  end


  bit [9:0] frame_width_minus_2;
  bit [9:0] frame_width;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      frame_width_minus_2 <= 0;
      frame_width <= 0;
    end else begin
      frame_width <= FRAME_WIDTH(pal_mode);
      frame_width_minus_2 <= 10'(frame_width - 2);
    end
  end

  assign last_line = cy == frame_height_minus_1;

  bit on_a_visible_line;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_res_drawing <= 1;
    end else begin
      if (last_line && cx == 710) super_res_drawing <= 1;

      if (cx == ext_reg_bus_arb_start_x && on_a_visible_line) super_res_drawing <= 1;

      else if (cx == ext_reg_bus_arb_start_x && cy == ext_reg_bus_arb_start_y) super_res_drawing <= 1;

      else if (cx == ext_reg_bus_arb_end_x && on_a_visible_line) super_res_drawing <= 0;
    end
  end

  bit [7:0] _REG_R7_FRAME_COL;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      _REG_R7_FRAME_COL <= 0;
    end else begin
      _REG_R7_FRAME_COL <= REG_R7_FRAME_COL;
    end
  end


  bit super_res_visible;
  bit super_res_visible_switched_on;
  bit [9:0] view_port_start_x;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_res_visible <= 0;
      on_a_visible_line <= 0;

    end else begin

      //cy == start_y-1 P(625-1) , N(525-1)
      if ((cx == frame_width_minus_2) && cy == ext_reg_view_port_start_y) on_a_visible_line <= 1;

      if ((cx == frame_width_minus_2) && cy == ext_reg_view_port_end_y) on_a_visible_line <= 0;

      if ((cx == ext_reg_view_port_start_x) && on_a_visible_line) begin
        super_res_visible <= 1;

      end else if (cx == ext_reg_view_port_end_x) begin
        super_res_visible <= 0;
      end

    end
  end


  bit [17:0] super_high_res_vram_addr;
  bit [17:0] super_mid_res_vram_addr;
  bit [7:0] super_high_res_palette_addr;
  bit [7:0] super_mid_res_palette_addr;

  assign super_res_vram_addr = super_res ? super_high_res_vram_addr : super_mid_res_vram_addr;
  assign PALETTE_ADDR2 = super_res ? super_high_res_palette_addr : super_mid_res_palette_addr;


  bit [7:0] first_pixel;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer
  bit [7:0] line_buffer[720];
  bit [9:0] line_buffer_index;
  bit odd_phase;
  bit [31:0] mvrm_32_1;
  bit [31:0] mvrm_32_2;
  assign active_line = ((super_mid) && cy[0] == 0) || super_res;

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

        ext_reg_view_port_start_x: begin //default: frame-width -1
          if (on_a_visible_line) super_mid_res_palette_addr <= first_pixel;
        end

        default begin
          if (!super_res_visible) begin
            super_mid_res_palette_addr <= _REG_R7_FRAME_COL;

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


  bit [31:0] vrm_32_1;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_high_res_vram_addr <= 0;
      vrm_32_1 <= '{default: 0};

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

        ext_reg_view_port_start_x: begin //default: frame-width -1
          if (on_a_visible_line)
            super_high_res_palette_addr <= vrm_32_1[7:0];
            //first pixel of each row, including first row???
        end

        ext_reg_view_port_end_x: begin
          super_high_res_palette_addr <= _REG_R7_FRAME_COL;
          vrm_32_1 <= vrm_32;  //load next 4 bytes for start of next row??
        end

        default begin
          if (!super_res_visible) begin
            super_high_res_palette_addr <= _REG_R7_FRAME_COL;
            // standard background border

          end else begin
            case (cx[1:0])
              0: begin
                super_high_res_vram_addr <= 18'(super_high_res_vram_addr + 1);
                //request 12, 16, 20.. pixel sets

                super_high_res_palette_addr <= vrm_32_1[15:8];
                //pixels 1, 5, 9, 13, ...
              end

              // During clock cycle 1:
              //   super_res: super_high_res_palette_addr is loaded pixel indexes [2, 6, 10, 14, ...]
              // Request for next double word is initiated at during this clock cycle (vrm_32_1)
              1: begin
                super_high_res_palette_addr <= vrm_32_1[23:16];
              end

              // During clock cycle 2:
              //   super_res: super_high_res_palette_addr is loaded pixel indexes [3, 7, 11, 15, ...]
              2: begin
                super_high_res_palette_addr <= vrm_32_1[31:24];
              end

              // During clock cycle 3:
              //   super_res: super_high_res_palette_addr is loaded pixel indexes [4, 8, 12, 16, ...]
              3: begin
                //new data request is ready (requested in state 0)
                super_high_res_palette_addr <= vrm_32[7:0];  // for pixel 4, this is as per addr in state 724

                vrm_32_1 <= vrm_32;  //load next 4 bytes
                //on state 3, load next pixels requested at state 0
                //this might be pixels for new row
              end
            endcase
          end
        end
      endcase
    end
  end

endmodule
