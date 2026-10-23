`timescale 1ns/1ps
module control_unit (
    input logic [31:0] instruction,
    output rv32i_pkg::control_t ctrl,
    output rv32i_pkg::fault_t decode_fault
);
    import rv32i_pkg::*;
    logic legal;
    // Decode all relevant function bits, including the upper shift-immediate bits.
    // Extension encodings (e.g. MUL with funct7=1) must never alias RV32I operations.
    always_comb begin
        ctrl = '0;
        ctrl.a_sel = A_RS1;
        ctrl.wb_sel = WB_ALU;
        ctrl.imm_sel = IMM_I;
        ctrl.alu_op = ALU_ADD;
        ctrl.mem_size = MEM_BYTE;
        legal = 1'b1;
        decode_fault = FAULT_NONE;
        case (instruction[6:0])
            7'b0110011: begin                       // OP
                ctrl.reg_write = 1'b1;
                case ({instruction[31:25], instruction[14:12]})
                    10'b0000000_000: ctrl.alu_op = ALU_ADD;
                    10'b0100000_000: ctrl.alu_op = ALU_SUB;
                    10'b0000000_001: ctrl.alu_op = ALU_SLL;
                    10'b0000000_010: ctrl.alu_op = ALU_SLT;
                    10'b0000000_011: ctrl.alu_op = ALU_SLTU;
                    10'b0000000_100: ctrl.alu_op = ALU_XOR;
                    10'b0000000_101: ctrl.alu_op = ALU_SRL;
                    10'b0100000_101: ctrl.alu_op = ALU_SRA;
                    10'b0000000_110: ctrl.alu_op = ALU_OR;
                    10'b0000000_111: ctrl.alu_op = ALU_AND;
                    default: legal = 1'b0;
                endcase
            end
            7'b0010011: begin                       // OP-IMM
                ctrl.reg_write = 1'b1;
                ctrl.b_imm = 1'b1;
                case (instruction[14:12])
                    3'b000: ctrl.alu_op = ALU_ADD;
                    3'b010: ctrl.alu_op = ALU_SLT;
                    3'b011: ctrl.alu_op = ALU_SLTU;
                    3'b100: ctrl.alu_op = ALU_XOR;
                    3'b110: ctrl.alu_op = ALU_OR;
                    3'b111: ctrl.alu_op = ALU_AND;
                    3'b001: begin
                        ctrl.alu_op = ALU_SLL;
                        legal = (instruction[31:25] == 7'b0000000);
                    end
                    3'b101: begin
                        if (instruction[31:25] == 7'b0000000) ctrl.alu_op = ALU_SRL;
                        else if (instruction[31:25] == 7'b0100000) ctrl.alu_op = ALU_SRA;
                        else legal = 1'b0;
                    end
                    default: legal = 1'b0;
                endcase
            end
            7'b0000011: begin                       // LOAD
                ctrl.reg_write = 1'b1;
                ctrl.mem_read = 1'b1;
                ctrl.b_imm = 1'b1;
                ctrl.wb_sel = WB_MEM;
                case (instruction[14:12])
                    3'b000: ctrl.mem_size = MEM_BYTE;
                    3'b001: ctrl.mem_size = MEM_HALF;
                    3'b010: ctrl.mem_size = MEM_WORD;
                    3'b100: begin ctrl.mem_size = MEM_BYTE; ctrl.load_unsigned = 1'b1; end
                    3'b101: begin ctrl.mem_size = MEM_HALF; ctrl.load_unsigned = 1'b1; end
                    default: legal = 1'b0;
                endcase
            end
            7'b0100011: begin                       // STORE
                ctrl.mem_write = 1'b1;
                ctrl.b_imm = 1'b1;
                ctrl.imm_sel = IMM_S;
                case (instruction[14:12])
                    3'b000: ctrl.mem_size = MEM_BYTE;
                    3'b001: ctrl.mem_size = MEM_HALF;
                    3'b010: ctrl.mem_size = MEM_WORD;
                    default: legal = 1'b0;
                endcase
            end
            7'b1100011: begin                       // BRANCH
                ctrl.branch = 1'b1;
                ctrl.imm_sel = IMM_B;
                case (instruction[14:12])
                    3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: legal = 1'b1;
                    default: legal = 1'b0;
                endcase
            end
            7'b1101111: begin                       // JAL
                ctrl.reg_write = 1'b1;
                ctrl.jal = 1'b1;
                ctrl.wb_sel = WB_PC4;
                ctrl.imm_sel = IMM_J;
            end
            7'b1100111: begin                       // JALR
                ctrl.reg_write = 1'b1;
                ctrl.jalr = 1'b1;
                ctrl.b_imm = 1'b1;
                ctrl.wb_sel = WB_PC4;
                legal = (instruction[14:12] == 3'b000);
            end
            7'b0110111: begin                       // LUI
                ctrl.reg_write = 1'b1;
                ctrl.a_sel = A_ZERO;
                ctrl.b_imm = 1'b1;
                ctrl.imm_sel = IMM_U;
            end
            7'b0010111: begin                       // AUIPC
                ctrl.reg_write = 1'b1;
                ctrl.a_sel = A_PC;
                ctrl.b_imm = 1'b1;
                ctrl.imm_sel = IMM_U;
            end
            7'b0001111: begin                       // FENCE (ordered local memory)
                // Per base ISA, ignore reserved rd/rs1 and fm/pred/succ fields.
                // funct3=001 is FENCE.I and is not supported.
                legal = (instruction[14:12] == 3'b000);
            end
            7'b1110011: begin
                if (instruction == 32'h00000073) decode_fault = FAULT_ECALL;
                else if (instruction == 32'h00100073) decode_fault = FAULT_EBREAK;
                else legal = 1'b0;                  // Includes all CSR instructions.
            end
            default: legal = 1'b0;
        endcase
        if (!legal) begin
            // Safe even when optional fault policy is bypassed.
            ctrl.reg_write = 1'b0;
            ctrl.mem_read = 1'b0;
            ctrl.mem_write = 1'b0;
            ctrl.branch = 1'b0;
            ctrl.jal = 1'b0;
            ctrl.jalr = 1'b0;
            decode_fault = FAULT_ILLEGAL;
        end
    end
endmodule
