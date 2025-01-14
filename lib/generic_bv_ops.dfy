include "../std_lib/src/Collections/Sequences/LittleEndianNat.dfy"
include "../std_lib/src/BoundedInts.dfy"

module integers
{
    import BoundedInts

    const BASE_1   : int := BoundedInts.TWO_TO_THE_1
    const BASE_2   : int := BoundedInts.TWO_TO_THE_2
    const BASE_4   : int := BoundedInts.TWO_TO_THE_4
    const BASE_5   : int := BoundedInts.TWO_TO_THE_5
    const BASE_8   : int := BoundedInts.TWO_TO_THE_8
    const BASE_16  : int := BoundedInts.TWO_TO_THE_16
    const BASE_31  : int := 0x80000000
    const BASE_32  : int := BoundedInts.TWO_TO_THE_32
    const BASE_63  : int := 0x80000000_00000000
    const BASE_64  : int := BoundedInts.TWO_TO_THE_64
    const BASE_128 : int := BoundedInts.TWO_TO_THE_128
    const BASE_192 : int := 0x1_00000000_00000000_00000000_00000000_00000000_00000000
    const BASE_256 : int := BoundedInts.TWO_TO_THE_256
    const BASE_512 : int := BoundedInts.TWO_TO_THE_512

    type uint1   = i :int | 0 <= i < BASE_1
    type uint2   = i :int | 0 <= i < BASE_2
    type uint4   = i :int | 0 <= i < BASE_4
    type uint5   = i :int | 0 <= i < BASE_5
    type uint10  = i :int | 0 <= i < 1024
    type uint12  = i :int | 0 <= i < 4096
    type uint32  = i :int | 0 <= i < BASE_32
    type uint64  = i :int | 0 <= i < BASE_64
    type uint128 = i :int | 0 <= i < BASE_128
    type uint192 = i :int | 0 <= i < BASE_192
    type uint256 = i :int | 0 <= i < BASE_256
    type uint512 = i :int | 0 <= i < BASE_512

    type int10   = i :int | -512 <= i <= 511
    type int12   = i :int | -2048 <= i <= 2047
    type int32   = i :int | -BASE_31 <= i <= (BASE_31 - 1)
    type int64   = i :int | -BASE_63 <= i <= (BASE_63 - 1)
}

abstract module generic_bv_ops
{
    import opened BVSEQ: LittleEndianNat
    import Mul
    import DivMod

    import integers

    type uint1 = integers.uint1

    // the signed version of uint
    type sint = i: int | -(BASE()/2 as int) <= i < BASE()/2 as int

    // half word base
    function method HW_BASE(): nat
        ensures 1 < HW_BASE() < BASE()
        ensures HW_BASE() * HW_BASE() == BASE()

    // double word base
    function method DW_BASE(): nat
    {
        Mul.LemmaMulStrictlyPositiveAuto();
        BASE() * BASE()
    }

    function method bool_to_uint1(i:bool): uint1
    {
        if i then 1 else 0
    }

    function method and(x: uint, y: uint): uint

    function method andi(x: uint, imm: sint): uint
    {
        and(x, to_2s_comp(imm))
    }

    function method or(x: uint, y: uint): uint

    function method not(x: uint) : uint

    function method xor(x: uint, y: uint): uint

    lemma {:axiom} xor_clear_lemma(x: uint, y: uint)
        ensures (x == y) <==> (xor(x, y) == 0)

    predicate valid_shift(amount: uint)

    function method rs(x: uint, amount: uint): uint
        requires valid_shift(amount)

    function method ls(x: uint, amount: uint): uint
        requires valid_shift(amount)

    function method {:opaque} lsb(x: uint): uint1
    {
        x % 2
    }

    function method msb(x: uint): uint1

/* addition */

    function method addc(x: uint, y: uint, cin: uint1): (uint, uint1)
    {
        var sum : int := x + y + cin;
        var sum_out := if sum < BASE() then sum else sum - BASE();
        var cout := if sum  < BASE() then 0 else 1;
        (sum_out, cout)
    }

    function method add(x: uint, y: uint): uint
    {
        addc(x, y, 0).0
    }

    function method to_2s_comp(n: sint): uint
    {
        if n < 0 then n + BASE() else n
    }

    function method addi(x: uint, imm: sint): uint
    {
        add(x, to_2s_comp(imm))
    }

/* subtraction */

    function method subb(x: uint, y: uint, bin: uint1): (uint, uint1)
    {
        var diff : int := x - y - bin;
        var diff_out := if diff >= 0 then diff else diff + BASE();
        var bout := if diff >= 0 then 0 else 1;
        (diff_out, bout)
    }

