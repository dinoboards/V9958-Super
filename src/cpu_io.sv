
module CPU_IO (
    input bit clk,
    input bit reset_n,
    input bit [7:2] A,
    inout logic [7:0] cd,
    input bit clk_sdram,
    input bit [7:0] vdp_data_out,
    input bit rd_iorq_n,
    input bit wr_iorq_n,

    output bit vdp_io_req,
    output bit vdp_io_wr,
    output bit [7:0] vdp_data_in,
    output bit cs_n
);

  bit       io_state_r = 1'b0;
  bit [1:0] cs_latch;
  bit       vdp_io_addr;
  bit       vdp_cs_wr_n;
  bit       vdp_cs_rd_n;

  assign vdp_io_addr = A[7] & ~A[6] & ~A[5] & A[4] & A[3] & ~A[2];  // $98 TO $9B
  assign vdp_cs_rd_n = !(vdp_io_addr & !rd_iorq_n);
  assign vdp_cs_wr_n = !(vdp_io_addr & !wr_iorq_n);
  assign cs_n = vdp_cs_rd_n & vdp_cs_wr_n;

  assign cd = vdp_cs_rd_n == 0 ? vdp_data_out : 8'bzzzzzzzz;

  always_ff @(posedge clk or negedge reset_n) begin
    if (reset_n == 0) begin
      io_state_r <= 1'b0;

      vdp_data_in <= 1'b0;
      vdp_io_wr <= 1'b0;
      vdp_io_req <= 1'b0;

    end else begin
      if (!io_state_r) begin
        vdp_data_in <= cd;
        vdp_io_req <= (vdp_cs_rd_n ^ vdp_cs_wr_n);
        vdp_io_wr <= ~vdp_cs_wr_n;

        cs_latch <= {vdp_cs_rd_n, vdp_cs_wr_n};
        io_state_r <= 1'b1;

      end else begin
        vdp_io_wr <= 1'b0;
        vdp_io_req <= 1'b0;

        if (cs_latch != {vdp_cs_rd_n, vdp_cs_wr_n}) begin
          io_state_r <= 1'b0;
        end

      end
    end
  end

endmodule
