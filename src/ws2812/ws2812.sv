
module WS2812 (
    input clk,  // input clock source
    input bit reset_n,

    output bit WS2812,  // output to the interface of WS2812

    input bit [1:0] mode,  //address of register to be written or read from

    input bit ws2812_io_req,  //active when a input or output request is active
    input bit ws2812_io_wr,   //for current req (if active), this is active when a write is requested

    input  bit [7:0] ws2812_data_in,  //when (ws2812_io_req & !ws2812_io_wr) this is the latched data from CPU
    output bit [7:0] ws2812_data_out  // when (ws2812_io_req & ws2812_io_wr) this is the data to be written to CPU

);

  bit [7:0] number_of_pixels;
  bit reg_pixel_we;
  bit [7:0] reg_pixel_dbo;
  bit [7:0] reg_pixel_dbi;
  // 3 bytes per RGB - bytes 0, 1, 2 for first pixel, 3, 4, 5 for second pixel, etc.
  bit [9:0] reg_pixel_addr;  // Index into pixel

  bit [9:0] tr_pixel_addr;  // Index into pixel
  bit [7:0] tr_pixel_dbi;

  DUAL_PORT_RAM10 #(
      .MEM_SIZE(256 * 3)
  ) pixel (
      .CLK(clk),
      .ADR1(reg_pixel_addr),
      .WE1 (reg_pixel_we),
      .DBO1(reg_pixel_dbo),
      .DBI1(reg_pixel_dbi),
      .ADR2(tr_pixel_addr),
      .DBI2(tr_pixel_dbi)
  );

  WS2812_TRANSMITTER transmitter (
      .clk(clk),
      .reset_n(reset_n),
      .WS2812(WS2812),

      .number_of_pixels(number_of_pixels),
      .pixel_addr(tr_pixel_addr),
      .pixel_dbi(tr_pixel_dbi)
  );

  WS2812_REGISTERS ws2812_registers (
      .clk(clk),
      .reset_n(reset_n),
      .addr(mode),
      .ws2812_io_req(ws2812_io_req),
      .ws2812_io_wr(ws2812_io_wr),
      .ws2812_data_in(ws2812_data_in),
      .ws2812_data_out(ws2812_data_out),

      .number_of_pixels(number_of_pixels),

      .pixel_addr(reg_pixel_addr),
      .pixel_we  (reg_pixel_we),
      .pixel_dbo (reg_pixel_dbo),
      .pixel_dbi (reg_pixel_dbi)
  );


endmodule
