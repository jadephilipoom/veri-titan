include "../arch/riscv/machine.s.dfy"
include "generic_mm_lemmas.dfy"
include "bv32_ops.dfy"

module bv32_mm_lemmas refines generic_mm_lemmas {
    import opened GBV = bv32_ops
    import opened rv_machine

    type uint64_view_t = dw_view_t

    const NA : int := -1;

    const NUM_WORDS := 96;

    predicate valid_uint64_view(
        num: uint64_view_t,
        lh: uint32, uh: uint32)
    {
        && lh == num.lh
        && uh == num.uh
    }

    lemma mul32_correct_lemma(a: uint32, b: uint32, c: uint32, d: uint32)
        requires c == uint32_mul(a, b);
        requires d == uint32_mulhu(a, b);
        ensures to_nat([c, d]) == a * b;
    {
        reveal dw_lh();
        reveal dw_uh();

        var full := a * b;
        dw_split_lemma(full);

        GBV.BVSEQ.LemmaSeqLen2([c, d]);
    }

    datatype mma_vars = mma_vars(
        frame_ptr: uint32, // writable
        iter_a: iter_t,
        a_i: uint32,
        i: nat,
        // d0: uint32,
        iter_b: iter_t,
        iter_c: iter_t, // writable
        iter_n: iter_t
    )

    predicate mvar_iter_inv(mem: mem_t, iter: iter_t, address: int, index: int, value: int)
    {
        && (address >= 0 ==> iter_inv(iter, mem, address))
        && (value >= 0 ==> to_nat(iter.buff) == value)
        && (index >= 0 ==> iter.index == index)
        && |iter.buff| == NUM_WORDS
    }

    predicate mma_vars_inv(
        vars: mma_vars,
        mem: mem_t,
        n_ptr: int, n_idx: int,
        c_ptr: int, c_idx: int,
        b_ptr: int, b_idx: int,
        rsa: rsa_params)
    {
        && valid_frame_ptr(mem, vars.frame_ptr, 12)

        && mvar_iter_inv(mem, vars.iter_a, -1, vars.i, NA)
        && vars.i <= NUM_WORDS
        && (vars.i < NUM_WORDS ==> vars.iter_a.buff[vars.i] == vars.a_i)
        && mvar_iter_inv(mem, vars.iter_n, n_ptr, n_idx, rsa.M)
        && mvar_iter_inv(mem, vars.iter_c, c_ptr, c_idx, NA)
        && mvar_iter_inv(mem, vars.iter_b, b_ptr, b_idx, NA)

        && vars.iter_c.base_addr != vars.iter_a.base_addr
        && vars.iter_c.base_addr != vars.iter_n.base_addr
        && vars.iter_c.base_addr != vars.iter_b.base_addr
        && vars.iter_c.base_addr != vars.frame_ptr

        && vars.frame_ptr != vars.iter_a.base_addr
        && vars.frame_ptr != vars.iter_n.base_addr
        && vars.frame_ptr != vars.iter_b.base_addr

        && rsa_params_inv(rsa)
    }


}