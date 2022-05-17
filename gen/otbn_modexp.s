/*
  This code is generated by the veri-titan project: https://github.com/secure-foundations/veri-titan
*/
.globl modexp_var_3072_f4
modexp_var_3072_f4:

  /**
   * Variable time 3072-bit modular exponentiation with exponent 65537
   *
   * Returns: C = modexp(A,65537) = mod M
   *
   * This implements the square and multiply algorithm for the
   * F4 exponent (65537).
   *
   * The squared Montgomery modulus RR and the Montgomery constant m0' have to
   * be provided at the appropriate locations in dmem. DMEM locations are
   * expected to be disjoint.
   *
   * Flags: Flags have no meaning beyond the scope of this subroutine.
   *
   * The base bignum A is expected in the input buffer, the result C is written
   * to the output buffer.
   *
   * @param[in]  dmem[x17] pointer to m0' in dmem
   * @param[in]  dmem[x26] pointer to RR in dmem
   * @param[in]  dmem[x16] pointer to first limb of modulus M in dmem
   * @param[in]  dmem[x23] pointer to buffer with base bignum
   * @param[in]  dmem[x24] pointer to output buffer
   */

  /* Prepare all-zero register. */
  bn.xor w31, w31, w31 << 0, FG0

  /* Prepare pointers to temporary registers. */
  li x8, 4
  li x9, 3
  li x10, 4
  li x11, 2

  /* Convert input to Montgomery domain.
       [w15:w4] <= (dmem[x23]*dmem[x26]*R^-1) mod M = (A * R) mod M */
  addi x19, x23, 0
  addi x20, x26, 0
  addi x21, x24, 0
  jal x1, montmul

  /* Store Montgomery-form input in dmem.
       dmem[x24] <= [w15:w4] = (A * R) mod M */
  loopi 12, 2
    bn.sid x8, 0(x21++)
    addi x8, x8, 1

  /* 16 consecutive Montgomery squares on the outbut buffer, i.e. after loop:
       dmem[out_buf] <= dmem[out_buf]^65536*R mod M */
  loopi 16, 8

    /* dmem[out_buf]  <= montmul(dmem[out_buf], dmem[out_buf]) */
    addi x19, x24, 0
    addi x20, x24, 0
    addi x21, x24, 0
    jal x1, montmul
    loopi 12, 2
      bn.sid x8, 0(x21++)
      addi x8, x8, 1
    nop

  /* Final multiplication and conversion of result from Montgomery domain.
       out_buf  <= montmul(*x28, *x20) = montmul(dmem[in_buf], dmem[out_buf]) */
  addi x19, x23, 0
  addi x20, x24, 0
  addi x21, x24, 0
  jal x1, montmul

  /* Final conditional subtraction of modulus if mod >= dmem[out_buf]. */

  /* Speculatively subtract modulus and store in separate registers.
       [w28:w17] <= (dmem[out_buf] - M) mod 2^3072 */
  bn.add w31, w31, w31 << 0, FG0
  li x17, 16
  loopi 12, 4
    bn.movr x11, x8++
    bn.lid x9, 0(x16++)
    bn.subb w2, w2, w3 << 0, FG0
    bn.movr x17++, x11

  /* Check the borrow flag and select the post-subtraction version iff the
     subtraction underflowed. */
  csrrs x2, 1984, x0
  andi x2, x2, 1
  li x8, 4
  bne x2, x0, label_0
  li x8, 16
  label_0:

  /* Store result in dmem: dmem[out_buf] <= A^65537 mod M */
  addi x21, x24, 0
  loopi 12, 2
    bn.sid x8, 0(x21++)
    addi x8, x8, 1
  ret

.globl montmul
montmul:

  /**
   * Variable-time 3072-bit Montgomery Modular Multiplication
   *
   * Returns: C = montmul(A,B) = A*B*R^(-1) mod M
   *
   * This implements the limb-by-limb interleadved Montgomory Modular
   * Multiplication Algorithm. This is only a wrapper around the main loop body.
   * For algorithmic implementation details see the mont_loop subroutine.
   *
   * Flags: Flags have no meaning beyond the scope of this subroutine.
   *
   * @param[in]  x16: dptr_M, dmem pointer to first limb of modulus M
   * @param[in]  x17: dptr_m0d, dmem pointer to Montgomery Constant m0'
   * @param[in]  x19: dptr_a, dmem pointer to first limb of operand A
   * @param[in]  x20: dptr_b, dmem pointer to first limb of operand B
   * @param[in]  w31: all-zero
   * @param[in]  x9: pointer to temp reg, must be set to 3
   * @param[in]  x10: pointer to temp reg, must be set to 4
   * @param[in]  x11: pointer to temp reg, must be set to 2
   * @param[out] [w15:w4]: result C
   */

  /* Load Montgomery constant: w3 <= m0' */
  bn.lid x9, 0(x17)

  /* Initialize result buffer with zeroes. */
  bn.mov w2, w31
  loopi 12, 1
    bn.movr x10++, x11

  /* Iterate over limbs of input operand. */
  loopi 12, 6

    /* Load limb of operand. */
    bn.lid x11, 0(x20++)

    /* Save some register values. */
    addi x6, x16, 0
    addi x7, x19, 0

    /* Main loop body of Montgomery multiplication algorithm. */
    jal x1, mont_loop

    /* Restore registers. */
    addi x16, x6, 0
    addi x19, x7, 0

  /* Restore pointers. */
  li x8, 4
  li x10, 4
  ret

