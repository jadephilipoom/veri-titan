.globl mod_pow
mod_pow:
  addi sp, sp, -32
  sw ra, 28(sp)
  sw s0, 24(sp)
  sw s1, 20(sp)
  sw s2, 16(sp)
  sw s3, 12(sp)
  sw s4, 8(sp)
  sw s5, 4(sp)
  sw s6, 0(sp)
  addi s0, a2, 0
  addi s6, a4, 0
  addi s3, a0, 0
  addi s5, a5, 0
  addi s4, a1, 0
  addi s2, a2, 384
  addi a2, a3, 0
  addi a1, s0, 0
  addi a3, s5, 0
  call mont_mul
  li s1, 8

w_start0:
  bleu s1, x0, w_end0
  addi a3, s0, 0
  addi a2, s0, 0
  addi a1, s2, 0
  addi a0, s3, 0
  addi a4, s6, 0
  call mont_mul
  addi a3, s2, 0
  addi a2, s2, 0
  addi a1, s0, 0
  addi a0, s3, 0
  addi a4, s6, 0
  call mont_mul
  addi s1, s1, -1
  j w_start0

w_end0:
  addi a0, s3, 0
  addi a3, s5, 0
  addi a2, s0, 0
  addi a1, s4, 0
  addi a4, s6, 0
  call mont_mul
  addi a0, s4, 0
  addi a1, s6, 0
  call ge_mod
  beq a0, x0, if_true1
  j if_end1

if_true1:
  addi a0, s4, 0
  addi a1, s6, 0
  call sub_mod

if_end1:
  lw ra, 28(sp)
  lw s0, 24(sp)
  lw s1, 20(sp)
  lw s2, 16(sp)
  lw s3, 12(sp)
  lw s4, 8(sp)
  lw s5, 4(sp)
  lw s6, 0(sp)
  addi sp, sp, 32
  ret

mont_mul:
  addi sp, sp, -32
  sw ra, 28(sp)
  sw s0, 24(sp)
  sw s1, 20(sp)
  sw s2, 16(sp)
  sw s3, 12(sp)
  sw s4, 8(sp)
  sw s5, 4(sp)
  addi s0, a0, 0
  addi s1, a1, 0
  addi s2, a2, 0
  addi s3, a3, 0
  addi s5, a4, 0
  addi s4, s1, 384

w_start2:
  bgeu s1, s4, w_end2
  sw x0, 0(s1)
  addi s1, s1, 4
  j w_start2

w_end2:
  addi s1, a1, 0
  addi s4, s2, 384

w_start3:
  bgeu s2, s4, w_end3
  addi a1, s1, 0
  addi a0, s0, 0
  addi a3, s3, 0
  addi a4, s5, 0
  lw a2, 0(s2)
  call mont_mul_add
  addi s2, s2, 4
  j w_start3

w_end3:
  lw ra, 28(sp)
  lw s0, 24(sp)
  lw s1, 20(sp)
  lw s2, 16(sp)
  lw s3, 12(sp)
  lw s4, 8(sp)
  lw s5, 4(sp)
  addi sp, sp, 32
  ret

mont_mul_add:
  addi sp, sp, -48
  sw ra, 44(sp)
  sw s0, 40(sp)
  sw s1, 36(sp)
  sw s2, 32(sp)
  sw s3, 28(sp)
  sw s4, 24(sp)
  sw s6, 16(sp)
  sw s5, 20(sp)
  sw s7, 12(sp)
  sw s8, 8(sp)
  addi s6, a1, 0
  lw a1, 0(a3)
  addi s7, a2, 0
  lw a2, 0(s6)
  addi s5, a0, 0
  addi a0, s7, 0
  addi s4, a3, 0
  call mula32
  mul s5, a0, s5
  addi s8, a4, 0
  addi s0, a1, 0
  lw a1, 0(s8)
  addi a2, a0, 0
  addi s2, s8, 4
  addi s4, s4, 4
  addi s3, s6, 0
  addi s8, s8, 384
  addi a0, s5, 0
  call mula32
  addi s1, a1, 0

w_start4:
  bgeu s2, s8, w_end4
  lw a2, 4(s3)
  lw a1, 0(s4)
  addi a3, s0, 0
  addi a0, s7, 0
  call mulaa32
  addi s0, a1, 0
  lw a1, 0(s2)
  addi a2, a0, 0
  addi a3, s1, 0
  addi a0, s5, 0
  call mulaa32
  sw a0, 0(s3)
  addi s2, s2, 4
  addi s1, a1, 0
  addi s4, s4, 4
  addi s3, s3, 4
  j w_start4

w_end4:
  add s0, s0, s1
  sw s0, 0(s3)
  bltu s0, s1, if_true5
  j if_end5

if_true5:
  addi a0, s6, 0
  addi a1, s8, -384
  call sub_mod

if_end5:
  lw ra, 44(sp)
  lw s0, 40(sp)
  lw s1, 36(sp)
  lw s2, 32(sp)
  lw s3, 28(sp)
  lw s4, 24(sp)
  lw s5, 20(sp)
  lw s6, 16(sp)
  lw s7, 12(sp)
  lw s8, 8(sp)
  addi sp, sp, 48
  ret

mula32:
  mul a5, a0, a1
  mulhu a1, a0, a1
  add a0, a5, a2
  sltu a5, a0, a5
  add a1, a1, a5
  ret

mulaa32:
  mul a5, a0, a1
  mulhu a1, a0, a1
  add a0, a5, a2
  sltu a5, a0, a5
  add a1, a1, a5
  add a0, a0, a3
  sltu a5, a0, a3
  add a1, a1, a5
  ret

sub_mod:
  addi a2, a1, 0
  addi a6, a2, 384
  li a5, 0
  li a1, 0

w_start6:
  beq a2, a6, w_end6
  lw a4, 0(a0)
  lw a3, 0(a2)
  addi a2, a2, 4
  add a5, a5, a4
  sub a3, a5, a3
  sltu a4, a5, a4
  add a4, a4, a1
  sltu a5, a5, a3
  sw a3, 0(a0)
  addi a0, a0, 4
  sub a5, a4, a5
  srai a1, a5, 31
  j w_start6

w_end6:
  ret

ge_mod:
  addi a0, a0, 380
  addi a5, a1, 380
  addi a2, x0, 1

w_start7:
  beq a2, x0, w_end7
  lw a3, 0(a0)
  lw a4, 0(a5)
  sub a2, a3, a4
  sltu a3, a3, a4
  sltu a4, x0, a2
  xor a2, a1, a5
  bne a4, x0, if_true8
  j if_end8

if_true8:
  add a2, x0, x0

if_end8:
  addi a0, a0, -4
  addi a5, a5, -4
  j w_start7

w_end7:
  addi a0, a3, 0
  ret

