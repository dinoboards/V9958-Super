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
  bit   [ 1:0] VdpDb_Rd_size;
  bit   [ 1:0] VdpDb_Wr_size;
  bit   [16:0] VdpAdr;
  bit   [ 7:0] VrmDbo_8;
  bit   [31:0] VrmDbo_32;
  bit   [31:0] VrmDbi_32;

  logic [10:0] cx;
  logic [ 9:0] cy;

  bit ram_busy, ram_fail;
  bit ram_enabled;

  bit v9958_read;
  bit v9958_write;
  bit memory_refresh;
  bit [16:0] super_res_vram_addr;
  bit vdp_super;

  logic [15:0] audio_sample_word[1:0];

  // Memory Interface
  assign v9958_read = (WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy);
  assign v9958_write = ~WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy;
  assign memory_refresh = ~VideoDLClk & ~VideoDHClk & ~ram_busy;

  MEM_CONTROLLER #(
      .FREQ(108_000_000)
  ) vram (
      .clk(clk_sdramp_w),
      .clk_sdram(clk_sdram_w),
      .resetn(reset_n_w),
      .read(v9958_read),
      .write(v9958_write),
      .refresh(memory_refresh),
      .busy(ram_busy),
      .fail(ram_fail),
      .enabled(ram_enabled),
      .addr(VdpAdr),
      .din8(VrmDbo_8),
      .din32(VrmDbo_32),
      .dout32(VrmDbi_32),
      .word_rd_size(VdpDb_Rd_size),
      .word_wr_size(VdpDb_Wr_size),
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

  bit       pal_mode;
  bit       scanlin;
  bit [7:0] dvi_r;
  bit [7:0] dvi_g;
  bit [7:0] dvi_b;

  VDP u_v9958 (
      .CLK21M      (clk_w),
      .RESET       (reset_w | ~ram_enabled),
      .REQ         (CpuReq),
      .ACK         (),
      .scanlin     (scanlin),
      .WRT         (CpuWrt),
      .mode        (mode),
      .DBI         (CpuDbi),
      .DBO         (CpuDbo),
      .INT_N       (int_n),
      .PRAMWE_N    (WeVdp_n),
      .PRAM_RD_SIZE(VdpDb_Rd_size),
      .PRAM_WR_SIZE(VdpDb_Wr_size),
      .PRAMADR     (VdpAdr),
      .PRAMDBI_32  (VrmDbi_32),
      .PRAMDBO_8   (VrmDbo_8),
      .PRAMDBO_32  (VrmDbo_32),
      .VDPSPEEDMODE(1'b1),                    // for V9958 MSX2+/tR VDP
      .PVIDEODHCLK (VideoDHClk),
      .PVIDEODLCLK (VideoDLClk),
      .PAL_MODE    (pal_mode),
      .SPMAXSPR    (1'b0),
      .CX          (cx),
      .CY          (cy),
      .vdp_super   (vdp_super),
      .red         (dvi_r),
      .green       (dvi_g),
      .blue        (dvi_b)
  );

  //--------------------------------------------------------------
  // HDMI output
  //--------------------------------------------------------------

  bit         hdmi_reset;
  logic [2:0] tmds;

  assign scanlin = 1'b0;

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

