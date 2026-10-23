# Control signal tables

Controls are defined in `rv32i_pkg::control_t`. All combinations shown below are for valid encodings only. Every combinational path receives a deterministic default; dashes indicate unused semantics, not X assignments in hardware.

- `reg_write`: request rd write; the register file separately discards rd=0.
- `a_sel`: A_RS1=0, A_PC=1, A_ZERO=2.
- `b_imm`: 0 selects rs2; 1 selects the generated immediate.
- `alu_op`: ADD=0, SUB=1, AND=2, OR=3, XOR=4, SLL=5, SRL=6, SRA=7, SLT=8, SLTU=9.
- `wb_sel`: WB_ALU=0, WB_MEM=1, WB_PC4=2.
- `imm_sel`: I=0, S=1, B=2, U=3, J=4.
- `mem_size`: BYTE=0, HALF=1, WORD=2. `load_unsigned` zero-extends byte/halfword loads when 1.
- `mem_read` and `mem_write`: requests independent of fault commit gating.
- `branch`, `jal`, `jalr`: next-PC selection requests.

| Opcode | Class | reg_write | a_sel | b_imm | alu_op | mem_read | mem_write | wb_sel | imm_sel | branch | jal | jalr |
|---|---|---:|---|---:|---|---:|---:|---|---|---:|---:|---:|
| 0110011 | OP | 1 | RS1 | 0 | Function decode | 0 | 0 | ALU | I (unused) | 0 | 0 | 0 |
| 0010011 | OP-IMM | 1 | RS1 | 1 | Function decode | 0 | 0 | ALU | I | 0 | 0 | 0 |
| 0000011 | LOAD | 1 | RS1 | 1 | ADD | 1 | 0 | MEM | I | 0 | 0 | 0 |
| 0100011 | STORE | 0 | RS1 | 1 | ADD | 0 | 1 | ALU (unused) | S | 0 | 0 | 0 |
| 1100011 | BRANCH | 0 | RS1 (unused) | 0 | ADD (unused) | 0 | 0 | ALU (unused) | B | 1 | 0 | 0 |
| 1101111 | JAL | 1 | RS1 (unused) | 0 | ADD (unused) | 0 | 0 | PC4 | J | 0 | 1 | 0 |
| 1100111 | JALR | 1 | RS1 | 1 | ADD | 0 | 0 | PC4 | I | 0 | 0 | 1 |
| 0110111 | LUI | 1 | ZERO | 1 | ADD | 0 | 0 | ALU | U | 0 | 0 | 0 |
| 0010111 | AUIPC | 1 | PC | 1 | ADD | 0 | 0 | ALU | U | 0 | 0 | 0 |
| 0001111 | FENCE (funct3=000) | 0 | RS1 (unused) | 0 | ADD (unused) | 0 | 0 | ALU (unused) | I (unused) | 0 | 0 | 0 |
| 1110011 | ECALL/EBREAK | 0 | RS1 (unused) | 0 | ADD (unused) | 0 | 0 | ALU (unused) | I (unused) | 0 | 0 | 0 |
| Any | Invalid encoding | 0 | — | — | — | 0 | 0 | — | — | 0 | 0 | 0 |

For nonmemory instructions, memory width/sign defaults are BYTE and signed. Invalid function encodings clear every side-effect/transfer request and assert FAULT_ILLEGAL. Some unused arithmetic selectors may retain decoded values, but no architectural write or transfer is permitted.

PC normally selects PC+4. `branch && taken` or `jal` selects PC+immediate. `jalr` selects ALU result with bit zero cleared. The decoder never asserts more than one of branch/jal/jalr. With fault policy enabled, `commit = !rst && !fault && event_cause==NONE`; `reg_write` and `mem_write` only affect state when commit is true. PC updates on commit as well.

## ALU subdecode

