module top (
    input clk,

    output bit led1_n,
    output bit led2_n,
    output bit led3_n,
    output bit led4_n,
    output bit led5_n
);

  assign led1_n = vram_access_addr[17];
  assign led2_n = 0;
  assign led3_n = 0;
  assign led4_n = 0;
  assign led5_n = 0;

  bit [17:0] vram_access_addr;
  bit [10:0] vram_access_y;
  bit [ 8:0] vram_access_x;

  always_ff @(posedge clk) begin
    vram_access_y <= vram_access_y + 1;
    vram_access_x <= vram_access_x + 1;
  end

  // assign vram_access_addr = 18'((vram_access_y * 720) + (vram_access_x * 2));
  assign vram_access_addr = 18'((vram_access_y * 360 * 2) + (vram_access_x * 2));

endmodule
