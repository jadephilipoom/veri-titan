include "../spec/rsa_ops.dfy"

module mont_loop_lemmas {
    import opened bv_ops
    import opened vt_ops
    import opened rsa_ops
    import opened vt_consts
    import opened powers
    import opened congruences

    lemma mont_loop_cong_lemma(
        p1: uint512_view_t,
        a0: uint256,
        y0: uint256,
        xi: uint256,
        w25: uint256,
        w26: uint256,
        m0d: uint256)

        requires a0 + y0 * xi == p1.full;
        requires to_nat([w25, w26]) == p1.lh * m0d;
        ensures cong_B256(w25, (a0 + y0 * xi) * m0d);
    {
        calc ==> {
            true;
                { reveal cong(); }
            cong_B256(a0 + y0 * xi, p1.full);
                { uint512_view_lemma(p1); }
            cong_B256(a0 + y0 * xi, p1.lh + p1.uh * BASE_256);
                {
                    cong_add_lemma_4(p1.lh, p1.uh, BASE_256);
                    reveal cong();
                }
            cong_B256(a0 + y0 * xi, p1.lh);
                { reveal cong(); }
            cong_B256(p1.lh, a0 + y0 * xi);
                { cong_mul_lemma_1(p1.lh, a0 + y0 * xi, m0d, BASE_256); }
            cong_B256(p1.lh * m0d, (a0 + y0 * xi) * m0d);
        }

        calc ==> {
            true;
                { to_nat_lemma_2([w25, w26]); }
            w25 + w26 * BASE_256 == p1.lh * m0d;
                { reveal cong();}
            cong_B256(w25 + w26 * BASE_256, p1.lh * m0d);
                { reveal cong();}
            cong_B256(w25 + w26 * BASE_256, (a0 + y0 * xi) * m0d);
                {
                    cong_add_lemma_4(w25, w26, BASE_256);
                    assert cong_B256(w25, w25 + w26 * BASE_256);
                    reveal cong();
                }
            cong_B256(w25, (a0 + y0 * xi) * m0d);
        }
    }

    lemma mont_loop_divisible_lemma(xi: uint256,
        ui: uint256,
        m0d: uint256,
        p1: uint512_view_t,
        p2: uint512_view_t,
        y0: uint256,
        m0: uint256,
        a0: uint256)

        requires p1.full == xi * y0 + a0;
        requires p2.full == ui * m0 + p1.lh;
        requires cong_B256(m0d * m0, BASE_256 - 1);
        requires cong_B256(ui, p1.full * m0d);
        ensures p2.lh == 0;
    {
        assume false; // TODO
    }

    predicate mont_loop_inv(
        xi: uint256,
        ui: uint256,
        p1: uint512_view_t,
        p2: uint512_view_t,
        y: seq<uint256>,
        m: seq<uint256>,
        prev_a: seq<uint256>,
        next_a: seq<uint256>,
        j: nat)
    {
        && |m| == |next_a| == |y| == |prev_a| == NUM_WORDS
        && (1 <= j <= NUM_WORDS)
        && (xi * to_nat(y[..j]) + ui * to_nat(m[..j]) + to_nat(prev_a[..j]) 
            == 
        to_nat([0] + next_a[..j-1]) + p2.uh * pow_B256(j) + p1.uh * pow_B256(j))
    }

    lemma mont_loop_inv_pre_lemma(
        xi: uint256,
        ui: uint256,
        m0d: uint256,
        p1: uint512_view_t,
        p2: uint512_view_t,
        y: seq<uint256>,
        m: seq<uint256>,
        a: seq<uint256>)

        requires |m| == |a| == |y| == NUM_WORDS;
        requires p1.full == xi * y[0] + a[0];
        requires p2.full == ui * m[0] + p1.lh;
        requires cong_B256(m0d * to_nat(m), BASE_256 - 1);
        requires cong_B256(ui, (a[0] + y[0] * xi) * m0d);

