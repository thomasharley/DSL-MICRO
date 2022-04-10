`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 15.03.2022 10:53:22
// Design Name: Mouse Driver
// Module Name: RAM
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Random Access Memory (RAM) module. We can write data from BUS_DATA to the RAM
//              and then read this data from the RAM later on.
// 
// Dependencies: none.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RAM(
    
    // Standard Signals
    input               CLK,
    
    // BUS Signals
    inout [7:0]         BUS_DATA,
    input [7:0]         BUS_ADDR,
    input               BUS_WE
    
    );
    
    parameter RAMBaseAddr       = 0;
    parameter RAMAddrWidth      = 7; // 128 x 8-bits memory
    
    // Tristate
    wire [7:0]      BufferedBusData;
    
    reg [7:0]       Out;
    reg             RAMBusWE;
    
    // Now, only place data on the bus if the processor is NOT writing, and it is addressing this memory
    assign BUS_DATA         = (RAMBusWE) ? Out : 8'hZZ;
    assign BufferedBusData  = BUS_DATA;
    
    // Memory
    reg [7:0]       Mem [2**RAMAddrWidth-1:0];     
    
    // Initialise the memory for data preloading, initialising variables, and
    // declaring constants
    initial $readmemh("Complete_Demo_RAM.txt", Mem);
    
    // Single Port RAM
    always@(posedge CLK) begin
            // Brute-force RAM address decoding. Think of a simpler way... 
            // Might change this later, for now keep the same.
            if((BUS_ADDR >= RAMBaseAddr) & (BUS_ADDR < RAMBaseAddr + 128)) begin
                    if(BUS_WE) begin
                            Mem[BUS_ADDR[6:0]] <= BufferedBusData;
                            RAMBusWE <= 1'b0;
                    end else
                            RAMBusWE <= 1'b1;
            end else
                    RAMBusWE <= 1'b0;
                    
            Out     <= Mem[BUS_ADDR[6:0]];
    end
    
endmodule