    function method sub(x: uint, y: uint): uint
    {
        subb(x, y, 0).0
    }

    function method mul(x: uint, y: uint): uint
    {
        full_mul_bound_lemma(x, y);
        dw_lh(x * y)
    }

/* upper/lower half split */

    lemma upper_half_bound_lemma(x: nat, base: nat, half_base: nat)
        requires x < base
        requires 1 < half_base
        requires base == half_base * half_base
        ensures 0 <= x / half_base < half_base
    {
        var lh, uh := x % half_base, x / half_base;

        DivMod.LemmaFundamentalDivMod(x, half_base);

        assert x == half_base * uh + lh;

        if uh > half_base {
            Mul.LemmaMulIsCommutativeAuto();
            Mul.LemmaMulInequalityAuto();
            assert false;
        }
        DivMod.LemmaDivPosIsPos(x, half_base);
    }

    function method {:opaque} lh(x: uint): uint
        ensures lh(x) < HW_BASE()
    {
        x % HW_BASE()
    }

    function method {:opaque} uh(x: uint): uint
        ensures uh(x) < HW_BASE()
    {
        upper_half_bound_lemma(x, BASE(), HW_BASE());
        x / HW_BASE()
    }

    lemma half_split_lemma(x: uint)
        ensures x == lh(x) + uh(x) * HW_BASE();
    {
        DivMod.LemmaFundamentalDivMod(x, HW_BASE());
        Mul.LemmaMulIsCommutativeAuto();
        reveal lh();
        reveal uh();
    }

    function method {:opaque} dw_lh(x: nat): uint
        requires x < DW_BASE()
    {
        x % BASE()
    }

    function method {:opaque} dw_uh(x: nat): uint
        requires x < DW_BASE()
    {
        upper_half_bound_lemma(x, DW_BASE(), BASE());
        x / BASE()
    }

    lemma dw_split_lemma(x: nat)
        requires x < DW_BASE()
        ensures x == dw_lh(x) + dw_uh(x) * BASE();
    {
        DivMod.LemmaFundamentalDivMod(x, BASE());
        Mul.LemmaMulIsCommutativeAuto();
        reveal dw_lh();
        reveal dw_uh();
    }

/* mul_add bounds */

    lemma full_mul_bound_lemma(a: uint, b: uint)
        ensures 0 <= a * b < DW_BASE();
        ensures 0 <= a * b <= (BASE() - 1) * (BASE() - 1)
    {
        var full := a * b;

        assert full <= (BASE() - 1) * (BASE() - 1) by {
            Mul.LemmaMulUpperBoundAuto();
        }

        assert full < BASE() * BASE() by {
            calc <= {
                full;
                (BASE() - 1) * (BASE() - 1);
                { Mul.LemmaMulIsDistributiveSubAuto(); }
                (BASE() - 1) * BASE() - (BASE() - 1);
                {
                    Mul.LemmaMulIsCommutativeAuto();
                    Mul.LemmaMulIsDistributiveSubAuto();
                }
                BASE() * BASE() - BASE() - (BASE() - 1);
                BASE() * BASE() - 2 * BASE() + 1;
            }
        }

        Mul.LemmaMulStrictlyPositiveAuto();
    }

    lemma mul_add_bound_lemma(a: uint, b: uint, c: uint)
       ensures a * b + c < DW_BASE();
    {
        var u := BASE() - 1;
        calc {
            a * b + c;
            <= { full_mul_bound_lemma(a, b); }
            u * u + c;
            <=
            u * u + u;
            == { Mul.LemmaMulIsDistributiveAddAuto(); }
            u * (u + 1); 
            <  { Mul.LemmaMulLeftInequality(u + 1, u, u + 1); }
            (u + 1) * (u + 1); 
            ==
            DW_BASE();
        }
    }
    
    lemma mul_double_add_bound_lemma(a: uint, b: uint, c: uint, d: uint)
        ensures a * b + c + d < DW_BASE();
    {
        var u := BASE() - 1;

        calc {
            a * b + c + d;
            <= { full_mul_bound_lemma(a, b); }
            u * u + c + d;
            <= u * u + u + u;
            u * u + 2 * u;
            < (u * u) + (2 * u) + 1;
        }

        calc == {
            (u + 1) * (u + 1);
            { Mul.LemmaMulIsDistributiveAdd(u + 1, u, 1); }
            (u + 1) * u + (u + 1) * 1; 
            u * (u + 1) + u + 1;
            { Mul.LemmaMulIsDistributiveAdd(u, u, 1); }
            (u * u) + (2 * u) + 1;
        }
    }
}