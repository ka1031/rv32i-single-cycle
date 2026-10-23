`timescale 1ns/1ps
module tb_imm_gen;
    import rv32i_pkg::*;
    logic [31:7] instr_hi;
    imm_sel_t sel;
    logic [31:0] immediate;
    // GNU-generated instruction/expected-value pairs, not hand-encoded opcodes.
    logic [31:0] vectors [0:25];
    int checks=0;
    imm_gen dut (.*);
    initial begin
        $readmemh("build/imm_vectors.hex",vectors);
        for (int i=0; i<13; i++) begin
            case (i)
                0,1: sel=IMM_I;
                2,3: sel=IMM_S;
                4,5,6,7: sel=IMM_B;
                8,9,10,11: sel=IMM_J;
                default: sel=IMM_U;
            endcase
            instr_hi=vectors[2*i][31:7]; #1;
            if (immediate !== vectors[2*i+1])
                $fatal(1,"FAIL immediate vector=%0d got=%h expected=%h",i,immediate,vectors[2*i+1]);
            checks++;
        end
        $display("PASS tb_imm_gen (%0d GNU instruction vectors)",checks); $finish;
    end
endmodule
