`timescale 1ns/1ps
module tb_core;
    import rv32i_pkg::*;
    parameter HEX_FILE="programs/sum.hex";
    parameter bit CHECK_SUM=1'b1;
    logic clk=0, rst=1, fault, store_valid;
    fault_t fault_cause;
    logic [31:0] debug_pc, store_address, store_data;
    mem_size_t store_size;
    int cycles=0;
    logic [31:0] failed_check=0;
    string wave_file;
    riscv_core #(.HEX_FILE(HEX_FILE)) dut (.*);
    task automatic tick;
        #4; clk=1; #1; clk=0; #1;
    endtask
    initial begin
        if ($value$plusargs("VCD=%s",wave_file)) begin
            $dumpfile(wave_file); $dumpvars(0,tb_core);
        end
        tick(); tick();
        if (debug_pc !== 0 || fault !== 0 || fault_cause !== FAULT_NONE)
            $fatal(1,"FAIL reset");
        rst=0;
        while (cycles<3000) begin
            // All combinational signals settle before the edge at which they commit.
            #1;
            if (fault) $fatal(1,"FAIL unexpected fault pc=%h cause=%0d",debug_pc,fault_cause);
            if (store_valid && store_address == 32'hff4) failed_check=store_data;
            if (store_valid && store_address == 32'hff0) begin
                if (store_size !== MEM_WORD || store_data !== 1)
                    $fatal(1,"FAIL program signature=%h check=%0d",store_data,failed_check);
                tick(); // Commit the signature store before checking data memory.
                if (CHECK_SUM) begin
                    if ({dut.u_dmem.mem[259],dut.u_dmem.mem[258],
                         dut.u_dmem.mem[257],dut.u_dmem.mem[256]} !== 32'd55)
                        $fatal(1,"FAIL sum memory / little-endian layout");
                    if (dut.u_regfile.regs[28] !== 32'd55)
                        $fatal(1,"FAIL sum load-back register t3");
                end
                if ({dut.u_dmem.mem[4083],dut.u_dmem.mem[4082],
                     dut.u_dmem.mem[4081],dut.u_dmem.mem[4080]} !== 32'd1)
                    $fatal(1,"FAIL signature not committed");
                // Completion loop must preserve x0 and must not produce a fault.
                repeat (4) tick();
                if (fault || dut.u_regfile.read_data1 !== 0)
                    $fatal(1,"FAIL completion loop / x0");
                $display("PASS tb_core image=%s cycles=%0d sum_check=%0d",HEX_FILE,cycles+1,CHECK_SUM);
                $finish;
            end
            tick(); cycles++;
        end
        $fatal(1,"FAIL core timeout pc=%h",debug_pc);
    end
endmodule
