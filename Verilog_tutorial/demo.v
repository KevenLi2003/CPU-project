// Module: Add_half
// Purpose: Implements a half adder, which calculates the sum and carry-out of two single-bit inputs.
// Inputs: a, b - Single-bit inputs to the half adder.
// Outputs: sum - XOR of inputs a and b; c_out - AND of inputs a and b.
module Add_half (
    output c_out,
    output sum, 
    input a, 
    input b
);
    xor (sum, a, b); // Compute the sum using XOR gate
    and (c_out, a, b); // Compute the carry-out using AND gate
endmodule

// Module: Add_full
// Purpose: Implements a full adder using two half adders and an OR gate.
// Inputs: a, b - Single-bit inputs; c_in - Carry-in from the previous stage.
// Outputs: sum - Sum of inputs and carry-in; c_out - Carry-out to the next stage.
module Add_full (
    output c_out,
    output sum, 
    input a, 
    input b,
    input c_in
);
    wire w1, w2, w3; // Internal wires for intermediate carry and sum signals

    Add_half M1 (w2, w1, a, b);    // First half adder
    Add_half M2 (w3, sum, c_in, w1); // Second half adder
    or(c_out, w3, w2);            // OR gate to calculate the final carry-out
endmodule

// Module: Add_rca_4
// Purpose: Implements a 4-bit ripple-carry adder using full adders.
// Inputs: a, b - 4-bit inputs; c_in - Carry-in for the least significant bit.
// Outputs: sum - 4-bit sum; c_out - Carry-out of the most significant bit.
module Add_rca_4 (
    output c_out,
    output [3:0] sum,
    input [3:0] a, b,
    input c_in
);
    wire c_in2, c_in3, c_in4; // Carry signals between full adders

    // Instantiate four full adders
    Add_full M1 (c_in2, sum[0], a[0], b[0], c_in);
    Add_full M2 (c_in3, sum[1], a[1], b[1], c_in2);
    Add_full M3 (c_in4, sum[2], a[2], b[2], c_in3);
    Add_full M4 (c_out, sum[3], a[3], b[3], c_in4);
endmodule

// Repeated Add_full and Add_half definitions for reuse in different contexts
module Add_full (
    output c_out, sum,
    input a, b, c_in
);
    wire w1, w2, w3; // Internal wires for carry and sum signals

    Add_half M1 (w2, w1, a, b);
    Add_half M2 (w3, sum, c_in, w1);
    or M3 (c_out, w3, w2);
endmodule

module Add_half (
    output c_out, sum,
    input a, b
);
    xor M1 (sum, a, b);
    and M2 (c_out, a, b);
endmodule

// User-Defined Primitive: mux_prim
// Purpose: Implements a 2-to-1 multiplexer using a truth table.
// Inputs: select - Select signal; a, b - Data inputs.
// Output: mux_out - Selected data output.
primitive mux_prim (
    output mux_out,
    input select, a, b
);
    table
        // select   a   b   :   mux_out
        0   0   0   :   0;
        0   0   1   :   0;
        0   0   x   :   0;
        0   1   0   :   1;
        0   1   1   :   1;
        0   1   x   :   1;

        1   0   0   :   0;
        1   1   0   :   0;
        1   x   0   :   0;
        1   0   1   :   1;
        1   1   1   :   1;
        1   x   1   :   1;

        x   0   0   :   0;
        x   1   1   :   1;
    endtable
endprimitive

// User-Defined Primitive: d_prim1
// Purpose: Implements a D flip-flop with a clock input and data input.
// Inputs: clock - Clock signal; data - Data input.
// Output: q_out - Stored value.
primitive d_prim1 (
    output reg q_out,
    input clock,
    input data
);
    table
        // clk    data    state : q_out/next_state
        (01)       0       ?   : 0; // Rising clock edge, data = 0 -> q_out = 0
        (01)       1       ?   : 1; // Rising clock edge, data = 1 -> q_out = 1
        (0x)       1       1   : 1; // Clock transition, maintain q_out
        (??)       ?       ?   : -; // Unknown transitions, no change
    endtable
endprimitive

