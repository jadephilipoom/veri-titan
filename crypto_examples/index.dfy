include "omega.dfy"
include "bins.dfy"

module rindex {
    import opened Power
    import opened Power2
    import opened Seq
    import opened Mul
    import opened DivMod

    import opened omegas
    import opened pows_of_2
    import opened bins

    type uint1   =  i: nat | i < 2

    datatype index_raw = index_cons(v: nat, bins: seq<uint1>, bound: pow2_t)

    predicate valid_index(idx: index_raw)
    {
        && 1 <= idx.bound.exp == |idx.bins| // exp is the number of bits, we have at least 1 bit
        && idx.v < idx.bound.full
        && idx.v == ToNatRight(idx.bins)
    }

    type index_t =  i: index_raw | valid_index(i) witness *

    function method build_index(v: nat): index_t
        requires v < N;
    {
        nth_root_lemma();
        index_cons(v, FromNatWithLen(v, L), pow2(L))
    }

    lemma valid_index_correspondence(idx: index_t)
        ensures idx.v % 2 == First(idx.bins);
        ensures idx.v / 2 == ToNatRight(DropFirst(idx.bins));
    {
        pow2_basics(idx.bound);
        var lsb, v' := idx.v % 2, idx.v / 2;
        var bins' := DropFirst(idx.bins);
        reveal ToNatRight();
        assert lsb == First(idx.bins);
        assert v' == ToNatRight(bins');
    }

    function method lsb(idx: index_t): (lsb: uint1)
        ensures lsb == First(idx.bins);
    {
        valid_index_correspondence(idx);
        idx.v % 2
    }

    function method bit_rev_index(idx: index_t): (new_idx: index_raw)
        requires idx.bound.exp < N == Pow(2, L);
        ensures valid_index(new_idx);
        ensures new_idx.bins == Reverse(idx.bins);
        // ensures forall i: 0 <= i < |idx.bin| ==>
        //     new_idx.bin[i] == idx.bin[idx.bound.full - i - 1];
        decreases idx.bound.exp;
    {
        if idx.bound.exp == 1 then idx
        else pow2_basics(idx.bound);
            var lsb, v' := idx.v % 2, idx.v / 2;
            var bound' := pow2_half(idx.bound);
            var bins' := DropFirst(idx.bins);
            valid_index_correspondence(idx);
            var temp := index_cons(v', bins', bound');
            var idx' := bit_rev_index(temp);
            valid_index_correspondence(idx');
            assert idx'.v + lsb * bound'.full == ToNatRight(idx'.bins + [lsb]) by {
                calc == {
                    ToNatRight(idx'.bins + [lsb]);
                    {
                        LemmaToNatLeftEqToNatRight(idx'.bins + [lsb]);
                    }
                    ToNatLeft(idx'.bins + [lsb]);
                    {
                        reveal ToNatLeft();
                    }
                    ToNatLeft(idx'.bins) + lsb * Pow(2, idx.bound.exp - 1);
                    {
                        reveal Pow2();
                    }
                    ToNatLeft(idx'.bins) + lsb * bound'.full;
                    {
                        LemmaToNatLeftEqToNatRight(idx'.bins);
                    }
                    idx'.v + lsb * bound'.full;
                }
            }
            assert idx'.v + lsb * bound'.full < idx.bound.full by {
                LemmaSeqNatBound(idx'.bins + [lsb]);
                reveal Pow2();
            }
            assert idx'.bins + [lsb] == Reverse(idx.bins) by {
                reveal Reverse();
            }
            index_cons(idx'.v + lsb * bound'.full, idx'.bins + [lsb], idx.bound)
    }

    predicate ntt_indicies_wf(idxs: seq<index_t>, len: pow2_t)
    {
        && len.exp <= L
        && |idxs| == len.full
        && (forall i: nat :: i < len.full ==> 
            idxs[i].bound == pow2(L))
    }

    function orignal_index(which_chunk: nat, which_slot: nat, len: pow2_t): index_t
        requires len.full <= N == Pow2(L)
        requires len.exp <= L
        requires which_chunk < pow2_div(pow2(L), len).full
        requires which_slot < len.full
    {
        LemmaMulStrictlyPositive(which_chunk, len.full);
        assert Pow2(L - len.exp) == N / len.full;
        var temp := Pow2(L - len.exp) - 1;
        assert which_chunk * len.full <= N - len.full by {
            LemmaMulInequality(which_chunk, temp, len.full);
            assert which_chunk * len.full <= temp * len.full;
            LemmaMulIsDistributiveAuto();
        }
        build_index(which_chunk * len.full + which_slot)
    }

    predicate ntt_indicies_inv(idxs: seq<index_t>, len: pow2_t, k: nat)
    {
        && N == Pow2(L)
        && len.full <= N
        && len.exp <= L
        && k < pow2_div(pow2(L), len).full
        && ntt_indicies_wf(idxs, len)
        && var offset := L - len.exp;
        && (forall i: nat | i < len.full :: (
            && var orignal := orignal_index(k, i, len);
            // the higher bits equal to i
            && ToNatRight(idxs[i].bins[offset..]) == i
            // the lower bits equal to the reverse of the original index (up to offset)
            && idxs[i].bins[..offset] == Reverse(orignal.bins[len.exp..])))
        && (forall i: nat, j: nat | i < len.full && j < len.full ::
            && idxs[i].bins[..offset] == idxs[j].bins[..offset])
    }

    // base case happens at level 1, chuck size is the whole array
    lemma ntt_indicies_inv_base_case(idxs: seq<index_t>, len: pow2_t, k: nat)
        requires len == pow2(L);
        requires k < pow2_div(pow2(L), len).full;
        requires ntt_indicies_wf(idxs, len);
        requires forall i: nat :: i < len.full ==> idxs[i].v == i;
        ensures ntt_indicies_inv(idxs, len, k);
    {
        forall i: nat | i < len.full
            ensures ToNatRight(idxs[i].bins[0..]) == i;
        {
            calc == {
                ToNatRight(idxs[i].bins[0..]);
                ToNatRight(idxs[i].bins);
                idxs[i].v;
                i;
            }
        }

        nth_root_lemma();
        assert k == 0;

        forall i: nat | i < len.full
            ensures idxs[i].bins[..0] == Reverse(orignal_index(0, i, len).bins)[..0];
        {
        }
        forall i: nat, j: nat | i < len.full && j < len.full
            ensures idxs[i].bins[..0] == idxs[j].bins[..0];
        {
        }
    }

    function method even_indexed_indices(idxs: seq<index_t>, len: pow2_t): (idx': seq<index_t>)
        requires |idxs| == len.full >= 2;
        ensures |idx'| == len.full / 2;
    {
        pow2_basics(len);
        seq(len.full/2, n requires 0 <= n < len.full/2 => idxs[n * 2])
    }

    lemma even_indexed_indices_reorder(idxs: seq<index_t>, len: pow2_t, idxs': seq<index_t>, k: nat)
        requires len.full >= 2;
        requires ntt_indicies_inv(idxs, len, k); 
        requires k < pow2_div(pow2(L), len).full
        requires even_indexed_indices(idxs, len) == idxs';
        ensures ntt_indicies_inv(idxs', pow2_half(len), k * 2);
    {
        var len' := pow2_half(len);
        assert ntt_indicies_wf(idxs', len');

        var offset := L - len.exp;
        var offset' := offset + 1;

        forall i: nat | i < len'.full
            ensures ToNatRight(idxs'[i].bins[offset'..]) == i
            ensures idxs'[i].bins[offset] == 0
        {
            var bins := idxs[i * 2].bins;
            assert bins == idxs'[i].bins;

            var prev := bins[offset..];
            var curr := bins[offset'..];

            calc == {
                2 * i;
                ToNatRight(prev);
                {
                    assert [bins[offset]] + curr == prev;
                    assert DropFirst(prev) == curr;
                    reveal ToNatRight();
                }
                ToNatRight(curr) * 2 + bins[offset];
            }

            assert bins[offset] == 0 by {
                LemmaSeqLswModEquivalence(prev);
                assert ToNatRight(prev) == 2 * i;
            }

            assert 2 * i == ToNatRight(curr) * 2;

            calc == {
                i;
                ToNatRight(curr);
                ToNatRight(idxs'[i].bins[offset'..]);
            }
        }

        forall i: nat, j: nat | i < len'.full && j < len'.full
            ensures idxs'[i].bins[..offset'] == idxs'[j].bins[..offset']
        {
            var i_bins := idxs[i * 2].bins;
            assert i_bins == idxs'[i].bins;

            var j_bins := idxs[j * 2].bins;
            assert j_bins == idxs'[j].bins;

            assert i_bins[..offset] == j_bins[..offset];

            calc == {
                i_bins[..offset'];
                i_bins[..offset] + [i_bins[offset]];
                i_bins[..offset] + [0];
                j_bins[..offset] + [j_bins[offset]];
                j_bins[..offset'];
            }
        }

        var k' := k * 2;

        calc {
            k';
            k * 2;
        <   
            pow2(L - len.exp).full * 2;
            { pow2_basics(pow2(1)); }
            pow2(L - len.exp).full * pow2(1).full;
            { var _ := pow2_mul(pow2(L - len.exp), pow2(1)); }
            pow2(L - len.exp + 1).full;
            pow2(L - len'.exp).full;
            { var _ := pow2_div(pow2(L), pow2(len.exp)); }
            pow2_div(pow2(L), len').full;
        }

        forall i: nat | i < len'.full
            ensures idxs'[i].bins[..offset'] ==
                Reverse(orignal_index(k', i, len').bins[len'.exp..])
        {
            pow2_basics(len);

            var orignal := orignal_index(k', i, len');

            calc == {
                orignal.v;
                k' * len'.full + i;
                2 * k * (len.full / 2) + i;
                {
                    LemmaMulIsAssociativeAuto();
                }
                k * (2 * (len.full / 2)) + i;
                k * len.full + i;
            }

            assert orignal_index(k, i, len) == orignal;

            calc == {
                idxs'[i].bins[..offset];
                idxs[i].bins[..offset];
                Reverse(orignal.bins[len.exp..]);
            }

            var obins := orignal.bins;

            calc == {
                obins[len.exp-1];
                {
                    BitSelModEquivalence(obins, len.exp-1);
                }
                (ToNatRight(obins) / Pow(2, len.exp-1)) % 2;
                {
                    assert Pow(2, len.exp-1) == Pow(2, len'.exp);
                    reveal Pow2();
                    assert Pow(2, len'.exp) == len'.full;
                }
                (orignal.v / len'.full) % 2;
                ((k' * len'.full + i) / len'.full) % 2;
                {
                    LemmaFundamentalDivModConverse(orignal.v, len'.full, k', i);
                    assert (k' * len'.full + i) / len'.full == k';
                }
                k' % 2;
                0;
            }

            calc == {
                Reverse(obins[len'.exp..]);
                Reverse(obins[len.exp-1..]);
                {
                    SubSeqReverseProperty(obins, len.exp);
                }
                Reverse(obins[len.exp..]) + [obins[len.exp-1]];
                idxs'[i].bins[..offset] + [obins[len.exp-1]];
                idxs'[i].bins[..offset] + [0];
                idxs'[i].bins[..offset'];
            }
        }
    }

    function method odd_indexed_indices(idxs: seq<index_t>, len: pow2_t): (idx': seq<index_t>)
        requires |idxs| == len.full >= 2;
        ensures |idx'| == len.full / 2;
    {
        pow2_basics(len);
        seq(len.full/2, n requires 0 <= n < len.full/2 => idxs[n * 2 + 1])
    }

    lemma odd_indexed_indices_reorder(idxs: seq<index_t>, len: pow2_t, idxs': seq<index_t>, k: nat)
        requires len.full >= 2;
        requires ntt_indicies_inv(idxs, len, k); 
        requires k < pow2_div(pow2(L), len).full
        requires odd_indexed_indices(idxs, len) == idxs';
        ensures ntt_indicies_inv(idxs', pow2_half(len), k * 2 + 1);
    {
        var len' := pow2_half(len);
        assert ntt_indicies_wf(idxs', len');

        var offset := L - len.exp;
        var offset' := offset + 1;

        forall i: nat | i < len'.full
            ensures ToNatRight(idxs'[i].bins[offset'..]) == i
            ensures idxs'[i].bins[offset] == 1
        {
            var bins := idxs[i * 2+1].bins;
            assert bins == idxs'[i].bins;

            var prev := bins[offset..];
            var curr := bins[offset'..];

            calc == {
                2 * i + 1;
                ToNatRight(prev);
                {
                    assert [bins[offset]] + curr == prev;
                    assert DropFirst(prev) == curr;
                    reveal ToNatRight();
                }
                ToNatRight(curr) * 2 + bins[offset];
            }

            assert bins[offset] == 1 by {
                LemmaSeqLswModEquivalence(prev);
                assert ToNatRight(prev) == 2 * i + 1;
            }

            assert 2 * i == ToNatRight(curr) * 2;

            calc == {
                i;
                ToNatRight(curr);
                ToNatRight(idxs'[i].bins[offset'..]);
            }
        }

        forall i: nat, j: nat | i < len'.full && j < len'.full
            ensures idxs'[i].bins[..offset'] == idxs'[j].bins[..offset']
        {
            var i_bins := idxs[i * 2+1].bins;
            assert i_bins == idxs'[i].bins;

            var j_bins := idxs[j * 2+1].bins;
            assert j_bins == idxs'[j].bins;

            assert i_bins[..offset] == j_bins[..offset];

            calc == {
                i_bins[..offset'];
                i_bins[..offset] + [i_bins[offset]];
                i_bins[..offset] + [1];
                j_bins[..offset] + [j_bins[offset]];
                j_bins[..offset'];
            }
        }

        var k' := k * 2 + 1;

        calc {
            k';
            k * 2 + 1;
        <   
            pow2(L - len.exp).full * 2 + 1;
            { pow2_basics(pow2(1)); }
            pow2(L - len.exp).full * pow2(1).full + 1;
            { var _ := pow2_mul(pow2(L - len.exp), pow2(1)); }
            pow2(L - len.exp + 1).full + 1;
            pow2(L - len'.exp).full + 1;
            { var _ := pow2_div(pow2(L), pow2(len.exp)); }
            pow2_div(pow2(L), len').full + 1;
        }

        assert k' < pow2_div(pow2(L), len').full by {
            pow2_basics(pow2_div(pow2(L), len'));
            assert k' != pow2_div(pow2(L), len').full;
        }

        forall i: nat | i < len'.full
            ensures idxs'[i].bins[..offset'] ==
                Reverse(orignal_index(k', i, len').bins[len'.exp..])
        {
            pow2_basics(len);

            var orignal := orignal_index(k', i, len');

            calc == {
                orignal.v;
                k' * len'.full + i;
                (2 * k + 1) * (len.full / 2) + i;
                {
                    LemmaMulIsDistributiveAuto();
                }
                2 * k * (len.full / 2) + len.full / 2 + i;
                {
                    LemmaMulIsAssociativeAuto();
                }
                k * (2 * (len.full / 2)) + len.full / 2 + i;
                k * len.full + len.full / 2 + i;
                k * len.full + len'.full + i;
            }
    
            assert orignal_index(k, len'.full + i, len) == orignal;

            calc == {
                idxs'[i].bins[..offset];
                idxs[i].bins[..offset];
                Reverse(orignal.bins[len.exp..]);
            }
    
            var obins := orignal.bins;

            calc == {
                obins[len.exp-1];
                {
                    BitSelModEquivalence(obins, len.exp-1);
                }
                (ToNatRight(obins) / Pow(2, len.exp-1)) % 2;
                {
                    assert Pow(2, len.exp-1) == Pow(2, len'.exp);
                    reveal Pow2();
                    assert Pow(2, len'.exp) == len'.full;
                }
                (orignal.v / len'.full) % 2;
                ((k' * len'.full + i) / len'.full) % 2;
                {
                    LemmaFundamentalDivModConverse(orignal.v, len'.full, k', i);
                    assert (k' * len'.full + i) / len'.full == k';
                }
                k' % 2;
                1;
            }

            calc == {
                Reverse(obins[len'.exp..]);
                Reverse(obins[len.exp-1..]);
                {
                    SubSeqReverseProperty(obins, len.exp);
                }
                Reverse(obins[len.exp..]) + [obins[len.exp-1]];
                idxs'[i].bins[..offset] + [obins[len.exp-1]];
                idxs'[i].bins[..offset] + [1];
                idxs'[i].bins[..offset'];
            }
        }
    }

    lemma ntt_indicies_inv_consequence(idxs: seq<index_t>, len: pow2_t, k: nat)
        requires len == pow2(1);
        requires ntt_indicies_inv(idxs, len, k);
        requires k < pow2_div(pow2(L), len).full
        ensures forall i: nat | i < len.full ::
            idxs[i].bins == Reverse(orignal_index(k, i, len).bins);
    {
        var offset := L - 1;
        pow2_basics(len);

        forall i: nat | i < len.full
            ensures idxs[i].bins == Reverse(orignal_index(k, i, len).bins);
        {
            var orignal := orignal_index(k, i, len);
            var obins := orignal.bins;
            var bins := idxs[i].bins;

            calc ==> {
                ToNatRight(bins[offset..]) == i;
                {
                    LemmaSeqLen1(bins[offset..]);
                }
                bins[offset..][0] == i;
                bins[offset] == i;
            }

            calc == {
                obins[0];
                {
                    LemmaSeqLswModEquivalence(obins);
                }
                orignal.v % 2;
                (k * len.full + i) % 2;
                {
                    LemmaMulIsCommutativeAuto();
                }
                (len.full * k + i) % 2;
                {
                    LemmaAddModNoop(len.full * k, i, 2);
                }
                ((len.full * k) % 2 + i % 2) % 2;
                {
                    pow2_basics(len);
                    assert (len.full * k) % 2 == 0;
                }
                (i % 2) % 2;
                i % 2;
                i;
            }

            calc == {
                bins;
                bins[..L-1] + [bins[offset]];
                {
                    assert bins[..L-1] == Reverse(obins[1..]);
                }
                Reverse(obins[1..]) + [bins[offset]];
                Reverse(obins[1..]) + [i];
                Reverse(obins[1..]) + [obins[0]];
                {
                    SubSeqReverseProperty(obins, 1);
                }
                Reverse(obins[0..]);
                Reverse(obins);
            }
        }
    }
}