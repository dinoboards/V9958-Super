
// 30h to 32h
// 0011 00XY
// write LED number to 30H
// write 3 bytes (RGB) to 31H
// or read 3 bytes (RGB) from 31H
// after three reads or writes, the LED number is incremented.
// 32H - write the number of attached LEDs in strip (defaults to MAX_NUM_LEDS)

module WS2812_REGISTERS #(
    parameter MAX_NUM_LEDS = 4
) (
    input bit clk,  // standard clock
    input bit reset_n,  //active low reset signal

    input bit [1:0] addr,  //address of register to be written or read from

    input bit ws2812_io_req,  //active when a input or output request is active
    input bit ws2812_io_wr,   //for current req (if active), this is active when a write is requested

    input  bit [7:0] ws2812_data_in,  //when (ws2812_io_req & !ws2812_io_wr) this is the latched data from CPU
    output bit [7:0] ws2812_data_out  // when (ws2812_io_req & ws2812_io_wr) this is the data to be written to CPU
);

  bit pixel_we;
  bit [7:0] pixel_dbo;
  bit [7:0] pixel_dbi;
  // 3 bytes per RGB - bytes 0, 1, 2 for first pixel, 3, 4, 5 for second pixel, etc.
  reg [9:0] pixel_addr;  // Index into pixel
  reg [7:0] number_of_pixel;

  RAM10 #(
      .MEM_SIZE(256 * 3)
  ) pixel (
      .CLK(clk),
      .ADR(pixel_addr),
      .WE (pixel_we),
      .DBO(pixel_dbo),
      .DBI(pixel_dbi)
  );

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_addr <= 0;
      number_of_pixel <= MAX_NUM_LEDS;

    end else begin
      pixel_we <= 0;
      if (ws2812_io_req) begin
        if (ws2812_io_wr) begin
          case (addr)
            0: begin
              pixel_addr <= ws2812_data_in * 3;
            end

            1: begin
              pixel_dbo  <= ws2812_data_in;
              pixel_we   <= 1;
              pixel_addr <= 10'(pixel_addr + 1);
            end

            2: begin
              number_of_pixel <= ws2812_data_in;
            end
          endcase
        end else begin
          case (addr)
            0: begin
              ws2812_data_out <= 8'(pixel_addr);
            end

            1: begin
              ws2812_data_out <= pixel_dbi;
              pixel_addr <= 10'(pixel_addr + 1);

            end
            2: begin
              ws2812_data_out <= number_of_pixel;
            end
          endcase
        end
      end
    end
  end

endmodule
