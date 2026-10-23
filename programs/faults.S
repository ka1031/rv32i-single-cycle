    .option norvc
    .option norelax
    .section .text
    .globl _start, fault_site, expected_pc, expected_a0
_start:
    li a0,85
    li t0,0x11223344
    sw t0,0(zero)              # retained sentinel: faulting stores must not corrupt it
    li t1,4096
    .set expected_a0,85
    .if CASE == 0
fault_site: lh a0,1(zero)
    .elseif CASE == 1
fault_site: lw a0,2(zero)
    .elseif CASE == 2
fault_site: sh zero,1(zero)
    .elseif CASE == 3
fault_site: sw zero,2(zero)
    .elseif CASE == 4
fault_site: lw a0,0(t1)
    .elseif CASE == 5
fault_site: sw zero,0(t1)
    .elseif CASE == 6
    lui t1,0x10000
fault_site: lw a0,0(t1)
    .elseif CASE == 7
    lui t1,0x10000
fault_site: sw zero,0(t1)
    .elseif CASE == 8
fault_site: lb a0,-1(zero)
    .elseif CASE == 9
fault_site: jal a0,.+2
    .elseif CASE == 10
    li t1,2
fault_site: jalr a0,0(t1)
    .elseif CASE == 11
fault_site: beq zero,zero,.+2
    .elseif CASE == 12
    # GNU assembles a genuine M instruction, which this RV32I decoder must reject.
    .option arch,+m
fault_site: mul a0,t0,t1
    .option arch,-m
    .elseif CASE == 13
    .option arch,+zicsr
fault_site: csrrw a0,mscratch,zero
    .option arch,-zicsr
    .elseif CASE == 14
    .option arch,+zifencei
fault_site: fence.i
    .option arch,-zifencei
    .elseif CASE == 15
fault_site: ecall
    .elseif CASE == 16
fault_site: ebreak
    .elseif CASE == 17
fault_site: jalr a0,0(t1)       # valid transfer, then instruction access fault at 0x1000
    .set expected_a0,fault_site+4
    .elseif CASE == 18
fault_site: lw zero,2(zero)     # rd=x0 does not suppress a memory fault
    .elseif CASE == 19
fault_site: lh a0,-1(zero)      # both alignment and range invalid: alignment wins
    .endif
    .if CASE == 17
    .set expected_pc,4096
    .else
    .set expected_pc,fault_site
    .endif
    sw zero,0(zero)            # must never execute
    jal zero,.
