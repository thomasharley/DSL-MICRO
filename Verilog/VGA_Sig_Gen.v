`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2022 11:16:32
// Design Name: 
// Module Name: VGA_Sig_Gen
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


module VGA_Sig_Gen(

    input               CLK,
    input               RESET,
    
    // Colour Configuration Interface
    input [15:0]        CONFIG_COLOURS,
    
    // Frame Buffer (Dual Port Memory)
    output              DPR_CLK,
    output [14:0]       VGA_ADDR,
    input               VGA_DATA,
    
    // VGA Port Interface
    output reg          VGA_HS,
    output reg          VGA_VS,
    output [7:0]        VGA_COLOUR
    );
    
    //Vertical Lines
    parameter           VertTimeToPulseWidthEnd     = 10'd2;
    parameter           VertTimeToBackPorchEnd      = 10'd31;
    parameter           VertTimeToDisplayTimeEnd    = 10'd511;
    parameter           VertTimeToFrontPorchEnd     = 10'd521;
        
    // Horizontal Lines
    parameter           HorzTimeToPulseWidthEnd     = 10'd96;
    parameter           HorzTimeToBackPorchEnd      = 10'd144;
    parameter           HorzTimeToDisplayTimeEnd    = 10'd784;
    parameter           HorzTimeToFrontPorchEnd     = 10'd800;
        
    // Counter Variables
    wire [9:0]          Horz_Count;
    wire [9:0]          Vert_Count;
        
    wire                VGA_CLK; // New 25MHz CLK for VGA
        
    // Address registers
    reg [9:0]           ADDRH;  // Horizontal address
    reg [9:0]           ADDRV;  // Vertical address
        
    // Colour registers
    reg [7:0]           COLOUR_STORE;     // Colour to be displayed
    reg [7:0]           Vga_Colour;       // Register asigned to output
        
        
    
    //**************************************************//    
    // Frequency Divider Counter (100MHz to 25MHz)
    // Using TRIG_OUT as the clock creates a 25MHz pulse rather than 25MHz
    // Using NEW_CLK creates a 25MHz square signal
    Generic_Counter #  (.COUNTER_WIDTH (2),
                        .COUNTER_MAX (3))
                        // Counter
                        NewCounter(
                        .CLK(CLK),
                        .RESET(RESET),
                        .ENABLE(1'b1),
                        .TRIG_OUT(VGA_CLK)
                           
                        //.NEW_CLK()
                        );
                            
        
    // Horizontal Counter
    // Enabled evrytime the frequency divider counter is triggered
    Generic_Counter # (.COUNTER_WIDTH (10),
                       .COUNTER_MAX (799))
                        // Counter
                        Horz_Counter(
                       .CLK(CLK),
                       .RESET(RESET),
                       .ENABLE(VGA_CLK),
                       .TRIG_OUT(Horz_TrigOut),
                       .COUNT(Horz_Count)
                        );
           
        
        
    //Vertical Counter
    //Enabled everytime the horizontal counter is triggered
    Generic_Counter #  (.COUNTER_WIDTH (10),
                        .COUNTER_MAX (520))
                        Vert_Counter(
                        .CLK(CLK),
                        .RESET(RESET),
                        .ENABLE(Horz_TrigOut),
                        .COUNT(Vert_Count)
                        );
        
 
    // HS Signal
    // set low when horizontal counter is in range
    always @ (posedge CLK) begin
            if (Horz_Count <= HorzTimeToPulseWidthEnd)
                    VGA_HS<=1'b0;
             else 
                    VGA_HS<=1'b1;
    end
        
    //VS Signal
    //set low when vertical counter is in range
    always @ (posedge CLK) begin
            if (Vert_Count <= VertTimeToPulseWidthEnd)
                    VGA_VS<=1'b0;
            else 
                    VGA_VS<=1'b1;
    end


    //logic to determine if  pixel or background colour is to displayed 
    always@(posedge CLK) begin
            if(VGA_DATA==0)
                    COLOUR_STORE <= CONFIG_COLOURS[7:0];    // VGA_DATA = 0 ---> pixel colour selected
            else
                    COLOUR_STORE <= CONFIG_COLOURS[15:8];   // VGA_DATA = 1 ---> background colour selected
    end
       
       
   //***************************************************************//    
   // Logic to set VGA Colour when vertical and horizontal counters are in range
    always @ (posedge CLK) begin
            if ((Horz_Count <= HorzTimeToDisplayTimeEnd) && (Horz_Count >= HorzTimeToBackPorchEnd) 
            && (Vert_Count <= VertTimeToDisplayTimeEnd) && (Vert_Count >= VertTimeToBackPorchEnd) ) begin
                    Vga_Colour  <= COLOUR_STORE;          // Output colour set to selected colour (either pixel of background)
                    ADDRH       <= Horz_Count -144;       // Subtracting 144 from horizontal count to set address to 0 at start of the display
                    ADDRV       <= Vert_Count - 31;       // Subtracting 31 from vertical count to set address to 0 at start of the display
            end
            
            else begin
                    Vga_Colour  <= 0;           // If count is not in range VGA will not display anything
                    ADDRH       <= 0;
                    ADDRV       <= 0;
            end
    end
        
       
    // Assign Statements
    assign VGA_COLOUR = Vga_Colour;             // Assigning VGA colour to output of the module

    assign DPR_CLK =VGA_CLK;                    // Tie new 25MHz clock to output
    assign VGA_ADDR ={ADDRV[8:2],ADDRH[9:2]};   // Concatenating horizontal and vertical address into one variable to be outputted
    
    
endmodule

