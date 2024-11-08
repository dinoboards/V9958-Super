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


Need to support:
1. Writing a single 8 bit value (CPU->VDP VRAM and COMMAND write operations)
2. Read a 16 bit value for legacy rendering. {Also used for reading a 8 bit value for legacy (VDP->CPU and POINT COMMAND)}
3. Read a 32 bit value for super res rendering
4. Write a 32 bit value for COMMANDS on super res
5. Write a 16 bit value for COMMANDS on super res
*/

`include "vdp_constants.vh"
`include "features.vh"

module MEM_CONTROLLER #(
    parameter int FREQ = 54_000_000
) (
    input bit        clk,        // Main logic clock (max speed is 166.7Mh - see SRAM.v)
    input bit        clk_sdram,  // A clock signal that is 180 degrees out of phase with the main clock.
    input bit        resetn,     // Active low reset signal.
    input bit        read,       // Signal to initiate a read operation from the SDRAM
    input bit        write,      // Signal to initiate a write operation to the SDRAM
    input bit        refresh,    // Signal to initiate an auto-refresh operation in the SDRAM
    input bit [22:0] addr,       // The address to read from or write to in the SDRAM


    input bit [7:0] din8,  // The data to be written to the SDRAM (only the byte specified by wdm is written 01 or 10)
`ifdef ENABLE_SUPER_RES
    input bit [1:0] word_wr_size,  //00 -> 8, 01 -> 16, 10 -> 32, 11 -> ??
    input bit [15:0] din16,  // The data to be written to the SDRAM (only the byte specified by wdm is written 01 or 10)
    input logic [31:0] din32,  // The data to be written to the SDRAM when wdm is 00
    output bit [31:0] dout32,
    output bit [31:0] dout32B,  //2nd channel of 32 bit data - to avoid congestion???
`endif
    output bit [15:0] dout16,  // The data read from the SDRAM. Available 4 cycles after the read signal is set.

    output bit enabled,  // Signal indicating that the memory controller is enabled.

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

  bit busy;

  bit [22:0] word_addr;  // The address to read from or write to in the SDRAM
  bit [22:0] requested_addr;  // address captured at time operation initiated
  bit [31:0] operation_din32;
  bit [1:0] __wdm;
  bit [3:0] wdm;
  bit [31:0] __din32;
`ifdef ENABLE_SUPER_RES
  bit [ 1:0] requested_word_wr_size;  // The word size captured at time operation initiated
  bit [31:0] data32;
  bit [31:0] data32B;
`endif
  bit [31:0] requested_din32;
  bit MemRD, MemWR, MemRefresh, MemInitializing;
  logic [31:0] MemDout32;
  logic [15:0] MemDout16;
  bit [2:0] cycles;
  bit r_read;
  bit [15:0] data16;
  bit MemBusy, MemDataReady;
  bit __operation_initiated;
  bit operation_read;
  bit operation_write;

  assign __operation_initiated = read || write;

  assign word_addr = {1'b0, addr[22:1]};

`ifdef ENABLE_SUPER_RES
  assign dout32  = data32;
  assign dout32B = data32B;
`endif
  assign dout16 = data16;

`ifdef ENABLE_SUPER_RES
  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) begin
      requested_word_wr_size <= `MEMORY_WIDTH_16;

    end else begin
      if (write) begin
        requested_word_wr_size <= word_wr_size;
      end
    end
  end
`endif

`ifdef ENABLE_SUPER_RES
  always_comb begin
    __din32 = {32{1'bx}};
    __wdm = 2'bxx;
    wdm = 4'bxxxx;

    case (requested_word_wr_size)
      `MEMORY_WIDTH_8: begin
        __din32 = {din8, din8, din8, din8};

        __wdm = {~addr[0], addr[0]};
        wdm = word_addr[0] == 1'd0 ? {2'b11, __wdm} : {__wdm, 2'b11};  // only write the correct byte
      end

      `MEMORY_WIDTH_16: begin
        __din32 = {din16, din16};
        wdm = word_addr[0] == 1'd0 ? {4'b1100} : {2'b0011};  // only write the correct word
      end

      `MEMORY_WIDTH_32: begin
        __din32 = din32;
        __wdm   = 2'b0000;
      end
    endcase
  end
`else
  always_comb begin
    __din32 = {din8, din8, din8, din8};

    __wdm = {~addr[0], addr[0]};
    wdm = word_addr[0] == 1'd0 ? {2'b11, __wdm} : {__wdm, 2'b11};  // only write the correct byte
  end
`endif

  assign operation_write = busy ? MemWR : write;
  assign operation_read  = busy ? MemRD : read;

  sdram #(
      .FREQ(FREQ)
  ) u_sdram (
      .clk(clk),
      .clk_sdram(clk_sdram),
      .resetn(resetn),
      .addr(word_addr),
      .rd(operation_read),
      .wr(operation_write),
      .refresh(busy ? MemRefresh : refresh),
      .din32(requested_din32),
      .wdm(wdm),
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

  assign MemDout16 = word_addr[0] ? MemDout32[31:16] : MemDout32[15:0];

  always_ff @(posedge clk or negedge resetn) begin
    if (~resetn) begin
      busy <= 1'b1;
      fail <= 1'b0;
      MemInitializing <= 1'b1;

    end else begin
      MemWR <= 1'b0;
      MemRD <= 1'b0;
      MemRefresh <= 1'b0;
      cycles <= cycles ? 3'(cycles - 1) : 0;

      // Initiate read or write
      if (!busy) begin
        if (read || write || refresh) begin
          MemWR <= write;
          MemRD <= read;
          MemRefresh <= refresh;
          busy <= 1'b1;
          requested_din32 <= __din32;
          cycles <= 4;
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
        if (cycles == 1) begin
          busy <= 0;
          if (r_read) begin
            if (~MemDataReady)  // assert data ready
              fail <= 1'b1;
            if (r_read) begin
`ifdef ENABLE_SUPER_RES
              data32  <= MemDout32;
              data32B <= MemDout32;
`endif
              data16 <= MemDout16;
            end
            r_read <= 1'b0;
          end
        end
      end
    end
  end

endmodule
