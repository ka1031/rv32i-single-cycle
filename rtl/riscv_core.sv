`timescale 1ns/1ps
module riscv_core #(
    parameter HEX_FILE = "programs/sum.hex",
    parameter bit ENABLE_FAULTS = 1'b1
) (
    input logic clk, rst,
    output logic fault,
    output rv32i_pkg::fault_t fault_cause,
    output logic [31:0] debug_pc,
    // Combinational store-commit observation: sample at the rising edge.
    output logic store_valid,
    output logic [31:0] store_address, store_data,
    output rv32i_pkg::mem_size_t store_size
);
    import rv32i_pkg::*;
    control_t ctrl;
    fault_t decode_fault, event_cause;
    logic [31:0] instruction, rs1_data, rs2_data, immediate;
    logic [31:0] alu_a, alu_b, alu_result, load_data, writeback;
    logic [31:0] pc4, pc_relative, next_pc;
    logic branch_taken, transfer, commit;
    logic i_misaligned, i_access_fault, d_misaligned, d_access_fault;

    // Fetch/decode: asynchronous instruction and register reads start at current PC.
    pc u_pc (.clk, .rst, .enable(commit), .next_pc, .current_pc(debug_pc));
    instr_mem #(.HEX_FILE(HEX_FILE)) u_imem (
        .address(debug_pc), .instruction,
        .misaligned(i_misaligned), .access_fault(i_access_fault));
    control_unit u_control (.instruction, .ctrl, .decode_fault);
    regfile u_regfile (
        .clk, .rst, .write_enable(commit && ctrl.reg_write),
        .rs1(instruction[19:15]), .rs2(instruction[24:20]), .rd(instruction[11:7]),
        .write_data(writeback), .read_data1(rs1_data), .read_data2(rs2_data));
    imm_gen u_imm (.instr_hi(instruction[31:7]), .sel(ctrl.imm_sel), .immediate);

    // Execute: one main ALU plus dedicated PC adders and branch comparison.
    always_comb begin
        case (ctrl.a_sel)
            A_PC: alu_a = debug_pc;
            A_ZERO: alu_a = 32'b0;
            default: alu_a = rs1_data;
        endcase
    end
    assign alu_b = ctrl.b_imm ? immediate : rs2_data;
    alu u_alu (.a(alu_a), .b(alu_b), .op(ctrl.alu_op), .result(alu_result));
    branch_unit u_branch (.a(rs1_data), .b(rs2_data),
                          .funct3(instruction[14:12]), .taken(branch_taken));
    assign pc4 = debug_pc + 32'd4;
    assign pc_relative = debug_pc + immediate;
    assign transfer = ctrl.jal || ctrl.jalr || (ctrl.branch && branch_taken);
    always_comb begin
        next_pc = pc4;
        if (ctrl.jal || (ctrl.branch && branch_taken)) next_pc = pc_relative;
        if (ctrl.jalr) next_pc = {alu_result[31:1], 1'b0};
    end

    // Memory: combinational load, synchronous byte-lane stores.
    data_mem u_dmem (
        .clk, .rst, .read_req(ctrl.mem_read), .write_req(ctrl.mem_write), .commit,
        .address(alu_result), .write_data(rs2_data), .size(ctrl.mem_size),
        .load_unsigned(ctrl.load_unsigned), .read_data(load_data),
        .misaligned(d_misaligned), .access_fault(d_access_fault));
    always_comb begin
        case (ctrl.wb_sel)
            WB_MEM: writeback = load_data;
            WB_PC4: writeback = pc4;
            default: writeback = alu_result;
        endcase
    end

    // Fault detection is independent of commit. No combinational feedback through
    // memory requests. Priority: current fetch, decode, target alignment, data.
    // Out-of-range jump targets fault on the subsequent fetch, after link writeback.
    always_comb begin
        event_cause = FAULT_NONE;
        if (i_misaligned) event_cause = FAULT_I_ALIGN;
        else if (i_access_fault) event_cause = FAULT_I_ACCESS;
        else if (decode_fault != FAULT_NONE) event_cause = decode_fault;
        else if (transfer && (|next_pc[1:0])) event_cause = FAULT_I_ALIGN;
        else if (d_misaligned) event_cause = FAULT_D_ALIGN;
        else if (d_access_fault) event_cause = FAULT_D_ACCESS;
    end
    fault_unit #(.ENABLE(ENABLE_FAULTS)) u_fault (
        .clk, .rst, .event_cause, .commit, .fault, .fault_cause);
    assign store_valid = commit && ctrl.mem_write && !d_misaligned && !d_access_fault;
    assign store_address = alu_result;
    assign store_data = rs2_data;
    assign store_size = ctrl.mem_size;
endmodule
