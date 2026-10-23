`timescale 1ns/1ps
package rv32i_pkg;
    typedef enum logic [3:0] {
        ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
        ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU
    } alu_op_t;
    typedef enum logic [2:0] {IMM_I, IMM_S, IMM_B, IMM_U, IMM_J} imm_sel_t;
    typedef enum logic [1:0] {A_RS1, A_PC, A_ZERO} a_sel_t;
    typedef enum logic [1:0] {WB_ALU, WB_MEM, WB_PC4} wb_sel_t;
    typedef enum logic [1:0] {MEM_BYTE, MEM_HALF, MEM_WORD} mem_size_t;
    typedef enum logic [3:0] {
        FAULT_NONE, FAULT_ILLEGAL, FAULT_I_ALIGN, FAULT_I_ACCESS,
        FAULT_D_ALIGN, FAULT_D_ACCESS, FAULT_ECALL, FAULT_EBREAK
    } fault_t;
    typedef struct packed {
        logic reg_write;
        logic mem_read;
        logic mem_write;
        logic b_imm;
        logic branch;
        logic jal;
        logic jalr;
        logic load_unsigned;
        a_sel_t a_sel;
        wb_sel_t wb_sel;
        imm_sel_t imm_sel;
        alu_op_t alu_op;
        mem_size_t mem_size;
    } control_t;
endpackage
