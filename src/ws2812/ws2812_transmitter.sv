module WS2812_TRANSMITTER (
    input clk,  // input clock source
    input bit reset_n,
    input bit [7:0] number_of_pixels,

    output bit WS2812  // output to the interface of WS2812
);

  parameter WS2812_WIDTH = 24;  // WS2812 data bit width
  parameter CLK_FRE = 27_000_000;  // CLK frequency (mHZ)

  parameter DELAY_1_HIGH = (CLK_FRE / 1_000_000 * 0.85) - 1;  //≈850ns±150ns     1 high level time
  parameter DELAY_1_LOW = (CLK_FRE / 1_000_000 * 0.40) - 1;  //≈400ns±150ns 	 1 low level time
  parameter DELAY_0_HIGH = (CLK_FRE / 1_000_000 * 0.40) - 1;  //≈400ns±150ns 	 0 high level time
  parameter DELAY_0_LOW = (CLK_FRE / 1_000_000 * 0.85) - 1;  //≈850ns±150ns     0 low level time
  parameter DELAY_RESET = (CLK_FRE) - 1;  //0.1s reset time ＞50us

  parameter RESET = 0;  //state machine statement
  parameter DATA_SEND = 1;
  parameter BIT_SEND_HIGH = 2;
  parameter BIT_SEND_LOW = 3;

  parameter INIT_DATA = 24'b1111;  // initial pattern

  bit [ 1:0] state;  // synthesis preserve  - main state machine control
  bit [ 8:0] bit_send;  // number of bits sent - increase for larger led strips/matrix
  bit [ 8:0] data_send;  // number of data sent - increase for larger led strips/matrix
  bit [31:0] clk_count;  // delay control
  bit [23:0] WS2812_data;  // WS2812 color data

  always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      state <= 0;
      bit_send <= 0;
      data_send <= 0;
      clk_count <= 0;
      WS2812_data <= 0;
    end else begin
      case (state)
        RESET: begin
          WS2812 <= 0;
          if (clk_count < DELAY_RESET) begin
            clk_count <= clk_count + 1;
          end else begin
            clk_count <= 0;
            if (WS2812_data == 0) WS2812_data <= INIT_DATA;
            else WS2812_data <= {WS2812_data[22:0], WS2812_data[23]};  //color shift cycle display
            state <= DATA_SEND;
          end
        end

        DATA_SEND:
        if (data_send > number_of_pixels && bit_send == WS2812_WIDTH) begin
          clk_count <= 0;
          data_send <= 0;
          bit_send <= 0;
          state <= RESET;
        end else if (bit_send < WS2812_WIDTH) begin
          state <= BIT_SEND_HIGH;
        end else begin
          data_send <= 9'(data_send + 1);
          bit_send  <= 0;
          state    <= BIT_SEND_HIGH;
        end

        BIT_SEND_HIGH: begin
          WS2812 <= 1;

          if (WS2812_data[bit_send])
            if (clk_count < DELAY_1_HIGH) clk_count <= clk_count + 1;
            else begin
              clk_count <= 0;
              state    <= BIT_SEND_LOW;
            end
          else if (clk_count < DELAY_0_HIGH) clk_count <= clk_count + 1;
          else begin
            clk_count <= 0;
            state    <= BIT_SEND_LOW;
          end
        end

        BIT_SEND_LOW: begin
          WS2812 <= 0;

          if (WS2812_data[bit_send])
            if (clk_count < DELAY_1_LOW) clk_count <= clk_count + 1;
            else begin
              clk_count <= 0;

              bit_send <= 9'(bit_send + 1);
              state    <= DATA_SEND;
            end
          else if (clk_count < DELAY_0_LOW) clk_count <= clk_count + 1;
          else begin
            clk_count <= 0;

            bit_send <= 9'(bit_send + 1);
            state    <= DATA_SEND;
          end
        end
      endcase
    end
endmodule
