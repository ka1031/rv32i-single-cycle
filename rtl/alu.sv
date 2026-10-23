`timescale 1ns/1ps
module alu (
    input logic [31:0] a, b,
    input rv32i_pkg::alu_op_t op,
    output logic [31:0] result
);
    import rv32i_pkg::*;
    // All results wrap to 32 bits. Register shifts use only b[4:0].
    always_comb begin
        result = 32'b0;
        case (op)
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_AND:  result = a & b;
            ALU_OR:   result = a | b;
            ALU_XOR:  result = a ^ b;
            ALU_SLL:  result = a << b[4:0];
            ALU_SRL:  result = a >> b[4:0];
            ALU_SRA:  result = $signed(a) >>> b[4:0];
            ALU_SLT:  result = {31'b0, ($signed(a) < $signed(b))};
            ALU_SLTU: result = {31'b0, (a < b)};
            default:  result = 32'b0;
        endcase
    end
endmodule