        ensures mont_loop_inv(xi, ui, p1, p2, y, m, a, a, 1)
    {
        assume cong_B256(m0d * m[0], BASE_256 - 1);
        mont_loop_divisible_lemma(xi, ui, m0d, p1, p2, y[0], m[0], a[0]);

        to_nat_lemma_1(y[..1]);
        to_nat_lemma_1(m[..1]);
        to_nat_lemma_1(a[..1]);

        assert p2.full == p2.uh * BASE_256 by {
            uint512_view_lemma(p2);
        }

        uint512_view_lemma(p1);

        calc {
            xi * to_nat(y[..1]) + ui * to_nat(m[..1]) + to_nat(a[..1]);
            p2.uh * pow_B256(1) + p1.uh * pow_B256(1);
                {
                    reveal to_nat();
                    assert to_nat([0]) == 0;
                }
            to_nat([0]) + p2.uh * pow_B256(1) + p1.uh * pow_B256(1);
                {
                    assert [0] + a[..0] == [0];
                }
            to_nat([0] + a[..0]) + p2.uh * pow_B256(1) + p1.uh * pow_B256(1);
        }
    }

    lemma mont_loop_inv_peri_lemma(
        xi: uint256,
        ui: uint256,
        p1: uint512_view_t,
        p2: uint512_view_t,
        next_p1: uint512_view_t,
        next_p2: uint512_view_t,
        y: seq<uint256>,
        m: seq<uint256>,
        prev_a: seq<uint256>,
        a: seq<uint256>,
        next_a: seq<uint256>,
        j: nat)

        requires 1 <= j < NUM_WORDS; // this is in the loop itself
        requires mont_loop_inv(xi, ui, p1, p2, y, m, prev_a, a, j);
        requires a[j] == prev_a[j];
        requires |next_a| == NUM_WORDS;
        requires next_p1.full == p1.uh + y[j] * xi + a[j];
        requires next_p2.full == m[j] * ui + next_p1.lh + p2.uh;
        requires next_a == a[j-1 := next_p2.lh];
        ensures mont_loop_inv(xi, ui, next_p1, next_p2, y, m, prev_a, next_a, j+1);
    {
        var y_nat := to_nat(y[..j]);
        var y_nat' := to_nat(y[..j+1]);
        var y_j := y[j];

        var m_nat := to_nat(m[..j]);
        var m_nat' := to_nat(m[..j+1]);
        var m_j := m[j];

        var ia_nat := to_nat(prev_a[..j]);
        var ia_nat' := to_nat(prev_a[..j+1]);
        var a_j := prev_a[j];

        var ea_nat := to_nat([0] + a[..j-1]);
        var ea_nat' := to_nat([0] + next_a[..j]);

        var pow_B256_j := pow_B256(j);
        var pow_B256_j' := pow_B256(j+1);

        var p1_uh := p1.uh;
        var p2_uh := p2.uh;

        assert pow_B256_j' == pow_B256_j * BASE_256 by {
            reveal power();
        }

        assert xi * y_nat + ui * m_nat + ia_nat 
            == 
        ea_nat + p2_uh * pow_B256_j +p1_uh * pow_B256_j;

        assert next_p1.lh + next_p1.uh * BASE_256 == p1_uh + y_j * xi + a_j by {
            uint512_view_lemma(next_p1);
        }

        assert next_p2.lh + next_p2.uh * BASE_256 == m_j * ui + next_p1.lh + p2_uh by {
            uint512_view_lemma(next_p2);
        }

