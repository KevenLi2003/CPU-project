`timescale 1ns/1ps
module tutorial_tb();
    reg clock, clear, RZout, RAout, RBout, RAin, RBin, RZin;
    reg [7:0] AddImmediate;
    reg [7:0] RegisterAImmediate;
    reg [3:0] present_state;

    // Instantiate the datapath module
    Datapath DP(
        clock, clear,
        AddImmediate, 
        RegisterAImmediate,
        RZout, RAout, RBout,
        RZin, RAin, RBin
    );

    parameter init = 4'd1, T0 = 4'd2, T1 = 4'd3, T2 = 4'd4;

    // Clock generation
    initial begin
        clock = 0;
        present_state = 4'd0;
    end

    always #10 clock = ~clock;

    always @(negedge clock)
        present_state = present_state + 1;

    always @(present_state) begin
        case (present_state)
            init: begin
                clear <= 1;
                AddImmediate <= 8'h00;
                RegisterAImmediate <= 8'h00;
                RZout <= 0; RAout <= 0; RBout <= 0;
                RAin <= 0; RBin <= 0; RZin <= 0;
                #15 clear <= 0;
            end
            T0: begin
                RegisterAImmediate <= 8'h5;
                RAin <= 1;
                #15 RegisterAImmediate <= 8'h00;
                RAin <= 0;
            end
            T1: begin
                RAout <= 1;
                AddImmediate <= 8'h5;
                RZin <= 1;
                #15 RAout <= 0;
                RZin <= 0;
            end
            T2: begin
                RZout <= 1;
                RBin <= 1;
                #15 RZout <= 0;
                RBin <= 0;
            end
        endcase
    end
endmodule