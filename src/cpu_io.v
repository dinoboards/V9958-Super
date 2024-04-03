
module cpu_io (
    input bit clk,
    input bit reset_n,
    input bit [7:2] A,
    inout logic [7:0] cd,
    input bit clk_sdram,
    input bit [7:0] CpuDbi,
    input bit rd_iorq_n,
    input bit wr_iorq_n,

    output bit CpuReq,
    output bit CpuWrt,
    output bit [7:0] CpuDbo,
    output bit cs_n
);

  bit       cswn_w;
  bit       csrn_w;
  bit       io_state_r = 1'b0;
  bit [1:0] cs_latch;
  bit       addr;
  bit       csw_n;
  bit       csr_n;

  assign addr = A[7] & ~A[6] & ~A[5] & A[4] & A[3] & ~A[2];  // $98 TO $9B
  assign csr_n = !(addr & !rd_iorq_n);
  assign csw_n = !(addr & !wr_iorq_n);
  assign cs_n = csr_n & csw_n;

  assign cd = csr_n == 0 ? CpuDbi : 8'bzzzzzzzz;

  PINFILTER cswn_filter (
      .clk(clk_sdram),
      .reset_n(reset_n),
      .din(csw_n),
      .dout(cswn_w)
  );

  PINFILTER csrn_filter (
      .clk(clk_sdram),
      .reset_n(reset_n),
      .din(csr_n),
      .dout(csrn_w)
  );

  always @(posedge clk or negedge reset_n) begin
    if (reset_n == 0) begin
      io_state_r = 1'b0;

      CpuDbo = 1'b0;
      CpuWrt = 1'b0;
      CpuReq = 1'b0;

    end else begin
      if (!io_state_r) begin
        CpuDbo = cd;
        CpuReq = (csrn_w ^ cswn_w);
        CpuWrt = ~cswn_w;

        cs_latch = {csrn_w, cswn_w};
        io_state_r = 1'b1;

      end else begin
        CpuWrt = 1'b0;
        CpuReq = 1'b0;

        if (cs_latch != {csrn_w, cswn_w}) begin
          io_state_r = 1'b0;
        end

      end
    end
  end


endmodule
