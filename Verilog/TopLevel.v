`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 16.03.2022 13:31:24
// Design Name: Mouse Driver
// Module Name: TopLevel
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Global Wrapper module which connects all the submodules together by instantiating them
//              in one top module. Local wires facilitate data transfer between the modules.
// 
// Dependencies: ROM, RAM, Processor, LEDs, SevenSeg, MouseTransceiver
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TopLevel(
        
    //Standard Inputs
    input           RESET,
    input           CLK,
    
    //IO - Mouse side
    inout           CLK_MOUSE,
    inout           DATA_MOUSE,
    
    // 7 Segment Display Variables to be written to the Display.
    output [3:0]    SEG_SELECT,
    output [7:0]    HEX_OUT,
    
    // LEDs Output to be tied to FPGA board pins
    output [3:0]    STATUS_LEDS, // Status Byte
    output [7:0]    SCROLL_LEDS, // Z Position Byte (Scroll Wheel)    
    output [3:0]    COMMAND_LEDS, // IR Commands printed to LEDs
    
    // IO for the VGA Display
    output [7:0]    COLOUR_OUT,  // Colour Sent To VGA
    output          HS,
    output          VS,
    
    // IR Output
    output          IR_LED
    );
    
    
    //***********************************************************//
    // Local Wires necessary for the transfer of Data
    
    // ROM Address and Data Signals
    wire [7:0]      ROM_ADDRESS;
    wire [7:0]      ROM_DATA;
    
    // BUS Address and Data Signals including Write Enable
    wire [7:0]      BUS_DATA;
    wire [7:0]      BUS_ADDR;
    wire            BUS_WE;
    
    // Interrupt Signals - 2 Signals, One for Mouse and One for Timer (Timer Not used in this Demo)
    wire [1:0]      BUS_INTERRUPTS_RAISE;
    wire [1:0]      BUS_INTERRUPTS_ACK;
    
    wire [2:0]      COLOUR_COUNTER;

    
    //***********************************************************//
    // Here begins the instantiation of all submodules relevant to the Program
    
    //***********************************************************//
    // Instantiate the ROM (READ ONLY MEMORY)
    ROM Rom(
                    // Standard Inputs
                    .CLK(CLK),
                    
                    // ROM Signals
                    .ADDR(ROM_ADDRESS),
                    .DATA(ROM_DATA) 
                    );
    
    
    //***********************************************************//
    // Instantiate the RAM (RANDOM ACCESS MEMORY)
    RAM Ram(
                    // Standard Inputs
                    .CLK(CLK),
                    
                    // BUS Signals
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR), 
                    .BUS_WE(BUS_WE)
                    );    
    
    
    //***********************************************************//
    // Instantiate the Central Processing Unit or Microprocessor
    Processor Proc(
                    // Standard Inputs
                    .CLK(CLK),
                    .RESET(RESET),
                    
                    // BUS Signals
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE),    
                    
                    // ROM Signals
                    .ROM_ADDRESS(ROM_ADDRESS),
                    .ROM_DATA(ROM_DATA),
                    
                    // Interrupt Signals
                    .BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),
                    .BUS_INTERRUPTS_ACK(BUS_INTERRUPTS_ACK) 
                    );
                    
                    
    //***********************************************************//
    // Instantiate the LEDs Peripheral SubModule
    LEDs Leds(
                    // Standard Inputs
                    .CLK(CLK),
                    
                    // BUS Signals
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE),
                    
                    // LED Variables to be written to FPGA LEDs
                    .STATUS_LEDS(STATUS_LEDS),
                    .SCROLL_LEDS(SCROLL_LEDS),
                    .COMMAND_LEDS(COMMAND_LEDS)
                    );
                    
                    
    //***********************************************************//
    // Instantiate the SevenSeg Peripheral Submodule which handles all modules
    // related to displaying the Mouse Position on the 7 Segment Display
    SevenSeg Seg7(
                    // Standard Inputs
                    .CLK(CLK),
                    
                    // BUS Signals
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE),
                    
                    // 7 Segment Display Variables to be written to the Display.
                    .SEG_SELECT(SEG_SELECT),
                    .HEX_OUT(HEX_OUT)
                    );
                    
                    
    //***********************************************************//
    // Instantiate the Mouse Transceiver Peripheral Submodule
    // This submodule contains all the necessary modules to fetch data from the Mouse
    // including the X coordinates, Y coordinates, Z coordinates and Status Byte. This data is then written to
    // the Data Bus when an interrupt occurs.
    MouseTransceiver Trans(
                    // Standard Inputs
                    .CLK(CLK),
                    .RESET(RESET),
                    
                    // Mouse IO - CLK and DATA
                    .CLK_MOUSE(CLK_MOUSE),
                    .DATA_MOUSE(DATA_MOUSE),
                    
                    // BUS Signals
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE),  
                    
                    // Interrupt Signals
                    .BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[0]),
                    .BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[0]),
                    
                    // Colour Counter
                    .COLOUR_COUNTER(COLOUR_COUNTER)
                    );
                    
    
    //***********************************************************//
    // Instantiate the Timer Peripheral Submodule
    // This submodule is used to generate Timed Interrupts
    Timer Time(
                    // Standard Inputs
                    .CLK(CLK),
                    .RESET(RESET),                    
                    
                    // BUS Signals
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE),
                    
                    // Interrupt Signals
                    .BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[1]),
                    .BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[1]) 
                    );
                    
     
     //*******************************************************//
     // Instantiate the VGA Driver Submodule
     // This submodule is responsible for dealing with the VGA Display               
     VGADriver VGA(
                    // Standard Inputs
                    .CLK(CLK),
                    
                    // VGA
                    .COLOUR_OUT(COLOUR_OUT),
                    .VGA_HS(HS),
                    .VGA_VS(VS),
           
                    //.A_WE(bus_we),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_DATA(BUS_DATA),
                    
                    // Colour Selection
                    .COLOUR_COUNTER(COLOUR_COUNTER)
                    );
   
   
   //**********************************************************//
   // Instantiation of IR Transmitter Submodule
   // Responsible for sending IR Signals to Remote Control Car        
   IRTransmitter IR(
                    // Standard Inputs
                    .CLK(CLK),
                    .RESET(RESET),
                    
                    // BUS Signals
                    .BUS_DATA(BUS_DATA),
                    .BUS_ADDR(BUS_ADDR),
                    .BUS_WE(BUS_WE),
                    
                    // IR Signal
                    .IR_LED(IR_LED)
                    );
                    
                    
    ila_0 IR_monitor (
        .clk(CLK), // input wire clk
        .probe0(IR_LED) // input wire [0:0] probe0
        );

endmodule
