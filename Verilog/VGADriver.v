`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2022 10:31:32
// Design Name: 
// Module Name: VGADriver
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


module VGADriver(
    // Standard Inputs
    input               CLK, 
    
    output wire [7:0]   COLOUR_OUT, // Colour Sent To VGA
    output wire         VGA_HS,     // Horizontal Sync
    output wire         VGA_VS,       
                   
    // Vertical Sync
    inout wire [7:0]    BUS_DATA,
    input wire [7:0]    BUS_ADDR,
    
    // Colour Counter for Background
    input wire [2:0]    COLOUR_COUNTER
 
    );
        
    // Register to hold the value of colour sent to VGA, Bits 0 to 7 hold pixel colours
    // Bits 8 to 15 hold the background colour.
    wire [15:0]         config_colours;
    
    reg [7:0]           background_colour;
    reg [7:0]           foreground_colour;
        
    assign config_colours = {background_colour[7:0],foreground_colour[7:0]};
    
    // Registers and Wires 
    reg [7:0]           A_ADDRH_FRAME ;     // Register to store horizontal address
    reg [6:0]           A_ADDRV_FRAME ;     // Register to store vertical address
        
    wire [14:0]         vga_addr;           // Address from VGA_Sig_Gen, combination of  horizontal and vertical adddress
        
    reg                 Pixel_in;           // Register stored in Frame buffer, used to create chequered image
    wire                B_OUT;              // Sent from frame buffer into VGA_Sig_Gen, decides to colour pixel or square
    wire                A_OUT;
    
    wire                dpr_clk;  
    wire                trig_out;           // Trigger from 1s counter 
       
    reg                 a_we;
        
    wire [14:0]         A_ADDR;
    reg [7:0]           X_DATA=0;
    reg [6:0]           Y_DATA=0;
        
    assign A_ADDR = {Y_DATA,X_DATA}; // Address to write to
    
    // Concatenating vertical and horizontal addresss into one variable to be sent to VGA_Sig_Gen  
    assign vga_addr ={A_ADDRV_FRAME[6:0],A_ADDRH_FRAME[7:0]};                  
    
    //*********************************************************//
    // Frame Buffer Instantiation
    Frame_Buffer Frame (
                    .A_CLK(CLK),
                    .A_ADDR(A_ADDR),
                    .A_DATA_IN(Pixel_in),
                    .A_DATA_OUT(A_OUT),
                    .A_WE(a_we),
                    .B_CLK(dpr_clk),
                    .B_ADDR(vga_addr),
                    .B_DATA(B_OUT)
                    );
    
    //********************************************************//   
    // VGA Signal Generator
    VGA_Sig_Gen Interface (
                    .CLK(CLK),
                    .CONFIG_COLOURS(config_colours),
                    .DPR_CLK(dpr_clk),
                    .VGA_HS(VGA_HS),
                    .VGA_VS(VGA_VS),
                    .VGA_ADDR(vga_addr),
                    .VGA_COLOUR(COLOUR_OUT),
                    .VGA_DATA(B_OUT)
                    );
    
    
    //********************************************************//
    // Sequential Logic  
    
    // Background Colour Counter - Indicate which car is being controlled  
    always@(posedge CLK) begin
            if (COLOUR_COUNTER == 3'b000)
                foreground_colour       <= 8'b11001000;   // Blue
            else if (COLOUR_COUNTER == 3'b001)
                foreground_colour       <= 8'b00000111;   // Red
            else if (COLOUR_COUNTER == 3'b010)
                foreground_colour       <= 8'b00111000;   // Green
            else if (COLOUR_COUNTER ==3'b011)
                foreground_colour       <= 8'b11111111;   // Yellow
                
    end
    
    // Sequential Logic                              
    always@(posedge CLK) begin
            if (BUS_ADDR ==8'hB0)
                    X_DATA              <= BUS_DATA;
       
            else if (BUS_ADDR ==8'hB1)
                    Y_DATA              <= BUS_DATA[6:0]; // Because Vertical(y) is 7 bits and Horizontal (x) is 8 bits
            
            else if(BUS_ADDR ==8'hB2) begin
                    a_we                <= 1'b1;
                    Pixel_in            <= BUS_DATA[0]; 
                    
            // Bonus Feature - Background Colour
            end else if(BUS_ADDR == 8'hB3)
                    background_colour   <= BUS_DATA;           

            else begin
                    a_we                <= 1'b0;
                    Pixel_in            <= Pixel_in;
                    X_DATA              <= X_DATA;
                    Y_DATA              <= Y_DATA;
            end
    end
                    
endmodule
