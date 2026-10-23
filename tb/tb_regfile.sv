`timescale 1ns/1ps
module tb_regfile;
    logic clk = 0, rst = 1, write_enable = 0;
    logic [4:0] rs1 = 0, rs2 = 0, rd = 0;
    logic [31:0] write_data = 0, read_data1, read_data2;
    int checks = 0;
    regfile dut (.*);
    // Clock driven by a task: no race between stimulus and the active clock edge.
    task automatic tick;
        #4; clk = 1; #1; clk = 0; #1;
    endtask
    task automatic check(input logic [31:0] expected1, expected2);
        #1;
        if (read_data1 !== expected1 || read_data2 !== expected2)
            $fatal(1, "FAIL regfile rs1=%0d rs2=%0d got=%h/%h expected=%h/%h",
                   rs1,rs2,read_data1,read_data2,expected1,expected2);
        checks++;
    endtask
    initial begin
        tick(); rst = 0;
        for (int i=0; i<32; i++) begin
            rs1=5'(i); rs2=5'(31-i); check(0,0);
        end
        write_enable=1;
        for (int i=1; i<32; i++) begin
            rd=5'(i); write_data=32'h80000000+32'(i); tick();
        end
        write_enable=0;
        for (int i=1; i<32; i++) begin
            rs1=5'(i); rs2=5'(32-i);
            check(32'h80000000+32'(i),32'h80000000+32'(32-i));
        end
        // Writes are synchronous, with no speculative write-through bypass.
        rs1=5; rs2=0; rd=5; write_data=123; write_enable=1;
        check(32'h80000005,0); tick(); check(123,0);
        rd=0; write_data=32'hffffffff; tick(); rs1=0; check(0,0);
        rd=5; write_data=999; write_enable=0; tick(); rs1=5; check(123,0);
        // Reset changes registers only at the rising edge, with reset priority.
        rst=1; write_enable=1; #1; check(123,0); tick(); check(0,0);
        rst=0; write_enable=0;
        $display("PASS tb_regfile (%0d checks)",checks); $finish;
    end
endmodule
