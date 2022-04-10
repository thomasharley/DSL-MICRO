`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 16.02.2022 12:28:24
// Design Name: Mouse Driver
// Module Name: MouseTransceiver
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Peripheral Transceiver Module to connect master state machine to receiver and transmitter, 
//              Process incoming mouse movement data (Dx, Dy, Dz, Status Byte), convert it to readable
//              Position data and write it to the DATA_BUS which will send it to other peripheral modules (LEDs/ 7 Segment Display).
// 
// Dependencies: MasterSM, Transmitter, Receiver
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MouseTransceiver(
        
    //Standard Inputs
    input               RESET,
    input               CLK,

    //IO - Mouse side
    inout               CLK_MOUSE,
    inout               DATA_MOUSE,
    
    // BUS Data and Address Signals
    output [7:0]        BUS_DATA,   // Will output Mouse Data 
    input [7:0]         BUS_ADDR,   // Will input Bus Address
    input               BUS_WE,     // Write Enable

    // Interrupt Signals so we know when Mouse is sending new data
    output              BUS_INTERRUPT_RAISE,
    input               BUS_INTERRUPT_ACK,
    
    // Colour Selection
    output [1:0]        COLOUR_COUNTER
    
    );
    
    // Mouse Status Byte information
    reg [3:0]           MouseStatus;
    
    // Scroll Wheel Position -- to be tied to 8 LEDs on FPGA board.
    reg [7:0]           MouseZ;
    
    // X and Y Coordinates Positional Data of the Mouse processed by the transceiver module, sent to Global Wrapper.
    reg [7:0]           MouseX      = 8'h50;
    reg [7:0]           MouseY      = 8'h3C;
    
    
    //*******************************************************//
    // Write Mouse Data to BUS_DATA when BUS_ADDR is the appropriate value and BUS_WE is set to 1 (Write Enable)
    // Also output when an interrupt has occurred to Global Wrapper as well as Mouse Data.
    
    
    // Raise interrupt signal if mouse sends an interrupt
    reg Interrupt;
    
    always@(posedge CLK) begin
        if(RESET)
            Interrupt       <= 1'b0;
        else if(SendInterrupt)
            Interrupt       <= 1'b1;
        else if(BUS_INTERRUPT_ACK)
            Interrupt       <= 1'b0;
    end
        
    assign BUS_INTERRUPT_RAISE = Interrupt; // Raise interrupt Signal
        
    parameter [7:0] MouseBaseAddr = 8'hA0; // Base Mouse Address

    reg [7:0]           MouseData; // Intermediate Local Register to Store Mouse Data    
    reg                 MouseWriteEnable; // Variable set to "1" if we can write to mouse
    
    assign BUS_DATA = (MouseWriteEnable) ? MouseData : 8'hZZ; // Assigns MouseData to BUS_DATA but only if the Bus Write Enable is False (nothing being written to bus)


    // Sequential logic to write Mouse Output Bytes to the BUS_DATA output
    always@(posedge CLK) begin
            if(BUS_ADDR == MouseBaseAddr)
                    MouseData       <= MouseStatus; // A0 - Status Byte
            else if(BUS_ADDR == MouseBaseAddr + 1)
                    MouseData       <= MouseX;      // A1 - X Coordinate
            else if(BUS_ADDR == MouseBaseAddr + 2)
                    MouseData       <= MouseY;      // A2 - Y Coordinate
            else if(BUS_ADDR == MouseBaseAddr + 3)
                    MouseData       <= MouseZ;      // A3 - Z Coordinate
    end   
    
    // Sequential Logic to Ascertain whether we can write to Mouse
    always@(posedge CLK) begin
            if((BUS_ADDR >= MouseBaseAddr) & (BUS_ADDR < MouseBaseAddr + 4)) begin
                if(!BUS_WE)
                    // Means we can write
                    MouseWriteEnable <= 1'b1;
                else
                    // Can't Write
                    MouseWriteEnable <= 1'b0;
            end
            else
                    // If address not Mouse Address, then don't write
                    MouseWriteEnable <= 1'b0;
    end
     
    
    // X, Y Limits of Mouse Position e.g. VGA Screen with 160 x 120 resolution
    parameter [7:0]     MouseLimitX = 160;
    parameter [7:0]     MouseLimitY = 120;
    
    // Z Limit Position -- So does not exceed 8 LEDS, i.e: 2^8 = 256
    parameter [7:0]     MouseLimitZ = 255; // 2 to the power of 8 (for 8 LEDs) minus 1
    


    //*****************************************************//
    // TriState Signals
    
    // Clk
    reg             ClkMouseIn;
    wire            ClkMouseOutEnTrans;

    // Data
    wire            DataMouseIn;
    wire            DataMouseOutTrans;
    wire            DataMouseOutEnTrans;

    
    // Clk Output - can be driven by host or device
    assign CLK_MOUSE = ClkMouseOutEnTrans ? 1'b0 : 1'bz;

    // Clk Input
    assign DataMouseIn = DATA_MOUSE;

    // Clk Output - can be driven by host or device
    assign DATA_MOUSE = DataMouseOutEnTrans ? DataMouseOutTrans : 1'bz;


    //*****************************************************//
    // This section filters the incoming Mouse clock to make sure that
    // it is stable before data is latched by either transmitter
    // or receiver modules.
    
    reg [7:0]       MouseClkFilter;

    always@(posedge CLK) begin
            if(RESET)
                ClkMouseIn          <= 1'b0;
            else begin
                // A simple shift register
                MouseClkFilter[7:1] <= MouseClkFilter[6:0];
                MouseClkFilter[0]   <= CLK_MOUSE;
    
                // Falling edge
                if(ClkMouseIn & (MouseClkFilter == 8'h00))
                    ClkMouseIn      <= 1'b0;
                
                // Rising edge
                else if(~ClkMouseIn & (MouseClkFilter == 8'hFF))
                    ClkMouseIn      <= 1'b1;
            end
    end


    //*******************************************************//
    // Instantiate the Transmitter module
    wire        SendByteToMouse;
    wire        ByteSentToMouse;
    wire [7:0]  ByteToSendToMouse;

    MouseTransmitter T(
                // Standard Inputs
                .RESET(RESET),
                .CLK(CLK),
                
                // Mouse IO - CLK
                .CLK_MOUSE_IN(ClkMouseIn),
                .CLK_MOUSE_OUT_EN(ClkMouseOutEnTrans),

                // Mouse IO - DATA
                .DATA_MOUSE_IN(DataMouseIn),
                .DATA_MOUSE_OUT(DataMouseOutTrans),
                .DATA_MOUSE_OUT_EN(DataMouseOutEnTrans),

                // Control
                .SEND_BYTE(SendByteToMouse),
                .BYTE_TO_SEND(ByteToSendToMouse),
                .BYTE_SENT(ByteSentToMouse)
                );


    //******************************************************//
    // Instantiate the Receiver module
    wire ReadEnable;
    wire [7:0]  ByteRead;
    wire [1:0]  ByteErrorCode;
    wire        ByteReady;
    
    MouseReceiver R(
                //Standard Inputs
                .RESET(RESET),
                .CLK(CLK),

                // Mouse IO - CLK
                .CLK_MOUSE_IN(ClkMouseIn),
                
                // Mouse IO - DATA
                .DATA_MOUSE_IN(DataMouseIn),

                // Control
                .READ_ENABLE(ReadEnable),
                .BYTE_READ(ByteRead),
                .BYTE_ERROR_CODE(ByteErrorCode),
                .BYTE_READY(ByteReady)
                );

    
    //***************************************************//
    // Instantiate the Master State Machine module
    wire [7:0]  MouseStatusRaw;
    wire [7:0]  MouseDxRaw;
    wire [7:0]  MouseDyRaw;
    wire [7:0]  MouseDzRaw; // Scroll wheel differential movement data - like X and Y must convert to position.
    wire        SendInterrupt;
    
    // For ILA Debugger
    wire [7:0]  MasterStateCode; // Current State of State machine

    MouseMasterSM MSM(
                // Standard Inputs
                .RESET(RESET),
                .CLK(CLK),

                // Transmitter Interface
                .SEND_BYTE(SendByteToMouse),
                .BYTE_TO_SEND(ByteToSendToMouse),
                .BYTE_SENT(ByteSentToMouse),
                
                // Receiver Interface
                .READ_ENABLE(ReadEnable),
                .BYTE_READ(ByteRead),
                .BYTE_ERROR_CODE(ByteErrorCode),
                .BYTE_READY(ByteReady),

                // Data Registers
                .MOUSE_STATUS(MouseStatusRaw),
                .MOUSE_DX(MouseDxRaw),
                .MOUSE_DY(MouseDyRaw),
                .MOUSE_DZ(MouseDzRaw),
                .SEND_INTERRUPT(SendInterrupt),
                
                // For ILA Debugger
                .STATE_WATCHER(MasterStateCode)   
                );


    // Pre-processing - handling of overflow and signs.
    // More importantly, this keeps tabs on the actual X/Y
    // location of the mouse.
    wire signed [8:0]   MouseDx; // X Direction Movement
    wire signed [8:0]   MouseDy; // Y Direction Movement
    wire signed [8:0]   MouseDz; // Only 8 bits since already 2's complement, don't need to add a bit.
    wire signed [8:0]   MouseNewX;
    wire signed [8:0]   MouseNewY;
    wire signed [8:0]   MouseNewZ; // Only 8 bits as already 2's complement, don't need to add a bit.
    

    // DX, DY and DZ are modified to take account of overflow and direction
    // Assign the proper expression to MouseDx
    assign MouseDx = (MouseStatusRaw[6]) ? (MouseStatusRaw[4] ? {MouseStatusRaw[4],8'h00} : {MouseStatusRaw[4],8'hFF} ) : {MouseStatusRaw[4],MouseDxRaw[7:0]};

    // Assign the proper expression to MouseDy -- this part added by me.
    assign MouseDy = (MouseStatusRaw[7]) ? (MouseStatusRaw[5] ? {MouseStatusRaw[5],8'h00} : {MouseStatusRaw[5],8'hFF} ) : {MouseStatusRaw[5],MouseDyRaw[7:0]};
    
    
    // Assign the proper expression to MouseDz -- this part is for the Scroll Wheel.
    // Decided for MouseZ (SCROLL WHEEL) to have the number go from 0 to 255 instead of -128 to 127 (i.e: could have displayed as an 8 bit 2's complement).
    
    // Sign extend the 2's complement by 4 bits (if in 5 button mode, the other 4 bits will be used for 4th, 5th button and 2 always 0 bits.
    assign MouseDz = {MouseDzRaw[3]} ? {5'b11111,MouseDzRaw[3:0]} : {5'b00000,MouseDzRaw[3:0]};                    
                    
    // Calculate new mouse position based on movement data
    assign MouseNewX = {1'b0,MouseX} + MouseDx;
    assign MouseNewY = {1'b0,MouseY} - MouseDy; // Had to be inverted for VGA SCREEN
    assign MouseNewZ = {1'b0,MouseZ} + MouseDz; // Adding 2's complement number to normal binary number.
    
    reg [1:0] ColourCounter = 2'b00;
    
    assign COLOUR_COUNTER   = ColourCounter; // Colour Counter for Background
    
    always@(posedge CLK) begin
            if(RESET) begin
                    MouseStatus             <= 0; // Resets Left, Right, Middle Mouse Button
                    MouseX                  <= MouseLimitX/2; // Resets all positional data to half maximum
                    MouseY                  <= MouseLimitY/2;
                    MouseZ                  <= MouseLimitZ/2;
                    ColourCounter           <= 0;
            
            //***************************************************// 
            // BONUS FEATURE - if middle mouse button pressed, resets Mouse X and Y position to middle of screen
            // so MouseLimitX/2 and MouseLimitY/2.        
            end else if (MouseStatus[2] == 1'b1) begin 
                    MouseStatus             <= MouseStatusRaw[3:0]; // Keeps receiving live status byte even while button is held.
                    MouseX                  <= MouseLimitX/2;
                    MouseY                  <= MouseLimitY/2;
                    ColourCounter           <= ColourCounter;
                    
            
            //***************************************************//        
            // Code Executes upon Mouse Interrupt Occurring
            end else if (SendInterrupt) begin
                    // Status is stripped of all unnecessary info
                    MouseStatus             <= MouseStatusRaw[3:0];
                    
                    // X is modified based on DX with limits on max and min
                    if(MouseNewX < 0)
                            MouseX          <= 0;
                    else if(MouseNewX > (MouseLimitX-1))
                            MouseX          <= MouseLimitX-1;
                    else
                            MouseX          <= MouseNewX[7:0];

                    // Y is modified based on DY with limits on max and min -- this part Added by me.
                    if(MouseNewY < 0)
                            MouseY          <= 0;
                    else if(MouseNewY > (MouseLimitY-1))
                            MouseY          <= MouseLimitY-1;
                    else
                            MouseY          <= MouseNewY[7:0];
                    
                    
                    // ****************************************************************************//        
                    // BONUS FEATURE -- Z (Scroll Wheel) is modified based on DY with limits on max and min
                    if(MouseNewZ > (MouseLimitZ-1))
                            MouseZ          <= 0;
                    else
                            MouseZ          <= MouseNewZ[7:0];     
                            
                    
                    //**********************************************************//
                    // BONUS FEATURE - Colour Changer for the Background     
                    if(MouseStatusRaw[0] == 1'b1) begin
                            if(MouseStatus[0] == 1'b0)
                                        ColourCounter <= ColourCounter + 1;
                    end
                                          
            end
    end
    
           
             
   
   
   //***************************************************************//
   //***************************************************************//
   // ILA Debugger Instantiation
   
   //ila_0 ILA(
   //       .clk(CLK), // input wire clk
   //       .probe0(RESET), // input wire [0:0]  probe0  
   //       .probe1(CLK_MOUSE), // input wire [0:0]  probe1 
   //       .probe2(DATA_MOUSE), // input wire [0:0]  probe2 
   //       .probe3(ByteErrorCode), // input wire [1:0]  probe3 
   //       .probe4(MasterStateCode), // input wire [7:0]  probe4 // Changed this from [3:0] to [7:0] since in new state machine with scroll wheel initialisation, more than 16 states.
   //       .probe5(ByteToSendToMouse), // input wire [3:0]  probe5 // not enough wires on device (so reduced this from [7:0] to [3:0])
   //       .probe6(ByteRead) // input wire [7:0]  probe6
   //   );
    
  
endmodule
