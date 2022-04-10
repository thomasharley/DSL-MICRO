`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 15.03.2022 11:05:53
// Design Name: Mouse Driver
// Module Name: ROM
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Read Only Memory (ROM) module which is programmed by an external .txt file
//              Microprocessor reads instructions from the ROM.
// 
// Dependencies: none.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ROM(
    
    // Standard Signals
    input                   CLK,
    
    // BUS Signals
    output reg [7:0]        DATA,
    input [7:0]             ADDR
    
    );
    
    parameter RAMAddrWidth      = 8;
    
    // Memory
    reg [7:0] ROM [2**RAMAddrWidth-1:0];
    
    // Load Program
    initial $readmemh("Complete_Demo_ROM.txt", ROM);
    
    // Single Port RAM
    always@(posedge CLK)
            DATA <= ROM[ADDR];
    
endmodule
