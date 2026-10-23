`timescale 1ns/1ps
module pc (
    input logic clk, rst, enable,
    input logic [31:0] next_pc,
    output logic [31:0] current_pc
);
    always_ff @(posedge clk) begin
        if (rst) current_pc <= 32'b0;
        else if (enable) current_pc <= next_pc;
    end
endmodule
