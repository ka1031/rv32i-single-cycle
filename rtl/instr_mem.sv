`timescale 1ns/1ps
module instr_mem #(
    parameter HEX_FILE = "programs/sum.hex"
) (
    input logic [31:0] address,
    output logic [31:0] instruction,
    output logic misaligned, access_fault
);
    logic [31:0] mem [0:1023];
    // ROM initialization is supported by many FPGA tools; ASIC ROM implementation
    // requires a technology-specific replacement. The supplied image is 1024 words.
    initial $readmemh(HEX_FILE, mem);
    assign misaligned = |address[1:0];
    assign access_fault = (address > 32'd4092);
    assign instruction = (!misaligned && !access_fault) ? mem[address[11:2]] : 32'b0;
endmodule
