
module WS2812_REGISTERS (
    input bit clk,  // standard clock
    input bit reset_n,  //active low reset signal

    input bit [1:0] addr,  //address of register to be written or read from

    input bit ws2812_io_req,  //active when a input or output request is active
    input bit ws2812_io_wr,   //for current req (if active), this is active when a write is requested

    input  bit [7:0] ws2812_data_in,  //when (ws2812_io_req & !ws2812_io_wr) this is the latched data from CPU
    output bit [7:0] ws2812_data_out  // when (ws2812_io_req & ws2812_io_wr) this is the data to be written to CPU
);

  reg [7:0] registers[3:0];  // Declare 4 8-bit registers

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      registers[0] <= 8'b0;
      registers[1] <= 8'b0;
      registers[2] <= 8'b0;
      registers[3] <= 8'b0;

    end else if (ws2812_io_req) begin
      if (ws2812_io_wr) begin
        // Write operation
        registers[addr] <= ws2812_data_in;

      end else begin
        // Read operation
        ws2812_data_out <= registers[addr];
      end
    end
  end

endmodule
