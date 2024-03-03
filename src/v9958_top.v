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

  localparam NUM_CHANNELS = 3;

  // VDP signals
  wire        VdpReq;
  wire [ 7:0] VdpDbi;
  wire        VideoSC;
  wire        VideoDLClk;
  wire        VideoDHClk;
  wire        WeVdp_n;
  wire        ReVdp_n;
  wire [16:0] VdpAdr;
  wire [ 7:0] VrmDbo;
  wire [15:0] VrmDbi;
  wire        pVdpInt_n;

  wire        r9palmode;

  // Video signals
  wire [ 5:0] VideoR;  // RGB Red
  wire [ 5:0] VideoG;  // RGB Green
  wire [ 5:0] VideoB;  // RGB Blue
  wire        VideoHS_n;  // Horizontal Sync
  wire        VideoVS_n;  // Vertical Sync
  wire        VideoCS_n;  // Composite Sync

  // ----------------------------------------
  // All Clocks
  // ----------------------------------------
  bit         clk_w;
  bit         clk_135_w;
  bit         clk_135_lock_w;
  bit         sckclk_w;
  bit         clk_audio_w;
  bit         clk_sdram_w;
  bit         clk_sdramp_w;
  bit         clk_sdram_lock_w;

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

  wire ram_busy, ram_fail;

  wire [19:0] ram_total_written;
  wire ram_enabled;

  memory_controller #(
      .FREQ(108_000_000)
  ) vram (
      .clk(clk_sdramp_w),
      .clk_sdram(clk_sdram_w),
      .resetn(reset_n_w),
      .read(WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy),
      .write(~WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy),
      .refresh(~VideoDLClk & ~VideoDHClk & ~ram_busy),
      .addr({6'b0, VdpAdr[15:0]}),
      .din({VrmDbo, VrmDbo}),
      .wdm({~VdpAdr[16], VdpAdr[16]}),
      .dout(VrmDbi),
      .busy(ram_busy),
      .fail(ram_fail),
      .total_written(ram_total_written),
      .enabled(ram_enabled),

      .SDRAM_DQ(IO_sdram_dq),
      .SDRAM_A(O_sdram_addr),
      .SDRAM_BA(O_sdram_ba),
      .SDRAM_nCS(O_sdram_cs_n),
      .SDRAM_nWE(O_sdram_wen_n),
      .SDRAM_nRAS(O_sdram_ras_n),
      .SDRAM_nCAS(O_sdram_cas_n),
      .SDRAM_CLK(O_sdram_clk),
      .SDRAM_CKE(O_sdram_cke),
      .SDRAM_DQM(O_sdram_dqm)
  );

  // Internal bus signals (common)
  bit          CpuReq;
  bit          CpuWrt;
  bit   [ 7:0] CpuDbo;
  bit   [ 7:0] CpuDbi;

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
      .cs_n(cs_n)
  );

  wire pal_mode;
  wire [10:0] vdp_cx;
  wire [10:0] vdp_cy;
  VDP u_v9958 (
      .CLK21M         (clk_w),
      .RESET          (reset_w | ~ram_enabled),
      .REQ            (CpuReq),
      .ACK            (),
      .WRT            (CpuWrt),
      .mode           (mode),
      .DBI            (CpuDbi),
      .DBO            (CpuDbo),
      .INT_N          (pVdpInt_n),
      .PRAMOE_N       (ReVdp_n),
      .PRAMWE_N       (WeVdp_n),
      .PRAMADR        (VdpAdr),
      .PRAMDBI        (VrmDbi),
      .PRAMDBO        (VrmDbo),
      .VDPSPEEDMODE   (1'b0),                    // for V9958 MSX2+/tR VDP
      .RATIOMODE      (3'b000),                  // for V9958 MSX2+/tR VDP
      .CENTERYJK_R25_N(1'b0),                    // for V9958 MSX2+/tR VDP
      .PVIDEOR        (VideoR),
      .PVIDEOG        (VideoG),
      .PVIDEOB        (VideoB),
      .PVIDEOHS_N     (VideoHS_n),
      .PVIDEOVS_N     (VideoVS_n),
      .PVIDEODHCLK    (VideoDHClk),
      .PVIDEODLCLK    (VideoDLClk),
      .NTSC_PAL_TYPE  (1'b1),
      .PAL_MODE       (pal_mode),
      .SPMAXSPR       (1'b0),
      .CX             (vdp_cx),
      .CY             (vdp_cy)
  );

  //--------------------------------------------------------------
  // Video output
  //--------------------------------------------------------------

  wire [7:0] dvi_r;
  wire [7:0] dvi_g;
  wire [7:0] dvi_b;
  reg ff_video_reset;
  wire hdmi_reset;
  wire [15:0] sample_w;
  reg [15:0] audio_sample_word[1:0], audio_sample_word0[1:0];
  logic [ 2:0] tmds;
  logic [11:0] cx;
  logic [10:0] cy;
  bit          scanlin;

  assign scanlin = 1'b0;

  assign dvi_r   = (scanlin && cy[0]) ? {1'b0, VideoR, 1'b0} : {VideoR, 2'b0};
  assign dvi_g   = (scanlin && cy[0]) ? {1'b0, VideoG, 1'b0} : {VideoG, 2'b0};
  assign dvi_b   = (scanlin && cy[0]) ? {1'b0, VideoB, 1'b0} : {VideoB, 2'b0};

  assign int_n   = pVdpInt_n ? 1'bz : 1'b0;

  always_ff @(posedge clk_w) begin
    ff_video_reset <= 1'b0;

    if (vdp_cx == 11'd0 && vdp_cy == 11'd0) begin
      if ((pal_mode == 1'b0 && !(cx == 12'd0 && cy == `NTSC_Y)) || (pal_mode == 1'b1 && !(cx == 12'd0 && cy == `PAL_Y))) ff_video_reset <= 1'b1;
    end
  end

  assign hdmi_reset = ff_video_reset | reset_w | ~ram_enabled;

  always @(posedge clk_w) begin  // crossing clock domain
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



