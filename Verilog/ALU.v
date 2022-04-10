`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 15.03.2022 13:47:55
// Design Name: Mouse Driver
// Module Name: ALU (Arithmetic Logic Unit)
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Arithmetic Logic Unit to perform various computations and return results
//              to the processor.
// 
// Dependencies: none.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU(
    
    // Standard Signals
    input           CLK,
    input           RESET,
    
    // I/O - Inputs and Outputs
    input [7:0]     IN_A,
    input [7:0]     IN_B,
    input [3:0]     ALU_Op_Code,
    output [7:0]    OUT_RESULT        
    
    );
    
    reg [7:0]       Out;
    
    // Arithmetic Computation
    always@(posedge CLK) begin
            if(RESET)
                    Out <= 0;
            else begin
                    // Chooses between possible Maths Operations
                    case(ALU_Op_Code)
                        // Add A + B
                        4'h0:       Out <= IN_A + IN_B;
                        // Subtract A - B
                        4'h1:       Out <= IN_A - IN_B;
                        // Multiply A * B
                        4'h2:       Out <= IN_A * IN_B;
                        // Shift Left A << 1
                        4'h3:       Out <= IN_A << 1;
                        // Shift Right A >> 1
                        4'h4:       Out <= IN_A >> 1;
                        // Increment A + 1
                        4'h5:       Out <= IN_A + 1'b1;
                        // Increment B + 1
                        4'h6:       Out <= IN_B + 1'b1;
                        // Decrement A - 1
                        4'h7:       Out <= IN_A - 1'b1;
                        // Decrement B + 1
                        4'h8:       Out <= IN_B - 1'b1;
                        
                        // Inequality Operations
                        
                        // A == B
                        4'h9:       Out <= (IN_A == IN_B) ? 8'h01 : 8'h00;
                        // A > B
                        4'hA:       Out <= (IN_A > IN_B) ? 8'h01 : 8'h00;
                        // A < B
                        4'hB:       Out <= (IN_A < IN_B) ? 8'h01 : 8'h00;
                        // Default A
                        default:    Out <= IN_A;
                    endcase
            end
    end
    
    // Assign Statement
    assign OUT_RESULT = Out;
    
endmodule
