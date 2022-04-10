`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 15.02.2022 10:58:49
// Design Name: Mouse Interface
// Module Name: MouseMasterSM
// Project Name: Digital Systems Laboratory 
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Master State Machine to Initialise Mouse Interface and then received data packets in the form of Bytes.
//              Communicates with receiver/ transmitter modules to do so.                
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MouseMasterSM(

    input           CLK,
    input           RESET,
    
    // Transmitter Control
    output          SEND_BYTE,
    output [7:0]    BYTE_TO_SEND, // Byte to be Send
    input           BYTE_SENT,
    
    // Receiver Control
    output          READ_ENABLE,
    input [7:0]     BYTE_READ, // Byte Received
    input [1:0]     BYTE_ERROR_CODE,
    input           BYTE_READY,
    
    // Data Registers
    output [7:0]    MOUSE_DX, // Movement Data in X Direction
    output [7:0]    MOUSE_DY, // Movement Data in Y Direction
    output [7:0]    MOUSE_DZ, // Movement Data Scroll Wheel
    output [7:0]    MOUSE_STATUS,
    output          SEND_INTERRUPT, // Set to Hi when time to send new Data from Mouse
    
    output [7:0]    STATE_WATCHER // FOR ILA DEBUGGER - Shows current state of state machine

    );
    
    
    //**************************************************//
    // Main State Machine - There is a setup sequence
    
    // (1) Send FF - Reset Command
    // (2) Read FA - Mouse Acknowledge
    // (3) Read AA - Self-Test Pass
    // (4) Send F4 - Start Transmitting Command
    // (5) Read FA - Mouse Acknowledge
    
    // If at any time this chain is broken, the SM will restart from
    // the beginning. Once it has finished the set-up sequence, the read enable flag
    // is raised.
    
    // The host is then ready to read mouse information 3 bytes at a time:
    
    // (S1) Wait for first read, When it arrives, save it to status. Go to S2.
    // (S2) Wait for second read, When it arrives, save it to DX. Go to S3.
    // (S3) Wait for third read, When it arrives, save it to DY. Go to S1.
    
    // Send Interrupt.
    
    // State Control.
    reg [7:0]       Curr_State,         Next_State;
    reg [23:0]      Curr_Counter,       Next_Counter;
    
    // Transmitter Control
    reg             Curr_SendByte,      Next_SendByte;
    reg [7:0]       Curr_ByteToSend,    Next_ByteToSend;
    
    // Receiver Control
    reg             Curr_ReadEnable,    Next_ReadEnable;
    
    // Data Registers
    reg [7:0]       Curr_Status,        Next_Status;
    reg [7:0]       Curr_Dx,            Next_Dx;
    reg [7:0]       Curr_Dy,            Next_Dy;
    reg [7:0]       Curr_Dz,            Next_Dz; // Scroll Wheel
    reg             Curr_SendInterrupt, Next_SendInterrupt;
    
    // For Scroll Wheel - BONUS FEATURES
    reg             Curr_ScrollWheel,   Next_ScrollWheel;
    
    
    // Sequential
    always@(posedge CLK) begin
            if(RESET) begin
                            Curr_State          <= 8'h00;
                            Curr_Counter        <= 0;
                            Curr_SendByte       <= 1'b0;
                            Curr_ByteToSend     <= 8'h00;
                            Curr_ReadEnable     <= 1'b0;
                            Curr_Status         <= 8'h00;
                            Curr_Dx             <= 8'h00;
                            Curr_Dy             <= 8'h00;
                            Curr_Dz             <= 8'h00;
                            Curr_SendInterrupt  <= 1'b0;
                            Curr_ScrollWheel    <= 1'b0;
            end else begin
                            Curr_State          <= Next_State;
                            Curr_Counter        <= Next_Counter;
                            Curr_SendByte       <= Next_SendByte;
                            Curr_ByteToSend     <= Next_ByteToSend;
                            Curr_ReadEnable     <= Next_ReadEnable;
                            Curr_Status         <= Next_Status;
                            Curr_Dx             <= Next_Dx;
                            Curr_Dy             <= Next_Dy;
                            Curr_Dz             <= Next_Dz; // Scroll Wheel
                            Curr_SendInterrupt  <= Next_SendInterrupt;    
                            Curr_ScrollWheel    <= Next_ScrollWheel; // Scroll Wheel Checker
            end
    end
    
    // Combinatorial
    always@*begin
            Next_State          = Curr_State;
            Next_Counter        = Curr_Counter;
            Next_SendByte       = 1'b0;
            Next_ByteToSend     = Curr_ByteToSend;
            Next_ReadEnable     = 1'b0;
            Next_Status         = Curr_Status;
            Next_Dx             = Curr_Dx;
            Next_Dy             = Curr_Dy;
            Next_Dz             = Curr_Dz; // Scroll Wheel
            Next_SendInterrupt  = 1'b0;
            Next_ScrollWheel    = Curr_ScrollWheel; // When it is set to 1, stays at 1 until RESET.            
            
            
            case(Curr_State)
            
                    // Initialise State - Wait here for 10ms before trying to initialise the mouse.
                    8'h00:   begin
                                if(Curr_Counter == 1000000) begin // 1/100th sec at 50MHz clock -- but clock is 100MHz, so double original count, since clock twice as fast.
                                    Next_State = 8'h01;
                                    Next_Counter = 0;
                                end else
                                Next_Counter = Curr_Counter + 1'b1;
                            end
                            
                    // Start initialisation by sending FF
                    8'h01:   begin
                                Next_State = 8'h02;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'hFF;
                            end
                            
                    // Wait for confirmation of the byte being sent
                    8'h02:   begin
                                if(BYTE_SENT)
                                    Next_State = 8'h03;
                            end
                            
                    // Wait for confirmation of a byte being received
                    // If the byte is FA go to next state, else re-initialise.
                    8'h03:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h04;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // Wait for self-test pass confirmation
                    // If the byte received is AA go to next state, else re-initialise
                    8'h04:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hAA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h05;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                    
                    // Wait for confirmation of a byte being received
                    // If the byte is 00 go to next state (MOUSE ID) else re-initialise
                    8'h05:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'h00) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h06;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                    
                    
                    //*************************************************//
                    //
                    // BONUS FEATURE - we will now aim to initialise the SCROLL WHEEL on the mouse
                    // Following PS2 Guidelines found online
                    // Must Set Sample Rates to particular values
                    //
                    // Sample Rate 1 = 200 or C8
                    // Sample Rate 2 = 100 or 64
                    // Sample Rate 3 = 80 or 50
                    //
                    // A Mouse ID of '03' will be returned if initialisation is successful
                    // A Mouse ID of '00' will be returned if the mouse does not have a scroll wheel
                    //
                    //*************************************************//
                    
                    // Send F3 to Enter "Set Sample Rate" mode
                    8'h06:   begin
                                Next_State = 8'h07;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'hF3;
                            end
                    
                    // Wait for confirmation of the byte being sent        
                    8'h07:   if(BYTE_SENT) Next_State = 8'h08;
                    
                    // Wait for confirmation of the byte being received.
                    // If the byte is FA go to next state, else re-initialise.
                    8'h08:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h09;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // SEND FIRST OF THE SAMPLE RATES - '200' in Decimal or 'C8' in Hexadecimal
                    8'h09:   begin
                                Next_State = 8'h0A;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'hC8;
                            end
                    
                    // Wait for confirmation of the byte being sent        
                    8'h0A:   if(BYTE_SENT) Next_State = 8'h0B;
                    
                    // Wait for confirmation of the byte being received.
                    // If the byte is FA go to next state, else re-initialise.
                    8'h0B:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h0C;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                    
                    // Send F3 to Enter "Set Sample Rate" mode
                    8'h0C:   begin
                                Next_State = 8'h0D;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'hF3;
                            end
                    
                    // Wait for confirmation of the byte being sent        
                    8'h0D:   if(BYTE_SENT) Next_State = 8'h0E;
                    
                    // Wait for confirmation of the byte being received.
                    // If the byte is FA go to next state, else re-initialise.
                    8'h0E:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h0F;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // SEND SECOND OF THE SAMPLE RATES - '100' in Decimal or '64' in Hexadecimal.
                    8'h0F:   begin
                                Next_State = 8'h10;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'h64;
                            end
                    
                    // Wait for confirmation of the byte being sent        
                    8'h10:   if(BYTE_SENT) Next_State = 8'h11;
                    
                    // Wait for confirmation of the byte being received.
                    // If the byte is FA go to next state, else re-initialise.
                    8'h11:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h12;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // Send F3 to Enter "Set Sample Rate" mode
                    8'h12:   begin
                                Next_State = 8'h13;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'hF3;
                            end
                    
                    // Wait for confirmation of the byte being sent        
                    8'h13:   if(BYTE_SENT) Next_State = 8'h14;
                    
                    // Wait for confirmation of the byte being received.
                    // If the byte is FA go to next state, else re-initialise.
                    8'h14:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h15;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // SEND THIRD AND FINAL OF THE SAMPLE RATES - '80' in Decimal or '50' in Hexadecimal
                    8'h15:   begin
                                Next_State = 8'h16;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'h50;
                            end
                    
                    // Wait for confirmation of the byte being sent        
                    8'h16:   if(BYTE_SENT) Next_State = 8'h17;
                    
                    // Wait for confirmation of the byte being received.
                    // If the byte is FA go to next state, else re-initialise.
                    8'h17:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h18;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // Send F2 in order to read the device type (MOUSE ID)
                    8'h18:   begin
                                Next_State = 8'h19;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'hF2;
                            end
                            
                    // Wait for confirmation of the byte being sent        
                    8'h19:   if(BYTE_SENT) Next_State = 8'h1A;

                    // Wait for confirmation of the byte being received.
                    // If the byte is FA go to next state, else re-initialise.
                    8'h1A:   begin
                                if(BYTE_READY) begin
                                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                                        Next_State = 8'h1B;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // Wait for confirmation of the byte being received
                    // NOW... if the byte (MOUSE ID) is 00, then no scroll wheel present - initialisation without scroll wheel (3 BYTE Packets)
                    // BUT... if the byte (MOUSE ID) is 03, scroll wheel present - inititalise scroll wheel (Receive 4 BYTE Packets)
                    // Initialisation changes depending on MOUSE ID received.
                    8'h1B:  begin     
                                if(BYTE_READY) begin
                                    if(BYTE_ERROR_CODE == 2'b00) begin
                                    
                                        if(BYTE_READ == 8'h00) begin // NON-SCROLL WHEEL MODE INITIALISED
                                            Next_State = 8'h1C;
                                            Next_ScrollWheel = 1'b0; // New variable to indicate whether there is a scroll wheel on the mouse or not.
                                            
                                        end else if(BYTE_READ == 8'h03) begin // SCROLL WHEEL MODE INITIALISED
                                            Next_State = 8'h1C;
                                            Next_ScrollWheel = 1'b1; // New variable to indicate whether there is a scroll wheel on the mouse or not.
                                            
                                        end else
                                            Next_State = 8'h00;
                                    end else
                                        Next_State = 8'h00;
                               end
                               Next_ReadEnable = 1'b1;
                           end 
                    
                    
                    //**************************************************//
                    // END OF SCROLL WHEEL INITIALISATION                             
                    //**************************************************//
                    
                    
                    // Now Switch Mouse to "Transmit" mode so it can transmit data to the Host (FPGA Board).
                    // Send F4 - to start mouse transmit
                    8'h1C:   begin
                                Next_State = 8'h1D;
                                Next_SendByte = 1'b1;
                                Next_ByteToSend = 8'hF4;
                            end
                            
                    // Wait for confirmation of the byte being sent
                    8'h1D: if(BYTE_SENT) Next_State = 8'h1E;
                    
                    // Wait for confirmation of a byte being received.
                    // If the byte is F4 go to next state, else re-initialise - acknowledgement code should be FA but due to USB
                    // to PS/2 Conversion, acknowledgement code is F4 so we check for this - BUT... actually through testing (ILA Debugger), Discover it received FA (so check for this)
                    8'h1E:   begin
                                if(BYTE_READY) begin
                                    if(BYTE_READ == 8'hFA) // This contradicts the lab manual but seems to be what is received in testing (ILA Debugger).
                                        Next_State = 8'h1F;
                                    else
                                        Next_State = 8'h00;
                                end
                                Next_ReadEnable = 1'b1;
                            end
                            
                    //************************************************//
                    // At this point the SM has initialised the mouse.
                    // Now we are constantly reading. If at any time
                    // there is an error, we will re-initialise
                    // the mouse - just in case.
                    //***********************************************//
                    
                    // Wait for the confirmation of a byte being received.
                    // This byte will be the first of three (or four), the status byte.
                    // If a byte arrives, but is corrupted, then we re-initialise
                    
                    8'h1F:   begin
                                if(BYTE_READY) begin // needed to separate out if statements here, first BYTE_READY checked, then BYTE_ERROR_CODE
                                    if(BYTE_ERROR_CODE == 2'b00) begin // this separation prevents looping back to 0 if BYTE_READY isn't set to 1 when first moving from state 8.
                                        Next_State = 8'h20;
                                        Next_Status = BYTE_READ;
                                    end else
                                        Next_State = 8'h00;
                                end
                                
                                Next_Counter = 0;
                                Next_ReadEnable = 1'b1;
                            end
                    
                    // Wait for confirmation of a byte being received
                    // This byte will be the second of three (or four), the Dx byte
    
                    8'h20:   begin
                                if(BYTE_READY) begin // separation here too...
                                    if(BYTE_ERROR_CODE == 2'b00) begin
                                        Next_State = 8'h21;
                                        Next_Dx = BYTE_READ;
                                    end else
                                        Next_State = 8'h00;
                                end
                                
                                Next_Counter = 0;
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // Wait for confirmation of a byte being received
                    // This byte will be the third of three (or four), the Dy byte.
                    
                    8'h21:   begin
                                if(BYTE_READY) begin // separation here too... of BYTE_READY and BYTE_ERROR_CODE
                                    if(BYTE_ERROR_CODE == 2'b00) begin
                                        Next_Dy = BYTE_READ;
                                        if(Curr_ScrollWheel == 1'b0) // If scroll wheel not initialised, skips straight to interrupt after third byte
                                            Next_State = 8'h23;
                                        else if(Curr_ScrollWheel == 1'b1) // if scroll wheel initialised, goes to read data from fourth byte
                                            Next_State = 8'h22;
                                            
                                    end else
                                        Next_State = 8'h00;
                                end
                                    
                                Next_Counter = 0;
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // Wait for confirmation of a byte being received
                    
                    // If SCROLL WHEEL was initialised earlier, then this will be the fourth of four bytes, the Dz byte.
                    // Carries 8 bits of differential information about movement of scroll wheel, 2's complement number.
                    
                    // If SCROLL WHEEL and FIVE BUTTON MODE was initialised earlier
                    // Carries Information about 4th and 5th buttons and about movement of scroll wheel.
                    
                    8'h22:  begin
                                if(BYTE_READY) begin // separation here too... of BYTE_READY and BYTE_ERROR_CODE
                                    if(BYTE_ERROR_CODE == 2'b00) begin
                                        Next_State = 8'h23;
                                        Next_Dz = BYTE_READ;
                                    end else
                                        Next_State = 8'h00;
                                end
                                    
                                Next_Counter = 0;
                                Next_ReadEnable = 1'b1;
                            end
                            
                    // Send Interrupt State + Loop to Byte 1 State.
                    
                    8'h23:   begin
                                Next_State = 8'h1F;
                                Next_SendInterrupt = 1'b1;
                            end
                            
                    // Default State - resetting states to 0, or FF in the case of BytetoSend.
                    
                    default: begin
                                Next_State          = 8'h00;
                                Next_Counter        = 0;
                                Next_SendByte       = 1'b0;
                                Next_ByteToSend     = 8'hFF;
                                Next_ReadEnable     = 1'b0;
                                Next_Status         = 8'h00;
                                Next_Dx             = 8'h00;
                                Next_Dy             = 8'h00;
                                Next_Dz             = 8'h00; // Scroll Wheel
                                Next_SendInterrupt  = 1'b0;  
                                Next_ScrollWheel    = 1'b0; // Scroll Wheel Checker
                            end
            endcase
    end
    
    //*******************************************//
    // Tie the SM signals to the IO
    
    // Transmitter
    assign SEND_BYTE            = Curr_SendByte;
    assign BYTE_TO_SEND         = Curr_ByteToSend;
    
    // Receiver
    assign READ_ENABLE          = Curr_ReadEnable;
    
    // Output Mouse Data
    assign MOUSE_DX             = Curr_Dx; // X Movement
    assign MOUSE_DY             = Curr_Dy; // Y Movement
    assign MOUSE_DZ             = Curr_Dz; // Scroll Wheel
    assign MOUSE_STATUS         = Curr_Status;
    assign SEND_INTERRUPT       = Curr_SendInterrupt;
    
    assign STATE_WATCHER        = Curr_State; // FOR ILA DEBUGGER
    
endmodule
