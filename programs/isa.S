    .option norvc
    .option norelax
    .section .text
    .globl _start
    .set check_id,0
    # t5 = failing check number, t6 = expected value. No hand-coded instructions.
    .macro EXPECT reg, value
    .set check_id,check_id+1
    li t5,check_id
    li t6,\value
    bne \reg,t6,fail
    .endm
    .macro SAME lhs,rhs
    .set check_id,check_id+1
    li t5,check_id
    bne \lhs,\rhs,fail
    .endm
    .macro TAKEN op,lhs,rhs
    .set check_id,check_id+1
    li t5,check_id
    \op \lhs,\rhs,1f
    jal zero,fail
1:
    .endm
    .macro NOT_TAKEN op,lhs,rhs
    .set check_id,check_id+1
    li t5,check_id
    \op \lhs,\rhs,fail
    .endm
_start:
    # x0, signed immediates, arithmetic wraparound and all register ALU operations.
    addi zero,zero,123
    EXPECT zero,0
    li t0,-1
    li t1,1
    add a0,t0,t1
    EXPECT a0,0
    sub a0,zero,t1
    EXPECT a0,-1
    li t0,0x7fffffff
    add a0,t0,t1
    EXPECT a0,0x80000000
    li t0,0xf0f00ff0
    li t1,0x0ff00ff0
    and a0,t0,t1
    EXPECT a0,0x00f00ff0
    or a0,t0,t1
    EXPECT a0,0xfff00ff0
    xor a0,t0,t1
    EXPECT a0,0xff000000
    li t0,-1
    li t1,1
    slt a0,t0,t1
    EXPECT a0,1
    sltu a0,t0,t1
    EXPECT a0,0
    slt a0,t0,t0
    EXPECT a0,0
    sltu a0,zero,t0
    EXPECT a0,1

    # Full immediate ALU group, with sign extension even for SLTIU/bitwise ops.
    addi a0,zero,-2048
    EXPECT a0,-2048
    addi a0,zero,2047
    EXPECT a0,2047
    slti a0,t0,0
    EXPECT a0,1
    sltiu a0,t1,-1
    EXPECT a0,1
    xori a0,zero,-1
    EXPECT a0,-1
    ori a0,zero,-2048
    EXPECT a0,0xfffff800
    andi a0,t0,0x123
    EXPECT a0,0x123

    # Register and immediate shifts: SRA/SRL distinction, 0/31, low-five-bit mask.
    li t0,0x80000001
    li t1,1
    srl a0,t0,t1
    EXPECT a0,0x40000000
    sra a0,t0,t1
    EXPECT a0,0xc0000000
    sll a0,t1,t1
    EXPECT a0,2
    li t1,31
    srl a0,t0,t1
    EXPECT a0,1
    sra a0,t0,t1
    EXPECT a0,-1
    li t1,32
    sll a0,t0,t1
    EXPECT a0,0x80000001
    sra a0,t0,t1
    EXPECT a0,0x80000001
    li t1,63
    srl a0,t0,t1
    EXPECT a0,1
    slli a0,t0,31
    EXPECT a0,0x80000000
    srli a0,t0,31
    EXPECT a0,1
    srai a0,t0,31
    EXPECT a0,-1
    slli a0,t0,0
    EXPECT a0,0x80000001
    srli a0,t0,0
    EXPECT a0,0x80000001
    srai a0,t0,0
    EXPECT a0,0x80000001

    # Byte addressing, little-endian words, signed/unsigned byte and halfword loads.
    li s0,0x200
    li t0,0x80ff7f01
    sw t0,0(s0)
    lw a0,0(s0)
    EXPECT a0,0x80ff7f01
    lb a0,0(s0)
    EXPECT a0,1
    lb a0,1(s0)
    EXPECT a0,127
    lb a0,2(s0)
    EXPECT a0,-1
    lbu a0,2(s0)
    EXPECT a0,255
    lb a0,3(s0)
    EXPECT a0,-128
    lbu a0,3(s0)
    EXPECT a0,128
    lh a0,0(s0)
    EXPECT a0,0x7f01
    lh a0,2(s0)
    EXPECT a0,0xffff80ff
    lhu a0,2(s0)
    EXPECT a0,0x80ff
    li t0,0xaa
    sb t0,1(s0)
    lw a0,0(s0)
    EXPECT a0,0x80ffaa01
    li t0,0x1234
    sh t0,2(s0)
    lw a0,0(s0)
    EXPECT a0,0x1234aa01
    lw zero,0(s0)
    EXPECT zero,0
    addi s0,s0,4
    lw a0,-4(s0)
    EXPECT a0,0x1234aa01
    sw a0,-4(s0)
    li s0,4092
    sw a0,0(s0)
    lbu a0,3(s0)
    EXPECT a0,0x12
    lhu a0,2(s0)
    EXPECT a0,0x1234

    # Every branch condition taken and not taken; signed/unsigned disagree.
    li t0,-1
    li t1,1
    TAKEN beq,t0,t0
    NOT_TAKEN beq,t0,t1
    TAKEN bne,t0,t1
    NOT_TAKEN bne,t0,t0
    TAKEN blt,t0,t1
    NOT_TAKEN blt,t1,t0
    TAKEN bge,t1,t0
    NOT_TAKEN bge,t0,t1
    TAKEN bltu,t1,t0
    NOT_TAKEN bltu,t0,t1
    TAKEN bgeu,t0,t1
    NOT_TAKEN bgeu,t1,t0
    li t0,3
back_branch:
    addi t0,t0,-1
    bne t0,zero,back_branch
    EXPECT t0,0
    # A not-taken branch must NOT fault even though its target is misaligned.
    bne zero,zero,.+2

    # Upper immediates, PC-relative addressing, forward/backward JAL and links.
    lui a0,0xabcde
    EXPECT a0,0xabcde000
pc_here:
    auipc a0,0
    la t0,pc_here
    SAME a0,t0
pc_upper:
    auipc a0,1
    la t0,pc_upper
    lui t1,1
    add t0,t0,t1
    SAME a0,t0
    jal ra,forward_target
return_point:
    jal zero,after_back
forward_target:
    la t0,return_point
    SAME ra,t0
    jal t2,return_point
back_link:
    jal zero,fail
 after_back:
    la t0,back_link
    SAME t2,t0
    # rs1 == rd tests that target uses old rs1, while rd receives PC+4.
    la t0,jalr_target
    addi t0,t0,1             # deliberately odd address: JALR must clear bit 0
    jalr t0,0(t0)
jalr_return:
    jal zero,fail
jalr_target:
    la t1,jalr_return
    SAME t0,t1
    la t0,jalr_zero_target
    jalr zero,0(t0)
    jal zero,fail
jalr_zero_target:
    EXPECT zero,0
    fence rw,rw
    li t0,0xff0
    li t1,1
    sw t1,0(t0)
done:
    jal zero,done
fail:
    li t0,0xff4
    sw t5,0(t0)             # identifies failing EXPECT/SAME/branch check
    li t0,0xff0
    li t1,-1
    sw t1,0(t0)
    jal zero,fail
