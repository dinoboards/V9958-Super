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
    input bit super_half,
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
    input bit ext_reg_pixel_depth,

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
  bit [ 7:0] super_high_res_palette_addr;

  bit [17:0] super_high_2ppb_res_vram_addr;
  bit [ 7:0] super_high_2ppb_res_palette_addr;

  bit [17:0] super_mid_res_vram_addr;
  bit [ 7:0] super_mid_res_palette_addr;

  bit [17:0] super_half_res_vram_addr;
  bit [ 7:0] super_half_res_palette_addr;

  always_comb begin
    if (super_res) begin
      if (ext_reg_pixel_depth == 0) begin
        super_res_vram_addr = super_high_res_vram_addr;
        PALETTE_ADDR2 = super_high_res_palette_addr;

      end else begin
        super_res_vram_addr = super_high_2ppb_res_vram_addr;
        PALETTE_ADDR2 = super_high_2ppb_res_palette_addr;
      end

    end else if (super_mid) begin
      super_res_vram_addr = super_mid_res_vram_addr;
      PALETTE_ADDR2 = super_mid_res_palette_addr;

    end else begin
      super_res_vram_addr = super_half_res_vram_addr;
      PALETTE_ADDR2 = super_half_res_palette_addr;

    end
  end

  VDP_SUPER_HALF_RES VDP_SUPER_HALF_RES (
      .reset(reset),
      .clk(clk),
      .vdp_super(vdp_super),
      .last_line(last_line),
      .on_a_visible_line(on_a_visible_line),
      .ext_reg_view_port_start_x(ext_reg_view_port_start_x),
      .ext_reg_view_port_end_x(ext_reg_view_port_end_x),
      .ext_reg_super_res_page_addr(ext_reg_super_res_page_addr),
      .REG_R7_FRAME_COL(_REG_R7_FRAME_COL),
      .super_res_visible(super_res_visible),
      .vrm_32(vrm_32),
      .cx(cx),
      .cy(cy),
      .super_half_res_vram_addr(super_half_res_vram_addr),
      .super_half_res_palette_addr(super_half_res_palette_addr)
  );

  VDP_SUPER_MID_RES VDP_SUPER_MID_RES (
      .reset(reset),
      .clk(clk),
      .vdp_super(vdp_super),
      .last_line(last_line),
      .on_a_visible_line(on_a_visible_line),
      .ext_reg_view_port_start_x(ext_reg_view_port_start_x),
      .ext_reg_view_port_end_x(ext_reg_view_port_end_x),
      .ext_reg_super_res_page_addr(ext_reg_super_res_page_addr),
      .REG_R7_FRAME_COL(_REG_R7_FRAME_COL),
      .super_res_visible(super_res_visible),
      .vrm_32(vrm_32),
      .cx(cx),
      .cy(cy),
      .REG_R1_DISP_ON(REG_R1_DISP_ON),
      .super_mid_res_vram_addr(super_mid_res_vram_addr),
      .super_mid_res_palette_addr(super_mid_res_palette_addr)
  );

  VDP_SUPER_HIGH_RES U_VDP_SUPER_HIGH_RES (
      .reset(reset),
      .clk(clk),
      .last_line(last_line),
      .vdp_super(vdp_super),
      .on_a_visible_line(on_a_visible_line),
      .ext_reg_view_port_start_x(ext_reg_view_port_start_x),
      .ext_reg_view_port_end_x(ext_reg_view_port_end_x),
      .ext_reg_super_res_page_addr(ext_reg_super_res_page_addr),
      .REG_R7_FRAME_COL(_REG_R7_FRAME_COL),
      .super_res_visible(super_res_visible),
      .vrm_32(vrm_32),
      .cx(cx),
      .super_high_res_vram_addr(super_high_res_vram_addr),
      .super_high_res_palette_addr(super_high_res_palette_addr)
  );

  VDP_SUPER_HIGH_2PPB_RES U_VDP_SUPER_HIGH_2PPB_RES (
      .reset(reset),
      .clk(clk),
      .last_line(last_line),
      .vdp_super(vdp_super),
      .on_a_visible_line(on_a_visible_line),
      .ext_reg_view_port_start_x(ext_reg_view_port_start_x),
      .ext_reg_view_port_end_x(ext_reg_view_port_end_x),
      .ext_reg_super_res_page_addr(ext_reg_super_res_page_addr),
      .REG_R7_FRAME_COL(_REG_R7_FRAME_COL),
      .super_res_visible(super_res_visible),
      .vrm_32(vrm_32),
      .cx(cx),
      .super_high_res_vram_addr(super_high_2ppb_res_vram_addr),
      .super_high_res_palette_addr(super_high_2ppb_res_palette_addr)
  );

endmodule
