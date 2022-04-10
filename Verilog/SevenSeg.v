`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 16.03.2022 13:30:49
// Design Name: Mouse Driver
// Module Name: SevenSeg
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Peripheral Module to handle all things related to the 7 segment display. Takes BUS_DATA as an input and
//              writes this data to the 7 segment display (BUS_DATA contains MouseX and MouseY coordinates from the transceiver).
// 
// Dependencies: Multiplexer_4Way, Generic_Counter, seg7decoder
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SevenSeg(
    
    // Standard Inputs
    input           CLK,
    
    // BUS Data and Address Inputs
    input [7:0]     BUS_DATA,
    input [7:0]     BUS_ADDR,
    input           BUS_WE, // Write Enable Signal (WE)        
   
    // 7 Segment Display Variables to be written to the Display.
    output [3:0]    SEG_SELECT,
    output [7:0]    HEX_OUT
    
    );
    
    //**************************************************************************//
    // Sequential Logic to write data from the BUS_DATA input which contains the X and Y Positional 
    // Coordinates of the mouse to a Register.
    
    reg [15:0]      MousePosition; // Stores Full Mouse Position (X and Y Coordinates in 2 Bytes) for Mouse Demonstration to be printed to 7 Segment.
     
    parameter [7:0] SevenSegBaseAddr = 8'hD0; // Base Address of Seven Segment defined in Lab Guide Book. Will stick with this value.
    
    always@(posedge CLK) begin
            if(BUS_WE) begin // if write enable is set to 1 then we can write to the Display.
                    if(BUS_ADDR == SevenSegBaseAddr)
                            MousePosition [15:8]        <= BUS_DATA;    // D0 -- TWO LEFT DIGITS
                    else if(BUS_ADDR == SevenSegBaseAddr + 1)
                            MousePosition [7:0]         <= BUS_DATA;    // D1 -- TWO RIGHT DIGITS      
            end
    end
                    
    
    
    //**************************************************************************//
    // Instantiation Of Sub-Modules Such as Generic_Counter, Multiplexer_4Way and seg7decoder.
    
    // Instantiate 17 Bit Generic Counter to allow for particular Refresh Rate of 7 Segment Display
    wire Bit17TrigOut;
    
    Generic_Counter #(
                      // Setting Generic Parameters
                      .COUNTER_WIDTH(17),
                      .COUNTER_MAX(99999) // Clk is 100MHz,  
                      )
                      // 17 Bit Counter
                      Bit17 (
                      .CLK(CLK),
                      .RESET(1'b0),
                      .ENABLE(1'b1),
                      .TRIG_OUT(Bit17TrigOut)
                      );
    
    
    // Instantiate 2 Bit Generic Counter
    wire [1:0] RefreshCount;
    
    Generic_Counter #(
                      // Setting Generic Parameters
                      .COUNTER_WIDTH(2),
                      .COUNTER_MAX(4)
                      )
                      // 2 Bit Counter
                      Bit2(
                      .CLK(CLK),
                      .RESET(1'b0),
                      .ENABLE(Bit17TrigOut),
                      .COUNT(RefreshCount)
                      );

    
    // Instantiate 4 Way Multiplexer to Select Which element of the Mouse Position is displayed on which
    // digit of display. MouseX[3:0], MouseX[7:4], MouseY[3:0], MouseY[7:4].
    wire [3:0] MuxOut;
    
    Multiplexer_4Way Mux4(
                    // Control Multiplexer
                    .CONTROL(RefreshCount),
                    
                    // Inputs to Choose From
                    .IN0(MousePosition [15:12]), // Leftmost
                    .IN1(MousePosition [11:8]),
                    .IN2(MousePosition [7:4]),
                    .IN3(MousePosition [3:0]), // Rightmost
                    
                    // Output
                    .OUT(MuxOut)
                    );
    
    
    // Instantiate the 7 Segment Decoder to display the Coordinates on the 7 Segment Display.
    seg7decoder Seg7(
                    // Select which digit is written to on Display, value of digit and if Dot is active.
                   .SEG_SELECT_IN(RefreshCount),
                   .BIN_IN(MuxOut),
                   .DOT_IN(1'b0),
                   
                   // Outputs that should be tied to the appropriate pins on FPGA in the XDC constraints file.
                   .SEG_SELECT_OUT(SEG_SELECT),
                   .HEX_OUT(HEX_OUT)
                   );
                                    
endmodule
