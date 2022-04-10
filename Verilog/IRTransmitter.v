`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03.03.2022 14:35:06
// Design Name:
// Module Name: IR_top
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


module IRTransmitter(

    // Standard Signals
    input           CLK,
    input           RESET,

    //BUS signals
    inout [7:0]     BUS_DATA,
    input [7:0]     BUS_ADDR,
    input           BUS_WE,

    // Peripheral signals
    output          IR_LED
    );

    parameter [7:0] IRBaseAddr = 8'h90; // IR_Transmitter Base Address in the Memory Map

    //BaseAddr + 0 -> Store Command & send packet
    //BaseAddr + 1 -> Car Select

    reg             RCLK = 1'b0;
    
    always@(posedge CLK) begin
            RCLK = ~RCLK;
    end
    
    //******************************************************************************//
    //**************** Send SEND_PACKET & store COMMAND signal. ********************//

    // Send Packet
    reg SEND_PACKET = 1'b0;
    
    always@(posedge CLK) begin
            if(RESET)
                SEND_PACKET     <= 1'b0;
            else if((BUS_ADDR == IRBaseAddr) & BUS_WE) // If Bus Addr == 0x90
                SEND_PACKET     <= 1'b1;
            else
                SEND_PACKET     <= 1'b0;
    end

    // Store COMMAND
    reg [3:0] COMMAND = 4'h0;
    
    always@(posedge CLK) begin
            if(RESET)
                COMMAND         <= 4'b0000;
            else if((BUS_ADDR == IRBaseAddr) & BUS_WE) // If Bus Addr == 0x90
                COMMAND         <= BUS_DATA[3:0];
    end


    // Retrieve Car Select signal
    reg [1:0] CAR_SELECT = 2'd0;
    
    always@(posedge CLK) begin
            if(RESET)
                CAR_SELECT      <= 2'd0;
            else if((BUS_ADDR == IRBaseAddr + 1) & BUS_WE) // If Bus Addr == 0x91
                CAR_SELECT      <= BUS_DATA[1:0];
    end


    //******************************************************************//
    //*************** State Machines for each car **********************//

    wire [3:0]  IR_OUT;
    
    parameter   BLUE = 2'd0, YELLOW = 2'd1, GREEN = 2'd2, RED = 2'd3;

    // Instantiations of Sub Module
    // Blue SM
    IRTransmitterSM # (
                        .StartBurstSize(191),       // 191
                        .CarSelectBurstSize(47),    // 47
                        .GapSize(25),               // 25
                        .AssertBurstSize(47),       // 47
                        .DeassertBurstSize(22),     // 22
                        .FrequencyReduction(4)      // 4
                        )
                        Blue_SM(
                        .CLK(RCLK),
                        .RESET(RESET),
                        .SEND_PACKET(SEND_PACKET),
                        .COMMAND(COMMAND),
                        .IR_LED(IR_OUT[0])
                        );


    // Yellow SM
    IRTransmitterSM # (
                        .StartBurstSize(88),        // 88
                        .CarSelectBurstSize(22),    // 22
                        .GapSize(40),               // 40
                        .AssertBurstSize(44),       // 44
                        .DeassertBurstSize(22),     // 22
                        .FrequencyReduction(4)      // 4
                        )
                        Yellow_SM(
                        .CLK(RCLK),
                        .RESET(RESET),
                        .SEND_PACKET(SEND_PACKET),
                        .COMMAND(COMMAND),
                        .IR_LED(IR_OUT[1])
                        );

    // Green SM
    IRTransmitterSM # (
                        .StartBurstSize(88),        // 88
                        .CarSelectBurstSize(44),    // 44
                        .GapSize(40),               // 40
                        .AssertBurstSize(44),       // 44
                        .DeassertBurstSize(22),     // 22
                        .FrequencyReduction(4)      // 4
                        )
                        Green_SM(
                        .CLK(RCLK),
                        .RESET(RESET),
                        .SEND_PACKET(SEND_PACKET),
                        .COMMAND(COMMAND),
                        .IR_LED(IR_OUT[2])
                        );

    // Red SM
    IRTransmitterSM # (
                        .StartBurstSize(192),       // 192
                        .CarSelectBurstSize(24),    // 24
                        .GapSize(24),               // 24
                        .AssertBurstSize(48),       // 48
                        .DeassertBurstSize(24),     // 24
                        .FrequencyReduction(4)      // 4
                        )
                        Red_SM(
                        .CLK(RCLK),
                        .RESET(RESET),
                        .SEND_PACKET(SEND_PACKET),
                        .COMMAND(COMMAND),
                        .IR_LED(IR_OUT[3])
                        );

    //******************************************************************//
    //*************** Send selected SM Output **************************//

    reg         LED_OUT = 1'b0;
    
    always@(CAR_SELECT or IR_OUT) begin
        case(CAR_SELECT)
            BLUE:       LED_OUT <= IR_OUT[0];
            YELLOW:     LED_OUT <= IR_OUT[1];
            GREEN:      LED_OUT <= IR_OUT[2];
            RED:        LED_OUT <= IR_OUT[3];

            default:    LED_OUT <= 0;
        endcase
    end

    // Assign Statement
    assign IR_LED = LED_OUT;


endmodule
