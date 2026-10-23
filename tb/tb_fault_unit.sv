`timescale 1ns/1ps
module tb_fault_unit;
    import rv32i_pkg::*;
    logic clk=0, rst=1, commit, fault, bypass_commit, bypass_fault;
    fault_t event_cause=FAULT_NONE, fault_cause, bypass_cause;
    fault_unit dut (.clk,.rst,.event_cause,.commit,.fault,.fault_cause);
    fault_unit #(.ENABLE(1'b0)) bypass (.clk,.rst,.event_cause,
        .commit(bypass_commit),.fault(bypass_fault),.fault_cause(bypass_cause));
    task automatic tick;
        #4; clk=1; #1; clk=0; #1;
    endtask
    initial begin
        tick(); rst=0; #1;
        if (!commit || fault || fault_cause !== FAULT_NONE || !bypass_commit)
            $fatal(1,"FAIL fault reset");
        event_cause=FAULT_ILLEGAL; #1;
        if (commit || fault || !bypass_commit) $fatal(1,"FAIL pre-edge fault gating");
        tick(); event_cause=FAULT_ECALL; tick();
        if (!fault || commit || fault_cause !== FAULT_ILLEGAL)
            $fatal(1,"FAIL sticky first cause");
        if (!bypass_commit || bypass_fault || bypass_cause !== FAULT_NONE)
            $fatal(1,"FAIL removable fault policy bypass");
        rst=1; #1;
        if (!fault || commit || bypass_commit) $fatal(1,"FAIL reset gating");
        tick(); event_cause=FAULT_NONE; rst=0; #1;
        if (!commit || fault || fault_cause !== FAULT_NONE)
            $fatal(1,"FAIL fault reset recovery");
        $display("PASS tb_fault_unit (enabled and bypassed)"); $finish;
    end
endmodule
