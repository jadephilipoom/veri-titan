include "../arch/otbn/machine.s.dfy"
include "../arch/otbn/vale.i.dfy"

include "bv256_op_s.dfy"
include "generic_ntt_lemmas.dfy"

module bv256_ntt_lemmas refines generic_ntt_lemmas {
    import opened GBV = bv256_op_s
    
    import opened ot_vale
    import opened ot_machine

    const NTT_PRIME := 12289;
}