// Module: Mux_2_32_CA
// Purpose: Implements a 2-channel, 32-bit multiplexer using conditional assignment.
// Parameter: word_size - Configurable bit width (default is 32).
module Mux_2_32_CA #(parameter word_size = 32) (
    output [word_size -1:0] mux_out,
    input [word_size -1:0] data_1, data_0,
    input select
);
    assign mux_out = select ? data_1 : data_0; // Conditional assignment
endmodule

// Module: Mux_4_32_if
// Purpose: Implements a 4-channel, 32-bit multiplexer using `if` statements.
// Inputs: data_3, data_2, data_1, data_0 - 32-bit input channels; select - Select signal; enable - Enable signal.
// Output: mux_out - Selected data output (or high-impedance/unknown).
module Mux_4_32_if (
    output [31:0] mux_out,
    input [31:0] data_3, data_2, data_1, data_0,
    input [1:0] select,
    input enable
);
    reg [31:0] mux_int; // Intermediate register to store selected output
    assign mux_out = enable ? mux_int : 32'bz; // High-impedance output if not enabled

    always @(data_3, data_2, data_1, data_0, select)
        if (select == 0) mux_int = data_0;
        else if (select == 1) mux_int = data_1;
        else if (select == 2) mux_int = data_2;
        else if (select == 3) mux_int = data_3;
        else mux_int = 32'bx; // Unknown output for invalid select
endmodule

// Module: Mux_4_32_case
// Purpose: Implements a 4-channel, 32-bit multiplexer using the `case` statement.
// Description: 
//   - The module selects one of four 32-bit input channels based on a 2-bit `select` signal.
//   - If `enable` is low, the output is set to high-impedance (`z`).
//   - If the `select` signal is invalid, the output is set to an unknown state (`x`).
module Mux_4_32_case (
    output [31:0] mux_out,         // 32-bit output of the multiplexer
    input [31:0] data_3, data_2, data_1, data_0, // Four 32-bit input channels
    input [1:0] select,            // 2-bit select signal to choose the input channel
    input enable                   // Enable signal to control the output
);
    reg [31:0] mux_int;            // Internal register to hold the selected value

    // Conditional assignment to drive the output.
    // If `enable` is low, the output is set to high-impedance (`z`).
    // Otherwise, the selected input is forwarded to the output.
    assign mux_out = enable ? mux_int : 32'bz;

    // Behavioral model for the multiplexer using a `case` statement.
    // Evaluates the `select` signal to determine which input channel to forward.
    always @(data_3, data_2, data_1, data_0, select) begin
        case (select)
            0: mux_int = data_0;          // If `select` is 0, choose `data_0`
            1: mux_int = data_1;          // If `select` is 1, choose `data_1`
            2: mux_int = data_2;          // If `select` is 2, choose `data_2`
            3: mux_int = data_3;          // If `select` is 3, choose `data_3`
            default: mux_int = 32'bx;     // For invalid `select`, set to unknown (`x`)
        endcase
    end
endmodule

// the same module implemented using nested conditional statement
module Mux_4_32_CA (
    output [31:0] mux_out,         // 32-bit output of the multiplexer
    input [31:0] data_3, data_2, data_1, data_0, // Four 32-bit input channels
    input [1:0] select,            // 2-bit select signal to choose the input channel
    input enable  
);
    wire [31:0] mux_int;
    assign mux_out = enable ? mux_int : 32'bz;
    assign mux_int = (select == 0) ? data_0 :
                            (select == 1) ? data_1 :
                                (select == 2) ? data_2 :
                                    (select == 3) ? data_3 : 32'bx;
endmodule

