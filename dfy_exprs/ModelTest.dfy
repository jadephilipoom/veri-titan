include "SystemFFI.dfy"
include "BitVector.dfy"
include "NativeTypes.dfy"

include "../otbn_model/lib/powers.dfy"
include "../otbn_model/lib/congruences.dfy"

import opened CutomBitVector
import opened NativeTypes

// method ArrayFromSeq<A>(s: seq<A>) returns (a: array<A>)
//   ensures a[..] == s
// {
//     a := new A[|s|] ( i requires 0 <= i < |s| => s[i] );
// }

method get_random_bv(l: uint32) returns (v: cbv)
{
    var a := new uint1[l];
    var i := 0;

    while i < l
        decreases l - i;
        invariant i <= l;
    {
        var b := SystemFFI.GetRandomBit();
        a[i] := b as uint1;
        i := i + 1;
    }

    v := a[..];
}

method simple_test(x: cbv)
    requires |x| == 768;
{
    var r1: cbv := cbv_slice(x, 0, 385);
    var q1: cbv := cbv_lsr(x, 383);
}

method {:main} Main()
{
    var v := get_random_bv(20);
    log_input("x", v);
}
