`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 01.02.2022 11:36:01
// Design Name: Mouse Driver
// Module Name: MouseTransmitter
// Project Name: Digital Systems Laboratory 
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Module to allow Host to send Data to the Mouse (set sample rates, check Mouse ID, etc.)
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MouseTransmitter(

    // Standard Inputs
    input               RESET,
    input               CLK,
    // Mouse IO - CLK
    input               CLK_MOUSE_IN,
    output              CLK_MOUSE_OUT_EN, // Allows for the control of the Clock Line
    // Mouse IO - DATA
    input               DATA_MOUSE_IN,
    output              DATA_MOUSE_OUT,
    output              DATA_MOUSE_OUT_EN, // Control the Data Line
    // Control
    input               SEND_BYTE,
    input [7:0]         BYTE_TO_SEND,
    output              BYTE_SENT // Confirms Byte was sent by transmitter
    );
    
    //**************************************************//
    //**************************************************//
    // Clk Mouse delayed to detect clock edges
    reg ClkMouseInDLY;
    always@(posedge CLK)
            ClkMouseInDLY <= CLK_MOUSE_IN;
    
    //*************************************************//
    // Now a State Machine to control the flow of write data
    reg [3:0]           Curr_State, Next_State;
    reg                 Curr_MouseClkOutWE, Next_MouseClkOutWE;
    reg                 Curr_MouseDataOut, Next_MouseDataOut;
    reg                 Curr_MouseDataOutWE, Next_MouseDataOutWE;
    reg [15:0]          Curr_SendCounter, Next_SendCounter;
    reg                 Curr_ByteSent, Next_ByteSent;
    reg [7:0]           Curr_ByteToSend, Next_ByteToSend;
    
    
    //*************************************************//
    // Sequential
    always@(posedge CLK) begin
            if(RESET) begin
                    Curr_State              <= 4'h0;
                    Curr_MouseClkOutWE      <= 1'b0;
                    Curr_MouseDataOut       <= 1'b0;
                    Curr_MouseDataOutWE     <= 1'b0;
                    Curr_SendCounter        <= 0;
                    Curr_ByteSent           <= 1'b0;
                    Curr_ByteToSend         <= 0;
            end else begin
                    Curr_State              <= Next_State;
                    Curr_MouseClkOutWE      <= Next_MouseClkOutWE;
                    Curr_MouseDataOut       <= Next_MouseDataOut;
                    Curr_MouseDataOutWE     <= Next_MouseDataOutWE;
                    Curr_SendCounter        <= Next_SendCounter;
                    Curr_ByteSent           <= Next_ByteSent;
                    Curr_ByteToSend         <= Next_ByteToSend;
           end
    end
    
    //*************************************************//
    // Combinatorial
    always@* begin
            // default values
            Next_State                  = Curr_State;
            Next_MouseClkOutWE          = 1'b0;
            Next_MouseDataOut           = 1'b0;
            Next_MouseDataOutWE         = Curr_MouseDataOutWE;
            Next_SendCounter            = Curr_SendCounter;
            Next_ByteSent               = 1'b0;
            Next_ByteToSend             = Curr_ByteToSend;
    
            case(Curr_State)
                    // IDLE State
                    4'h0 : begin
                        if(SEND_BYTE) begin
                            Next_State          = 4'h1;
                            Next_ByteToSend     = BYTE_TO_SEND;
                        end
                        Next_MouseDataOutWE = 1'b0;   
                    end
                    
                    // Bring Clock line low for at least 100 microsecs i.e. 5000 clock cycles @ 50MHz - but clock is actually @100MHz
                    4'h1 : begin
                        if(Curr_SendCounter == 10000) begin
                            Next_State          = 4'h2;
                            Next_SendCounter    = 0;
                        end else
                            Next_SendCounter    = Curr_SendCounter + 1'b1;
                            
                        Next_MouseClkOutWE      = 1'b1; // Clock line low... opposite (see transceiver)
                    end
                    
                    // Bring the Data Line Low and release the Clock line - clock will default release don't need to add another line
                    4'h2 : begin
                            Next_State          = 4'h3;
                            Next_MouseDataOutWE = 1'b1; // brings data line low as sets it to value of MouseDataOut which is currently set to 1'b0 (see transceiver)
                    end
                    
                    // Start Sending
                    4'h3 : begin // change data at falling edge of clock, start bit = 0 
                        if(ClkMouseInDLY & ~CLK_MOUSE_IN)
                            Next_State      = 4'h4;
                        end
                    
                    //Send Bits 0 to 7 - We need to send the byte
                    4'h4 : begin // change data at falling edge of clock
                        if(ClkMouseInDLY & ~CLK_MOUSE_IN) begin
                            if(Curr_SendCounter == 7) begin
                                    Next_State          = 4'h5;
                                    Next_SendCounter    = 0;
                            end else
                                    Next_SendCounter    = Curr_SendCounter + 1'b1;
                        end
                        
                        Next_MouseDataOut = Curr_ByteToSend[Curr_SendCounter]; // As we loop through this commmand fills this variable with the bits to be transmitted.
                    end
                    
                    // Send the parity bit
                    4'h5 : begin // change data at falling edge of clock
                        if(ClkMouseInDLY & ~CLK_MOUSE_IN)
                            Next_State              = 4'h6;
                        
                        Next_MouseDataOut           = ~^Curr_ByteToSend[7:0];
                        end
                    
                    //****************************************************************//    
                    // Need to Send Stop Bit which wasn't included in Default Code.
                    4'h6 : begin // change data at falling edge of clock
                        if(ClkMouseInDLY & ~CLK_MOUSE_IN)
                            Next_State              = 4'h7;
                            
                        Next_MouseDataOut           = 1'b1; // Stop Bit = 1
                        end
                            
                    // Release Data line
                    4'h7 : begin
                            Next_State              = 4'h8;
                            Next_MouseDataOutWE     = 1'b0; // This will set Data line to 1 (see transceiver)
                    end 
                    
                    //***************************************************************//
                    // My Own Additional Code to Finish State Machine
                    //***************************************************************//
                    
                    // Wait for Device to Bring Data Line Low, then progress to next state.
                    4'h8 : begin
                        if(~DATA_MOUSE_IN)
                            Next_State              = 4'h9; 
                    end
                        
                    // Wait for Device to Bring Clock Line Low, then progress to next state.
                    4'h9 : begin
                        if(~CLK_MOUSE_IN)
                            Next_State              = 4'hA;
                    end
                    
                    // Finally, Wait for Device to Release Data line and Clock line, then cycle back to IDLE state
                    4'hA : begin
                        if(DATA_MOUSE_IN & CLK_MOUSE_IN)
                            Next_State              = 4'h0;
                            Next_ByteSent           = 1'b1;
                    end
                    
                    // Default case if nothing is happening
                    default: begin
                        Next_State              <= 4'h0;
                        Next_MouseClkOutWE      <= 1'b0;
                        Next_MouseDataOut       <= 1'b0;
                        Next_MouseDataOutWE     <= 1'b0;
                        Next_SendCounter        <= 0;
                        Next_ByteSent           <= 1'b0;
                        Next_ByteToSend         <= 0;
                            end
                    
            endcase
    end
    
    //*************************************************//
    //*************************************************//
    //Assign OUTPUTs
    //Mouse IO - CLK
    assign CLK_MOUSE_OUT_EN             = Curr_MouseClkOutWE;
    //Mouse IO - DATA
    assign DATA_MOUSE_OUT               = Curr_MouseDataOut;
    assign DATA_MOUSE_OUT_EN            = Curr_MouseDataOutWE;
    //Control
    assign BYTE_SENT                    = Curr_ByteSent;
    
endmodule
