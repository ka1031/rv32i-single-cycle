`timescale 1ns/1ps
module tb_data_mem;
    import rv32i_pkg::*;
    logic clk=0, rst=0, read_req=0, write_req=0, commit=1;
    logic [31:0] address=0, write_data=0, read_data;
    mem_size_t size=MEM_WORD;
    logic load_unsigned=0, misaligned, access_fault;
    int checks=0;
    data_mem dut (.*);
    task automatic tick;
        #4; clk=1; #1; clk=0; #1;
    endtask
    task automatic store(input logic [31:0] addr, value, input mem_size_t width);
        address=addr; write_data=value; size=width; read_req=0; write_req=1;
        tick(); write_req=0;
    endtask
    task automatic load_check(input logic [31:0] addr, input mem_size_t width,
                              input logic unsigned_load, input logic [31:0] expected);
        address=addr; size=width; load_unsigned=unsigned_load; read_req=1; write_req=0; #1;
        if (misaligned || access_fault || read_data !== expected)
            $fatal(1,"FAIL memory addr=%h size=%d got=%h expected=%h",addr,width,read_data,expected);
        checks++;
    endtask
    task automatic bad_access(input logic [31:0] addr, input mem_size_t width,
                              input logic align_error, range_error);
        address=addr; size=width; read_req=1; write_req=1; write_data=32'hdeadbeef; #1;
        if (misaligned !== align_error || access_fault !== range_error || read_data !== 0)
            $fatal(1,"FAIL memory fault addr=%h",addr);
        tick(); write_req=0; checks++;
    endtask
    initial begin
        store(0,32'h80ff7f01,MEM_WORD);
        load_check(0,MEM_WORD,0,32'h80ff7f01);
        load_check(0,MEM_BYTE,0,1); load_check(1,MEM_BYTE,0,127);
        load_check(2,MEM_BYTE,0,32'hffffffff); load_check(2,MEM_BYTE,1,255);
        load_check(3,MEM_BYTE,0,32'hffffff80); load_check(3,MEM_BYTE,1,128);
        load_check(0,MEM_HALF,0,32'h00007f01);
        load_check(2,MEM_HALF,0,32'hffff80ff); load_check(2,MEM_HALF,1,32'h000080ff);
        store(1,32'haa,MEM_BYTE); load_check(0,MEM_WORD,0,32'h80ffaa01);
        store(2,32'h1234,MEM_HALF); load_check(0,MEM_WORD,0,32'h1234aa01);
        // All four byte lanes and both halfword lanes preserve neighboring bytes.
        for (int i=0; i<4; i++) store(32'(i),32'(i+1),MEM_BYTE);
        load_check(0,MEM_WORD,0,32'h04030201);
        store(0,32'hbeef,MEM_HALF); load_check(0,MEM_WORD,0,32'h0403beef);
        // High boundary and full-address checks; no low-bit address aliasing.
        store(4092,32'hfedcba98,MEM_WORD);
        load_check(4092,MEM_WORD,0,32'hfedcba98);
        load_check(4095,MEM_BYTE,1,32'hfe);
        load_check(4094,MEM_HALF,1,32'hfedc);
        bad_access(1,MEM_HALF,1,0); bad_access(2,MEM_WORD,1,0);
        bad_access(4095,MEM_HALF,1,1); bad_access(4096,MEM_BYTE,0,1);
        bad_access(32'h10000000,MEM_WORD,0,1);
        bad_access(32'hfffffffc,MEM_WORD,0,1);
        load_check(0,MEM_WORD,0,32'h0403beef);
        load_check(4092,MEM_WORD,0,32'hfedcba98);
        commit=0; store(0,0,MEM_WORD); load_check(0,MEM_WORD,0,32'h0403beef);
        commit=1; rst=1; store(0,0,MEM_WORD); rst=0;
        load_check(0,MEM_WORD,0,32'h0403beef);
        // Write occurs at the edge, not when request/data changes.
        address=0; size=MEM_WORD; read_req=1; write_req=1; write_data=42; #1;
        if (read_data !== 32'h0403beef) $fatal(1,"FAIL asynchronous store");
        tick(); write_req=0; load_check(0,MEM_WORD,0,42);
        read_req=0; address=32'hffffffff; #1;
        if (read_data !== 0 || misaligned || access_fault) $fatal(1,"FAIL inactive memory");
        $display("PASS tb_data_mem (%0d checks)",checks); $finish;
    end
endmodule
