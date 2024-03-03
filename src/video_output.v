
module video_output #(

    // Defaults to 640x480 which should be supported by almost if not all HDMI sinks.
    // See README.md or CEA-861-D for enumeration of video id codes.
    // Pixel repetition, interlaced scans and other special output modes are not implemented (yet).
    parameter int VIDEO_ID_CODE = 1,

    // Specify the refresh rate in Hz you are using for audio calculations
    parameter real VIDEO_REFRESH_RATE = 59.94,

    // Defaults to 16-bit audio, the minmimum supported by HDMI sinks. Can be anywhere from 16-bit to 24-bit.
    parameter int AUDIO_BIT_WIDTH = 16,

    // As specified in Section 7.3, the minimal audio requirements are met: 16-bit or more L-PCM audio at 32 kHz, 44.1 kHz, or 48 kHz.
    // See Table 7-4 or README.md for an enumeration of sampling frequencies supported by HDMI.
    // Note that sinks may not support rates above 48 kHz.
    parameter int AUDIO_RATE = 44100,

    // Starting screen coordinate when module comes out of reset.
    //
    // Setting these to something other than (0, 0) is useful when positioning
    // an external video signal within a larger overall frame (e.g.
    // letterboxing an input video signal). This allows you to synchronize the
    // negative edge of reset directly to the start of the external signal
    // instead of to some number of clock cycles before.
    //
    // You probably don't need to change these parameters if you are
    // generating a signal from scratch instead of processing an
    // external signal.
    parameter int START_Y = 0,
    parameter int NUM_CHANNELS = 3
) (

    input dvi_output,
    input clk_pixel_x5,
    input clk_pixel,
    input clk_audio,

    // synchronous reset back to 0,0
    input logic reset,
    input logic [23:0] rgb,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word[1:0],


    output logic [9:0] tmds_channels[NUM_CHANNELS-1:0],

    // All outputs below this line stay inside the FPGA
    // They are used (by you) to pick the color each pixel should have
    // i.e. always_ff @(posedge pixel_clk) rgb <= {8'd0, 8'(cx), 8'(cy)};
    output logic [11:0] cx,
    output logic [10:0] cy
);

  logic [11:0] cx_hdmi;
  logic [10:0] cy_hdmi;
  logic [11:0] cx_dvi;
  logic [10:0] cy_dvi;

  logic [ 9:0] tmds_channels_hdmi[NUM_CHANNELS-1:0];
  logic [ 9:0] tmds_channels_dvi [NUM_CHANNELS-1:0];

  assign cx = dvi_output ? cx_dvi : cx_hdmi;
  assign cy = dvi_output ? cy_dvi : cy_hdmi;
  assign tmds_channels = dvi_output ? tmds_channels_dvi : tmds_channels_hdmi;

  hdmi #(
      .VIDEO_ID_CODE(VIDEO_ID_CODE),
      .DVI_OUTPUT(0),
      .VIDEO_REFRESH_RATE(VIDEO_REFRESH_RATE),
      .IT_CONTENT(1),
      .VENDOR_NAME({"Unknown", 8'd0}),  // Must be 8 bytes null-padded 7-bit ASCII
      .PRODUCT_DESCRIPTION({"FPGA", 96'd0}),  // Must be 16 bytes null-padded 7-bit ASCII
      .SOURCE_DEVICE_INFORMATION(8'h00),  // See README.md or CTA-861-G for the list of valid codes
      .START_X(0),
      .START_Y(START_Y)
  ) hdmi_ntsc (
      .clk_pixel_x5(clk_pixel_x5),
      .clk_pixel(clk_pixel),
      .clk_audio(clk_audio),
      .rgb(rgb),
      .reset(reset),
      .audio_sample_word(audio_sample_word),
      .cx(cx_hdmi),
      .cy(cy_hdmi),
      .tmds_channels(tmds_channels_hdmi),
      .frame_width(),
      .frame_height(),
      .screen_width(),
      .screen_height()
  );

  hdmi #(
      .VIDEO_ID_CODE(VIDEO_ID_CODE),
      .DVI_OUTPUT(1),
      .VIDEO_REFRESH_RATE(VIDEO_REFRESH_RATE),
      .IT_CONTENT(1),
      .START_X(0),
      .START_Y(START_Y)
  ) dvi_ntsc (
      .clk_pixel_x5(clk_pixel_x5),
      .clk_pixel(clk_pixel),
      .clk_audio(1'bx),
      .rgb(rgb),
      .reset(reset),
      .audio_sample_word({{16'bx}, {16'bx}}),
      .cx(cx_dvi),
      .cy(cy_dvi),
      .tmds_channels(tmds_channels_dvi),
      .frame_width(),
      .frame_height(),
      .screen_width(),
      .screen_height()
  );

endmodule
