`define GW_IDE

`include "vdp_constants.vh"

module v9958_top (
    //high => send a HDMI single without any audio encoded
    //low => send HDMI single with audio encoded
    input exclude_audio,

    input [7:2] A,

    input rd_n,
    input wr_n,
    input iorq_n,

    input clk,

    input reset_n,
    input [1:0] mode,
    output cs_n,

    output int_n,
    inout [7:0] cd,

    output adc_clk,
    output adc_cs,
    output adc_mosi,
    input  adc_miso,

    output       tmds_clk_p,
    output       tmds_clk_n,
    output [2:0] tmds_data_p,
    output [2:0] tmds_data_n,

    // SDRAM
    output              O_sdram_clk,
    output              O_sdram_cke,
    output              O_sdram_cs_n,   // chip select
    output              O_sdram_cas_n,  // columns address select
    output              O_sdram_ras_n,  // row address select
    output              O_sdram_wen_n,  // write enable
    inout  logic [31:0] IO_sdram_dq,    // 32 bit bidirectional data bus
    output       [10:0] O_sdram_addr,   // 11 bit multiplexed address bus
    output       [ 1:0] O_sdram_ba,     // two banks
    output       [ 3:0] O_sdram_dqm     // 32/4
);

  import custom_timings::*;

  // ----------------------------------------
  // All Clocks
  // ----------------------------------------
  bit clk_w;
  bit clk_135_w;
  bit clk_135_lock_w;
  bit clk_900k_w;
  bit clk_audio_w;
  bit clk_sdram_w;
  bit clk_sdramp_w;
  bit clk_sdram_lock_w;

  clocks clocks (
      .rst_n(reset_n),
      .clk(clk),
      .clk_w(clk_w),
      .clk_135_w(clk_135_w),
      .clk_135_lock_w(clk_135_lock_w),
      .clk_900k_w(clk_900k_w),
      .clk_audio_w(clk_audio_w),
      .clk_sdram_w(clk_sdram_w),
      .clk_sdramp_w(clk_sdramp_w),
      .clk_sdram_lock_w(clk_sdram_lock_w)
  );

  // ----------------------------------------
  // Master Reset combined with clock phase locks
  // ----------------------------------------

  bit reset_w;
  bit reset_n_w;
  assign reset_n_w = clk_135_lock_w & clk_sdram_lock_w & reset_n;
  assign reset_w   = ~reset_n_w;

  // ----------------------------------------
  // V5598 Video Generation
  // ----------------------------------------

  bit          CpuReq;
  bit          CpuWrt;
  bit   [ 7:0] CpuDbo;
  bit   [ 7:0] CpuDbi;
  bit          VideoDLClk;
  bit          VideoDHClk;
  bit          WeVdp_n;
  bit   [16:0] VdpAdr;
  bit   [ 7:0] VrmDbo;
  logic [31:0] out_vrm_32;
  bit          vrm_32_mode;  // 0: 16 bit mode, 1: 32 bit mode
  bit   [15:0] VrmDbi;

  bit   [ 5:0] VideoR;  // RGB Red
  bit   [ 5:0] VideoG;  // RGB Green
  bit   [ 5:0] VideoB;  // RGB Blue

  logic [10:0] cx;
  logic [ 9:0] cy;

  bit ram_busy, ram_fail;
  bit ram_enabled;

  bit v9958_read;
  bit v9958_write;
  bit memory_refresh;
  bit [31:0] vrm_32;
  bit [16:0] high_res_vram_addr;
  bit vdp_super;
  bit super_color;
  bit super_mid;
  bit super_res;

  logic [15:0] audio_sample_word[1:0];

  // Memory Interface
  assign v9958_read = (WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy);
  assign v9958_write = ~WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy;
  assign memory_refresh = ~VideoDLClk & ~VideoDHClk & ~ram_busy;
  memory_controller #(
      .FREQ(108_000_000)
  ) vram (
      .clk(clk_sdramp_w),
      .clk_sdram(clk_sdram_w),
      .resetn(reset_n_w),
      .read(v9958_read),
      .write(v9958_write),
      .refresh(memory_refresh),
      .addr((vdp_super && WeVdp_n) ? {6'b0, high_res_vram_addr[16:0]} : (vrm_32_mode ? {6'b0, VdpAdr[16:0]} : {7'b0, VdpAdr[16:1]})),
      .din({VrmDbo, VrmDbo}),
      .din32(out_vrm_32),
      .wdm(vrm_32_mode ? 2'b00 : {~VdpAdr[0], VdpAdr[0]}),
      .dout(VrmDbi),
      .dout32(vrm_32),
      .busy(ram_busy),
      .fail(ram_fail),
      .enabled(ram_enabled),

      .IO_sdram_dq(IO_sdram_dq),
      .O_sdram_addr(O_sdram_addr),
      .O_sdram_ba(O_sdram_ba),
      .O_sdram_cs_n(O_sdram_cs_n),
      .O_sdram_wen_n(O_sdram_wen_n),
      .O_sdram_ras_n(O_sdram_ras_n),
      .O_sdram_cas_n(O_sdram_cas_n),
      .O_sdram_clk(O_sdram_clk),
      .O_sdram_cke(O_sdram_cke),
      .O_sdram_dqm(O_sdram_dqm)
  );

  cpu_io cpu_io (
      .clk(clk_w),
      .reset_n(reset_n_w),
      .A(A),
      .rd_n(rd_n),
      .wr_n(wr_n),
      .iorq_n(iorq_n),
      .cd(cd),
      .clk_sdram(clk_sdram_w),

      .CpuReq(CpuReq),
      .CpuWrt(CpuWrt),
      .CpuDbo(CpuDbo),
      .CpuDbi(CpuDbi),
      .cs_n  (cs_n)
  );

  bit pal_mode;

  bit [7:0] REG_R31;

  bit [7:0] high_res_red;
  bit [7:0] high_res_green;
  bit [7:0] high_res_blue;

  vdp_super_high_res vdp_super_high_res (
      .reset(reset_w),
      .clk(clk_w),
      .vdp_super(vdp_super),
      .super_color(super_color),
      .super_mid(super_mid),
      .super_res(super_res),
      .cx(cx),
      .cy(cy),
      .pal_mode(pal_mode),
      .vrm_32(vrm_32),
      .high_res_vram_addr(high_res_vram_addr),
      .high_res_red(high_res_red),
      .high_res_green(high_res_green),
      .high_res_blue(high_res_blue)
  );

  VDP u_v9958 (
      .CLK21M      (clk_w),
      .RESET       (reset_w | ~ram_enabled),
      .REQ         (CpuReq),
      .ACK         (),
      .WRT         (CpuWrt),
      .mode        (mode),
      .DBI         (CpuDbi),
      .DBO         (CpuDbo),
      .INT_N       (int_n),
      .PRAMWE_N    (WeVdp_n),
      .PRAMADR     (VdpAdr),
      .PRAMDBI     (VrmDbi),
      .vrm_32      (vrm_32),
      .PRAMDBO     (VrmDbo),
      .out_vram_32 (out_vrm_32),
      .vrm_32_mode (vrm_32_mode),
      .VDPSPEEDMODE(1'b1),                    // for V9958 MSX2+/tR VDP
      .PVIDEOR     (VideoR),
      .PVIDEOG     (VideoG),
      .PVIDEOB     (VideoB),
      .PVIDEODHCLK (VideoDHClk),
      .PVIDEODLCLK (VideoDLClk),
      .PAL_MODE    (pal_mode),
      .SPMAXSPR    (1'b0),
      .CX          (cx),
      .CY          (cy),
      .REG_R31     (REG_R31),
      .vdp_super   (vdp_super),
      .super_color (super_color),
      .super_mid   (super_mid),
      .super_res   (super_res)
  );

  //--------------------------------------------------------------
  // HDMI output
  //--------------------------------------------------------------

  bit   [7:0] dvi_r;
  bit   [7:0] dvi_g;
  bit   [7:0] dvi_b;
  bit         hdmi_reset;
  logic [2:0] tmds;
  bit         scanlin;

  assign scanlin = 1'b0;

  assign dvi_r = vdp_super ? high_res_red : (scanlin && cy[0]) ? {1'b0, VideoR, 1'b0} : {VideoR, 2'b0};
  assign dvi_g = vdp_super ? high_res_green : (scanlin && cy[0]) ? {1'b0, VideoG, 1'b0} : {VideoG, 2'b0};
  assign dvi_b = vdp_super ? high_res_blue : (scanlin && cy[0]) ? {1'b0, VideoB, 1'b0} : {VideoB, 2'b0};

  assign hdmi_reset = reset_w | ~ram_enabled;


  hdmi_selection #() hdmi (
      .include_audio(~exclude_audio),
      .clk_pixel_x5(clk_135_w),
      .clk_pixel(clk_w),
      .clk_audio(clk_audio_w),
      .rgb({dvi_r, dvi_g, dvi_b}),
      .hdmi_reset(hdmi_reset),
      .reset(reset_w),
      .audio_sample_word(audio_sample_word),
      .pal_mode(pal_mode),
      .cx(cx),
      .cy(cy),
      .tmds(tmds)
  );

  // now take the tmds encoded feed and send it to the Gowin LVDS output buffer
  ELVDS_OBUF tmds_bufds[3:0] (
      .I ({clk_w, tmds}),
      .O ({tmds_clk_p, tmds_data_p}),
      .OB({tmds_clk_n, tmds_data_n})
  );

  //--------------------------------------------------------------

  AUDIO #() audio (
      .clk(clk_w),
      .clk_135(clk_135_w),
      .clk_900k(clk_900k_w),
      .reset_n(reset_n_w),
      .audio_sample_word(audio_sample_word),
      .adc_miso(adc_miso),
      .adc_clk(adc_clk),
      .adc_cs(adc_cs),
      .adc_mosi(adc_mosi)
  );

endmodule

