`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2022 11:15:03
// Design Name: 
// Module Name: Frame_Buffer
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


module Frame_Buffer(

    // PORT A - READ/WRITE
    input               A_CLK,
    input [14:0]        A_ADDR,
    input               A_DATA_IN,  // PIXEL DATA IN
    
    output reg          A_DATA_OUT,
    input               A_WE,       // WRITE ENABEL
   
    // PORT B - READ ONLY
    input               B_CLK,
    input [14:0]        B_ADDR,     // PIXEL DATA OUT
   
    output reg          B_DATA
    );
   
    // 256X128 1-bit memory to hold frame data
    // LSB--> X-AXIS
    // MSB-->Y-AXIS
    
    reg[0:0] Mem[2**15-1:0];
   
    //*********************************************//
    // Port A - Read/Write (used my microprocessor)
    always@(posedge A_CLK) begin
            if(A_WE)
                    Mem[A_ADDR]<=A_DATA_IN;
           
            A_DATA_OUT <=Mem[A_ADDR];
       
   end
   
   //*********************************************//
   // Port B -Read only (read by VGA module)
   always@(posedge B_CLK)
            B_DATA  <=Mem[B_ADDR];
   
endmodule