mont_loop:

  /**
  * Main loop body for variable-time 3072-bit Montgomery Modular Multiplication
  *
  * Returns: C <= (C + A*b_i + M*m0'*(C[0] + A[0]*b_i))/(2^WLEN) mod R
  *
  * This implements the main loop body for the Montgomery Modular Multiplication
  * as well as the conditional subtraction. See e.g. Handbook of Applied
  * Cryptography (HAC) 14.36 (steps 2.1 and 2.2) and step 3.
  * This subroutine has to be called for every iteration of the loop in step 2
  * of HAC 14.36, i.e. once per limb of operand B (x in HAC notation). The limb
  * is supplied via w2. In the comments below, the index i refers to the
  * i_th call to this subroutine within one full Montgomery Multiplication run.
  * Step 3 of HAC 14.36 is replaced by the approach to perform the conditional
  * subtraction when the intermediate result is larger than R instead of m. See
  * e.g. https://eprint.iacr.org/2017/1057 section 2.4.2 for a justification.
  * This does not omit the conditional subtraction.
  * Variable names of HAC are mapped as follows to the ones used in the
  * this library: x=B, y=A, A=C, b=2^WLEN, m=M, R=R, m' = m0', n=N.
  *
  * Flags: The states of both FG0 and FG1 depend on intermediate values and are
  *        not usable after return.
  *
  * @param[in]  x16: dmem pointer to first limb of modulus M
  * @param[in]  x19: dmem pointer to first limb operand A
  * @param[in]  w2:  current limb of operand B, b_i
  * @param[in]  w3:  Montgomery constant m0'
  * @param[in]  w31: all-zero
  * @param[in]  [w15:w4] intermediate result A
  * @param[out] [w15:w4] intermediate result A
  *
  */

  /* Save pointer to modulus. */
  addi x22, x16, 0

  /* Pointers to temporary registers. */
  li x12, 30
  li x13, 24

  /* Buffer read pointer. */
  li x8, 4

  /* Buffer write pointer. */
  li x10, 4

  /* Load 1st limb of input y (operand a): w30 = y[0] */
  bn.lid x12, 0(x19++)

  /* [w26, w27] = w30*w2 = y[0]*xi */
  jal x1, mul256_w30xw2

  /* w24 = w4 = A[0] */
  bn.movr x13, x8++

  /* add A[0]: [w29, w30] = [w26, w27] + w24 = y[0]*xi + A[0] */
  bn.add w30, w27, w24 << 0, FG0
  bn.addc w29, w26, w31 << 0, FG0

  /* w25 = w3 = m0d */
  bn.mov w25, w3

  /* [_, ui] = [w26, w27] = w30*w25 = (y[0]*xi + A[0])*m0d*/
  jal x1, mul256_w30xw25

  /* [_, ui] = [w28, w25] = [w26, w27]  */
  bn.mov w25, w27

  /* w24 <= w30 =  y[0]*xi + A[0] mod b */
  bn.mov w24, w30

  /* Load first limb of modulus: w30 <= m[0]. */
  bn.lid x12, 0(x16++)

  /* [w26, w27] = w30*w25 = m[0]*ui */
  jal x1, mul256_w30xw25

  /* [w28, w27] <= [w26, w27] + w24 = m[0]*ui + (y[0]*xi + A[0] mod b) */
  bn.add w27, w27, w24 << 0, FG0
  bn.addc w28, w26, w31 << 0, FG0

  /* This loop implements step 2.2 of HAC 14.36 with a word-by-word approach.
     The loop body is subdivided into two steps. Each step performs one
     multiplication and subsequently adds two WLEN sized words to the
     2WLEN-sized result, such that there are no overflows at the end of each
     step-
     Two carry words are required between the cycles. Those are c_xy and c_m.
     Assume that the variable j runs from 1 to N-1 in the explanations below.
     A cycle 0 is omitted, since the results from the computations above are
     re-used */
  loopi 11, 14

    /* Load limb of y (operand a): w30 <= y[j] */
    bn.lid x12, 0(x19++)

    /* Load limb of buffer: w24 <= A[j] */
    bn.movr x13, x8++

    /* Multiply y[j]*xi, add A[j], and add carry from previous iteration:
         [w26, w27] <= w30*w2 + w24 + w29 = y[j]*x_i + A[j] + c_xy */
    jal x1, mul256_w30xw2
    bn.add w27, w27, w24 << 0, FG0
    bn.addc w26, w26, w31 << 0, FG0
    bn.add w24, w27, w29 << 0, FG0
    bn.addc w29, w26, w31 << 0, FG0

    /* Step 2:  Second multiplication computes the product of a limb m[j] of
       the modulus with u_i. The 2nd carry word from the previous loop cycle
       c_m and the lower word a_tmp of the result of Step 1 are added. */

    /* Load limb m[j] of modulus: w30 <= m[j] */
    bn.lid x12, 0(x16++)

    /* Multiply with ui and add result from first step:
         [w28, w24] <= w30*w25 + w24 + w28 = m[j]*ui + a_tmp + c_m */
    jal x1, mul256_w30xw25
    bn.add w27, w27, w24 << 0, FG0
    bn.addc w26, w26, w31 << 0, FG0
    bn.add w24, w27, w28 << 0, FG0
    bn.addc w28, w26, w31 << 0, FG0

    /* store at w[4+j] = A[j-1]
       This includes the reduction by 2^WLEN = 2^b in step 2.2 of HAC 14.36 */
    bn.movr x10++, x13

  /* Most significant limb of A is sum of the carry words of last loop cycle.
     A[N-1] = w24 <- w29 + w28 = c_xy + c_m */
  bn.add w24, w29, w28 << 0, FG1
  bn.movr x10++, x13

  /* Clear flag group 0. */
  bn.add w31, w31, w31 << 0, FG0

  /* The below replaces Step 3 of HAC 14.36 and performs conditional
     subtraction of the modulus from the output buffer.  */

  /* Read carry flag 1 into a register: x2 <= FG1.C */
  csrrs x2, 1985, x0
  andi x2, x2, 1

  /* Subtract modulus if the carry was 1; otherwise skip. */
  beq x2, x0, label_1
  li x12, 30
  li x13, 24
  addi x16, x22, 0
  li x8, 4
  loopi 12, 4
    bn.lid x13, 0(x16++)
    bn.movr x12, x8
    bn.subb w24, w30, w24 << 0, FG0
    bn.movr x8++, x13
  label_1:

  /* Restore pointers. */
  li x8, 4
  li x10, 4
  ret

