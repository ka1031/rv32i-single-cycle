`timescale 1ns/1ps
module tb_faults;
    import rv32i_pkg::*;
    parameter HEX_FILE="programs/fault_0.hex";
    parameter logic [3:0] EXPECT_CAUSE=4'd4;
    parameter logic [31:0] EXPECT_PC=32'd20;
    parameter logic [31:0] EXPECT_A0=32'd85;
    logic clk=0, rst=1, fault, store_valid;
    fault_t fault_cause;
    logic [31:0] debug_pc, store_address, store_data;
    mem_size_t store_size;
    int cycles=0;
    riscv_core #(.HEX_FILE(HEX_FILE)) dut (.*);
    task automatic tick;
        #4; clk=1; #1; clk=0; #1;
    endtask
    task automatic check_stopped;
        if (!fault || fault_cause !== EXPECT_CAUSE || debug_pc !== EXPECT_PC)
            $fatal(1,"FAIL fault state pc=%h cause=%0d expected pc=%h cause=%0d",
                   debug_pc,fault_cause,EXPECT_PC,EXPECT_CAUSE);
        if (store_valid || dut.commit || dut.u_regfile.regs[10] !== EXPECT_A0)
            $fatal(1,"FAIL fault commit suppression a0=%h",dut.u_regfile.regs[10]);
        if ({dut.u_dmem.mem[3],dut.u_dmem.mem[2],dut.u_dmem.mem[1],dut.u_dmem.mem[0]}
              !== 32'h11223344) $fatal(1,"FAIL fault corrupted sentinel");
    endtask
    initial begin
        tick(); rst=0;
        while (!fault && cycles<100) begin
            #1;
            if (store_valid && (store_address !== 0 || store_data !== 32'h11223344 || store_size !== MEM_WORD))
                $fatal(1,"FAIL unexpected store before fault");
            tick(); cycles++;
        end
        check_stopped();
        repeat (3) begin tick(); check_stopped(); end
        // Synchronous reset: fault/PC remain unchanged before edge; then clear.
        rst=1; #1;
        if (!fault || debug_pc !== EXPECT_PC) $fatal(1,"FAIL asynchronous reset");
        tick();
        if (fault || fault_cause !== FAULT_NONE || debug_pc !== 0 || dut.u_regfile.regs[10] !== 0)
            $fatal(1,"FAIL reset did not clear state");
        if ({dut.u_dmem.mem[3],dut.u_dmem.mem[2],dut.u_dmem.mem[1],dut.u_dmem.mem[0]}
              !== 32'h11223344) $fatal(1,"FAIL reset changed data memory");
        $display("PASS tb_faults image=%s cause=%0d pc=%h",HEX_FILE,EXPECT_CAUSE,EXPECT_PC);
        $finish;
    end
endmodule
