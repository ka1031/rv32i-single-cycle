`timescale 1ns/1ps
module regfile (
    input logic clk, rst, write_enable,
    input logic [4:0] rs1, rs2, rd,
    input logic [31:0] write_data,
    output logic [31:0] read_data1, read_data2
);
    // Only x1..x31 need storage. x0 is a literal zero on both read ports.
    logic [31:0] regs [1:31];
    assign read_data1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 1; i < 32; i++) regs[i] <= 32'b0;
        end else if (write_enable && rd != 5'd0) begin
            regs[rd] <= write_data;
        end
    end
endmodule