module encoder (
    output reg [2:0] Code,
    input [7:0] Data
);
    always @(data_in) 
    begin
        // Check each input using `if` conditions
        if (data_in == 8'b0000_0001)
            code = 3'b000; // Input d0 is active
        else if (data_in == 8'b0000_0010)
            code = 3'b001; // Input d1 is active
        else if (data_in == 8'b0000_0100)
            code = 3'b010; // Input d2 is active
        else if (data_in == 8'b0000_1000)
            code = 3'b011; // Input d3 is active
        else if (data_in == 8'b0001_0000)
            code = 3'b100; // Input d4 is active
        else if (data_in == 8'b0010_0000)
            code = 3'b101; // Input d5 is active
        else if (data_in == 8'b0100_0000)
            code = 3'b110; // Input d6 is active
        else if (data_in == 8'b1000_0000)
            code = 3'b111; // Input d7 is active
        else
            code = 3'bxxx; // Undefined output for invalid or multiple inputs
    end

    // alternative description is given below
    always @(data_in) begin
        case (data_in)
            8'b0000_0001: code = 3'b000; // Input d0 is active
            8'b0000_0010: code = 3'b001; // Input d1 is active
            8'b0000_0100: code = 3'b010; // Input d2 is active
            8'b0000_1000: code = 3'b011; // Input d3 is active
            8'b0001_0000: code = 3'b100; // Input d4 is active
            8'b0010_0000: code = 3'b101; // Input d5 is active
            8'b0100_0000: code = 3'b110; // Input d6 is active
            8'b1000_0000: code = 3'b111; // Input d7 is active
            default: code = 3'bxxx;      // Undefined output for invalid or multiple inputs
        endcase
    end
endmodule

module priority (
    output reg [2:0] Code, 
    output valid_data, 
    input [7:0] Data
);
    assign valid_data = | Data;
    always @ (Data)
    begin
        if (Data[7]) Code = 7; else
        if (Data[6]) Code = 6; else 
        if (Data[5]) Code = 5; else 
        if (Data[4]) Code = 4; else 
        if (Data[3]) Code = 3; else 
        if (Data[2]) Code = 2; else 
        if (Data[1]) Code = 1; else 
                     Code = 3'bx;
    end
        
    // alternative description is shown below
    // casex statement ignores x and z in bits of the case item
    // casex statement only ignores z in bits of the case item
    always @ (Data)
    casex (Data)
        8'b1xxx_xxxx: Code = 7;
        8'b01xx_xxxx: Code = 6;
        8'b001x_xxxx: Code = 5;
        8'b0001_xxxx: Code = 4;
        8'b0000_1xxx: Code = 3;
        8'b0000_01xx: Code = 2;
        8'b0000_001x: Code = 1;
        8'b0000_0001: Code = 0;
        default: Code = 3'bx;
    endcase
endmodule

// Module: Decoder_3_to_8
// Purpose: Implements a 3-to-8 decoder that activates one of eight output lines based on a 3-bit input code.
// Inputs: 
//   - Code: 3-bit input code.
// Outputs: 
//   - Data: 8-bit output where only one bit is high based on the input code.
module Decoder_3_to_8 (
    input [2:0] Code,       // 3-bit input code
    output reg [7:0] Data   // 8-bit output with one active high signal
);
    always @ (Code) begin
        // Using `if` statements to determine which output bit to activate
        if (Code == 0) Data = 8'b00000001; // Activate output bit 0
        else if (Code == 1) Data = 8'b00000010; // Activate output bit 1
        else if (Code == 2) Data = 8'b00000100; // Activate output bit 2
        else if (Code == 3) Data = 8'b00001000; // Activate output bit 3
        else if (Code == 4) Data = 8'b00010000; // Activate output bit 4
        else if (Code == 5) Data = 8'b00100000; // Activate output bit 5
        else if (Code == 6) Data = 8'b01000000; // Activate output bit 6
        else if (Code == 7) Data = 8'b10000000; // Activate output bit 7
        else Data = 8'bxxxxxxxx; // Undefined output for invalid Code
    end

    // Alternative implementation using `case` statement
    always @ (Code) begin
        case (Code)
            3'b000: Data = 8'b00000001; // Activate output bit 0
            3'b001: Data = 8'b00000010; // Activate output bit 1
            3'b010: Data = 8'b00000100; // Activate output bit 2
            3'b011: Data = 8'b00001000; // Activate output bit 3
            3'b100: Data = 8'b00010000; // Activate output bit 4
            3'b101: Data = 8'b00100000; // Activate output bit 5
            3'b110: Data = 8'b01000000; // Activate output bit 6
            3'b111: Data = 8'b10000000; // Activate output bit 7
            default: Data = 8'bxxxxxxxx; // Undefined output for invalid Code
        endcase
    end
endmodule

// Repeat Loops
// Purpose: Initializes a memory array to zero by iterating a fixed number of times.
// Details:
// - The `repeat` loop evaluates the expression `memory_size` once at the start
//   and executes the enclosed statements that many times.
// - `word_address` is used to traverse the memory locations, which are set to zero.
word_address = 0;                // Start from the first memory location
repeat (memory_size)             // Iterate `memory_size` times
    begin
        memory[word_address] = 0; // Set the current memory location to 0
        word_address = word_address + 1; // Move to the next memory location
    end

// For Loops
// Purpose: Assigns values to specific bits of a register based on a calculated index.
// Details:
// - The `for` loop iterates through values of `K`, decrementing from 4.
// - It uses calculated offsets (e.g., `K + 10`, `K + 2`) to assign values within the `demo` register.
// - Demonstrates initialization and bit-level manipulation of registers.
reg [15:0] demo;                // A 16-bit register
integer K;                      // Loop control variable
for (K = 4; K > 0; K = K - 1)   // Iterate K from 4 down to 1
    begin
        demo[K + 10] = 0;       // Assign 0 to the bit at index K + 10
        demo[K + 2] = 1;        // Assign 1 to the bit at index K + 2
    end

// Module: Majority_4b
// Purpose: Determines if the majority of four input signals (A, B, C, D) are high.
// Outputs:
// - Y: High (1) if the majority of inputs are high; Low (0) otherwise.
// Inputs:
// - A, B, C, D: Single-bit inputs representing signals.
module Majority_4b (
    output reg Y, // Output signal for majority result
    input A, B, C, D // Four single-bit input signals
);
    always @ (A, B, C, D) begin
        // Check combinations where the majority of inputs are high
        case ({A, B, C, D})
            7, 11, 13, 14, 15: Y = 1; // Majority cases (binary representations of majority values)
            default: Y = 0;           // Default case when the majority is not high
        endcase
    end
endmodule

// Module: Majority
// Purpose: Computes the majority of an arbitrary number of bits in the input data.
// Inputs:
// - Data: Input vector of arbitrary size defined by `size` parameter.
// Outputs:
// - Y: High (1) if the majority of bits in `Data` are high; Low (0) otherwise.
module Majority #(
    parameter size = 8,         // Default size of the input data vector
    parameter majority = 4      // Threshold for majority (e.g., >= 4 for an 8-bit vector)
)(
    input [size - 1:0] Data,    // Input data vector
    output reg Y                // Output signal for majority result
);
    reg [31:0] count;           // Counter for the number of high bits
    integer k;                  // Loop control variable

    always @ (Data) begin
        count = 0;              // Initialize the count to 0
        // Iterate through each bit of the input data vector
        for (k = 0; k < size; k = k + 1) begin
            if (Data[k] == 1)   // Increment the count for every high bit
                count = count + 1;
        end
        Y = (count >= majority); // Set Y based on whether the majority condition is met
    end
endmodule

// Count the Number of 1s
// Purpose: Counts the number of 1s in an 8-bit register using a `while` loop.
// Details:
// - The least significant bit (LSB) is checked in each iteration.
// - The register is right-shifted to process the next bit.
begin: count_of_1s
    reg [7:0] temp;             // Temporary register to hold data during processing
    count = 0;                  // Initialize the count to 0

    temp = reg_a;               // Load the input register into the temporary register
    while (temp) begin          // Continue while `temp` is not zero
        if (temp[0])            // Check if the LSB is 1
            count = count + 1;  // Increment the count
        temp = temp >> 1;       // Right-shift the register to check the next bit
    end
end

// Module: find_first_one
// Purpose: Finds the index of the first '1' bit in a 16-bit word.
// Inputs:
// - word: 16-bit input to search for the first '1' bit.
// - trigger: A trigger signal for starting the search.
// Outputs:
// - index: Index of the first '1' bit (0 to 15). 
module find_first_one (
    output reg [3:0] index, // Output index of the first '1' bit
    input [15:0] word,      // 16-bit input word
    input trigger           // Trigger signal to initiate search
);
    always @ (posedge trigger) begin: search_for_1 // Search begins on the positive edge of `trigger`
        // Use a for loop to check each bit of the word from LSB to MSB
        for (index = 0; index < 16; index = index + 1)
            if (word[index] == 1) disable search_for_1; // Exit the loop when the first '1' is found
    end
endmodule

// Module: Adder4
// Purpose: Implements a 4-bit ripple-carry adder using a `generate` loop for instantiating full adders.
// Inputs:
// - A, B: 4-bit numbers to add.
// - Ci: Carry-in for the least significant bit.
// Outputs:
// - S: 4-bit sum of A, B, and Ci.
// - Co: Carry-out from the most significant bit.
module Adder4 (
    input [3:0] A,           // 4-bit input A
    input [3:0] B,           // 4-bit input B
    input Ci,                // Carry-in for the LSB
    output [3:0] S,          // 4-bit sum output
    output Co                // Carry-out from the MSB
);
    wire [4:0] C;            // Intermediate carry signals
    assign C[0] = Ci;        // Initial carry-in is assigned to C[0]

    genvar i;                // Generate variable for loop iteration
    generate
        // Instantiate a FullAdder module for each bit of the 4-bit inputs
        for (i = 0; i < 4; i = i + 1)
            begin: gen_loop // Named loop block for clarity
                FullAdder FA (A[i], B[i], C[i], C[i + 1], S[i]);
            end
    endgenerate

    assign Co = C[4];        // Assign the final carry-out to Co
endmodule

// Module: FullAdder
// Purpose: Implements a 1-bit full adder.
// Inputs:
// - X, Y: 1-bit inputs to add.
// - Cin: Carry-in from the previous stage.
// Outputs:
// - Cout: Carry-out to the next stage.
// - Sum: Sum of X, Y, and Cin.
module FullAdder (
    input X,                 // First 1-bit input
    input Y,                 // Second 1-bit input
    input Cin,               // Carry-in signal
    output Cout,             // Carry-out signal
    output Sum               // Sum of the inputs
);
    assign #10 Sum = X ^ Y ^ Cin;          // XOR operation for sum, with delay of 10 time units
    assign #10 Cout = (X & Y) | (X & Cin) | (Y & Cin); // Compute carry-out, with delay of 10 time units
endmodule

// Module: RAM6116
// Purpose: Implements a simple 8-bit wide, 256-entry RAM module with asynchronous read and write operations.
// Inputs:
// - Cs_b: Chip select (active low).
// - We_b: Write enable (active low).
// - Oe_b: Output enable (active low).
// - Address: 8-bit address for read/write.
// - IO: Bidirectional data bus.
// Internal:
// - RAM1: Array of 256 8-bit memory locations.
module RAM6116 (
    input Cs_b,              // Chip select (active low)
    input We_b,              // Write enable (active low)
    input Oe_b,              // Output enable (active low)
    input [7:0] Address,     // 8-bit address for accessing memory
    inout [7:0] IO           // Bidirectional data bus
);
    reg [7:0] RAM1[0:255];   // Define the memory array with 256 8-bit locations

    // Output logic: drive data onto the IO bus when chip is selected, and write or output is enabled
    assign IO = (Cs_b == 1'b1 || We_b == 1'b1 || Oe_b == 1'b1) ? 8'bzzzz_zzzz : RAM1[Address];

    // Write operation: triggered on the negative edge of We_b
    always @ (negedge We_b)
        if (Cs_b == 1'b0)    // Check if chip select is active
            RAM1[Address] <= IO; // Write the data from IO to the addressed memory location
endmodule

// Module: test_squares
// Purpose: Computes the square of a 4-bit number using a custom function and stores the result.
// Inputs:
// - CLK: Clock signal to synchronize the calculation.
// Internal:
// - FN: A 4-bit input number.
// - answer: An 8-bit register to store the square of FN.
module test_squares (CLK);
    input CLK;                // Clock signal
    reg [3:0] FN;             // 4-bit input number
    reg [7:0] answer;         // 8-bit register to store the square of FN

    // Function: squares
    // Purpose: Calculates the square of a given 4-bit number.
    // Inputs:
    // - Number: 4-bit input to the function.
    // Outputs:
    // - The square of the input number as an 8-bit value.
    function [7:0] squares;
        input [3:0] Number;   // Input number
        begin
            square = Number * Number; // Compute the square
        end
    endfunction

    // Initialize FN to 3 (binary 0011)
    initial
        FN = 4'b0011;

    // On the rising edge of the clock, compute the square of FN and store it in answer
    always @ (posedge CLK)
    begin 
        answer = squares(FN); // Call the squares function
    end
endmodule

// Module: arithmetic_unit
// Purpose: Performs arithmetic operations on two 4-bit operands.
// Operations:
// - Calculates the sum of two operands.
// - Identifies the larger of the two operands.
// Inputs:
// - operand_1, operand_2: 4-bit operands for calculations.
// Outputs:
// - result_1: 5-bit sum of operand_1 and operand_2.
// - result_2: 4-bit largest of operand_1 and operand_2.
module arithmetic_unit (
    output [4:0] result_1,     // Sum of operands
    output [3:0] result_2,     // Largest operand
    input [3:0] operand_1, operand_2 // 4-bit input operands
);

    // Compute the sum of the operands
    assign result_1 = sum_of_operands(operand_1, operand_2);

    // Compute the largest operand
    assign result_2 = largest_operand(operand_1, operand_2);

    // Function: sum_of_operands
    // Purpose: Calculates the sum of two 4-bit operands.
    function [4:0] sum_of_operands (input [3:0] operand_1, operand_2);
        sum_of_operands = operand_1 + operand_2; // Add the two operands
    endfunction

    // Function: largest_operand
    // Purpose: Identifies the larger of two 4-bit operands.
    function [3:0] largest_operand (input [3:0] operand_1, operand_2);
        largest_operand = (operand_1 >= operand_2) ? operand_1 : operand_2; // Compare operands
    endfunction
endmodule

// Module: word_aligner
// Purpose: Aligns the most significant bit (MSB) of an input word to the highest position in the output word.
// Parameter:
// - word_size: Size of the input and output words (default is 8 bits).
// Inputs:
// - word_in: Input word to align.
// Outputs:
// - word_out: Aligned output word.
module word_aligner #(parameter word_size = 8) (
    output [word_size - 1:0] word_out, // Aligned output word
    input [word_size - 1:0] word_in    // Input word to be aligned
);
    // Perform alignment using the aligned_word function
    assign word_out = aligned_word(word_in);

    // Function: aligned_word
    // Purpose: Aligns the MSB of the input word to the highest bit position.
    function [word_size - 1:0] aligned_word;
        input [word_size - 1:0] word; // Input word
        begin
            aligned_word = word;       // Initialize aligned_word with the input word
            if (aligned_word != 0)     // Check if the word is non-zero
                // Left-shift the word until the MSB becomes 1
                while (aligned_word[word_size - 1] == 0) aligned_word = aligned_word << 1;
        end 
    endfunction
endmodule

// Module: adder_task
// Purpose: Adds two 4-bit numbers with a carry-in using a task.
// Inputs:
// - data_a, data_b: 4-bit operands to add.
// - c_in: Carry-in bit for addition.
// - clk: Clock signal to trigger the operation.
// - reset: Resets the outputs to 0 when active.
// Outputs:
// - c_out: Carry-out of the addition.
// - sum: 4-bit sum of data_a, data_b, and c_in.
module adder_task (
    output reg c_out,           // Carry-out of the addition
    output reg [3:0] sum,       // Sum of the addition
    input reg [3:0] data_a, data_b, // 4-bit input operands
    input c_in, clk, reset      // Carry-in, clock, and reset signals
);

    // On the rising edge of the clock or reset
    always @ (posedge clk or posedge reset)
    if (reset == 1'b1) 
        {c_out, sum} <= 0;      // Reset outputs to 0
    else 
        add_values(c_out, sum, data_a, data_b, c_in); // Call the addition task

    // Task: add_values
    // Purpose: Performs the addition of two operands with a carry-in.
    task add_values (
        output c_out,           // Carry-out of the addition
        output [3:0] sum,       // Sum of the addition
        input [3:0] data_a, data_b, // 4-bit input operands
        input c_in              // Carry-in bit
    );
        begin
            {c_out, sum} = data_a + data_b + c_in; // Perform the addition
        end 
    endtask
endmodule