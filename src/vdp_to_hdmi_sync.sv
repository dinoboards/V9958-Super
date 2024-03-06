`include "vdp_constants.vh"

// ---------------
// Generate a reset signal for HDMI to reset 0,0 page
// triggered as a function of the VDP's cx, cy coords

module vdp_to_hdmi_sync (

    input bit reset,
    input bit clk,
    input [10:0] vdp_cx,
    input [10:0] vdp_cy,
    input [11:0] hdmi_cx,
    input [10:0] hdmi_cy,

    output bit ff_video_reset
);

  bit [27:0] counter;
  bit [ 2:0] state;

  always_ff @(posedge reset, posedge clk) begin
    if (reset == 1'b1) begin
      counter <= 0;
      ff_video_reset <= 1'b1;
      state <= 3'b000;

    end else begin
      ff_video_reset <= 1'b0;

      if (vdp_cx == hdmi_cx && vdp_cy == hdmi_cy) begin
        ff_video_reset <= 0;
        state <= 0;

      end else begin
        case (state)
          0: begin
            state <= 1;
          end
          1: begin
            // out of sync - hold counter, and wait for next 0,0
            counter <= 0;
            if (vdp_cx == 0 && vdp_cy == 0) begin
              state <= 2;
            end
          end
          2: begin
            // out of sync - count to next 0,0
            if (vdp_cx == 0 && vdp_cy == 0) begin
              state <= 3;
              //counter now has number of clock cycles for a page
            end else begin
              counter <= 28'(counter + 1);
            end
          end
          3: begin
            //count down until we are 1 clock cycle before 0,0
            if (counter == 2) begin
              state <= 0;  // hopefully in sync now
              ff_video_reset <= 1'b1;

            end else begin
              counter <= 28'(counter - 1);
            end
          end
        endcase
      end
    end
  end

endmodule
