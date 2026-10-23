`timescale 1ns/1ps
module data_mem (
    input logic clk, rst,
    // Requests drive checks independently of commit, avoiding a fault/enable loop.
    input logic read_req, write_req, commit,
    input logic [31:0] address, write_data,
    input rv32i_pkg::mem_size_t size,
    input logic load_unsigned,
    output logic [31:0] read_data,
    output logic misaligned, access_fault
);
    import rv32i_pkg::*;
    logic [7:0] mem [0:4095];
    logic active, valid_access;
    logic [11:0] index;
    assign active = read_req || write_req;
    assign index = address[11:0];
    // Check the entire 32-bit address BEFORE using its low bits as an index.
    always_comb begin
        misaligned = 1'b0;
        access_fault = 1'b0;
        if (active) begin
            case (size)
                MEM_BYTE: access_fault = (address > 32'd4095);
                MEM_HALF: begin
                    misaligned = address[0];
                    access_fault = (address > 32'd4094);
                end
                MEM_WORD: begin
                    misaligned = |address[1:0];
                    access_fault = (address > 32'd4092);
                end
                default: access_fault = 1'b1;
            endcase
        end
    end
    assign valid_access = active && !misaligned && !access_fault;
    always_comb begin
        read_data = 32'b0;
        if (read_req && valid_access) begin
            case (size)
                MEM_BYTE: read_data = {{24{!load_unsigned && mem[index][7]}}, mem[index]};
                MEM_HALF: read_data = {{16{!load_unsigned && mem[index+12'd1][7]}},
                                       mem[index+12'd1], mem[index]};
                MEM_WORD: read_data = {mem[index+12'd3], mem[index+12'd2],
                                       mem[index+12'd1], mem[index]};
                default: read_data = 32'b0;
            endcase
        end
    end
    // No memory reset/initialization: software must initialize data before reading.
    // Reset inhibits writes; unaffected bytes retain their old values.
    always_ff @(posedge clk) begin
        if (!rst && commit && write_req && valid_access) begin
            mem[index] <= write_data[7:0];
            if (size == MEM_HALF || size == MEM_WORD)
                mem[index+12'd1] <= write_data[15:8];
            if (size == MEM_WORD) begin
                mem[index+12'd2] <= write_data[23:16];
                mem[index+12'd3] <= write_data[31:24];
            end
        end
    end
endmodule
