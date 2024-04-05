module SERIALIZER_DIPLEXER #(
    parameter int  NUM_CHANNELS = 3,
    parameter real VIDEO_RATE   = 0
) (
    input logic clk_pixel,
    input logic clk_pixel_x5,
    input logic reset,

    input logic pal_mode,
    input logic [9:0] tmds_channels_pal[NUM_CHANNELS-1:0],
    input logic [9:0] tmds_channels_ntsc[NUM_CHANNELS-1:0],
    output logic [2:0] tmds
);

  logic [9:0] tmds_channels[NUM_CHANNELS-1:0];

  assign tmds_channels = pal_mode ? tmds_channels_pal : tmds_channels_ntsc;

  SERIALIZER #(
      .NUM_CHANNELS(NUM_CHANNELS),
      .VIDEO_RATE  (VIDEO_RATE)
  ) serializer (
      .clk_pixel(clk_pixel),
      .clk_pixel_x5(clk_pixel_x5),
      .reset(reset),
      .tmds_internal(tmds_channels),
      .tmds(tmds),
      .tmds_clock()
  );


endmodule

module SERIALIZER #(
    parameter int  NUM_CHANNELS = 3,
    parameter real VIDEO_RATE
) (
    input logic clk_pixel,
    input logic clk_pixel_x5,
    input logic reset,
    input logic [9:0] tmds_internal[NUM_CHANNELS-1:0],
    output logic [2:0] tmds,
    output logic tmds_clock
);

  OSER10 gwSer0 (
      .Q(tmds[0]),
      .D0(tmds_internal[0][0]),
      .D1(tmds_internal[0][1]),
      .D2(tmds_internal[0][2]),
      .D3(tmds_internal[0][3]),
      .D4(tmds_internal[0][4]),
      .D5(tmds_internal[0][5]),
      .D6(tmds_internal[0][6]),
      .D7(tmds_internal[0][7]),
      .D8(tmds_internal[0][8]),
      .D9(tmds_internal[0][9]),
      .PCLK(clk_pixel),
      .FCLK(clk_pixel_x5),
      .RESET(reset)
  );

  OSER10 gwSer1 (
      .Q(tmds[1]),
      .D0(tmds_internal[1][0]),
      .D1(tmds_internal[1][1]),
      .D2(tmds_internal[1][2]),
      .D3(tmds_internal[1][3]),
      .D4(tmds_internal[1][4]),
      .D5(tmds_internal[1][5]),
      .D6(tmds_internal[1][6]),
      .D7(tmds_internal[1][7]),
      .D8(tmds_internal[1][8]),
      .D9(tmds_internal[1][9]),
      .PCLK(clk_pixel),
      .FCLK(clk_pixel_x5),
      .RESET(reset)
  );

  OSER10 gwSer2 (
      .Q(tmds[2]),
      .D0(tmds_internal[2][0]),
      .D1(tmds_internal[2][1]),
      .D2(tmds_internal[2][2]),
      .D3(tmds_internal[2][3]),
      .D4(tmds_internal[2][4]),
      .D5(tmds_internal[2][5]),
      .D6(tmds_internal[2][6]),
      .D7(tmds_internal[2][7]),
      .D8(tmds_internal[2][8]),
      .D9(tmds_internal[2][9]),
      .PCLK(clk_pixel),
      .FCLK(clk_pixel_x5),
      .RESET(reset)
  );

  assign tmds_clock = clk_pixel;

endmodule
