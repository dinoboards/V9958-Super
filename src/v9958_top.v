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
    output        O_sdram_clk,
    output        O_sdram_cke,
    output        O_sdram_cs_n,   // chip select
    output        O_sdram_cas_n,  // columns address select
    output        O_sdram_ras_n,  // row address select
    output        O_sdram_wen_n,  // write enable
    inout  [31:0] IO_sdram_dq,    // 32 bit bidirectional data bus
    output [10:0] O_sdram_addr,   // 11 bit multiplexed address bus
    output [ 1:0] O_sdram_ba,     // two banks
    output [ 3:0] O_sdram_dqm     // 32/4
);

  // ----------------------------------------
  // All Clocks
  // ----------------------------------------
  bit clk_w;
  bit clk_135_w;
  bit clk_135_lock_w;
  bit sckclk_w;
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
      .sckclk_w(sckclk_w),
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
  bit          ReVdp_n;
  bit   [16:0] VdpAdr;
  bit   [ 7:0] VrmDbo;
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
      .addr({7'b0, VdpAdr[16:1]}),
      .din({VrmDbo, VrmDbo}),
      .wdm({~VdpAdr[0], VdpAdr[0]}),
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

  wire pal_mode;

  VDP u_v9958 (
      .CLK21M         (clk_w),
      .RESET          (reset_w | ~ram_enabled),
      .REQ            (CpuReq),
      .ACK            (),
      .WRT            (CpuWrt),
      .mode           (mode),
      .DBI            (CpuDbi),
      .DBO            (CpuDbo),
      .INT_N          (int_n),
      .PRAMOE_N       (ReVdp_n),
      .PRAMWE_N       (WeVdp_n),
      .PRAMADR        (VdpAdr),
      .PRAMDBI        (VrmDbi),
      .PRAMDBO        (VrmDbo),
      .VDPSPEEDMODE   (1'b1),                    // for V9958 MSX2+/tR VDP
      .PVIDEOR        (VideoR),
      .PVIDEOG        (VideoG),
      .PVIDEOB        (VideoB),
      .PVIDEODHCLK    (VideoDHClk),
      .PVIDEODLCLK    (VideoDLClk),
      .PAL_MODE       (pal_mode),
      .SPMAXSPR       (1'b0),
      .CX             (cx),
      .CY             (cy)
  );

  //--------------------------------------------------------------
  // HDMI output
  //--------------------------------------------------------------

  wire [7:0] dvi_r;
  wire [7:0] dvi_g;
  wire [7:0] dvi_b;
  wire hdmi_reset;
  wire [15:0] sample_w;
  reg [15:0] audio_sample_word[1:0], audio_sample_word0[1:0];
  logic [2:0] tmds;
  bit         scanlin;

  assign scanlin = 1'b0;

  assign dvi_r = (scanlin && cy[0]) ? {1'b0, VideoR, 1'b0} : {VideoR, 2'b0};
  assign dvi_g = (scanlin && cy[0]) ? {1'b0, VideoG, 1'b0} : {VideoG, 2'b0};
  assign dvi_b = (scanlin && cy[0]) ? {1'b0, VideoB, 1'b0} : {VideoB, 2'b0};

  assign hdmi_reset = reset_w | ~ram_enabled;

  always @(posedge clk_w) begin
    audio_sample_word0[0] <= sample_w;
    audio_sample_word[0]  <= audio_sample_word0[0];
    audio_sample_word0[1] <= sample_w;
    audio_sample_word[1]  <= audio_sample_word0[1];
  end
  wire [15:0] audio_sample_word_w[1:0];
  assign audio_sample_word_w = audio_sample_word;

  hdmi_selection #() hdmi (
      .include_audio(~exclude_audio),
      .clk_pixel_x5(clk_135_w),
      .clk_pixel(clk_w),
      .clk_audio(clk_audio_w),
      .rgb({dvi_r, dvi_g, dvi_b}),
      .hdmi_reset(hdmi_reset),
      .reset(reset_w),
      .audio_sample_word(audio_sample_word_w),
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


  // ADC
  wire sck_enable;
  wire [11:0] audio_sample;
  SPI_MCP3202 #(
      .SGL(1),  // sets ADC to single ended mode
      .ODD(0)   // sets sample input to channel 0
  ) SPI_MCP3202 (
      .clk       (clk_135_w),     // 125  MHz???
      .EN        (reset_n_w),     // Enable the SPI core (ACTIVE HIGH)
      .MISO      (adc_miso),      // data out of ADC (Dout pin)
      .MOSI      (adc_mosi),      // Data into ADC (Din pin)
      .SCK_ENABLE(sck_enable),
      .o_DATA    (audio_sample),  // 12 bit word (for other modules)
      .CS        (adc_cs),        // Chip Select
      .DATA_VALID(sample_valid)   // is high when there is a full 12 bit word.
  );


  assign adc_clk = sckclk_w & sck_enable;

  reg [15:0] adc_sample;
  always @(posedge clk_135_w) begin
    if (sample_valid) adc_sample <= {audio_sample[11:0], 4'b0};
  end

  wire [31:0] adc_sample_w;
  assign adc_sample_w = {adc_sample, 16'b0};

  reg [31:0] sample;
  LPF1 #(
      .MSBI(32)
  ) LPF (
      .CLK21M(clk_135_w),
      .RESET (reset_w),
      .CLKENA(1'b1),
      .IDATA (adc_sample_w),
      .ODATA (sample)
  );

  assign sample_w = sample[31:16];

endmodule



