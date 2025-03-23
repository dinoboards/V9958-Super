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
    input  bit [7:0] PALETTE_DATA_R2_OUT,
    input  bit [7:0] PALETTE_DATA_G2_OUT,
    input  bit [7:0] PALETTE_DATA_B2_OUT,

    output logic [17:0] super_res_vram_addr,
    output bit [7:0] high_res_red,
    output bit [7:0] high_res_green,
    output bit [7:0] high_res_blue,
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

  bit odd_phase;
  bit [31:0] current_vram_data;
  bit [31:0] next_vram_data;
  bit super_high_res_visible_x;
  bit super_high_res_visible_y;
  bit last_line;
  bit active_line;  // true if line is drawn from sdram, false if drawn from line buffer
  bit [7:0] line_buffer[360];
  bit [8:0] line_buffer_index;

  assign high_res_red = PALETTE_DATA_R2_OUT;
  assign high_res_green = PALETTE_DATA_G2_OUT;
  assign high_res_blue = PALETTE_DATA_B2_OUT;

  assign active_line = (super_mid && cy[0] == 0) || super_res;
  assign last_line = cy == (FRAME_HEIGHT(pal_mode) - 1);

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

  bit super_res_visible;
  bit super_res_visible_switched_on;
  bit [9:0] view_port_start_x;

  assign view_port_start_x = ext_reg_view_port_start_x;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_res_visible <= 0;
      on_a_visible_line <= 0;

    end else begin

      //cy == start_y-1 P(625-1) , N(525-1)
      if ((cx == FRAME_WIDTH(pal_mode) - 2) && cy == ext_reg_view_port_start_y) on_a_visible_line <= 1;

      if ((cx == FRAME_WIDTH(pal_mode) - 2) && cy == ext_reg_view_port_end_y) on_a_visible_line <= 0;

      if ((cx == ext_reg_view_port_start_x) && on_a_visible_line) begin
        super_res_visible <= 1;

      end else if ((cx == ext_reg_view_port_end_x) && on_a_visible_line) begin
        super_res_visible <= 0;
      end

    end
  end

  bit [7:0] first_col_palett_addr;

  always_ff @(posedge reset or posedge clk) begin
    if (reset | ~vdp_super) begin
      super_res_vram_addr <= 0;
      next_vram_data <= '{default: 0};
      current_vram_data <= '{default: 0};
      first_col_palett_addr <= '{default: 0};
      line_buffer_index <= 0;
      odd_phase <= 0;

    end else begin
      case (cx)
        720: begin  //(DL)
          if (last_line) begin
            super_res_vram_addr <= ext_reg_super_res_page_addr;
          end
          line_buffer_index <= 0;
        end

        //721: super_res_vram_addr will be latched into VRAM access by `ADDRESS_BUS

        722: begin
        end

        //723 VRAM refreshing

        724: begin  // cycle cx[1:0] == 0
          if (last_line) begin
            super_res_vram_addr <= 18'(super_res_vram_addr + 1);
          end
        end

        725: begin  //cycle cx[1:0] == 1
          if (last_line) begin
            next_vram_data <= vrm_32;
          end
        end

        726: begin  //cycle cx[1:0] == 2
        end

        856: begin  //cycle cx[1:0] == 2
          //LOAD PALETTE_ADDR2 for first pixel of each row
          if (super_res) begin
            PALETTE_ADDR2 <= next_vram_data[7:0];
            first_col_palett_addr <= next_vram_data[7:0];
          end else begin
            if (!active_line || last_line) begin
              PALETTE_ADDR2 <= next_vram_data[7:0];
              first_col_palett_addr <= next_vram_data[7:0];

              line_buffer[line_buffer_index] <= next_vram_data[7:0];
            end else begin
              PALETTE_ADDR2 <= line_buffer[line_buffer_index];
              first_col_palett_addr <= line_buffer[line_buffer_index];

            end
            line_buffer_index <= 9'(line_buffer_index + 1);
            odd_phase <= 0;
          end
        end

        view_port_start_x: begin
          if (on_a_visible_line) PALETTE_ADDR2 <= first_col_palett_addr;
        end

        default begin
          if (!super_res_visible) begin
            PALETTE_ADDR2 <= 2;  //TODO: make this the default background colour index

          end else begin
            if (super_mid) begin
              case ({
                odd_phase, cx[1:0]
              })
                3'b000: begin
                  if (active_line) begin
                    current_vram_data   <= REG_R1_DISP_ON ? next_vram_data : 0;
                    super_res_vram_addr <= 18'(super_res_vram_addr + 1);
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
                  current_vram_data <= next_vram_data;
                  PALETTE_ADDR2 <= next_vram_data[15:8];
                  super_res_vram_addr <= 18'(super_res_vram_addr + 1);
                end

                // During clock cycle 1:
                //   super_res: PALETTE_ADDR2 is loaded pixel indexes [2, 6, 10, 14, ...]
                // Request for next double word is initiated at during this clock cycle (next_vram_data)
                1: begin
                  PALETTE_ADDR2 <= current_vram_data[23:16];
                end

                // During clock cycle 2:
                //   super_res: PALETTE_ADDR2 is loaded pixel indexes [3, 7, 11, 15, ...]
                2: begin
                  PALETTE_ADDR2 <= current_vram_data[31:24];
                end

                // During clock cycle 3:
                //   super_res: PALETTE_ADDR2 is loaded pixel indexes [4, 8, 12, 16, ...]
                3: begin
                  next_vram_data <= vrm_32;  //load next 4 bytes
                  PALETTE_ADDR2  <= vrm_32[7:0];
                end
              endcase
            end
          end
        end
      endcase
    end
  end

endmodule
