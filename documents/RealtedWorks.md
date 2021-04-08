# Related Works:

----
## [Get Rid of Inline Assembly through Verification-Oriented Lifting](https://rbonichon.github.io/papers/tina-ase19.pdf)

### Motivation:
Inline assembly code is often needed along side with C code. The problem is that inline assembly makes formal analysis on the code difficult. Say I have some tool that works on C, it will not be able to handle the inline assembly parts.

This paper describes an approach to "decompile" the inline assembly code into C code, in a way that is amenable towards formal analysis. 

### Insights:
Semantic persevering deompilation in general is hard. So they have to work off certain assumptions. They identify several properties of inline assembly:
* The control flow structure is limited: only a handful
of conditionals and loops, hosting up to hundreds of
instructions;
* The interface of the chunk with the C code is usually
given: programmers annotate chunks with the description
of its inputs, outputs and clobbers with respect to its C
context
* Furthermore, the chunk appears in a C context, where
the types, and possibly more, are known: they only need to propagate the information here.

### Overall Work Flow:
* Compilation: the source code is compiled with debugging symbols
* IR lifting: the binary is then lifted into a simple IR.
* C lifting: the IR is translated into C code
* Validation: the decompiled C code is validated. 

The last two steps are the meat of their work.

### IR -> C Part:
There are several difficulties are in the IR -> C step:

* Low-level data: explicit flags, including overflows or
carry, bitwise operations (masks), low-level comparisons they don't have good correspondence with C code.

    To address this issue, they refer to an external technique that can prove equivalence of low level predicates. So instead of control flow condition depending on a bit in the flag register, it will depend on expressions from registers.

* Implicit variables: separate logical variables could be packed inside a large register. like different parts of the same register corresponds to different C variables. 

    To address this, they used something called register unpacking. They basically split up register to 8/16/32 bit sizes. Then they see if any of them is being used and assign a variable to it. Unused ones are eliminated. 

    They also talk about expression propagation. From my understanding they are propagating symbolic values, aggregating them into expressions, then a simplification pass happens over the expressions. 

* Implicit loop counters/index: structures indexed by loop
counters at high-level are split into multiple low-level
computations where the link between the different logical
elements is lost.

    To address this they used a pass called loop normalization. Basically recovering the loop counter.

### Validation Part:

They compile the "decompiled" C code, and re-lift the compiled code. Then they demonstrate that the re-lifted code is equivalent to the IR derived from the inline assembly. 

The validation is done through something called block-based semantic equivalence. 
* isomorphism of the control-flow graphs extracted from the two lifted programs
* pairwise equivalence of corresponding vertices using SMT, or fall back with randomized testing.

### Comments:
* The validation process in this paper (Figure 4) is a bit circular. 
* This paper uses the term verification a lot, but it is more general formal analysis. The evaluation section seems a bit short. 
* It is a fair point that os/hardware specific instructions cannot be lifted/decompiled easily, since there is no correspondence with C.
----

## [Certified Verification of Algebraic Properties on LowLevel Mathematical Constructs in Cryptographic Programs](https://dl.acm.org/doi/pdf/10.1145/3133956.3134076)

They develop a certified technique to verify low-level mathematical constructs in X25519. 
They translate algebraic specification of mathematical constructs into an algebraic problem.
Algebraic problems are solved by algebra system Singular.
Range problems are solved by  SMT solvers.
They certify the translation using Coq.

### Comments:
* the translation from assembly to bvCryptoLine is pushed into future work
* moreover, bvCryptoLine is supposedly close to assembly code, but it is unclear how large the gap is. would be interesting to know how well it translates from SIMD extensions for example. 
* the Gröbner Bases method is sound but incomplete
* the verification time is pretty long (131 hours), which seems high for interactive development

----
## [Signed Cryptographic Program Verification with Typed CryptoLine](https://dl.acm.org/doi/pdf/10.1145/3319535.3354199)

### Comments:
* the extension from CryptoLine seems somewhat incremental
* the translation from GIMPLE to CryptoLine does not seem to be verified, so the TCB excludes C -> GIMPLE, but includes GIMPLE -> CryptoLine. The GIMPLE -> ASM part is still in the TCB. 

----
## [Verifying Arithmetic in Cryptographic C Programs](https://www.iis.sinica.edu.tw/~bywang/papers/ase19.pdf)

### Comments:
* the diff between this work and Signed CryptoLine does not seem very significant. not sure how the LLVM -> CryptoLine differs greatly from GIMPLE -> CryptoLine.
* instead of a equivalence proof, the translation have a soundness theorem, which is a contribution
