include "ntt_model.dfy"

abstract module ntt_impl {
    import opened Seq
    import opened Power
    import opened Power2
    import opened DivMod
    import opened Mul

    import opened pows_of_2
    import opened nth_root
    import opened ntt_index

    import opened ntt_model
    import opened ntt_polys

    method j_loop(a: n_sized, p: n_sized, t: pow2_t, d: pow2_t, j: nat, u: nat, ghost view: loop_view)
    returns (a': n_sized)
        requires u == j * (2 * d.full);
        requires view.j_loop_inv(a, d, j);
        requires t == view.lsize();
        requires p == rev_mixed_powers_mont_table();
        requires j < view.lsize().full;
        ensures view.j_loop_inv(a', d, j + 1);
    {
        view.s_loop_inv_pre_lemma(a, d, j);

        assert  (2 * j) * d.full == j * (2 * d.full) by {
            LemmaMulProperties();
        }

        rev_mixed_powers_mont_table_lemma(t, d, j);
        var w := p[t.full + j];
        // modmul(x_value(2 * j, d), R);

        var s := u;
        a' := a;

        ghost var bi := 0;

        while (s < u + d.full)
            invariant view.s_loop_inv(a', d, j, s-u);
        {
            var a :n_sized := a';
            var bi := s-u;

            var _ := view.higher_points_view_index_lemma(a, d, j, bi);

            var e := a[s];
            var o := a[s + d.full];

            var x := montmul(o, w);
            a' := a[s+d.full := mqsub(e, x)];
            a' := a'[s := mqadd(e, x)];
            s := s + 1;

            view.s_loop_inv_peri_lemma(a, a', d, j, bi);
        }

        assert s == u + d.full;
        view.s_loop_inv_post_lemma(a', d, j, d.full);
    }

    method t_loop(a: n_sized, p: n_sized, t: pow2_t, d: pow2_t, ghost view: loop_view)
        returns (a': n_sized, ghost view': loop_view)

        requires view.t_loop_inv(a, d);
        requires p == rev_mixed_powers_mont_table();
        requires t == view.lsize();
        requires t.exp < N.exp;

        ensures view.hsize.exp < N.exp ==> view'.t_loop_inv(a', pow2_half(d));
        ensures view.hsize.exp == N.exp ==> view' == view;
        ensures view.hsize.exp == N.exp ==> view'.t_loop_end(a');
    {
        var j := 0;
        var u: nat := 0;
        a' := a;

        view.j_loop_inv_pre_lemma(a', d);

        while (j < t.full)
            invariant t == view.lsize();
            invariant u == j * (2 * d.full);
            invariant view.j_loop_inv(a', d, j);
        {
            a' := j_loop(a', p, t, d, j, u, view);

            calc == {
                u + 2 * d.full;
                j * (2 * d.full) + 2 * d.full;
                {
                    LemmaMulProperties();
                }
                (j + 1) * (2 * d.full);
            }

            j := j + 1;
            u := u + 2 * d.full;
        }

        view' := view.j_loop_inv_post_lemma(a', d, j);
    }

    method mulntt_ct(a: n_sized, p: n_sized, ghost view: loop_view)
        returns (a': n_sized, ghost view': loop_view)
        requires N == pow2_t_cons(512, 9);
        requires view.t_loop_inv(a, pow2(N.exp-1));
        requires p == rev_mixed_powers_mont_table();
        ensures view'.t_loop_end(a');
    {
        var d := pow2(9);
        var t := pow2(0);
        a' := a;
        view' := view;

        assert view'.lsize() == pow2(0) by {
            view'.size_count_lemma();
        }

        pow2_basics(t);

        Nth_root_lemma();

        while (t.full < 512)
            invariant 1 <= d.exp <= N.exp;
            invariant view'.t_loop_inv(a', pow2_half(d));
            invariant t.full >= N.full ==> view'.hsize.exp == N.exp;
            invariant t == view'.lsize();
        {
            d := pow2_half(d);
            a', view' := t_loop(a', p, t, d, view');
            t := pow2_double(t);

            if t.full >= N.full {
                assume view'.hsize.exp == N.exp;
            }
        }

        assert view'.hsize.exp == N.exp;
    }
}