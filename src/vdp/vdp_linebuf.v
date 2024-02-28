// Verilog equivalent for VDP_LINEBUF entity in VHDL

module VDP_LINEBUF (
    input wire [9:0] ADDRESS,
    input wire INCLOCK,
    input wire WE,
    input wire [5:0] DATA,
    output reg [5:0] Q
);

    reg [4:0] IMEM [0:639];
    reg [9:0] IADDRESS;

    always @(posedge INCLOCK) begin
        if (WE) begin
            IMEM[ADDRESS] <= DATA[5:1];    // data range required by YJK mode
        end
        IADDRESS <= ADDRESS;
    end

    always @(*) begin
        Q <= {IMEM[IADDRESS], 1'b0};
    end
endmodule
