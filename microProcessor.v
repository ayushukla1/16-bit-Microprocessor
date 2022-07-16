// --------------------------------------------------------------------
// FILE NAME: microProcessor.v
// TYPE: module
// DEPARTMENT: ELECTRONICS & COMMUNICATION ENGINEERING
// AUTHOR: AYUSH SHUKLA
// AUTHOR'S EMAIL: bt20ece003@iiitn.ac.in
// --------------------------------------------------------------------
// PURPOSE: 16-Bit MicroProcessor which has very basic INSTRUCTION SET 
//          ARCHITECTURE designed in behavioral style of Modelling
// -------------------------------------------------------------------- 


module microProcessor (
    clk // clock signals
);

    parameter N1 = 16, N2 = 12, N3 = 8;
    parameter WORDS = 4096; // No of words that can be stored in the memory

    // Hexadecimal Code for Memory Reference Instruction
    // "_D" is a suffix to represent Direct Memory addressing mode
    // "_I" is a suffix to represent Indirect Memory addressing mode
    parameter AND = 3'b000; // Opcode: AND memory word to the Accumulator
    parameter ADD = 3'b001; // ADD memory word to AC
    parameter LDA = 3'b010; // Load memory Word to AC
    parameter STA = 3'b011; // Store content of AC in memory
    parameter BUN = 3'b100; // Branch uncoditionally
    parameter BSA = 3'b101; // Branch and save return address
    parameter ISZ = 3'b110; // Increment and skip if zero

    // Hexadecimal code for Register Reference Instructions
    parameter CLA = 12'h800; // Clear AC
    parameter CLE = 12'h400; // Clear E
    parameter CMA = 12'h200; // Complement AC
    parameter CME = 12'h100; // Complement E
    parameter CIR = 12'h080; // Circulate right AC and E
    parameter CIL = 12'h040; // Circulate left AC and E
    parameter INC = 12'h020; // Increment AC
    parameter SPA = 12'h010; // Skip next instruction if AC is positive
    parameter SNA = 12'h008; // Skip next instruction if AC is negative
    parameter SZA = 12'h004; // Skip next instruction if AC is zero
    parameter SZE = 12'h002; // Skip next instruction if E is zero
    parameter HLT = 12'h001; // Halt processor

    // Hexadecimal code for I/O Reference Instructions
    parameter INP = 12'h800; // Input character to AC
    parameter OUT = 12'h400; // Output character from AC
    parameter SKI = 12'h200; // Skip on input flag
    parameter SKO = 12'h100; // Skip on output flag
    parameter ION = 12'h080; // Interrupt on
    parameter IOF = 12'h040; // Interrupt off

    input clk; // clock signal

    // Register of the Processor
    reg [N1-1:0] bus;   // Bus System of the processor
    reg [N2-1:0] AR;    // 12 bit Address Register - Holds address for memory to read and write
    reg [N2-1:0] PC;    // 12 bit Program Counter - Holds address of next Instruction to be fetched.
    reg [N1-1:0] AC;    // 16-Bit Accumulator - Processor Register
    reg [N1-1:0] DR;    // 16-Bit Data Register - Holds Memory operand 
    reg [N1-1:0] IR;    // 16-Bit Instruction Register - Holds Instruction Code
    reg [N1-1:0] TR;    // 16-Bit Temporary Register - Holds Temporary Data
    reg [N3-1:0] INPR;  // 8-Bit Input Register
    reg [N3-1:0] OUTR;  // 8-bit Output Register

    reg [N1-1:0] M [0:WORDS-1]; // Memory of 4096 words where each word is of 15 bits.
    // Flip-Flops Used are:
    // (i) R: It is used to indicate whether interrupt occurs or not.
    // (ii) I: This flip-flop is used to store the MSB of IR so as to decide whether it is Direct Memory Access or Indirect Memory Access.
    // (iii) E: The flip-flop represents the carry flag.
    // (iv) IEN: This flag enables the interrupt.
    // (v) FGI: This flag will set when INPR register is filled.
    // (vi) FGO: This flag will set when output device is ready to receive data.
    // (vii) S: This flip-Flop is used to start the microprocessor.

    reg I,E,R,S,FGI,FGO,IEN,SC; // Flip-Flops which control the instrutions.
    reg [2:0] opcode; // 3-Bit Operational Code 
    reg [2:0] t; // variable for timing sequence

    // Timing Sequence, which helps us to sequentialize instruction
    // This counter will help to sequentialize the instructions
    // It will get resetted when SC = 0.
    // And microprocessor will start working only when S = 1.
    always @(posedge clk) begin // a 4-bit counter
        if(S == 1'b1) begin
            if(SC == 1'b0) 
            begin
                t <= #2 3'b0;
                SC <= #2 1'b1;                 
            end
            else
                t <= #2 t + 1;
        end
        else begin
            t <= #2 3'b0;
        end
    end


    // For Interrupt 
    // Interrupt will get activated either when processor is communicating with peripheral devices 
    // or enabled using Instruction in which case IEN will get set.
    always @(posedge clk) begin
        if(t != 3'b00 && t !=3'b001 && t != 3'b010 && IEN == 1'b1 && (FGI == 1'b1 || FGO == 1'b1))
            R <= #2 1'b1;
    end
    
    // When T0 is active
    // In this clock cycle AR will get the address of the Instruction if interrupt is not enabled
    // otherwise AR will point the 0th location to store current PC address.
    always @(posedge clk) begin
        if(t == 3'b000) begin
            if(R == 1'b0) begin
                AR <= #2 PC; // Transfer the content of PC to AR to fetch Instruction
            end
            else begin
                AR <= #2 12'b0; // Store the 0th location of Memory
                TR <= #2 {4'b0,PC}; // store the content of PC in TR
            end
        end
    end

    // When T1 is active
    // In this clock cycle we fetch the Instruction pointed by the AR
    // If the interrupt is enabled then we can store the address of the
    // location where we have to return at 0th location.
    always @(posedge clk) begin
        if(t == 3'b001) begin
            if(R == 1'b0) begin
                IR <= #2 M[AR]; // Fetch Instruction from memory location pointed by AR
                PC <= #2 PC + 1; // Increment PC by 1 to point to next Instruction
            end
            else begin
                M[AR] <= #2 TR; // Saving the return address
                PC <= #2 12'b0; // Point the 0th location of memory
            end
        end
    end

    // When T2 is active
    // In this cycle we decode the Instruction and also transfer the address of operand
    //  to AR to fetch it, if it is a Memory Reference Instruction.
    always @(posedge clk) begin
        if(t == 3'b010) begin
            if(R == 1'b0) begin
                opcode <= #2 IR[14:12]; // decoding opcode
                AR <= #2 IR[11:0]; // transferring the address of the operand to AR.
                I <= #2 IR[15]; // Storing MSB of IR so as to distinguish between Direct Addressing and
                // Indirect Addressing or Register Reference and I/O Reference.
            end
            else begin // If interrupt is enabled
                PC <= #2 PC + 1;
                IEN <= #2 1'b0;
                R <= #2 1'b0;
                SC <= #2 1'b0;
            end
        end
    end
    // When T3 is active
    // In this clock cycle we can execute the Register Reference and I/O Reference Instruction and 
    // can point the Effective address of the operand if it is a Indirect Addressing Mode.
    always @(posedge clk) begin
        if(t == 3'b011) begin
            if(opcode != 3'b111 && I == 1'b1) begin //Indirect Memory Reference Instruction
                AR <= #2 M[AR]; // Fetching the Effective address of the Operand
            end
            else if(opcode == 3'b111 && I == 1'b0) begin // Register Reference Instruction
                SC <= #2 1'b0; // Refresh Timing Sequence to start next Instruction Cycle
                case (IR[11:0])
                    CLA: begin // Clear Accumulator
                        AC <= #2 16'b0;
                    end
                    CLE: begin // Clear Carry flag
                        E <= #2 1'b0;
                    end
                    CMA: begin // Complement Accumulator
                        AC <= #2 ~AC;
                    end
                    CME: begin // Complement Carry flag
                        E <= #2 ~E; 
                    end
                    CIR: begin // Circular Right E and AC
                        AC <= #2 {E,AC[N1-1:1]};
                        E <= #2 AC[0];
                    end
                    CIL: begin // Circular Left E and AC
                        AC <= #2 {AC[N1-2:0],E};
                        E <= #2 AC[N1-1];
                    end
                    INC: begin // Increment AC
                        AC <= #2 AC + 1;
                    end
                    SPA: begin // Skip next instruction if MSB of AC is zero
                        if (AC[N1-1] == 1'b0) begin
                            PC <= #2 PC + 1; 
                        end
                    end
                    SNA: begin // Skip next instruction if MSB of AC is one
                        if (AC[N1-1] == 1'b1) begin
                            PC <= #2 PC + 1; 
                        end
                    end
                    SZA: begin // Skip next instruction if AC is zero
                        if (AC == 16'b0) begin
                            PC <= #2 PC + 1; 
                        end
                    end
                    SZE: begin // Skip next instruction if Carry flag is zero
                        if (E == 1'b0) begin
                            PC <= #2 PC + 1;
                        end
                    end
                    HLT: begin // HLT instruction
                        S <= #2 1'b0;
                    end
                    default: begin // if wrong instruction came do noting
                        // do nothing
                    end
                endcase
            end 
            else if(opcode == 3'b111 && I == 1'b1) begin // I/O Reference Instruction
                SC <= #2 1'b0; // Refresh Timing Sequence to start next Instruction Cycle
                case (IR[11:0])
                    INP: begin // Transfer content of Input register to the Accumulator
                        AC <= #2 {8'b0,INPR};
                        FGI <= #2 1'b0;
                    end
                    OUT: begin // Transfer content of Acccumulator to the output register
                        OUTR <= #2 AC[N3-1:0];
                        FGO <= #2 1'b0;
                    end
                    SKI: begin // Skip next instruction if there is some input
                        if(FGI == 1'b1) begin
                            PC <= #2 PC + 1;
                        end
                    end
                    SKO: begin // skip next instruction if output device is ready to accept data 
                        if(FGO == 1'b1) begin
                            PC <= #2 PC + 1;
                        end
                    end
                    ION: begin // Enable Interrupt
                        IEN <= #2 1'b1;
                    end
                    IOF: begin // Disable Interrupt
                        IEN <= #2 1'b0;
                    end
                    default: begin // If wrong instruction came the do noting
                        // do nothing
                    end
                endcase
            end 
        end
    end

    // When T4 is active
    // This clock cylce mainly executes Memory Reference Instruction which are composed
    // of two to three microinstruction. Mostly in this clock cycle we fetch the operand from the memory.
    always @(posedge clk) begin
        if(t == 3'b100) begin
            case (opcode)
                AND: begin 
                    DR <= #2 M[AR]; // Fetch the operand and store it in DR
                end
                ADD: begin
                    DR <= #2 M[AR]; // Fetch the operand and store it in DR
                end
                LDA: begin
                    DR <= #2 M[AR]; // Fetch the operand and store it in DR
                end
                STA: begin
                    M[AR] <= #2 AC; // Store the content of AC in memory location pointed by AR.
                    SC <= #2 1'b0; // Refresh Timing Sequence to start new Instructin cylce
                end
                BUN: begin // Branch Instruction
                    PC <= #2 AR; // Store the location where we next Instruction is in PC.
                    SC <= #2 1'b0; // Refresh Timing Sequence to start new Instructin cylce
                end
                BSA: begin // Branch and Save return Address
                    M[AR] <= #2 PC; // Saving Return Address
                    AR <= #2 AR + 1;
                end
                ISZ: begin // Increment and Skip if zero 
                    DR <= #2 M[AR]; // Fetch the operand and store in in DR
                end
                default: begin // If wrong instruction came the do noting
                    // do nothing
                end
            endcase
        end
    end

    // When T5 is active
    // In this clock cylce we execute the operating between the operands store in DR and AC.
    always @(posedge clk) begin
        if(t == 3'b101) begin
            case (opcode)
                AND: begin // Perform anding and Refresh Timing Sequence to start next Instruction Cycle
                    AC <= #2 AC & DR;
                    SC <= #2 1'b0;
                end 
                ADD: begin // Perform addition and Refresh Timing Sequence to start next Instruction Cycle
                    {E,AC} <= #2 AC + DR;
                    SC <= #2 1'b0;
                end
                LDA: begin // Load Operand in AC and Refresh Timing Sequence to start next Instruction Cycle
                    AC <= #2 DR;
                    SC <= #2 1'b0;
                end
                BSA: begin // Point the Branch Instruction Address and Refresh Timing Sequence to start next Instruction Cycle
                    PC <= #2 AR;
                    SC <= #2 1'b0;
                end
                ISZ: begin // Incrementing DR
                    DR <= #2 DR + 1;
                end
                default: begin
                    // do nothing
                end
            endcase
        end
    end

    // When T6 is active
    // In this we only execute the ISZ operating whether on Incrementing it become zero or not
    // If it is zero then skip next instruction.
    always @(posedge clk) begin
        if(t == 3'b110) begin
            if(opcode == ISZ) begin
                M[AR] <= #2 DR;
                if (DR == 16'b0) begin
                    PC <= #2 PC + 1;
                end
            end
        end
    end

endmodule