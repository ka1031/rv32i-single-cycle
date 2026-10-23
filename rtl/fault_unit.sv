`timescale 1ns/1ps
module fault_unit #(
    parameter bit ENABLE = 1'b1
) (
    input logic clk, rst,
    input rv32i_pkg::fault_t event_cause,
    output logic commit, fault,
    output rv32i_pkg::fault_t fault_cause
);
    import rv32i_pkg::*;
    // All fault POLICY/state is isolated here. The datapath only consumes commit.
    // ENABLE=0 bypasses halting; local decoder/memory safety checks still operate.
    // This is not a privileged architectural trap implementation (no CSRs/mtvec).
    assign commit = !rst && (!ENABLE || (!fault && event_cause == FAULT_NONE));
    always_ff @(posedge clk) begin
        if (rst) begin
            fault <= 1'b0;
            fault_cause <= FAULT_NONE;
        end else if (ENABLE && !fault && event_cause != FAULT_NONE) begin
            fault <= 1'b1;
            fault_cause <= event_cause;
        end
    end
endmodule