        assert ia_nat' == ia_nat + a_j * pow_B256_j by {
            assert prev_a[..j+1][..j] == prev_a[..j];
            reveal to_nat();
        }

        assert y_nat' == y_nat + y_j * pow_B256_j by {
            assert y[..j+1][..j] == y[..j];
            reveal to_nat();
        }

        assert m_nat' == m_nat + m_j * pow_B256_j by {
            assert m[..j+1][..j] == m[..j];
            reveal to_nat();
        }

        assert ea_nat' == ea_nat + next_p2.lh * pow_B256_j by {
            calc == {
                to_nat(next_a[..j]);
                { to_nat_prefix_lemma(next_a, j); }
                to_nat(next_a[..j-1]) + next_p2.lh * pow_B256(j-1);
                to_nat(a[..j-1]) + next_p2.lh * pow_B256(j-1);
            }

            assert to_nat([0] + a[..j-1]) == to_nat(a[..j-1]) * BASE_256 by {
                to_nat_zero_prepend_lemma(a[..j-1]);
            }

            assert to_nat([0] + next_a[..j]) == to_nat(next_a[..j]) * BASE_256 by {
                to_nat_zero_prepend_lemma(next_a[..j]);
            }
            assert pow_B256(j-1) * BASE_256 == pow_B256(j) by {
                reveal power();
            }
        }

        assert xi * y_nat' + ui * m_nat' + ia_nat'
            == 
        ea_nat' + next_p2.uh * pow_B256_j' + next_p1.uh *pow_B256_j';
    }

    lemma mont_loop_inv_post_lemma(
        xi: uint256,
        ui: uint256,
        p1: uint512_view_t,
        p2: uint512_view_t,
        y: seq<uint256>,
        m: seq<uint256>,
        prev_a: seq<uint256>,
        a: seq<uint256>,
        bout: uint1)

        requires mont_loop_inv(xi, ui, p1, p2, y, m, prev_a, a, NUM_WORDS);
        requires uint256_addc(p1.uh, p2.uh, 0) == (a[NUM_WORDS-1], bout);

        ensures to_nat(a) * BASE_256 + bout * pow_B256(NUM_WORDS+1)
            == xi * to_nat(y) + ui * to_nat(m) + to_nat(prev_a);
    {
        // var m := to_nat(m);
        calc {
            to_nat(a) * BASE_256 + bout * pow_B256(NUM_WORDS+1);
                { reveal to_nat(); }
            (to_nat(a[..NUM_WORDS-1]) + a[NUM_WORDS-1] * pow_B256(NUM_WORDS-1)) * BASE_256 + bout * pow_B256(NUM_WORDS+1);
            to_nat(a[..NUM_WORDS-1]) * BASE_256 + a[NUM_WORDS-1] * pow_B256(NUM_WORDS-1) * BASE_256 + bout * pow_B256(NUM_WORDS+1);
                { reveal power(); }
            to_nat(a[..NUM_WORDS-1]) * BASE_256 + a[NUM_WORDS-1] * pow_B256(NUM_WORDS) + bout * pow_B256(NUM_WORDS+1);
                { reveal power(); }
            to_nat(a[..NUM_WORDS-1]) * BASE_256 + a[NUM_WORDS-1] * pow_B256(NUM_WORDS) + bout * BASE_256 * pow_B256(NUM_WORDS);
            to_nat(a[..NUM_WORDS-1]) * BASE_256 + p2.uh * pow_B256(NUM_WORDS) + p1.uh * pow_B256(NUM_WORDS);
                { to_nat_zero_prepend_lemma(a[..NUM_WORDS-1]); }
            to_nat([0] + a[..NUM_WORDS-1]) + p2.uh * pow_B256(NUM_WORDS) + p1.uh * pow_B256(NUM_WORDS);
                {
                    assert y == y[..NUM_WORDS];
                    assert m == m[..NUM_WORDS];
                    assert prev_a == prev_a[..NUM_WORDS];
                }
            xi * to_nat(y) + ui * to_nat(m) + to_nat(prev_a);
        }
    }

    lemma mont_loop_cond_sub_lemma(
        xi: uint256,
        ui: uint256,
        y: seq<uint256>,
        m: nat,
        prev_a: seq<uint256>,
        a: seq<uint256>,
        next_a: seq<uint256>,
        bout: uint1,
        next_bout: uint1)

        requires m != 0;
        requires |next_a| == |y| == NUM_WORDS;
        requires to_nat(prev_a) < m + to_nat(y);
        requires to_nat(a) * BASE_256 + bout * pow_B256(NUM_WORDS+1)
            == xi * to_nat(y) + ui * m + to_nat(prev_a);
        requires bout == 0 ==>
            to_nat(a) == to_nat(next_a);
        requires bout == 1 ==>
            to_nat(next_a) - pow_B256(NUM_WORDS) * next_bout == to_nat(a) - m;

        ensures to_nat(next_a) < m + to_nat(y);
        ensures cong(to_nat(next_a) * BASE_256, xi * to_nat(y) + ui * m + to_nat(prev_a), m);
    {
        assert to_nat(a) + bout * pow_B256(NUM_WORDS) < to_nat(y) + m by {
            calc {
                (to_nat(a) + bout * pow_B256(NUM_WORDS)) * BASE_256;
                to_nat(a) * BASE_256 + bout * pow_B256(NUM_WORDS) * BASE_256;
                    { reveal power(); }
                to_nat(a) * BASE_256 + bout * pow_B256(NUM_WORDS+1);
                xi * to_nat(y) + ui * m + to_nat(prev_a);
            <
                xi * to_nat(y) + ui * m + m + to_nat(y);
                (xi + 1) * to_nat(y) + (ui + 1) * m;
            <=
                    {
                        assert xi + 1 <= BASE_256;
                        assert ui + 1 <= BASE_256;
                        assume false; // TODO
                    }
                to_nat(y) * BASE_256 + m * BASE_256;
                (to_nat(y) + m) * BASE_256;
            }
        }

        if bout == 1 {
            if to_nat(a) >= m {
                to_nat_bound_lemma(y);
                assert to_nat(a) + pow_B256(NUM_WORDS) < to_nat(y) + m;
                assert false; // prove by contradiction
            }
            if next_bout != 1 {
                to_nat_bound_lemma(next_a);
                assert false; // prove by contradiction
            }

            calc {
                to_nat(next_a) * BASE_256;
                to_nat(a) * BASE_256 + pow_B256(NUM_WORDS) * BASE_256 - m * BASE_256;
                    { reveal power(); }
                to_nat(a) * BASE_256 + pow_B256(NUM_WORDS+1) - m * BASE_256;
                xi * to_nat(y) + ui * m + to_nat(prev_a) - m * BASE_256;
            }

            assert cong(to_nat(next_a) * BASE_256,
                xi * to_nat(y) + ui * m + to_nat(prev_a), m) by {
                cong_add_lemma_4(xi * to_nat(y) + ui * m + to_nat(prev_a), -BASE_256, m);
                reveal cong();
                assert cong(to_nat(next_a) * BASE_256,
                    xi * to_nat(y) + ui * m + to_nat(prev_a), m);
            }
        } else {
            reveal cong();
            assert cong(to_nat(next_a) * BASE_256,
                xi * to_nat(y) + ui * m + to_nat(prev_a), m);
        }
    }

    predicate montmul_inv(
        a: seq<uint256>,
        x: seq<uint256>,
        i: nat,
        y: seq<uint256>,
        rsa: rsa_params)
    {
        && |a| == |y| == |x| == NUM_WORDS
        && i <= |x|
        && rsa_params_inv(rsa)
        && to_nat(a) < rsa.m + to_nat(y)
        && cong(to_nat(a) * pow_B256(i), to_nat(x[..i]) * to_nat(y), rsa.m)
    }

    lemma montmul_inv_lemma(
        prev_a: seq<uint256>,
        a: seq<uint256>,
        x: seq<uint256>, 
        i: nat,
        ui: uint256,
        y: seq<uint256>, 
        rsa: rsa_params)

        requires montmul_inv(prev_a, x, i, y, rsa);
        requires |a| == NUM_WORDS;
        requires i < |x|;
        requires to_nat(a) < rsa.m + to_nat(y);
        requires cong(to_nat(a) * pow_B256(1),
                x[i] * to_nat(y) + ui * rsa.m + to_nat(prev_a), rsa.m);
        ensures montmul_inv(a, x, i+1, y, rsa);
    {
        calc ==> {
            cong(to_nat(a) * pow_B256(1), x[i] * to_nat(y) + ui * rsa.m + to_nat(prev_a), rsa.m);
                { assume false; }
            cong(to_nat(a) * pow_B256(1), x[i] * to_nat(y) + to_nat(prev_a), rsa.m);
                { assume false; }
            cong(to_nat(a) * pow_B256(1+i), x[i] * to_nat(y) * pow_B256(i) + to_nat(prev_a) * pow_B256(1+i), rsa.m);
                {
                    assert cong(to_nat(prev_a) * pow_B256(i), to_nat(x[..i]) * to_nat(y), rsa.m);
                    assume false;
                }
            cong(to_nat(a) * pow_B256(1+i), x[i] * to_nat(y) * pow_B256(i) + to_nat(x[..i]) * to_nat(y), rsa.m);
            cong(to_nat(a) * pow_B256(1+i), (x[i] * pow_B256(i) + to_nat(x[..i])) * to_nat(y), rsa.m);
                {
                    assert x[..i+1][..i] == x[..i];
                    reveal to_nat();
                }
            cong(to_nat(a) * pow_B256(1+i), to_nat(x[..i+1]) * to_nat(y), rsa.m);
        }

        assert cong(to_nat(a) * pow_B256(1+i), to_nat(x[..i+1]) * to_nat(y), rsa.m);
    }
}