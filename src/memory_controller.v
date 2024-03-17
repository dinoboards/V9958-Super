/*
The memory_controller module is designed to interface with the GOWIN's SDRAM memory module. It provides
upto 8MBytes of storage, organized as 4M 16-bit words. The module supports read, write, and auto-
refresh operations, controlled by the read, write, and refresh inputs respectively.

For write operations, the wdm (write data mask) input is used to specify which byte (or bytes) of the
16-bit data word is to be updated. For read operations, both bytes of the 16-bit word are retrieved.

* If wdm is 01, then only the lower 8 bits are written;
* if wdm is 10, then only the upper 8 bits are written;
* if wdm is 11, then both bytes are written;
* if wdm is 00, then nothing will be updated.

The module provides a busy output to indicate when an operation is in progress, and a fail output
to indicate a timing mistake or SDRAM malfunction.

The physical interface to the SDRAM is provided by the IO_sdram_dq, O_sdram_addr, O_sdram_ba, O_sdram_cs_n,
O_sdram_wen_n, O_sdram_ras_n, O_sdram_cas_n, O_sdram_clk, O_sdram_cke, and O_sdram_dqm signals.  These must
map to the gowin special pins to access the onchip SDRAM
*/

module memory_controller #(
    parameter int FREQ = 54_000_000
) (
    input  bit          clk,        // Main logic clock (max speed is 166.7Mh - see SRAM.v)
    input  bit          clk_sdram,  // A clock signal that is 180 degrees out of phase with the main clock.
    input  bit          resetn,     // Active low reset signal.
    input  bit          read,       // Signal to initiate a read operation from the SDRAM
    input  bit          write,      // Signal to initiate a write operation to the SDRAM
    input  bit          refresh,    // Signal to initiate an auto-refresh operation in the SDRAM
    input  bit   [22:0] addr,       // The address to read from or write to in the SDRAM
    input  bit   [15:0] din,        // The data to be written to the SDRAM (only the byte specified by wdm is written 01 or 10)
    input  logic [31:0] din32,      // The data to be written to the SDRAM when wdm is 00
    input  bit   [ 1:0] wdm,        // Write data mask
    output bit   [15:0] dout,       // The data read from the SDRAM. Available 4 cycles after the read signal is set.
    output bit          busy,       // Signal indicating that an operation is in progress.
    output bit          enabled,    // Signal indicating that the memory controller is enabled.
    output bit   [31:0] dout32,

    // debug interface
    output bit fail,  // Signal indicating a timing mistake or SDRAM malfunction

    // GoWin's Physical SDRAM interface
    inout  logic [31:0] IO_sdram_dq,    // 32 bit bidirectional data bus
    output bit   [10:0] O_sdram_addr,   // 11 bit multiplexed address bus
    output bit   [ 1:0] O_sdram_ba,     // 4 banks
    output bit          O_sdram_cs_n,   // chip select
    output bit          O_sdram_wen_n,  // write enable
    output bit          O_sdram_ras_n,  // row address strobe
    output bit          O_sdram_cas_n,  // columns address strobe
    output bit          O_sdram_clk,    // sdram's clock
    output bit          O_sdram_cke,    // sdram's clock enable
    output bit   [ 3:0] O_sdram_dqm     // data mask control
);

  bit [22:0] MemAddr;
  bit MemRD, MemWR, MemRefresh, MemInitializing;
  bit [15:0] MemDin;
  bit [31:0] MemDin32;
  bit [15:0] MemDout;
  bit [31:0] MemDout32;
  bit [2:0] cycles;
  bit r_read;
  bit [15:0] data;
  bit [31:0] data32;
  bit MemBusy, MemDataReady;

  assign dout   = (cycles == 3'd4 && r_read) ? MemDout : data;
  assign dout32 = (cycles == 3'd4 && r_read) ? MemDout32 : data32;

  // SDRAM driver
  sdram #(
      .FREQ(FREQ)
  ) u_sdram (
      .clk(clk),
      .clk_sdram(clk_sdram),
      .resetn(resetn),
      .addr(busy ? MemAddr : addr),
      .rd(busy ? MemRD : read),
      .wr(busy ? MemWR : write),
      .refresh(busy ? MemRefresh : refresh),
      .din(busy ? MemDin : din),
      .din32(busy ? MemDin32 : din32),
      .wdm(wdm),
      .dout(MemDout),
      .dout32(MemDout32),
      .busy(MemBusy),
      .data_ready(MemDataReady),
      .enabled(enabled),

      .IO_sdram_dq(IO_sdram_dq),
      .O_sdram_addr(O_sdram_addr),
      .O_sdram_ba(O_sdram_ba),
      .O_sdram_cs_n(O_sdram_cs_n),
      .O_sdram_wen_n(O_sdram_wen_n),
      .O_sdram_ras_n(O_sdram_ras_n),
      .O_sdram_cas_n(O_sdram_cas_n),
      .O_sdram_clk(O_sdram_clk),
      .O_sdram_cke(O_sdram_cke),
      .O_sdram_dqm(O_sdram_dqm)
  );

  always @(posedge clk or negedge resetn) begin

    if (~resetn) begin
      busy <= 1'b1;
      fail <= 1'b0;
      MemInitializing <= 1'b1;
    end else begin
      MemWR <= 1'b0;
      MemRD <= 1'b0;
      MemRefresh <= 1'b0;
      cycles <= cycles == 3'd7 ? 3'd7 : cycles + 3'd1;

      // Initiate read or write
      if (!busy) begin
        if (read || write || refresh) begin
          MemAddr <= addr;
          MemWR <= write;
          MemRD <= read;
          MemRefresh <= refresh;
          busy <= 1'b1;
          MemDin <= din;
          MemDin32 <= din32;
          cycles <= 3'd1;
          r_read <= read;

        end
      end else if (MemInitializing) begin
        if (~MemBusy) begin
          // initialization is done
          MemInitializing <= 1'b0;
          busy <= 1'b0;
        end
      end else begin
        // Wait for operation to finish and latch incoming data on read.
        if (cycles == 3'd4) begin
          busy <= 0;
          if (r_read) begin
            if (~MemDataReady)  // assert data ready
              fail <= 1'b1;
            if (r_read) begin
              data   <= MemDout;
              data32 <= MemDout32;
            end
            r_read <= 1'b0;
          end
        end
      end
    end
  end

endmodule
