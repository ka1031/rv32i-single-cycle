    .option norvc
    .option norelax
    .section .text
    .globl _start
_start:
    # Every pair is an instruction assembled by GNU, then a 32-bit expected
    # immediate (DATA, not an instruction encoding). This program is not executed.
    addi a0,a1,-2048
    .word -2048
    addi a0,a1,2047
    .word 2047
    sw a0,-2048(a1)
    .word -2048
    sw a0,2047(a1)
    .word 2047
    beq a0,a1, .+4094
    .word 4094
    beq a0,a1, .-4096
    .word -4096
    beq a0,a1, .+2050
    .word 2050
    beq a0,a1, .-2050
    .word -2050
    jal a0, .+1048574
    .word 1048574
    jal a0, .-1048576
    .word -1048576
    jal a0, .+2050
    .word 2050
    jal a0, .-2050
    .word -2050
    lui a0,0xabcde
    .word 0xabcde000
