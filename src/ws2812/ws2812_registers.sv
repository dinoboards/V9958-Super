
// 30h to 32h
// 0011 00XY
// write LED number to 30H
// write 3 bytes (RGB) to 31H
// or read 3 bytes (RGB) from 31H
// after three reads or writes, the LED number is incremented.
// 32H - write the number of attached LEDs in strip (defaults to MAX_PIXELS)

module WS2812_REGISTERS (
    input bit clk,  // standard clock
    input bit reset_n,  //active low reset signal

    input bit [1:0] addr,  //address of register to be written or read from

    input bit ws2812_io_req,  //active when a input or output request is active
    input bit ws2812_io_wr,   //for current req (if active), this is active when a write is requested

    input  bit [7:0] ws2812_data_in,  //when (ws2812_io_req & !ws2812_io_wr) this is the latched data from CPU
    output bit [7:0] ws2812_data_out, // when (ws2812_io_req & ws2812_io_wr) this is the data to be written to CPU

    output bit [7:0] number_of_pixels,

    output bit pixel_we,
    output bit [7:0] pixel_dbo,
    input bit [7:0] pixel_dbi,
    // 3 bytes per RGB - bytes 0, 1, 2 for first pixel, 3, 4, 5 for second pixel, etc.
    output bit [9:0] pixel_addr  // Index into pixel
);

  parameter MAX_PIXELS = 4;

  bit [7:0] i_number_of_pixels;

  assign number_of_pixels = i_number_of_pixels;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_addr <= 0;
      i_number_of_pixels <= MAX_PIXELS;

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
              i_number_of_pixels <= ws2812_data_in;
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
              ws2812_data_out <= i_number_of_pixels;
            end
          endcase
        end
      end
    end
  end

endmodule
