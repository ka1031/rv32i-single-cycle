`timescale 1ns/1ps
module tb_branch_unit;
    logic [31:0] a, b;
    logic [2:0] funct3;
    logic taken;
    int checks=0;
    branch_unit dut (.*);
    task automatic check(input logic [2:0] f, input logic [31:0] x,y,
                         input logic expected);
        a=x; b=y; funct3=f; #1;
        if (taken !== expected) $fatal(1,"FAIL branch f=%b a=%h b=%h",f,x,y);
        checks++;
    endtask
    initial begin
        check(0,5,5,1); check(0,5,6,0);
        check(1,5,6,1); check(1,5,5,0);
        check(4,32'hffffffff,1,1); check(4,1,32'hffffffff,0);
        check(5,1,32'hffffffff,1); check(5,32'hffffffff,1,0);
        check(6,1,32'hffffffff,1); check(6,32'hffffffff,1,0);
        check(7,32'hffffffff,1,1); check(7,1,32'hffffffff,0);
        check(4,32'h80000000,32'h7fffffff,1);
        check(6,32'h80000000,32'h7fffffff,0);
        check(4,5,5,0); check(5,5,5,1); check(6,5,5,0); check(7,5,5,1);
        check(2,0,0,0); check(3,0,0,0);
        $display("PASS tb_branch_unit (%0d checks)",checks); $finish;
    end
endmodule
