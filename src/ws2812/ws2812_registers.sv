
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
  bit [1:0] pixel_addr_adj;
  bit wr_done;

  assign number_of_pixels = i_number_of_pixels;

  // the pixel_addr is into a GRB 24 bit colour array
  // we want to model a RGB sequence
  // so first byte to assign is RED of PIXEL 0 -> addr 1
  // 2nd byte to assign is GREEN of PIXEL 0 -> addr 0
  // 3rd byte to assign is BLUE of PIXEL 0 -> addr 2
  // 4th byte to assign is RED of PIXEL 1 -> addr 4
  // 5th byte to assign is GREEN of PIXEL 1 -> addr 3
  // 6th byte to assign is BLUE of PIXEL 1 -> addr 5
  // so sequence of address is:
  // 1, 0, 2,       4, 3, 5,      7, 6, 8,       10, 9, 11, ...
  // and the incrementing sequence is (starting at 1)
  // --, -1, +2,   +2, -1, +2,    +2, -1, +2,    +2, -1, +2, +2, ...


  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pixel_addr <= 1;
      pixel_addr_adj <= 0;
      wr_done <= 0;
      i_number_of_pixels <= MAX_PIXELS;

    end else begin
      if (pixel_we) begin
        pixel_we <= 0;
        case (pixel_addr_adj)
          0: pixel_addr <= 10'(pixel_addr - 1);  // move from RED to GREEN
          1: pixel_addr <= 10'(pixel_addr + 2);  // move from GREEN to BLUE
          2: pixel_addr <= 10'(pixel_addr + 2);  // move from BLUE to next RED
        endcase
        pixel_addr_adj <= pixel_addr_adj == 2'd2 ? 0 : 2'(pixel_addr_adj + 1);
      end

      if (ws2812_io_req) begin
        if (ws2812_io_wr) begin
          case (addr)
            0: begin
              pixel_addr <= 10'(ws2812_data_in * 3 + 1);
              pixel_addr_adj <= 0;
            end

            1: begin
              pixel_dbo <= ws2812_data_in;
              pixel_we  <= 1;
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
              case (pixel_addr_adj)
                0: pixel_addr <= 10'(pixel_addr - 1);  // move from RED to GREEN
                1: pixel_addr <= 10'(pixel_addr + 2);  // move from GREEN to BLUE
                2: pixel_addr <= 10'(pixel_addr + 2);  // move from BLUE to next RED
              endcase
              pixel_addr_adj <= pixel_addr_adj == 2'd2 ? 0 : 2'(pixel_addr_adj + 1);

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
