`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.02.2022 11:57:09
// Design Name: 
// Module Name: IRTransmitterSM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IRTransmitterSM(
    // Standard Inputs
    input           CLK,
    input           RESET,
    
    input [3:0]     COMMAND,
    input           SEND_PACKET,
    output          IR_LED
    );
    
    // Blue car / default parameters
    parameter       StartBurstSize = 191;
    parameter       CarSelectBurstSize = 47;
    parameter       GapSize = 25;
    parameter       AssertBurstSize = 47;
    parameter       DeassertBurstSize = 22;
    
    parameter       FrequencyReduction = 1389; 
    
    // State Machine codes
    parameter       WAIT = 5'd0, START = 5'd1, GAP_START = 5'd2, CAR = 5'd3, GAP_CAR = 5'd4;
    parameter       R_ASS = 5'd5, GAP_R = 5'd6, L_ASS = 5'd7, GAP_L = 5'd8, B_ASS = 5'd9;
    parameter       GAP_B = 5'd10, F_ASS = 5'd11, GAP_F = 5'd12, L_DEASS = 5'd15, R_DEASS = 5'd17;
    parameter       B_DEASS = 5'd19, F_DEASS = 5'd21;
    
    /*
    Generate the pulse signal here from the main clock running at 50MHz to generate the right frequency for
    the car in question e.g. 40KHz for BLUE coded cars
    */
    
    wire            fr_trig;
    wire [11:0]     FR_COUNT;
    
    Generic_Counter #(
                    .COUNTER_WIDTH(12),
                    .COUNTER_MAX(FrequencyReduction)
                    )
                    FR(
                    .CLK(CLK),   
                    .RESET(1'b0),  
                    .ENABLE(1'b1),
                    .COUNT(FR_COUNT),
                    .TRIG_OUT(fr_trig)
                    );
                
    reg             RCLK = 1'b0;
    
    // Sequential Logic
    always@(posedge CLK) begin
        if (FR_COUNT >= FrequencyReduction / 2)
                RCLK <= 1'b1;
        else
                RCLK <= 1'b0;
    end
    
    
    assign RCLK_out = RCLK;
    
    
    //****************************************************//
    // SEND_PACKET EXTENDER
    
    reg             start_SM = 1'b0;
    reg [10:0]      packet_ext_count = 11'd0;
    
    always@(posedge CLK) begin
        if(RESET) begin
                start_SM <= 1'b0;
                packet_ext_count <= 2**11 - 11'd1;
        end
        
        else if(SEND_PACKET) begin
                packet_ext_count <= 0;
                start_SM <= 1'b1;
        end
        
        else begin
            if(packet_ext_count == 2**11 - 11'd1)
                start_SM <= 1'b0;
            else begin
                packet_ext_count <= packet_ext_count + 11'd1;
                start_SM <= 1'b1;
            end
        end
    end
    
    
    /*****************
    Simple state machine to generate the states of the packet i.e. Start, Gaps, Right Assert or De-Assert, Left
    Assert or De-Assert, Backward Assert or De-Assert, and Forward Assert or De-Assert
    ******************/
    
    // State Machine codes
    reg [4:0]       Curr_State = WAIT;
    reg [4:0]       Next_State = WAIT;
        
    reg [7:0]       Curr_Count = 8'd1;
    reg [7:0]       Next_Count = 8'd1;


    // Synchronous Logic for SM
    always@(posedge RCLK) begin
        if(RESET) begin
                Curr_State <= WAIT;
                Curr_Count <= 8'd1;
        end
        else begin
                Curr_State <= Next_State;
                Curr_Count <= Next_Count;     
        end
        
    end

    // Asynchronous Logic for SM
    always@(Curr_State or start_SM or Curr_Count or COMMAND) begin
        case(Curr_State)
        
            // Wait for send packet to continue
            WAIT: begin
                if(start_SM) begin
                    Next_State      <= START;
                    Next_Count      <= 8'd0;
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count;
                end
            end
             
            // Send Start burst
            START: begin
                if(Curr_Count == StartBurstSize - 1) begin
                    Next_State      <= GAP_START;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Gap burst
            GAP_START: begin
                if(Curr_Count == GapSize - 1) begin
                    Next_State      <= CAR;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Car Select burst
            CAR: begin
                if(Curr_Count == CarSelectBurstSize - 1) begin
                    Next_State      <= GAP_CAR;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Gap burst and read Right COMMAND
            GAP_CAR: begin
                if(Curr_Count == GapSize - 1) begin
                    if(COMMAND[0])
                        Next_State <= R_ASS;
                    else
                        Next_State <= R_DEASS;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Assert Right burst
            R_ASS: begin
                if(Curr_Count == AssertBurstSize - 1) begin
                Next_State          <= GAP_R;
                    Next_Count      <= 8'd0;                
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Gap burst and read Left COMMAND
            GAP_R: begin
                if(Curr_Count == GapSize - 1) begin
                    if(COMMAND[1])
                        Next_State  <= L_ASS;
                    else
                        Next_State  <= L_DEASS;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State <= Curr_State;
                    Next_Count <= Curr_Count + 1;
                end
            end
            
            // Send Assert Left burst
            L_ASS: begin
                if(Curr_Count == AssertBurstSize - 1) begin
                    Next_State      <= GAP_L;
                    Next_Count      <= 8'd0;                
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Gap burst and read Backwards COMMAND
            GAP_L: begin
                if(Curr_Count == GapSize - 1) begin
                    if(COMMAND[2])
                        Next_State  <= B_ASS;
                    else
                        Next_State  <= B_DEASS;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Assert Backwards burst
            B_ASS: begin
                if(Curr_Count == AssertBurstSize - 1) begin
                        Next_State  <= GAP_B;
                        Next_Count  <= 8'd0;                
                    end
                    else begin
                        Next_State  <= Curr_State;
                        Next_Count  <= Curr_Count + 1;
                    end
                end
            
            // Send Gap burst and read Forwards COMMAND
            GAP_B: begin
                if(Curr_Count == GapSize - 1) begin
                    if(COMMAND[3])
                        Next_State <= F_ASS;
                    else
                        Next_State <= F_DEASS;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Assert Forward burst
            F_ASS: begin
                if(Curr_Count == AssertBurstSize - 1) begin
                    Next_State      <= GAP_F;
                    Next_Count      <= 8'd0;                
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
        
            // Send Gap burst and return to start
            GAP_F: begin
                if(Curr_Count == GapSize - 1) begin
                    Next_State      <= WAIT;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Deassert Right burst
            L_DEASS: begin
                if(Curr_Count == DeassertBurstSize - 1) begin
                    Next_State      <= GAP_L;
                    Next_Count      <= 8'd0;                
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Deassert Left burst
            R_DEASS: begin
                if(Curr_Count >= DeassertBurstSize - 1) begin
                    Next_State      <= GAP_R;
                    Next_Count      <= 8'd0;
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Deassert Backwards burst
            B_DEASS: begin
                if(Curr_Count >= DeassertBurstSize - 1) begin
                    Next_State      <= GAP_B;
                    Next_Count      <= 8'd0; 
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end
            end
            
            // Send Deassert Forward burst
            F_DEASS: begin
                if(Curr_Count == DeassertBurstSize - 1) begin
                    Next_State      <= GAP_F;
                    Next_Count      <= 8'd0;
                end
                else begin
                    Next_State      <= Curr_State;
                    Next_Count      <= Curr_Count + 1;
                end 
            end

            // Default State
            default: begin
                    Next_State      <= WAIT; 
                    Next_Count      <= 8'd0;
            end
        endcase
    
    end

    // Assignment Statements
    // Finally tie the pulse generator with packet state to generate IR_LED
    assign IR_LED = RCLK && Curr_State[0];    
    
endmodule
