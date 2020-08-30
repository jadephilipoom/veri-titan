include "types.dfy"

module ops {

	import opened types

	function pow2(n:nat) : nat {
		if n == 0 then 1 else 2 * pow2(n-1)
	}

	///////////////////////////
	// Operations on bv32s
	///////////////////////////
	function method {:opaque} BitAdd(x:bv32, y:bv32): bv32
	{
		x + y
	}

	function method {:opaque} BitSub(x:bv32, y:bv32): bv32
	{
		x - y
	}

	function method {:opaque} BitAnd(x:bv32, y:bv32): bv32
	{
		x & y
	}

	function method {:opaque} BitOr(x:bv32, y:bv32): bv32
	{
		x | y
	}

	function method {:opaque} BitXor(x:bv32, y:bv32): bv32
	{
		x ^ y
	}

	function method {:opaque} BitMod(x:bv32, y:bv32): bv32
		requires y != 0
	{
		x % y
	}

	function method {:opaque} BitDiv(x:bv32, y:bv32): bv32
		requires y != 0
	{
		x / y
	}

	function method {:opaque} BitMul(x:bv32, y:bv32): bv32
	{
		x * y
	}

	function method {:opaque} BitNot(x:bv32): bv32
	{
		!x
	}

	function method {:opaque} BitShiftLeft(x:bv32, amount:int): bv32
		requires 0 <= amount < 32;
	{
		x << amount
	}

	function method {:opaque} BitShiftRight(x:bv32, amount:int): bv32
		requires 0 <= amount < 32;
	{
		x >> amount
	}

	function method {:opaque} BitRotateRight(x:bv32, amount:int): bv32
		requires 0 <= amount < 32;
	{
		// TODO: Replace with Dafny's builtin operator for this
		(x >> amount) | (x << (32 - amount))
	}

	function method {:opaque} BitRotateLeft(x:bv32, amount:int): bv32
		requires 0 <= amount < 32;
	{
		// TODO: Replace with Dafny's builtin operator for this
		(x << amount) | (x >> (32 - amount))
	}

	function method {:opauqe} BitSignExtend(x:bv32, sz:int): bv32
		requires 0 < sz < 32;
	{
		(x ^ (1 << (sz - 1))) - (1 << (sz - 1))
	}
			
	function method BoolToInt(b: bool) : int
	{
		if b then 1 else 0
	}

	////////////////////////
	// Operations on words
	////////////////////////

	function BitwiseAnd(x:uint32, y:uint32) : uint32
	{
		BitsToWord(BitAnd(WordToBits(x), WordToBits(y)))
	}

	function BitwiseOr(x:uint32, y:uint32):uint32
	{
		BitsToWord(BitOr(WordToBits(x), WordToBits(y)))
	}

	function BitwiseNot(x:uint32) : uint32
	{
		BitsToWord(BitNot(WordToBits(x)))
	}

	function BitwiseXor(x:uint32, y:uint32) : uint32
	{
		BitsToWord(BitXor(WordToBits(x), WordToBits(y)))
	}

	function RotateRight(x:uint32, amount:uint32) : uint32
		requires amount < 32;
	{
		BitsToWord(BitRotateRight(WordToBits(x), amount))
	}

	function RotateLeft(x:uint32, amount:uint32):uint32
		requires amount < 32;
	{
		BitsToWord(BitRotateLeft(WordToBits(x), amount))
	}

	function RightShift(x:uint32, amount:uint32) : uint32
		requires amount < 32;
	{
		BitsToWord(BitShiftRight(WordToBits(x), amount))
	}

	function LeftShift(x:uint32, amount:uint32) : uint32
		requires amount < 32;
	{
		BitsToWord(BitShiftLeft(WordToBits(x), amount))
	}

	function {:opaque} BitwiseAdd32(x:uint32, y:uint32):uint32
	{
		(x + y) % 0x1_0000_0000
	}

	function {:opaque} BitwiseAddCarry(x:uint32, y:uint32):uint64
	{
		(x + y) % 0x1_0000_0000_0000_0000
	}

	function BitwiseSub32(x:uint32, y:uint32):uint32
	{
		BitsToWord(BitSub(WordToBits(x), WordToBits(y)))
	}

	function BitwiseMul32(x:uint32, y:uint32):uint32
	{
		BitsToWord(BitMul(WordToBits(x), WordToBits(y)))
	}

	function BitwiseDiv32(x:uint32, y:uint32):uint32
		requires y != 0;
	{
		if WordToBits(y) == 0 then 0 else BitsToWord(BitDiv(WordToBits(x), WordToBits(y)))
	}

	function BitwiseMod32(x:uint32, y:uint32):uint32
		requires y != 0;
	{
		if WordToBits(y) == 0 then 0 else BitsToWord(BitMod(WordToBits(x), WordToBits(y)))
	}

	function BitwiseSignExtend(x:uint32, size:int):uint32
		requires 0 <= size < 32;
	{
		if size == 0 then x else BitsToWord(BitSignExtend(WordToBits(x), size))
	}

	////////////////////////
	// Operations on Bignums
	////////////////////////

	////////////////////////
	// Operations on bv256s
	////////////////////////

	function {:opaque} uint256_xor(x: uint256, y: uint256): uint256
	{
		(x as bv256 ^ y as bv256) as uint256
	}

	function {:opaque} uint256_or(x: uint256, y: uint256): uint256
	{
		(x as bv256 | y as bv256) as uint256
	}
	
	function {:opaque} uint256_and(x: uint256, y: uint256): uint256
	{
		(x as bv256 | y as bv256) as uint256
	}

	function {:opaque} uint256_ls(x: uint256, num_bytes:int): uint256
		requires 0 <= num_bytes < 32;
		ensures uint256_ls(x, 0) == x;
	{
		assume false;
		(x as bv256 << (num_bytes * 8)) as uint256
	}

	function {:opaque} uint256_rs(x:uint256, num_bytes:int): uint256
		requires 0 <= num_bytes < 32;
		ensures uint256_rs(x, 0) == x;
	{
		assume false;
		(x as bv256 >> (num_bytes * 8)) as uint256
	}

	function uint256_sb(b:uint256, st:bool, sb:uint32) : uint256
		requires sb < 32;
	{	
		if sb == 0 then b
		else if st then uint256_ls(b, sb)
		else uint256_rs(b, sb)
	}

	function {:opaque} uint256_lh(x: uint256): uint128
	{
		x % HALF_BASE
	}

	function {:opaque} uint256_uh(x: uint256): uint128
	{
		x / HALF_BASE
	}

	function {:opaque} uint256_hwb(x: uint256, v: uint128, lower: bool): (x': uint256)
		// overwrites the lower half, keeps the higher half
		ensures lower ==> (uint256_lh(x') == v && uint256_uh(x') == uint256_uh(x));
		// overwrites the higher half, keeps the lower half
		ensures !lower ==> (uint256_uh(x') == v && uint256_lh(x') == uint256_lh(x));

	function {:opaque} uint256_qmul(x: uint256, qx: uint2, y: uint256, qy:uint2): uint128

	function {:opaque} uint256_qsel(x: uint256, qx: uint2): uint64
	{
		if qx == 0 then
			x % QUARTER_BASE
		else if qx == 1 then
			(x / QUARTER_BASE) % QUARTER_BASE
		else if qx == 1 then
			(x / HALF_BASE) % QUARTER_BASE
		else
			(x / QUARTER_BASE / HALF_BASE) % QUARTER_BASE
	}
} // end module ops
