// This is a test bench which runs a Binary Coded Program to add two numbers
module mp_tb;
    reg clk;
    integer  k;

    microProcessor MIPS(clk);

    initial begin
        clk = 0;
        repeat(50) // Generating Clock Signal
        begin
            #5 clk = 1;#5 clk = 0;
        end
    end

    initial begin
        MIPS.AC = 0;
        MIPS.DR = 0;
        
        MIPS.M[0] = 16'h2004; // LDA 004
        MIPS.M[1] = 16'h1005; // ADD 005
        MIPS.M[2] = 16'h3006; // STA 006
        MIPS.M[3] = 16'h7001; // HLT
        MIPS.M[4] = 16'h0053; // DEC 83
        MIPS.M[5] = 16'hFFE9; // DEC -23
        MIPS.M[6] = 16'h0000;
        MIPS.R = 1'b0;
        MIPS.S = 1'b1;
        MIPS.FGI = 1'b0;
        MIPS.FGO = 1'b0;
        MIPS.IEN = 1'b0;
        MIPS.PC = 12'b0; // PC contains the address of the 0th location from where the program starts
        MIPS.SC = 1'b0; // Resetting Timing Sequence Counter

        #310
        $display("Ans = %d", MIPS.M[6]);
    end

    initial begin
        $dumpfile("mp.vcd");
        $dumpvars(0,mp_tb);
        $monitor("Time = %d,t = %d, AR = %h,IR= %h,opcode = %b,PC=%h", $time,MIPS.t,MIPS.AR,MIPS.IR,MIPS.opcode,MIPS.PC);
        #400 $finish;
    end
endmodule