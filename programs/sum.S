    .option norvc
    .option norelax
    .section .text
    .globl _start
_start:
    addi t0, zero, 0          # running sum
    addi t1, zero, 1          # i = 1
    addi t2, zero, 11         # exclusive upper bound
loop:
    add  t0, t0, t1
    addi t1, t1, 1
    blt  t1, t2, loop
    sw   t0, 256(zero)        # data[0x100] = 55
    lw   t3, 256(zero)        # verify load path too
    addi t4, zero, 55
    bne  t3, t4, fail
    lui  t6, 1
    addi t6, t6, -16          # testbench completion address = 0xff0
    addi t5, zero, 1
    sw   t5, 0(t6)           # success signature
finished:
    jal  zero, finished
fail:
    lui  t6, 1
    addi t6, t6, -16
    addi t5, zero, -1
    sw   t5, 0(t6)           # failure signature
    jal  zero, fail
