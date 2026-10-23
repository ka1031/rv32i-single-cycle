# ISA reference

Design semantics are based on the RISC-V Unprivileged ISA, RV32I Base Integer Instruction Set, version 2.1:

https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html

Relevant rules include x0, signed immediates, lower-five-bit shift counts, JALR bit-zero clearing, instruction alignment, signed versus unsigned comparisons/loads, and the execution-environment role of ECALL/EBREAK. This project implements a small external terminal-fault interface, not the privileged ISA or CSR trap state.
