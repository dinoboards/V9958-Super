module WS2812_TRANSMITTER (
    input clk,  // input clock source
    input bit reset_n,
    input bit [7:0] number_of_pixels,

    output bit WS2812,  // output to the interface of WS2812

    output bit [9:0] pixel_addr,  // Index into pixel
    input  bit [7:0] pixel_dbi
);

  parameter BIT_WIDTH = 8;  // storage bit width
  parameter CLK_FRE = 27_000_000;  // CLK frequency (Mhz)

  parameter DELAY_1_HIGH = (CLK_FRE / 1_000_000 * 0.85) - 1;  //≈850ns±150ns     1 high level time
  parameter DELAY_1_LOW = (CLK_FRE / 1_000_000 * 0.40) - 1;  //≈400ns±150ns 	 1 low level time
  parameter DELAY_0_HIGH = (CLK_FRE / 1_000_000 * 0.40) - 1;  //≈400ns±150ns 	 0 high level time
  parameter DELAY_0_LOW = (CLK_FRE / 1_000_000 * 0.85) - 1;  //≈850ns±150ns     0 low level time
  parameter DELAY_RESET = (CLK_FRE / 1_000_000 * 1000) - 1;  //1000us delay reset time ＞50us

  parameter RESET = 0;  //state machine statement
  parameter DATA_SEND = 1;
  parameter BIT_SEND_HIGH = 2;
  parameter BIT_SEND_LOW = 3;
  parameter DATA_SEND_FIRST = 4;

  bit [ 2:0] state;  // main state machine
  bit [ 3:0] bit_sent;  // 7 to 0 (to 15 overflow)
  bit [31:0] clk_count;  // delay control
  bit [ 7:0] WS2812_data;  // WS2812 buffered data
  bit [ 9:0] pixel_end_addr;

  always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      WS2812_data <= 8'h5A;
      state       <= 0;
      bit_sent    <= 4'd7;
      clk_count   <= 0;
      pixel_addr  <= 0;

    end else begin
      case (state)
        RESET: begin
          WS2812 <= 0;
          if (clk_count < DELAY_RESET) begin
            pixel_addr     <= 10'd0;
            clk_count      <= 32'(clk_count + 1);
            pixel_end_addr <= 10'(number_of_pixels * 3);

          end else begin
            clk_count      <= 32'd0;
            pixel_end_addr <= 10'(pixel_end_addr + 3);
            pixel_addr     <= 10'd0;
            bit_sent       <= 4'd7;
            state          <= DATA_SEND_FIRST;
          end
        end

        DATA_SEND_FIRST: begin
          WS2812_data <= pixel_dbi;
          pixel_addr  <= 10'd1;
          state       <= BIT_SEND_HIGH;
        end

        DATA_SEND: begin
          if (pixel_end_addr == pixel_addr && bit_sent[3]) begin
            clk_count <= 32'd0;
            bit_sent  <= 4'd7;
            state     <= RESET;

          end else if (!bit_sent[3]) begin
            state <= BIT_SEND_HIGH;

          end else begin
            WS2812_data <= pixel_dbi;
            pixel_addr  <= 10'(pixel_addr + 1);
            bit_sent    <= 4'd7;
            state       <= BIT_SEND_HIGH;
          end
        end

        BIT_SEND_HIGH: begin
          WS2812 <= 1;

          if (WS2812_data[bit_sent]) begin
            if (clk_count < DELAY_1_HIGH) begin
              clk_count <= 32'(clk_count + 1);

            end else begin
              clk_count <= 32'd0;
              state     <= BIT_SEND_LOW;
            end

          end else if (clk_count < DELAY_0_HIGH) begin
            clk_count <= 32'(clk_count + 1);

          end else begin
            clk_count <= 32'd0;
            state     <= BIT_SEND_LOW;

          end
        end

        BIT_SEND_LOW: begin
          WS2812 <= 0;

          if (WS2812_data[bit_sent]) begin
            if (clk_count < DELAY_1_LOW) begin
              clk_count <= 32'(clk_count + 1);

            end else begin
              clk_count <= 32'd0;
              bit_sent  <= 4'(bit_sent - 1);
              state     <= DATA_SEND;
            end

          end else if (clk_count < DELAY_0_LOW) begin
            clk_count <= 32'(clk_count + 1);

          end else begin
            clk_count <= 32'd0;
            bit_sent  <= 4'(bit_sent - 1);
            state     <= DATA_SEND;

          end
        end
      endcase
    end
endmodule
