`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Thomas Harley (s1810956) 
// 
// Create Date: 18.03.2022 17:47:50
// Design Name: Mouse Driver
// Module Name: Timer
// Project Name: Digital Systems Laboratory
// Target Devices: Basys3 FPGA Board
// Tool Versions: Vivado 2015.2
// Description: Timer peripheral submodule to Trigger Interrupts on a timer.
// 
// Dependencies: none. 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Timer(
    
    // Standard Signals
    input                   CLK,
    input                   RESET,
    
    // BUS Signals
    inout [7:0]             BUS_DATA,
    inout [7:0]             BUS_ADDR,
    input                   BUS_WE,
    
    // Interrupt Signals
    output                  BUS_INTERRUPT_RAISE,
    input                   BUS_INTERRUPT_ACK // Acknowledge                         
    
    );
    
    // Parameters
    parameter [7:0]         TimerBaseAddr = 8'hF0;          // Timer Base Address in the Memory Map
    parameter               InitialInterruptRate = 100;     // Changed Interrupt rate leading to 1 interrupt every 10s (ROUGHLY)
    parameter               InitialInterruptEnable = 1'b1;  // By default the interrupt is Enabled
    
    //**********************************************************//
    //
    // BaseAddr + 0 --> Reports Current timer value
    // BaseAddr + 1 --> Address of a timer interrupt interval register, 100ms by default
    // BaseAddr + 2 --> Resets the timer, restart counting from zero
    // BaseAddr + 3 --> Address of an interrupt Enable register, allows the microprocessor to disable the timer
    
    // This Module will raise an interrupt flag when the designated time is up. It will
    // automatically set the time of the next interrupt to the time of the last interrupt plus
    // a configurable value ( in milliseconds).
    
    
    //**********************************************************//
    // Interrupt Rate Configuration - The Rate is initialised to 100 by the parameter above, but can
    // also be set by the processor by writing to mem address BaseAddr + 1.
    reg [7:0]               InterruptRate;
    
    // Sequential Logic
    always@(posedge CLK) begin
            if(RESET)
                    InterruptRate           <= InitialInterruptRate;
            else if((BUS_ADDR == TimerBaseAddr + 8'h01) & BUS_WE)
                    InterruptRate           <= BUS_DATA;
    end
    
    
    //**********************************************************//
    // Interrupt Enable Configuration - If this is not set to 1, no interrupts will be
    // created.
    reg                     InterruptEnable;
    
    always@(posedge CLK) begin
            if(RESET)
                    InterruptEnable         <= InitialInterruptEnable;
            else if((BUS_ADDR == TimerBaseAddr + 8'h03) & BUS_WE)
                    InterruptEnable         <= BUS_DATA[0];
    end
    
    // First we must lower the clock speed from 50MHz to 1KHz (1ms period)
    
    // Edited this by multiplying it so clock speed is 100ms
    reg [31:0]              DownCounter;
    
    always@(posedge CLK) begin
            if(RESET)
                    DownCounter             <= 0;
            else begin
                    if(DownCounter == 32'd99999)
                            DownCounter     <= 0;
                    else
                            DownCounter     <= DownCounter + 1'b1;
            end
    end
    
    // Now we can record the last time an interrupt was sent, 
    // and add a value to it to determine if it is time to raise the interrupt.
    
    // But first, let us generate the 1ms counter (TIMER) (NOTE: NOW ITS 100MS BECAUSE OF CHANGE I MADE).
    reg [31:0]              Timer;
    
    always@(posedge CLK) begin
            if(RESET | (BUS_ADDR == TimerBaseAddr + 8'h02))
                    Timer                   <= 0;
            else begin
                    if((DownCounter == 0))
                            Timer           <= Timer + 1'b1;
                    else
                            Timer           <= Timer;
            end
    end
    
    //**********************************************************//
    // Interrupt Generation
    reg                     TargetReached;
    reg [31:0]              LastTime;
    
    always@(posedge CLK) begin
            if(RESET) begin
                    TargetReached           <= 1'b0;
                    LastTime                <= 0;
            end else if((LastTime + InterruptRate) == Timer) begin
                    if(InterruptEnable)
                            TargetReached   <= 1'b1;
                    LastTime                <= Timer;
            end else
                    TargetReached           <= 1'b0;
    end
    
    //**********************************************************//
    // Broadcast the Interrupt
    reg                     Interrupt;
    
    always@(posedge CLK) begin
            if(RESET)
                    Interrupt               <= 1'b0;
            else if(TargetReached)
                    Interrupt               <= 1'b1;
            else if(BUS_INTERRUPT_ACK)
                    Interrupt               <= 1'b0;
    end                
    
    // Assign Statement - Raise Interrupt
    assign BUS_INTERRUPT_RAISE = Interrupt;
    
    
    //**********************************************************//
    // Tristate output for interrupt timer output value
    reg TransmitTimerValue;
    
    always@(posedge CLK) begin
            if(BUS_ADDR == TimerBaseAddr)
                    TransmitTimerValue      <= 1'b1;
            else
                    TransmitTimerValue      <= 1'b0;
    end
    
    // Assign Statement - Transmit Timer Value over BUS_DATA
    assign BUS_DATA = (TransmitTimerValue) ? Timer[7:0] : 8'hZZ;

endmodule
