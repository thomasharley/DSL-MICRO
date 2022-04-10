`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.03.2022 09:33:35
// Design Name: 
// Module Name: Processor
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


//This is the processor module, here the Program counter counts through the program and
//determines the instruction from the ROM file that corresponds to the address of the 
//program counter, it tkaes the values on the ROM and determines which instruction is 
//to be carried out. Inside theprocessor lies the ALU.


module Processor(
    // Standard Signals
    input           CLK,
    input           RESET,
    
    // BUS Signals
    inout [7:0]     BUS_DATA,
    output [7:0]    BUS_ADDR,
    output          BUS_WE,
    
    // ROM signals
    output [7:0]    ROM_ADDRESS,
    input [7:0]     ROM_DATA,
    
    // INTERRUPT signals 
    input [1:0]     BUS_INTERRUPTS_RAISE,
    output [1:0]    BUS_INTERRUPTS_ACK
    );
    
    // The main data bus is treated as tristate, so we need a mechanism to handle this.
    // Tristate signals that interface with the main state machine
    wire [7:0]      BusDataIn;
    
    reg [7:0]       CurrBusDataOut, NextBusDataOut;
    reg             CurrBusDataOutWE, NextBusDataOutWE;
    
    // Tristate Mechanism
    assign BusDataIn    = BUS_DATA;
    assign BUS_DATA     = CurrBusDataOutWE ? CurrBusDataOut : 8'hZZ;
    assign BUS_WE       = CurrBusDataOutWE;
    
    // Address of the bus
    reg [7:0]       CurrBusAddr, NextBusAddr;
    
    assign BUS_ADDR = CurrBusAddr;
    
    // The processor has two internal registers to hold data between operations, and a third to hold
    // the current program context when using function calls.
    reg [7:0]       CurrRegA, NextRegA;
    reg [7:0]       CurrRegB, NextRegB;
    reg             CurrRegSelect, NextRegSelect;
    reg [7:0]       CurrProgContext, NextProgContext;
    
    //Dedicated Interrupt output lines - one for each interrupt line
    reg [1:0]       CurrInterruptAck, NextInterruptAck;
    
    assign BUS_INTERRUPTS_ACK = CurrInterruptAck;
    
    // Instantiate program memory here
    // There is a program counter which points to the current operation. The program counter
    // has an offset that is used to reference information that is part of the current operation
    reg [7:0]       CurrProgCounter, NextProgCounter;
    reg [1:0]       CurrProgCounterOffset, NextProgCounterOffset;
    wire [7:0]      ProgMemoryOut;
    wire [7:0]      ActualAddress;
    
    assign ActualAddress = CurrProgCounter + CurrProgCounterOffset;
    
    // ROM signals
    assign ROM_ADDRESS      = ActualAddress;
    assign ProgMemoryOut    = ROM_DATA;
    
    //*************************************************//
    // Instantiate the ALU
    // The processor has an integrated ALU that can do several different operations
    
    wire [7:0] AluOut;
    
    ALU ALU0(
        //Standard Signals
        .CLK(CLK),
        .RESET(RESET),
        
        //I/O
        .IN_A(CurrRegA),
        .IN_B(CurrRegB),
        .ALU_Op_Code(ProgMemoryOut[7:4]),
        .OUT_RESULT(AluOut)
    );
    
    //***********************************************************************//
    // The microprocessor is essentially a state machine, with one sequential pipeline
    // of states for each operation.
    // The current list of operations is:
    // 0: Read from memory to A
    // 1: Read from memory to B
    // 2: Write to memory from A
    // 3: Write to memory from B
    // 4: Do maths with the ALU, and save result in reg A
    // 5: Do maths with the ALU, and save result in reg B
    // 6: if A (== or < or > B) GoTo ADDR
    // 7: Goto ADDR
    // 8: Go to IDLE
    // 9: End thread, goto idle state and wait for interrupt.
    // 10: Function call
    // 11: Return from function call
    // 12: Dereference A
    // 13: Dereference B
    //***********************************************************************//
    
    
    // Program Thread Selection
    parameter [7:0]  
           
    IDLE = 8'hF0,                       // Waits here until an interrupt wakes up the processor.
    GET_THREAD_START_ADDR_0 = 8'hF1,    // Wait.
    GET_THREAD_START_ADDR_1 = 8'hF2,    // Apply the new address to the program counter.
    GET_THREAD_START_ADDR_2 = 8'hF3,    // Wait. Goto ChooseOp.
    
    // Operation selection
    // Depending on the value of ProgMemOut, goto one of the instruction start states.
    CHOOSE_OPP              = 8'h00,
    
    // Data Flow
    READ_FROM_MEM_TO_A      = 8'h10,    // Wait to find what address to read, save reg select.
    READ_FROM_MEM_TO_B      = 8'h11,    // Wait to find what address to read, save reg select
    
    READ_FROM_MEM_0         = 8'h12,    // Set BUS_ADDR to designated address.
    READ_FROM_MEM_1         = 8'h13,    // Wait - Increments program counter by 2. Reset offset.
    READ_FROM_MEM_2         = 8'h14,    // Writes memory output to chosen register, end op.
    
    WRITE_TO_MEM_FROM_A     = 8'h20,    // Reads Op+1 to find what address to Write to.
    WRITE_TO_MEM_FROM_B     = 8'h21,    // Reads Op+1 to find what address to Write to.
    WRITE_TO_MEM_0          = 8'h22,    // Wait - Increments program counter by 2. Reset offset.
    
    // Data Manipulation
    DO_MATHS_OPP_SAVE_IN_A  = 8'h30,    // The result of maths op. is available, save it to Reg A.
    DO_MATHS_OPP_SAVE_IN_B  = 8'h31,    // The result of maths op. is available, save it to Reg B.
    DO_MATHS_OPP_0          = 8'h32,    // Wait for new op address to settle. end op.
    
    //IF_A_EQUALITY_B_GOTO
    IF_A_EQUALITY_B_GOTO            = 8'h40,    // Determines which inequailty is to be completed
    IF_A_EQUALITY_B_GOTO_EQUAL      = 8'h41,    // A=B (if not increases counter by 2)
    IF_A_EQUALITY_B_GOTO_GREATER    = 8'h42,    // A>B (if not increases counter by 2)
    IF_A_EQUALITY_B_GOTO_LESS       = 8'h43,    // A<B(if not increases counter by 2)
    IF_A_EQUALITY_B_GOTO_0          = 8'h44,    // Returns to choose op
    
    // GOTO
    GOTO                    = 8'h50,    // Wait to read address
    GOTO_0                  = 8'h51,    // Address is stable and prog couner = mem out
    GOTO_1                  = 8'h52,    // Returns to choose op
    
    // FUNCTION_START
    FUNCTION_START          = 8'h60,    // Wait state to read address
    FUNCTION_START_0        = 8'h61,    // Increase prog context by 2 to determine where to return to
    FUNCTION_START_1        = 8'h62,    // Returns to choose op
    
    // RETURN
    RETURN                  = 8'h70,    // Sets prog counter to current prog conext set by FUNCTION_START_0
    RETURN_0                = 8'h71,    // Returns to choose op
    
    // DE_REFERENCE_A
    DE_REFERENCE_A          = 8'h80,    // Sets addr to current reg A
    DE_REFERENCE_A_0        = 8'h81,    // Increments prog count by 1
    DE_REFERENCE_A_1        = 8'h82,    // Sets next reg A to bus data and returns to choose op
    
    // DE_REFERENCE_B
    DE_REFERENCE_B          = 8'h83,    // Sets addr to current reg B
    DE_REFERENCE_B_0        = 8'h84,    // Increments prog count by 1
    DE_REFERENCE_B_1        = 8'h85;    // Sets next reg B to bus data and returns to choose op
   
 
    
    //-------------------Sequential part of the State Machine.-------------//
    reg [7:0]               CurrState, NextState;
    
    always@(posedge CLK) begin
        if(RESET) begin     // RESET TO INITAL VALUES
            CurrState               = 8'h00;
            CurrProgCounter         = 8'h00;
            CurrProgCounterOffset   = 2'h0;
            CurrBusAddr             = 8'hFF; // Initial instruction after reset.
            CurrBusDataOut          = 8'h00;
            CurrBusDataOutWE        = 1'b0;
            CurrRegA                = 8'h00;
            CurrRegB                = 8'h00;
            CurrRegSelect           = 1'b0;
            CurrProgContext         = 8'h00;
            CurrInterruptAck        = 2'b00;
        end 
        
        else begin  //SET CURRENT STATE = NEXT STATE
            CurrState               = NextState;
            CurrProgCounter         = NextProgCounter;
            CurrProgCounterOffset   = NextProgCounterOffset;
            CurrBusAddr             = NextBusAddr;
            CurrBusDataOut          = NextBusDataOut;
            CurrBusDataOutWE        = NextBusDataOutWE;
            CurrRegA                = NextRegA;
            CurrRegB                = NextRegB;
            CurrRegSelect           = NextRegSelect;
            CurrProgContext         = NextProgContext;
            CurrInterruptAck        = NextInterruptAck;
        end
    end
    
    //************************* Combinatorial Section ********************************// 
    always@* begin
        // Generic assignment to reduce the complexity of the rest of the S/M
        NextState                   = CurrState;
        NextProgCounter             = CurrProgCounter;
        NextProgCounterOffset       = 2'h0;
        NextBusAddr                 = 8'hFF;
        NextBusDataOut              = CurrBusDataOut;
        NextBusDataOutWE            = 1'b0;
        NextRegA                    = CurrRegA;
        NextRegB                    = CurrRegB;
        NextRegSelect               = CurrRegSelect;
        NextProgContext             = CurrProgContext;
        NextInterruptAck            = 2'b00;
        
        //Case statement to describe each state
        case (CurrState)
        
        //***********************************************************//
        // Thread states.
        IDLE: begin
             if(BUS_INTERRUPTS_RAISE[0]) begin // Interrupt Request A. (from timer)
                NextState           = GET_THREAD_START_ADDR_0;
                NextProgCounter     = 8'hFF;
                NextInterruptAck    = 2'b01;
             end else if(BUS_INTERRUPTS_RAISE[1]) begin // Interrupt Request B.
                NextState           = GET_THREAD_START_ADDR_0;
                NextProgCounter     = 8'hFE;
                NextInterruptAck    = 2'b10;
             end else begin
                NextState           = IDLE;
                NextProgCounter     = 8'hFF; //Nothing has happened.
                NextInterruptAck    = 2'b00;
             end
        end
    
        // Wait state - for new prog address to arrive.
        GET_THREAD_START_ADDR_0: begin
                NextState           = GET_THREAD_START_ADDR_1;
        end
        
        //Assign the new program counter value
        GET_THREAD_START_ADDR_1: begin
                NextState           = GET_THREAD_START_ADDR_2;
                NextProgCounter     = ProgMemoryOut;
        end
        
        //Wait for the new program counter value to settle
        GET_THREAD_START_ADDR_2:
                NextState           = CHOOSE_OPP;
        
        //************************************************************************//
        // CHOOSE_OPP - Another case statement to choose which operation to perform
        
        CHOOSE_OPP: begin
            case (ProgMemoryOut[3:0])
                4'h0: NextState         = READ_FROM_MEM_TO_A;
                4'h1: NextState         = READ_FROM_MEM_TO_B;
                4'h2: NextState         = WRITE_TO_MEM_FROM_A;
                4'h3: NextState         = WRITE_TO_MEM_FROM_B;
                4'h4: NextState         = DO_MATHS_OPP_SAVE_IN_A;
                4'h5: NextState         = DO_MATHS_OPP_SAVE_IN_B;
                4'h6: NextState         = IF_A_EQUALITY_B_GOTO;
                4'h7: NextState         = GOTO;
                4'h8: NextState         = IDLE;
                4'h9: NextState         = FUNCTION_START;
                4'hA: NextState         = RETURN;
                4'hB: NextState         = DE_REFERENCE_A;
                4'hC: NextState         = DE_REFERENCE_B;
                
            default:
                NextState               = CurrState;         
        endcase
        
            NextProgCounterOffset = 2'h1;
        end
        
        //******************************************************************************//
        // READ_FROM_MEM_TO_A : here starts the memory read operational pipeline.
        // Wait state - to give time for the mem address to be read. Reg select is set to 0
        READ_FROM_MEM_TO_A: begin
                NextState           = READ_FROM_MEM_0;
                NextRegSelect       = 1'b0;
        end
        
        // READ_FROM_MEM_TO_B : here starts the memory read operational pipeline.
        // Wait state - to give time for the mem address to be read. Reg select is set to 1
        READ_FROM_MEM_TO_B: begin
            NextState               = READ_FROM_MEM_0;
            NextRegSelect           = 1'b1;
        end
        
        // The address will be valid during this state, so set the BUS_ADDR to this value.
        READ_FROM_MEM_0: begin
            NextState               = READ_FROM_MEM_1;
            NextBusAddr             = ProgMemoryOut;
        end
        
        // Wait state - to give time for the mem data to be read
        // Increment the program counter here. This must be done 2 clock cycles ahead
        // so that it presents the right data when required.
        READ_FROM_MEM_1: begin
            NextState               = READ_FROM_MEM_2;
            NextProgCounter         = CurrProgCounter + 2;
        end
        
        // The data will now have arrived from memory. Write it to the proper register.
        READ_FROM_MEM_2: begin
            NextState               = CHOOSE_OPP;
            if(!CurrRegSelect)
                NextRegA            = BusDataIn;
            else
                NextRegB            = BusDataIn;
        end
        
        //*******************************************************************************//
        // WRITE_TO_MEM_FROM_A : here starts the memory write operational pipeline.
        // Wait state - to find the address of where we are writing
        // Increment the program counter here. This must be done 2 clock cycles ahead
        // so that it presents the right data when required.
        WRITE_TO_MEM_FROM_A: begin
            NextState               = WRITE_TO_MEM_0;
            NextRegSelect           = 1'b0;
            NextProgCounter         = CurrProgCounter + 2;
        end
        
        // WRITE_TO_MEM_FROM_B : here starts the memory write operational pipeline.
        // Wait state - to find the address of where we are writing
        // Increment the program counter here. This must be done 2 clock cycles ahead
        //so that it presents the right data when required.
        WRITE_TO_MEM_FROM_B:begin
            NextState               = WRITE_TO_MEM_0;
            NextRegSelect           = 1'b1;
            NextProgCounter         = CurrProgCounter + 2;
        end
        
        // The address will be valid during this state, so set the BUS_ADDR to this value,
        // and write the value to the memory location.
        WRITE_TO_MEM_0: begin
            NextState               = CHOOSE_OPP;
            NextBusAddr             = ProgMemoryOut;
            if(!NextRegSelect)
                NextBusDataOut      = CurrRegA;
            else
                NextBusDataOut      = CurrRegB;
                NextBusDataOutWE    = 1'b1;
        end
        
        //**********************************************************************************//
        // DO_MATHS_OPP_SAVE_IN_A : here starts the DoMaths operational pipeline.
        // Reg A and Reg B must already be set to the desired values. The MSBs of the
        // Operation type determines the maths operation type. At this stage the result is
        // ready to be collected from the ALU.
        DO_MATHS_OPP_SAVE_IN_A: begin
            NextState               = DO_MATHS_OPP_0;
            NextRegA                = AluOut;
            NextProgCounter         = CurrProgCounter + 1;
        end
        
        // DO_MATHS_OPP_SAVE_IN_B : here starts the DoMaths operational pipeline
        // When the result will go into reg B.
        DO_MATHS_OPP_SAVE_IN_B: begin
            NextState               = DO_MATHS_OPP_0;
            NextRegB                = AluOut;
            NextProgCounter         = CurrProgCounter + 1;
        end
        
        // Wait state for new prog address to settle.
        DO_MATHS_OPP_0: NextState   = CHOOSE_OPP;
        
        // IF_A_EQUALITY_B_GOTO: here start the jump operation, the following achieve the function 
        // that when A==B or A>B, then jump to the address stored in the memory
        // the first state of this operation is to wait a clk time unitl the address can be read from the memory   
        IF_A_EQUALITY_B_GOTO: begin
            if(ProgMemoryOut[7:4] == 4'b1001)
                NextState           = IF_A_EQUALITY_B_GOTO_EQUAL;
            if(ProgMemoryOut[7:4] == 4'b1010)
                NextState           = IF_A_EQUALITY_B_GOTO_GREATER;
            if(ProgMemoryOut[7:4] == 4'b1011)
                NextState           = IF_A_EQUALITY_B_GOTO_LESS;  
        end
        
        
        // Set Program Counter here depending on result
        IF_A_EQUALITY_B_GOTO_EQUAL: begin
            if(CurrRegA == CurrRegB)
                NextProgCounter     = ProgMemoryOut;            // If A=B go to next line in ROM
            else
                NextProgCounter     = CurrProgCounter + 2;      // If a!=b go two lines down ROM
            NextState               = IF_A_EQUALITY_B_GOTO_0;
        end
        
        // Set Program Counter here depending on result
        IF_A_EQUALITY_B_GOTO_GREATER: begin
            if(CurrRegA > CurrRegB)
                NextProgCounter     = ProgMemoryOut;            // If A>B go to next line in ROM
            else
                NextProgCounter     = CurrProgCounter + 2;      // If A!>B go two lines down ROM
               
            NextState               = IF_A_EQUALITY_B_GOTO_0;
        end
        
        // Set Program Counter here depending on result
        IF_A_EQUALITY_B_GOTO_LESS: begin
            if(CurrRegA < CurrRegB)
                NextProgCounter     = ProgMemoryOut;            // If A<B go to next line in ROM
            else
                NextProgCounter     = CurrProgCounter + 2;      // If A!<B go two lines down ROM
               
            NextState               = IF_A_EQUALITY_B_GOTO_0;
        end
         
         // Wait state for new prog address to settle.
        IF_A_EQUALITY_B_GOTO_0: begin
            NextState               = CHOOSE_OPP;
        end
         
        // Wait state to load from memory
        GOTO: begin
             NextState              = GOTO_0;
        end
        
        // Address will be valid now
        GOTO_0: begin
             NextProgCounter        = ProgMemoryOut;
             NextState              = GOTO_1;
        end
         
        // Wait state for new prog address to settle.
        GOTO_1: NextState           = CHOOSE_OPP;
        
        // Wait for program to access memory
        FUNCTION_START: begin
            NextState               = FUNCTION_START_0;
        end
        
        // Address is stable. Increm prog context by 2 to know where to return to after function
        FUNCTION_START_0: begin
            NextProgCounter         = ProgMemoryOut;
            NextProgContext         = CurrProgCounter + 2;  // Sets place to return to after function is called
            NextState               = FUNCTION_START_1;
        end
        
        // Wait state for new prog address to settle.
        FUNCTION_START_1: NextState = CHOOSE_OPP;
        
        // Sets counter to the value of prog conext set in Function START
        RETURN: begin
            NextState               = RETURN_0;
            NextProgCounter         = CurrProgContext;
        end
        
        // Wait state for new prog address to settle.
        RETURN_0: NextState         = CHOOSE_OPP;
        
        // Read memory address given by the value of register A and set the result as the 
        // new register A value
        DE_REFERENCE_A: begin
            NextState               = DE_REFERENCE_A_0;
            NextBusAddr             = CurrRegA;
        end
        
        // Increment Program counter
        DE_REFERENCE_A_0: begin
            NextState               = DE_REFERENCE_A_1;
            NextProgCounter         = CurrProgCounter + 1;
        end
        
        // The data will now have arrived from memory. Write it to the proper register.
        DE_REFERENCE_A_1: begin
            NextState               = CHOOSE_OPP;
            NextRegA                = BusDataIn;
        end
        
        
        // Read memory address given by the value of register B and set the result as the 
        // new register B value
        DE_REFERENCE_B: begin
            NextState               = DE_REFERENCE_B_0;
            NextBusAddr             = CurrRegB;
        end 
        
        //Increment Prog Counter
        DE_REFERENCE_B_0: begin
            NextState               = DE_REFERENCE_B_1;
            NextProgCounter         = CurrProgCounter + 1;
        end    
        
        //The data will now have arrived from memory. Write it to the proper register.
        DE_REFERENCE_B_1: begin
            NextState               = CHOOSE_OPP;
            NextRegB                = BusDataIn;
        end  
                       
        endcase
        
    end
     
endmodule