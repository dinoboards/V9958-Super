
module AUDIO #(
    parameter int AUDIO_BIT_WIDTH = 16
) (
    input bit clk,
    input bit clk_135,
    input bit reset_n,
    output logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word[1:0],

    // ADC SPI interface
    input  bit adc_miso,
    output bit adc_clk,
    output bit adc_cs,
    output bit adc_mosi
);

  bit [15:0] sample_w;
  bit [15:0] audio_sample_word0[1:0];
  bit [15:0] adc_sample;
  bit sck_enable;
  bit [11:0] audio_sample;
  bit sample_valid;

  always @(posedge clk) begin
    audio_sample_word0[0] <= sample_w;
    audio_sample_word[0]  <= audio_sample_word0[0];
    audio_sample_word0[1] <= sample_w;
    audio_sample_word[1]  <= audio_sample_word0[1];
  end

  SPI_MCP3202_2 #(
      .SGL(1),  // sets ADC to single ended mode
      .ODD(0)   // sets sample input to channel 0
  ) SPI_MCP3202 (
      .clk       (clk_135),       //
      .EN        (reset_n),       // Enable the SPI core (ACTIVE HIGH)
      .MISO      (adc_miso),      // data out of ADC (Dout pin)
      .MOSI      (adc_mosi),      // Data into ADC (Din pin)
      .SCK       (adc_clk),
      .o_DATA    (audio_sample),  // 12 bit word (for other modules)
      .CS        (adc_cs),        // Chip Select
      .DATA_VALID(sample_valid)   // is high when there is a full 12 bit word.
  );

  always_ff @(posedge clk_135) begin
    if (sample_valid) adc_sample <= {audio_sample[11:0], 4'b0};
  end

  assign sample_w = adc_sample;

endmodule
