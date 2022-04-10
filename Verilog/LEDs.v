`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 16.03.2022 13:30:27
// Design Name: Mouse Driver
// Module Name: LEDs
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Peripheral Module to write data from the BUS_DATA to the LEDs on the
//              FPGA Board.
// 
// Dependencies: none.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module LEDs(

    // Standard Inputs
    input           CLK,
    
    // BUS Data and Address Inputs
    input [7:0]     BUS_DATA,
    input [7:0]     BUS_ADDR,
    input           BUS_WE, // Write Enable Signal (WE)   
    
    // Status Mouse Byte Output to be tied to FPGA board pins
    output [3:0]    STATUS_LEDS,
    
    // Scroll Wheel Mouse Byte Output to be tied to FPGA board pins 
    output [7:0]    SCROLL_LEDS,
    
    // Commands sent from the IR
    output [3:0]    COMMAND_LEDS
    
    );
    
    
    //**************************************************************************//
    // Sequential Logic to write Mouse Status information (Right Click, Left Click,
    // Middle Mouse Button, from BUS_DATA to the LEDs.
    
    reg [3:0] MouseStatus; // Register to fill with mousestatus data from BUS_DATA. Will be assigned to STATUS_LEDS.
    reg [7:0] MouseScroll; // Register to fill with mousescroll data from BUS_DATA. Will be assigned to SCROLL_LEDS.
    reg [3:0] Command;     // LED Command Register
    
    
    parameter [7:0] LEDsBaseAddr = 8'hC0; // LEDs Base Address defined in Lab Guidebook. Remains unchanged.
    
    
    always@(posedge CLK) begin
            if(BUS_WE) begin // If Write enable set to 1 then proceed.
                    if(BUS_ADDR == LEDsBaseAddr)            // Checking whether BUS_ADDR is set to Base LED Address (C0)
                            MouseStatus <= BUS_DATA[3:0];   // Set MouseStatus to value of BUS_DATA[3:0] which will hold MouseStatus information.
                    if(BUS_ADDR == LEDsBaseAddr + 1)        // Checking whether BUS_ADDR is set to High LED Address (C1)
                            MouseScroll <= BUS_DATA[7:0];   // Set MouseScroll to value of BUS_DATA[7:0] which will hold scroll wheel positional information.
                    if(BUS_ADDR == LEDsBaseAddr + 2) begin  // Checking whether BUS_ADDR is set to Highest LED Address (C2)
                            Command[0] <= BUS_DATA[3];      // IR Commands
                            Command[1] <= BUS_DATA[2];   
                            Command[2] <= BUS_DATA[1];   
                            Command[3] <= BUS_DATA[0];
                    end
            end
    end
    
    
    // Assign Statements to link LED output to MouseStatus/ MouseScrollWheel Information read in from BUS_DATA + Spare LEDs to Computation
    assign STATUS_LEDS      = MouseStatus; 
    assign SCROLL_LEDS      = MouseScroll;
    assign COMMAND_LEDS     = Command;
    
endmodule
