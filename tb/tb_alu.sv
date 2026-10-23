`timescale 1ns/1ps
module tb_alu;
    import rv32i_pkg::*;
    logic [31:0] a, b, result;
    alu_op_t op;
    int checks = 0;
    alu dut (.*);
    task automatic check(input alu_op_t operation, input logic [31:0] x, y, expected);
        a = x; b = y; op = operation; #1;
        if (result !== expected)
            $fatal(1, "FAIL alu op=%0d a=%h b=%h got=%h expected=%h", op,a,b,result,expected);
        checks++;
    endtask
    initial begin
        check(ALU_ADD, 32'hffffffff, 1, 0);
        check(ALU_ADD, 32'h7fffffff, 1, 32'h80000000);
        check(ALU_SUB, 0, 1, 32'hffffffff);
        check(ALU_AND, 32'hf0f00ff0, 32'h0ff00ff0, 32'h00f00ff0);
        check(ALU_OR, 32'hf00000f0, 32'h0f00000f, 32'hff0000ff);
        check(ALU_XOR, 32'hff00ff00, 32'h0f0f0f0f, 32'hf00ff00f);
        check(ALU_SLL, 1, 31, 32'h80000000);
        check(ALU_SLL, 1, 32, 1);
        check(ALU_SRL, 32'h80000001, 1, 32'h40000000);
        check(ALU_SRA, 32'h80000001, 1, 32'hc0000000);
        check(ALU_SRL, 32'h80000001, 31, 1);
        check(ALU_SRA, 32'h80000001, 31, 32'hffffffff);
        check(ALU_SRA, 32'h80000001, 32, 32'h80000001);
        check(ALU_SRL, 32'h80000001, 63, 1);
        check(ALU_SRA, 32'h70000000, 4, 32'h07000000);
        check(ALU_SLT, 32'hffffffff, 1, 1);
        check(ALU_SLTU, 32'hffffffff, 1, 0);
        check(ALU_SLT, 32'h80000000, 32'h7fffffff, 1);
        check(ALU_SLT, 7, 7, 0);
        check(ALU_SLTU, 0, 32'hffffffff, 1);
        $display("PASS tb_alu (%0d checks)", checks);
        $finish;
    end
endmodule
