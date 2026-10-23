# Directed test coverage map

**All directed HDL regression tests passed on 2026-10-23.** This table maps the executed tests to requirements. It is not a measured code-coverage report or a formal RV32I compliance result. See [verification.md](verification.md) for commands and tool versions.

| Requirement / corner case | Authored test |
|---|---|
| All ten ALU operations | `tb_alu`, OP cases in `isa.S` |
| All nine immediate ALU operations | OP-IMM cases in `isa.S` |
| 32-bit add/sub wraparound | `tb_alu`; ADD overflow and SUB underflow in `isa.S` |
| Signed/unsigned comparisons disagree | `tb_alu`, `tb_branch_unit`; SLT/SLTU and branch pairs in `isa.S` |
| Signed immediate extension, including SLTIU | I extremes in `tb_imm_gen`; negative ADDI/ORI/XORI and SLTIU in `isa.S` |
| SRA versus SRL on negative inputs | `tb_alu` tests 0x80000001 at counts 1 and 31; `isa.S` register/immediate shifts |
| Shift counts 0 and 31, register count masked at 32 and 63 | `tb_alu`, `isa.S` |
| All x1..x31 readable/writable through both ports | `tb_regfile` writes and reads all 31 registers |
| x0 write discard | `tb_regfile`, ADDI x0 / LW x0 / JAL x0 / JALR x0 in core programs |
| Load to x0 still faults | Fault case 18 |
| Register read combinational, write synchronous, write-enable honored | `tb_regfile` checks before/after edge and disabled writes |
| Synchronous reset and reset priority | `tb_regfile`, `tb_fault_unit`, `tb_core`, every `tb_faults` run |
| I/S immediate bounds | GNU vectors -2048 and +2047 in `imm_vectors.S` |
| B immediate bit reconstruction and sign | GNU vectors +4094, -4096, +2050, -2050; backward branch in `isa.S` and sum loop |
| J immediate bit reconstruction and sign | GNU vectors +1048574, -1048576, +2050, -2050; forward/backward JAL in `isa.S` |
| U immediate reconstruction | GNU LUI 0xabcde vector and `isa.S` |
| LB negative sign extension / LBU zero extension | `tb_data_mem`, `isa.S`: bytes 0x80/0xff versus 0x01/0x7f |
| LH negative sign extension / LHU zero extension | `tb_data_mem`, `isa.S`: halfword 0x80ff versus 0x7f01 |
| LW and SW; little-endian layout | `tb_data_mem`, `isa.S`, sum core test checks all four result bytes |
| SB/SH preserve surrounding bytes | `tb_data_mem` checks all byte lanes/both halfword lanes; `isa.S` partial stores |
| Signed load/store address offsets | `isa.S` accesses offset -4 from an adjusted base |
| Memory first/last legal addresses | `tb_data_mem`; end-of-RAM SW/LBU/LHU in `isa.S` |
| Memory writes synchronous, commit-gated, reset-inhibited | `tb_data_mem` |
| Reset preserves RAM | `tb_data_mem`, all fault runs |
| All six branches taken and not taken | `tb_branch_unit`, `isa.S` TAKEN/NOT_TAKEN macros |
| Branch equality boundaries | `tb_branch_unit` checks signed/unsigned GE and LT on equal values |
| Untaken misaligned branch does not fault | `bne zero,zero,.+2` in `isa.S` |
| JAL forward/backward link values | `isa.S` compares ra/t2 against GNU-resolved labels |
| JALR bit-0 clearing | `isa.S` jumps to target+1 |
| JALR uses old rs1 when rd=rs1 | Same odd-address JALR in `isa.S` |
| JALR does not clear bit 1 | Fault case 10 |
| LUI and AUIPC at nonzero PCs | `isa.S`, with GNU-resolved PC labels for AUIPC |
| FENCE does not change state or stop execution | FENCE before success signature in `isa.S` |
| Misaligned LH/LW/SH/SW | Fault cases 0–3; unit memory checks |
| Data accesses above RAM and negative addresses | Fault cases 4–8; unit memory boundary checks |
| No truncated high-address aliasing | Fault cases 6–7 preserve address-zero sentinel; `tb_data_mem` |
| Misaligned JAL/JALR/taken branch | Fault cases 9–11 |
| Unsupported M, CSR, FENCE.I rejected | GNU-assembled extension instructions in fault cases 12–14 |
| ECALL/EBREAK event reporting | Fault cases 15–16 |
| Out-of-range instruction fetch; prior jump link retained | Fault case 17 |
| Alignment priority over range fault | Fault case 19 |
| Fault suppresses stores, register writes, and PC advance | Every `tb_faults` run checks sentinel, a0, PC, commit and store_valid |
| First fault cause sticky until reset | `tb_fault_unit`; every core fault case holds for additional cycles |
| Fault-policy bypass/removal option | `tb_fault_unit` has ENABLE=0 and ENABLE=1 instances |
| Normal program execution and completion | `sum.S`: sum 1..10=55, store, load-back, completion loop |
| Test failure detection / runaway program | `$fatal(1,...)`, failure signature and 3,000-cycle core timeout |
| Lint diagnostics, including inferred-latch warnings; no warning suppression | Full Verilator -Wall gate passed for RTL and all eight testbenches; synthesis was not run |

The suite is directed rather than exhaustive. It does not replace formal proof, a full architectural compliance suite, technology synthesis, or static timing analysis. In particular, reserved encoding space is validated in the decoder but not exhaustively enumerated by the testbench.
