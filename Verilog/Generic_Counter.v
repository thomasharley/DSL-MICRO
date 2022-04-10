`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956)
// 
// Create Date: 05.11.2020 12:37:10
// Design Name: Mouse Driver
// Module Name: Generic_Counter
// Project Name: Digital Systems Laboratory 
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Generic Counter to count to a certain number based on how many clock cycles have passed.
// 
// Dependencies: none
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Generic_Counter(
        CLK,
        RESET,
        ENABLE,
        TRIG_OUT,
        COUNT
        );
        
        // Can choose counter width/ maximum
        parameter COUNTER_WIDTH     = 4;
        parameter COUNTER_MAX       = 9;
        
        // Inputs
        input           CLK;
        input           RESET;
        input           ENABLE;
        
        // Outputs
        output          TRIG_OUT;
        output          [COUNTER_WIDTH-1:0] COUNT;
        
        // Declare registers that hold the current count value and trigger out
        // between Clock Cycles.
        reg [COUNTER_WIDTH-1:0] count_value;
        reg Trigger_out;
        
        // Synchronous Logic for value of count_value
        always@(posedge CLK) begin
                if(RESET)
                        count_value <= 0;
                else begin
                        if(ENABLE) begin
                                if(count_value == COUNTER_MAX)
                                        count_value <= 0;
                                else
                                        count_value <= count_value + 1;
                        end
                end
        end
                        
        // Synchronous Logic for value of Trigger_out
        always@(posedge CLK) begin
                if(RESET)
                        Trigger_out <= 0;
                else begin
                        if(ENABLE && (count_value == COUNTER_MAX))
                                Trigger_out <= 1;
                        else
                                Trigger_out <= 0;
                end
        end
        
        // Assign Statements
        assign COUNT            = count_value;
        assign TRIG_OUT         = Trigger_out;
                        
    
endmodule
