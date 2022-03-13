// msp430-elf-gcc hello.c -O3 -S --no-inline

#include <stdio.h>
#include <stdint.h>

#define RSANUMWORDS 192 

uint32_t mul32(uint16_t a, uint16_t b) {
  return (uint32_t)a*b;
}

uint32_t mula32(uint16_t a, uint16_t b, uint16_t c) {
  return (uint32_t)a*b+c;
}

uint32_t mulaa32(uint16_t a, uint16_t b, uint16_t c, uint16_t d) {
  return (uint32_t)a*b+c+d;
}

/**
 * a[] -= mod
 */
void sub_mod(uint16_t *a, const uint16_t *n)
{
  int32_t A = 0;
  uint16_t i;
  for (i = 0; i < RSANUMWORDS; ++i) {
    A += (uint32_t)a[i] - n[i];
    a[i] = (uint16_t)A;
    A >>= 16;
  }
}

/**
 * Return a[] >= mod
 */
int ge_mod(const uint16_t *a, const uint16_t *n)
{
  uint16_t i;
  for (i = RSANUMWORDS; i;) {
    --i;
    if (a[i] < n[i])
      return 0;
    if (a[i] > n[i])
      return 1;
  }
  return 1;  /* equal */
}

/**
 * Montgomery c[] += a * b[] / R % mod
 */
void mont_mul_add(const uint16_t d0inv,
      uint16_t *c,
      const uint16_t a,
      const uint16_t *b,
      const uint16_t *n)
{
  uint32_t A = mula32(a, b[0], c[0]);
  uint16_t d0 = (uint16_t)A * d0inv;
  uint32_t B = mula32(d0, n[0], (uint16_t)A);
  uint16_t i;
  for (i = 1; i < RSANUMWORDS; ++i) {
    A = mulaa32(a, b[i], c[i], A >> 16);
    B = mulaa32(d0, n[i], (uint16_t)A, B >> 16);
    c[i - 1] = (uint16_t)B;
  }
  A = (A >> 16) + (B >> 16);
  c[i - 1] = (uint16_t)A;
  if (A >> 16)
    sub_mod(c, n);
}

/**
 * Montgomery c[] = a[] * b[] / R % mod
 */
void mont_mul(const uint16_t d0inv,
         uint16_t *c,
         const uint16_t *a,
         const uint16_t *b,
         const uint16_t *n)
{
  uint16_t i;
  for (i = 0; i < RSANUMWORDS; ++i)
    c[i] = 0;
  for (i = 0; i < RSANUMWORDS; ++i)
    mont_mul_add(d0inv, c, a[i], b, n);
}

/**
 * In-place public exponentiation.
 * Exponent depends is fixed to 65537
 *
 * @param rr    Precomputed constant, (R*R) mod n, considered part of key
 * @param d0inv Precomputed Montgomery constant,
 *                considered part of key d0inv=-n^(-1) mod R
 * @param n     Modulus of key
 * @param in    Input signature as little-endian array
 * @param out   Output message as little-endian array
 * @param workbuf32 Work buffer; caller must verify this is
 *      2 x RSANUMWORDS elements long.
 */
void mod_pow(const uint16_t d0inv,
        uint16_t *out,
        uint16_t *workbuf32,
        const uint16_t * rr,
        const uint16_t *n,
        uint16_t *in)
{
  uint16_t *a_r = workbuf32;
  uint16_t *aa_r = a_r + RSANUMWORDS;
  int i;

  /* Exponent 65537 */
  mont_mul(d0inv, a_r, in, rr, n);  /* a_r = a * RR / R mod M */
  for (i = 0; i < 16; i += 2) {
    mont_mul(d0inv, aa_r, a_r, a_r, n); /* aa_r = a_r * a_r / R mod M */
    mont_mul(d0inv, a_r, aa_r, aa_r, n);/* a_r = aa_r * aa_r / R mod M */
  }
  mont_mul(d0inv, out, a_r, in, n);  /* aaa = a_r * a / R mod M */

  /* Make sure aaa < mod; aaa is at most 1x mod too large. */
  if (ge_mod(out, n))
    sub_mod(out, n);
}