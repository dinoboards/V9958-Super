`include "..\features.vh"

module CPU_IO (
    input bit clk,
    input bit reset_n,
    input bit [7:2] A,
    inout logic [7:0] cd,
    input bit clk_sdram,
    input bit [7:0] vdp_data_out,
    input bit rd_n,
    input bit wr_n,
    input bit iorq_n,
    output bit cs_n,

    output bit vdp_io_req,
    output bit vdp_io_wr,
    output bit [7:0] vdp_data_in

`ifdef ENABLE_WS2812
    ,
    input bit [7:0] ws2812_data_out,
    output bit ws2812_io_req,
    output bit ws2812_io_wr,
    output bit [7:0] ws2812_data_in
`endif
);

  bit rd_iorq_n;
  bit wr_iorq_n;

  assign rd_iorq_n = rd_n | iorq_n;
  assign wr_iorq_n = wr_n | iorq_n;

  bit       io_state_r = 0;
  bit [1:0] cs_latch;
  bit       vdp_io_addr;
  bit       vdp_cs_wr_n;
  bit       vdp_cs_rd_n;

  assign vdp_io_addr = A[7] & ~A[6] & ~A[5] & A[4] & A[3] & ~A[2];  // $98 TO $9B
  assign vdp_cs_rd_n = !(vdp_io_addr & !rd_iorq_n);
  assign vdp_cs_wr_n = !(vdp_io_addr & !wr_iorq_n);

  always_ff @(posedge clk or negedge reset_n) begin
    if (reset_n == 0) begin
      io_state_r  <= 0;

      vdp_data_in <= 0;
      vdp_io_wr   <= 0;
      vdp_io_req  <= 0;

    end else begin
      if (!io_state_r) begin
        vdp_data_in <= cd;
        vdp_io_req <= (vdp_cs_rd_n ^ vdp_cs_wr_n);
        vdp_io_wr <= ~vdp_cs_wr_n;

        cs_latch <= {vdp_cs_rd_n, vdp_cs_wr_n};
        io_state_r <= 1;

      end else begin
        vdp_io_wr  <= 0;
        vdp_io_req <= 0;

        if (cs_latch != {vdp_cs_rd_n, vdp_cs_wr_n}) begin
          io_state_r <= 0;
        end

      end
    end
  end

`ifdef ENABLE_WS2812
  assign cs_n = vdp_cs_rd_n & vdp_cs_wr_n & ws2812_cs_rd_n & ws2812_cs_wr_n;

  assign cd   = vdp_cs_rd_n == 0 ? vdp_data_out : (ws2812_cs_rd_n == 0 ? ws2812_data_out : 8'bzzzzzzzz);

`else
  assign cs_n = vdp_cs_rd_n & vdp_cs_wr_n;

  assign cd   = vdp_cs_rd_n == 0 ? vdp_data_out : 8'bzzzzzzzz;

`endif

`ifdef ENABLE_WS2812
  bit       ws2812_io_state_r = 1'b0;
  bit [1:0] ws2812_latch;
  bit       ws2812_io_addr;
  bit       ws2812_cs_wr_n;
  bit       ws2812_cs_rd_n;

  //30h to 32h
  // 0011 00XY
  // write LED number to 30H
  // write 3 bytes (RGB) to 31H
  // or read 3 bytes (RGB) from 31H
  // after three reads or writes, the LED number is incremented.
  // 32H - write the number of attached LEDs in strip.
  assign ws2812_io_addr = ~A[7] & ~A[6] & A[5] & A[4] & ~A[3] & ~A[2];  // $30 TO $32
  assign ws2812_cs_rd_n = !(ws2812_io_addr & !rd_iorq_n);
  assign ws2812_cs_wr_n = !(ws2812_io_addr & !wr_iorq_n);

  always_ff @(posedge clk or negedge reset_n) begin
    if (reset_n == 0) begin
      ws2812_io_state_r <= 1'b0;

      ws2812_data_in <= 1'b0;
      ws2812_io_wr <= 1'b0;
      ws2812_io_req <= 1'b0;

    end else begin
      if (!ws2812_io_state_r) begin
        ws2812_data_in <= cd;
        ws2812_io_req <= (ws2812_cs_rd_n ^ ws2812_cs_wr_n);
        ws2812_io_wr <= ~ws2812_cs_wr_n;

        ws2812_latch <= {ws2812_cs_rd_n, ws2812_cs_wr_n};
        ws2812_io_state_r <= 1'b1;

      end else begin
        ws2812_io_wr  <= 1'b0;
        ws2812_io_req <= 1'b0;

        if (ws2812_latch != {ws2812_cs_rd_n, ws2812_cs_wr_n}) begin
          ws2812_io_state_r <= 1'b0;
        end

      end
    end
  end

`endif

endmodule
