`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 05.11.2020 16:10:19
// Design Name: Mouse Driver
// Module Name: Multiplexer_4Way
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: 4-way multiplexer to select between 4 different variables based on an Input "CONTROL"
//              variable.
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Multiplexer_4Way(
    
    // Inputs to Multiplexer
    input               [1:0] CONTROL, // Controls Multiplexer
    input               [3:0] IN0,
    input               [3:0] IN1,
    input               [3:0] IN2,
    input               [3:0] IN3,
    
    // Output of Multiplexer
    output reg          [3:0] OUT
    );
    
    always@(        CONTROL         or
                    IN0             or
                    IN1             or
                    IN2             or    
                    IN3
                    )
                    
   begin
        // Select output of multiplexer based on control input.
        case(CONTROL)
                2'b00           : OUT <= IN0;
                2'b01           : OUT <= IN1;
                2'b10           : OUT <= IN2;
                2'b11           : OUT <= IN3;
                default         : OUT <= 4'b0000;
        endcase
  end 
  
  
endmodule