mul256_w30xw2:

  /**
   * Unrolled 512=256x256 bit multiplication.
   *
   * Returns c = a x b.
   *
   * Flags: No flags are set in this subroutine
   *
   * @param[in] w30: a, first operand
   * @param[in] w2: b, second operand
   * @param[out] [w26, w27]: c, result
   */
  bn.mulqacc.z w30.0, w2.0, 0
  bn.mulqacc w30.1, w2.0, 64
  bn.mulqacc.so w27.L, w30.0, w2.1, 64, FG0
  bn.mulqacc w30.2, w2.0, 0
  bn.mulqacc w30.1, w2.1, 0
  bn.mulqacc w30.0, w2.2, 0
  bn.mulqacc w30.3, w2.0, 64
  bn.mulqacc w30.2, w2.1, 64
  bn.mulqacc w30.1, w2.2, 64
  bn.mulqacc.so w27.U, w30.0, w2.3, 64, FG0
  bn.mulqacc w30.3, w2.1, 0
  bn.mulqacc w30.2, w2.2, 0
  bn.mulqacc w30.1, w2.3, 0
  bn.mulqacc w30.3, w2.2, 64
  bn.mulqacc.so w26.L, w30.2, w2.3, 64, FG0
  bn.mulqacc.so w26.U, w30.3, w2.3, 0, FG0
  ret

mul256_w30xw25:

  /**
   * Unrolled 512=256x256 bit multiplication.
   *
   * Returns c = a x b.
   *
   * Flags: No flags are set in this subroutine
   *
   * @param[in] w30: a, first operand
   * @param[in] w25: b, second operand
   * @param[out] [w26, w27]: c, result
   */
  bn.mulqacc.z w30.0, w25.0, 0
  bn.mulqacc w30.1, w25.0, 64
  bn.mulqacc.so w27.L, w30.0, w25.1, 64, FG0
  bn.mulqacc w30.2, w25.0, 0
  bn.mulqacc w30.1, w25.1, 0
  bn.mulqacc w30.0, w25.2, 0
  bn.mulqacc w30.3, w25.0, 64
  bn.mulqacc w30.2, w25.1, 64
  bn.mulqacc w30.1, w25.2, 64
  bn.mulqacc.so w27.U, w30.0, w25.3, 64, FG0
  bn.mulqacc w30.3, w25.1, 0
  bn.mulqacc w30.2, w25.2, 0
  bn.mulqacc w30.1, w25.3, 0
  bn.mulqacc w30.3, w25.2, 64
  bn.mulqacc.so w26.L, w30.2, w25.3, 64, FG0
  bn.mulqacc.so w26.U, w30.3, w25.3, 0, FG0
  ret