| Instruction | Opcode class | funct3 | funct7 / instr[31:25] | ALU |
|---|---|---|---|---|
| ADD | OP | 000 | 0000000 | ADD |
| SUB | OP | 000 | 0100000 | SUB |
| SLL | OP | 001 | 0000000 | SLL |
| SLT | OP | 010 | 0000000 | SLT |
| SLTU | OP | 011 | 0000000 | SLTU |
| XOR | OP | 100 | 0000000 | XOR |
| SRL | OP | 101 | 0000000 | SRL |
| SRA | OP | 101 | 0100000 | SRA |
| OR | OP | 110 | 0000000 | OR |
| AND | OP | 111 | 0000000 | AND |
| ADDI | OP-IMM | 000 | Immediate bits, unrestricted | ADD |
| SLTI | OP-IMM | 010 | Immediate bits, unrestricted | SLT |
| SLTIU | OP-IMM | 011 | Immediate bits, unrestricted | SLTU |
| XORI | OP-IMM | 100 | Immediate bits, unrestricted | XOR |
| ORI | OP-IMM | 110 | Immediate bits, unrestricted | OR |
| ANDI | OP-IMM | 111 | Immediate bits, unrestricted | AND |
| SLLI | OP-IMM | 001 | 0000000 | SLL |
| SRLI | OP-IMM | 101 | 0000000 | SRL |
| SRAI | OP-IMM | 101 | 0100000 | SRA |

Any other OP function pair, or upper shift-immediate pattern, is illegal. SLTIU compares unsigned register and unsigned representation of the **sign-extended** immediate. There are no arithmetic overflow traps.

## Branch subdecode

| funct3 | Instruction | Taken condition |
|---|---|---|
| 000 | BEQ | rs1 == rs2 |
| 001 | BNE | rs1 != rs2 |
| 100 | BLT | signed(rs1) < signed(rs2) |
| 101 | BGE | signed(rs1) >= signed(rs2) |
| 110 | BLTU | unsigned(rs1) < unsigned(rs2) |
| 111 | BGEU | unsigned(rs1) >= unsigned(rs2) |
| 010 / 011 | Invalid | Decoder faults; comparator defaults false |

## Memory subdecode

| Opcode class | funct3 | Instruction | mem_size | load_unsigned | Data operation |
|---|---|---|---|---:|---|
| LOAD | 000 | LB | BYTE | 0 | Sign-extend bit 7 |
| LOAD | 001 | LH | HALF | 0 | Sign-extend bit 15 |
| LOAD | 010 | LW | WORD | 0 | Full 32 bits |
| LOAD | 100 | LBU | BYTE | 1 | Zero-extend 8 bits |
| LOAD | 101 | LHU | HALF | 1 | Zero-extend 16 bits |
| STORE | 000 | SB | BYTE | 0 (unused) | Store rs2[7:0] |
| STORE | 001 | SH | HALF | 0 (unused) | Store rs2[15:0] |
| STORE | 010 | SW | WORD | 0 (unused) | Store rs2[31:0] |

Other memory funct3 values are illegal. At effective address A, the lowest-addressed byte holds bits [7:0]. SB preserves all neighboring bytes; SH preserves the other two bytes of an aligned word. Legal last starting addresses are 4095/4094/4092 for byte/halfword/word, respectively.

## Immediate reconstruction

Here `i` denotes instruction bits; `sext` extends the indicated signed bit-vector to 32 bits.

| Format | 32-bit result |
|---|---|
| I | sext(i[31:20]) |
| S | sext({i[31:25], i[11:7]}) |
| B | sext({i[31], i[7], i[30:25], i[11:8], 0}) |
| U | {i[31:12], 12 zero bits} |
| J | sext({i[31], i[19:12], i[20], i[30:21], 0}) |

JALR requires funct3=000. ECALL and EBREAK require their exact base encodings; all other SYSTEM instructions are illegal. FENCE requires funct3=000; reserved rd/rs1 and fence fields are ignored as allowed for base FENCE. FENCE.I (funct3=001) is not supported.
