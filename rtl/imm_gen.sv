`timescale 1ns/1ps
module imm_gen (
    // Opcode bits are deliberately absent: the controller selects the format.
    input logic [31:7] instr_hi,
    input rv32i_pkg::imm_sel_t sel,
    output logic [31:0] immediate
);
    import rv32i_pkg::*;
    always_comb begin
        immediate = 32'b0;
        case (sel)
            IMM_I: immediate = {{20{instr_hi[31]}}, instr_hi[31:20]};
            IMM_S: immediate = {{20{instr_hi[31]}}, instr_hi[31:25], instr_hi[11:7]};
            IMM_B: immediate = {{19{instr_hi[31]}}, instr_hi[31], instr_hi[7],
                                instr_hi[30:25], instr_hi[11:8], 1'b0};
            IMM_U: immediate = {instr_hi[31:12], 12'b0};
            IMM_J: immediate = {{11{instr_hi[31]}}, instr_hi[31], instr_hi[19:12],
                                instr_hi[20], instr_hi[30:21], 1'b0};
            default: immediate = 32'b0;
        endcase
    end
endmodule
