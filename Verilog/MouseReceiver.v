`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 01.02.2022 10:11:49
// Design Name: Mouse Driver
// Module Name: MouseReceiver
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Module to allow host to receive Data from the Mouse.
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MouseReceiver(

    // Standard Inputs
    input               RESET,
    input               CLK,
    // Mouse IO - CLK
    input               CLK_MOUSE_IN,
    // Mouse IO - DATA
    input               DATA_MOUSE_IN,
    //Control
    input               READ_ENABLE,
    output [7:0]        BYTE_READ, // Value of the Byte received.
    output [1:0]        BYTE_ERROR_CODE,
    output              BYTE_READY // Confirms Byte was received.                 
    );
    
    //*****************************************//
    //*****************************************//
    // Clk Mouse delayed to detect clock edges
    reg ClkMouseInDLY;
    always@(posedge CLK)
           ClkMouseInDLY <= CLK_MOUSE_IN;
    
    //*****************************************//
    // A Simple state machine to handle the incoming 11-bit codewords
    reg [2:0]           Curr_State, Next_State;
    reg [7:0]           Curr_MSCodeShiftReg, Next_MSCodeShiftReg;
    reg [3:0]           Curr_BitCounter, Next_BitCounter;
    reg                 Curr_ByteReceived, Next_ByteReceived;
    reg [1:0]           Curr_MSCodeStatus, Next_MSCodeStatus;
    reg [15:0]          Curr_TimeoutCounter, Next_TimeoutCounter;
    
    
    //*****************************************//
    // Sequential
    always@(posedge CLK) begin
            // Resets all states to 0
            if(RESET) begin
                    Curr_State              <= 3'b000;
                    Curr_MSCodeShiftReg     <= 8'h00;
                    Curr_BitCounter         <= 0;
                    Curr_ByteReceived       <= 1'b0;
                    Curr_MSCodeStatus       <= 2'b00;
                    Curr_TimeoutCounter     <= 0;
            // Cycle to the next state at posedge of the CLK
            end else begin
                    Curr_State              <= Next_State;
                    Curr_MSCodeShiftReg     <= Next_MSCodeShiftReg;
                    Curr_BitCounter         <= Next_BitCounter;
                    Curr_ByteReceived       <= Next_ByteReceived;
                    Curr_MSCodeStatus       <= Next_MSCodeStatus;
                    Curr_TimeoutCounter     <= Next_TimeoutCounter;
             end
     end
     
     
     //****************************************//
     // Combinatorial
     always@* begin
            // defaults to make the State Machine more readable, states stay the same by default
            Next_State              = Curr_State;
            Next_MSCodeShiftReg     = Curr_MSCodeShiftReg;
            Next_BitCounter         = Curr_BitCounter;
            Next_ByteReceived       = 1'b0;
            Next_MSCodeStatus       = Curr_MSCodeStatus;
            Next_TimeoutCounter     = Curr_TimeoutCounter + 1'b1;
            
            // The States
            case(Curr_State)
            
            3'b000: begin
                // Falling edge of Mouse clock and Mouse Data is low i.e. start bit
                if(READ_ENABLE & ClkMouseInDLY & ~CLK_MOUSE_IN & ~DATA_MOUSE_IN) begin
                    Next_State                  = 3'b001;
                    Next_MSCodeStatus           = 2'b00;
                end
                Next_BitCounter                 = 0;
                Next_TimeoutCounter             = 0;
            end
                
            // Read Successive bits of the byte sent from the mouse here
            3'b001: begin
                if(Curr_TimeoutCounter == 50000) // 0.5ms Timeout
                    Next_State                  = 3'b000;
                else if(Curr_BitCounter == 8) begin // if its the last bit, go to parity bit check
                    Next_State                  = 3'b010;
                    Next_BitCounter             = 0;
                end else if(ClkMouseInDLY & ~CLK_MOUSE_IN) begin // Shift Byte bits in
                    Next_MSCodeShiftReg [6:0]   = Curr_MSCodeShiftReg [7:1];
                    Next_MSCodeShiftReg [7]     = DATA_MOUSE_IN;
                    Next_BitCounter             = Curr_BitCounter +1;
                    Next_TimeoutCounter         = 0;
                end
            end
            
            // Check the Parity Bit
            3'b010: begin
            // Falling edge of Mouse Clock and Mouse Data is odd parity
                if(Curr_TimeoutCounter == 50000) // 0.5ms Timeout
                    Next_State                  = 3'b000;
                else if(ClkMouseInDLY & ~CLK_MOUSE_IN) begin
                    if (DATA_MOUSE_IN != ~^Curr_MSCodeShiftReg[7:0]) // Parity Bit Error
                            Next_MSCodeStatus[0] = 1'b1;
                    Next_BitCounter         = 0;
                    Next_State              = 3'b011;
                    Next_TimeoutCounter     = 0;
                end
            end
               
            //***************************************************************//
            // My Own Additional Code to Finish State Machine   
            
            // Check the Stop Bit
            3'b011: begin
                if(Curr_TimeoutCounter == 100000) // 1ms Timeout
                    Next_State                  = 3'b000;
                // Falling edge of Mouse Clock and Mouse Data is high i.e stop bit
                else if(ClkMouseInDLY & ~CLK_MOUSE_IN) begin
                    if(DATA_MOUSE_IN)
                        Next_MSCodeStatus[1] = 1'b0;
                    else
                        // else there is an error
                        Next_MSCodeStatus[1] = 1'b1;
                    
                    Next_State              = 3'b100;
                    Next_TimeoutCounter     = 0; // Reset timeout counter.
                end
            end
            
            // Final State to confirm that byte was received and then Loop Back to the beginning
            3'b100: begin
                //if(Curr_TimeoutCounter == 100000) // 1ms Timeout
                //    Next_State = 3'b000;
                //else if (CLK_MOUSE_IN & DATA_MOUSE_IN) begin
                    Next_ByteReceived = 1'b1; // Confirm byte was received.
                    Next_State = 3'b000;
                //end
            end
            
            // Default Case if nothing is happening - reset all states to 0
            default: begin
                Next_State              = 3'b000;
                Next_MSCodeShiftReg     = 8'h00;
                Next_BitCounter         = 0;
                Next_ByteReceived       = 1'b0;
                Next_MSCodeStatus       = 2'b00;
                Next_TimeoutCounter     = 0;
                    end 
            
            endcase
            
    end
    
    //**********************************************//
    //**********************************************//                    
    // Assign Statements
    assign BYTE_READY           = Curr_ByteReceived;
    assign BYTE_READ            = Curr_MSCodeShiftReg;
    assign BYTE_ERROR_CODE      = Curr_MSCodeStatus;
    

endmodule
