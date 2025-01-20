module Bus (
    // mux
    input [7:0] BusMuxInRZ, input [7:0] BusMuxInRA, input [7:0] BusMuxInRB,
    // encoder
    input RZout, RAout, RBout,
    output wire [7:0] BusMuxOut
);
    reg [7:0] q;
    always @ (*) begin
        if (RZout) q = BusMuxInRZ;
        if (RAout) q = BusMuxInRA;
        if (RBout) q = BusMuxInRB;
    end 
    assign BusMuxOut = q;
endmodule