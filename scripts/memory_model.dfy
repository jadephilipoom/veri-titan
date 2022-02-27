include "../lib/generic_bv_ops.dfy"

module flat_memory {
  import opened integers

  const DMEM_LIMIT: int := 0x80000

  // basic map
  type flat_t = map<int, uint32>


  predicate method ptr_admissible_32(ptr: nat)
  {
    // uint32 ptr should be 4 bytes aligned
    && ptr % 4 == 0
    && (ptr + 4) < DMEM_LIMIT
  }

  predicate method flat_ptr_valid_32(flat: flat_t, ptr: nat)
  {
    && ptr_admissible_32(ptr)
    && ptr + 0 in flat
  }

  function method {:opaque} select_32_from_32(x: uint32, sel: nat): uint32
    requires sel < 1
  {
    if sel == 0 then ((x as bv32) as int) % BASE_32
    else ((x as bv32 >> 0) as int) % BASE_32
  }

  function method {:opaque} assemble_32_to_32(
    p0: uint32): uint32
  {
    ((p0 as bv32)) as uint32
  }

  lemma {:axiom} value_32_from_32(x: uint32)
    ensures x == assemble_32_to_32(
      select_32_from_32(x, 0));

  function method flat_read_32(flat: flat_t, ptr: nat): uint32
    requires flat_ptr_valid_32(flat, ptr)
  {
    var p0 := flat[ptr + 0];
    assemble_32_to_32(p0)
  }

  function method flat_write_32(flat: flat_t, ptr: nat, x: uint32): (new_flat: flat_t) 
    requires ptr_admissible_32(ptr)
    ensures flat_ptr_valid_32(new_flat, ptr)
  {
    flat
    [ptr + 0 := select_32_from_32(x, 0)]
  }

  lemma flat_read_write_basic_32(flat: flat_t, x: uint32, ptr: nat)
    requires ptr_admissible_32(ptr)
    ensures flat_read_32(flat_write_32(flat, ptr, x), ptr) == x
  {
    var new_flat := flat_write_32(flat, ptr, x);
    value_32_from_32(x);
    assert flat_read_32(new_flat, ptr) == x;
  }
  predicate method ptr_admissible_256(ptr: nat)
  {
    // uint256 ptr should be 32 bytes aligned
    && ptr % 32 == 0
    && (ptr + 32) < DMEM_LIMIT
  }

  predicate method flat_ptr_valid_256(flat: flat_t, ptr: nat)
  {
    && ptr_admissible_256(ptr)
    && ptr + 0 in flat
    && ptr + 4 in flat
    && ptr + 8 in flat
    && ptr + 12 in flat
    && ptr + 16 in flat
    && ptr + 20 in flat
    && ptr + 24 in flat
    && ptr + 28 in flat
  }

  function method {:opaque} select_32_from_256(x: uint256, sel: nat): uint32
    requires sel < 8
  {
    if sel == 0 then ((x as bv256) as int) % BASE_32
    else if sel == 1 then ((x as bv256 >> 32) as int) % BASE_32
    else if sel == 2 then ((x as bv256 >> 64) as int) % BASE_32
    else if sel == 3 then ((x as bv256 >> 96) as int) % BASE_32
    else if sel == 4 then ((x as bv256 >> 128) as int) % BASE_32
    else if sel == 5 then ((x as bv256 >> 160) as int) % BASE_32
    else if sel == 6 then ((x as bv256 >> 192) as int) % BASE_32
    else ((x as bv256 >> 224) as int) % BASE_32
  }

  function method {:opaque} assemble_32_to_256(
    p0: uint32, 
    p1: uint32, 
    p2: uint32, 
    p3: uint32, 
    p4: uint32, 
    p5: uint32, 
    p6: uint32, 
    p7: uint32): uint256
  {
    ((p0 as bv256)
    |(p1 as bv256 << 32)
    |(p2 as bv256 << 64)
    |(p3 as bv256 << 96)
    |(p4 as bv256 << 128)
    |(p5 as bv256 << 160)
    |(p6 as bv256 << 192)
    |(p7 as bv256 << 224)) as uint256
  }

  lemma {:axiom} value_256_from_32(x: uint256)
    ensures x == assemble_32_to_256(
      select_32_from_256(x, 0), 
      select_32_from_256(x, 1), 
      select_32_from_256(x, 2), 
      select_32_from_256(x, 3), 
      select_32_from_256(x, 4), 
      select_32_from_256(x, 5), 
      select_32_from_256(x, 6), 
      select_32_from_256(x, 7));

  function method flat_read_256(flat: flat_t, ptr: nat): uint256
    requires flat_ptr_valid_256(flat, ptr)
  {
    var p0 := flat[ptr + 0];
    var p1 := flat[ptr + 4];
    var p2 := flat[ptr + 8];
    var p3 := flat[ptr + 12];
    var p4 := flat[ptr + 16];
    var p5 := flat[ptr + 20];
    var p6 := flat[ptr + 24];
    var p7 := flat[ptr + 28];
    assemble_32_to_256(p0, p1, p2, p3, p4, p5, p6, p7)
  }

  function method flat_write_256(flat: flat_t, ptr: nat, x: uint256): (new_flat: flat_t) 
    requires ptr_admissible_256(ptr)
    ensures flat_ptr_valid_256(new_flat, ptr)
  {
    flat
    [ptr + 0 := select_32_from_256(x, 0)]
    [ptr + 4 := select_32_from_256(x, 1)]
    [ptr + 8 := select_32_from_256(x, 2)]
    [ptr + 12 := select_32_from_256(x, 3)]
    [ptr + 16 := select_32_from_256(x, 4)]
    [ptr + 20 := select_32_from_256(x, 5)]
    [ptr + 24 := select_32_from_256(x, 6)]
    [ptr + 28 := select_32_from_256(x, 7)]
  }

  lemma flat_read_write_basic_256(flat: flat_t, x: uint256, ptr: nat)
    requires ptr_admissible_256(ptr)
    ensures flat_read_256(flat_write_256(flat, ptr, x), ptr) == x
  {
    var new_flat := flat_write_256(flat, ptr, x);
    value_256_from_32(x);
    assert flat_read_256(new_flat, ptr) == x;
  }
}

  // predicate valid_frames(frames: seq<frame_t>)
  // {
  //   && (|frames| != 0 ==> frames[0].fptr == STACK_INIT)
  //   && (forall i | 0 <= i < |frames| - 1 ::
  //     frames[i].fptr == frames[i + 1].fptr - |frames[i].content|)
  //   && (forall i | 0 <= i < |frames| ::
  //     frames[i].fptr <= STACK_INIT - STACK_MAX_SIZE)
  // }


module heap {
  import opened flat_memory
  import opened integers

  const STACK_INIT: nat;
  const STACK_MAX_BYTES: nat := 0x400;

  predicate in_stack_addr_range(addr: int)
  {
    STACK_INIT - STACK_MAX_BYTES <= addr <= STACK_INIT
  }

  function heap_b256_index_ptr(ptr: nat, i: nat): nat
  {
    ptr + 32 * i
  }

  function stack_index_ptr(i: nat): nat
    requires STACK_INIT >= STACK_MAX_BYTES
  {
    STACK_INIT - STACK_MAX_BYTES + i * 4
  }

  // iterator for buffer entries
  datatype b256_iter = b256_iter_cons(base_ptr: nat, index: nat,
    ptr: nat, buff: seq<uint256>)

  function b256_iter_load_next(iter: b256_iter, inc: bool): b256_iter
  {
    iter.(index := if inc then iter.index + 1 else iter.index)
  }

  function b256_iter_store_next(iter: b256_iter, value: uint256, inc: bool): b256_iter
    requires iter.index < |iter.buff|
  {
      iter.(index := if inc then iter.index + 1 else iter.index)
          .(buff := iter.buff[iter.index := value])
  }

  datatype entry_t = 
    | W32(w32: uint32)
    | B256(b256: seq<uint256>)

  type heap_t = map<int, entry_t>

  datatype mem_t = memory(heap: heap_t, stack: seq<uint32>)
  {
    predicate stack_valid()
      requires STACK_MAX_BYTES % 4 == 0
    {
      && ptr_admissible_32(STACK_INIT)
      && STACK_INIT >= STACK_MAX_BYTES
      && |stack| == STACK_MAX_BYTES / 4
    }

    predicate equiv_inv_stack(flat: flat_t)
      requires stack_valid()
    {
      (forall i | 0 <= i < |stack| ::
        && var ptr := stack_index_ptr(i);
        && flat_ptr_valid_32(flat, ptr)
        && stack[i] == flat_read_32(flat, ptr)
        && ptr !in heap)
    }

    function stack_write(i: nat, value: uint32): mem_t
      requires i < |stack|
    {
      this.(stack := stack[i:= value])
    }

    // valid pointer for W32 heaplet entry
    predicate heap_w32_ptr_valid(base_ptr: nat)
    {
      && ptr_admissible_32(base_ptr)
      && base_ptr in heap
      && heap[base_ptr].W32?
    }

    // this holds for each W32 heaplet entry
    predicate equiv_inv_w32(flat: flat_t, ptr: nat)
      requires heap_w32_ptr_valid(ptr)
    {
      && flat_ptr_valid_32(flat, ptr)
      && heap[ptr].w32 == flat_read_32(flat, ptr)
      // disjointness from stack
      && !in_stack_addr_range(ptr)
    }

    function heap_w32_read(ptr: nat): uint32
      requires heap_w32_ptr_valid(ptr)
    {
      heap[ptr].w32
    }

    function heap_w32_write(ptr: nat, value: uint32): mem_t
      requires heap_w32_ptr_valid(ptr)
    {
      this.(heap := heap[ptr := W32(value)])
    }

    // valid pointer for B256 heaplet entry
    predicate heap_b256_ptr_valid(base_ptr: nat)
    {
      && ptr_admissible_256(base_ptr)
      && base_ptr in heap
      && heap[base_ptr].B256?
      && var len := |heap[base_ptr].b256|;
      //  the buffer is not empty
      && len != 0
      // end of buffer is in bound
      && ptr_admissible_256(heap_b256_index_ptr(base_ptr, len - 1))
    }

    predicate b256_iter_inv(iter: b256_iter)
    {
      var base_ptr := iter.base_ptr;
      // base_ptr points to a valid buffer
      && heap_b256_ptr_valid(base_ptr)
      // ptr is correct
      && iter.ptr == heap_b256_index_ptr(base_ptr, iter.index)
      // the view is consistent with heap
      && heap[base_ptr].b256 == iter.buff
      // the index is within bound (or at end)
      && iter.index <= |iter.buff|
    }

    predicate b256_iter_safe(iter: b256_iter)
    {
      && b256_iter_inv(iter)
      // tighter constraint so we can dereference
      && iter.index < |iter.buff|
    }

    // this holds for each uint256 in a B256 heaplet entry
    predicate heap_256_equiv_inv(flat: flat_t, base_ptr: nat, i: nat)
      requires heap_b256_ptr_valid(base_ptr)
      requires i < |heap[base_ptr].b256|
    {
      var ptr := heap_b256_index_ptr(base_ptr, i);
      // ptr points to some uint256, which has 8 base words uint32
      && flat_ptr_valid_256(flat, ptr)
      && flat_read_256(flat, ptr) == heap[base_ptr].b256[i]
      // disjointness
      && (i != 0 ==> ptr !in heap)
      && ptr + 4 !in heap
      && ptr + 8 !in heap
      && ptr + 12 !in heap
      && ptr + 16 !in heap
      && ptr + 20 !in heap
      && ptr + 24 !in heap
      && ptr + 28 !in heap
      && !in_stack_addr_range(ptr)
      && !in_stack_addr_range(ptr + 4)
      && !in_stack_addr_range(ptr + 8)
      && !in_stack_addr_range(ptr + 12)
      && !in_stack_addr_range(ptr + 16)
      && !in_stack_addr_range(ptr + 20)
      && !in_stack_addr_range(ptr + 24)
      && !in_stack_addr_range(ptr + 28)
    }

    // this holds for each B256 heaplet entry
    predicate heap_b256_equiv_inv(flat: flat_t, base_ptr: nat)
      requires heap_b256_ptr_valid(base_ptr)
    {
      forall i | 0 <= i < |heap[base_ptr].b256| ::
        heap_256_equiv_inv(flat, base_ptr, i)
    }

    function heap_read_b256(iter: b256_iter): uint256
      requires b256_iter_safe(iter)
    {
      iter.buff[iter.index]
    }

    function heap_b256_write(iter: b256_iter, value: uint256): mem_t
      requires b256_iter_safe(iter)
    {
      var buff := heap[iter.base_ptr].b256;
      var new_buff := buff[iter.index := value];
      this.(heap := heap[iter.base_ptr := B256(new_buff)])
    }

    // the equivalence invariant between heaplet and memory
    predicate flat_equiv_inv(flat: flat_t)
    {
      && (forall base_ptr | heap_b256_ptr_valid(base_ptr) ::
        heap_b256_equiv_inv(flat, base_ptr))
      && (forall base_ptr | heap_w32_ptr_valid(base_ptr) ::
        equiv_inv_w32(flat, base_ptr))
      && stack_valid()
      && equiv_inv_stack(flat)
    }

    lemma sub_ptrs_disjoint(flat: flat_t, base1: nat, base2: nat)
      requires flat_equiv_inv(flat)
      requires heap_b256_ptr_valid(base1)
      requires heap_b256_ptr_valid(base2)
      requires base1 != base2
      ensures forall i, j ::
        (0 <= i < |heap[base1].b256| && 0 <= j < |heap[base2].b256|)
          ==> 
        (heap_b256_index_ptr(base1, i) != heap_b256_index_ptr(base2, j))
    {
      var heap := heap;
      if exists i, j ::
        && 0 <= i < |heap[base1].b256|
        && 0 <= j < |heap[base2].b256|
        && heap_b256_index_ptr(base1, i) == heap_b256_index_ptr(base2, j)
      {
        var i, j :|
          && 0 <= i < |heap[base1].b256|
          && 0 <= j < |heap[base2].b256|
          && heap_b256_index_ptr(base1, i) == heap_b256_index_ptr(base2, j);
        assert base1 + 32 * i == base2 + 32 * j;
        var buff1 := heap[base1].b256;
        var buff2 := heap[base2].b256;

        if base1 > base2 {
          assert heap_b256_equiv_inv(flat, base2);
          var k := j - i;
          assert base1 == heap_b256_index_ptr(base2, k);
          assert 0 <= k < |buff2|;
          assert heap_256_equiv_inv(flat, base2, k);
          assert base1 !in heap;
          assert false;
        } else {
          assert heap_b256_equiv_inv(flat, base1);
          var k := i - j;
          assert base2 == heap_b256_index_ptr(base1, k);
          assert 0 <= k < |buff1|;
          assert heap_256_equiv_inv(flat, base1, k);
          assert base2 !in heap;
          assert false;
        }
      }
    }

    lemma heap_b256_write_preserves_b256_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      iter: b256_iter, value: uint256,
      other_ptr: nat)

      requires flat_equiv_inv(flat)
      requires b256_iter_safe(iter)
      requires heap_b256_ptr_valid(other_ptr)
      requires new_mem == heap_b256_write(iter, value)
      requires new_flat == flat_write_256(flat, iter.ptr, value)

      ensures new_mem.heap_b256_equiv_inv(new_flat, other_ptr)
    {
      var base_ptr, j := iter.base_ptr, iter.index;
      var buff := heap[other_ptr].b256;
      var len := |buff|;

      if other_ptr == base_ptr {
        forall i | 0 <= i < len
          ensures new_mem.heap_256_equiv_inv(new_flat, base_ptr, i)
        {
          assert heap_256_equiv_inv(flat, base_ptr, i);
          if i == j {
            value_256_from_32(value);
            assert new_mem.heap_256_equiv_inv(new_flat, base_ptr, i);
          }
        }
      } else {
        forall i | 0 <= i < len
          ensures new_mem.heap_256_equiv_inv(new_flat, other_ptr, i)
        {
          assert heap_256_equiv_inv(flat, other_ptr, i);
          var ptr := heap_b256_index_ptr(other_ptr, i);
          assert flat_ptr_valid_256(new_flat, ptr);
          assert ptr != iter.ptr by {
            sub_ptrs_disjoint(flat, other_ptr, base_ptr);
          }
          assert flat_read_256(new_flat, ptr) == buff[i];
        }
      }
      assert heap_b256_equiv_inv(flat, other_ptr);
    }

    lemma heap_b256_write_preserves_stack_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      iter: b256_iter, value: uint256)

      requires flat_equiv_inv(flat)
      requires b256_iter_safe(iter)

      requires new_mem == heap_b256_write(iter, value)
      requires new_flat == flat_write_256(flat, iter.ptr, value)

      ensures new_mem.equiv_inv_stack(new_flat)
    {
      var stack_end := STACK_INIT - STACK_MAX_BYTES;

      forall i | 0 <= i < |new_mem.stack|
        ensures
          && var ptr := stack_end + i * 4;
          && flat_ptr_valid_32(new_flat, ptr)
          && new_mem.stack[i] == flat_read_32(new_flat, ptr)
          && ptr !in new_mem.heap
      {
        var ptr := stack_end + i * 4;
        assert flat_ptr_valid_32(new_flat, ptr);

        if flat_read_32(new_flat, ptr) != flat_read_32(flat, ptr) {
          // this pointer can't be in stack range
          assert heap_256_equiv_inv(flat, iter.base_ptr, iter.index);
          assert false;
        }
      }
    }

    lemma heap_b256_write_preserves_w32_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      iter: b256_iter, value: uint256,
      other_ptr: nat)

      requires flat_equiv_inv(flat)
      requires b256_iter_safe(iter)
      requires heap_w32_ptr_valid(other_ptr)
      requires new_mem== heap_b256_write(iter, value)
      requires new_flat == flat_write_256(flat, iter.ptr, value)

      ensures new_mem.equiv_inv_w32(new_flat, other_ptr)
    {
      if flat[other_ptr] != new_flat[other_ptr] {
        assert heap_256_equiv_inv(flat, iter.base_ptr, iter.index);
        assert false;
      }
    }

    lemma heap_b256_write_preverses_flat_equiv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      iter: b256_iter, value: uint256)

      requires flat_equiv_inv(flat)
      requires b256_iter_safe(iter)
      requires new_mem == heap_b256_write(iter, value)
      requires new_flat == flat_write_256(flat, iter.ptr, value)

      ensures new_mem.flat_equiv_inv(new_flat)
    {
      forall base_ptr | new_mem.heap_b256_ptr_valid(base_ptr)
        ensures new_mem.heap_b256_equiv_inv(new_flat, base_ptr)
      {
        heap_b256_write_preserves_b256_inv(new_mem,
          flat, new_flat, iter, value, base_ptr);
      }
      forall base_ptr | new_mem.heap_w32_ptr_valid(base_ptr)
        ensures new_mem.equiv_inv_w32(new_flat, base_ptr)
      {
        heap_b256_write_preserves_w32_inv(new_mem,
          flat, new_flat, iter, value, base_ptr);
      }

      heap_b256_write_preserves_stack_inv(new_mem,
        flat, new_flat, iter, value);
    }

    lemma heap_w32_write_preserves_b256_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      value: uint32,
      write_ptr: nat, other_ptr: nat)

    requires flat_equiv_inv(flat)
    requires heap_w32_ptr_valid(write_ptr)
    requires heap_b256_ptr_valid(other_ptr)
    requires new_mem == heap_w32_write(write_ptr, value)
    requires new_flat == flat_write_32(flat, write_ptr, value)

    ensures new_mem.heap_b256_equiv_inv(new_flat, other_ptr)
    {
      assert heap_b256_equiv_inv(flat, other_ptr);
      var buff := heap[other_ptr].b256;
      forall i | 0 <= i < |buff| 
        ensures new_mem.heap_256_equiv_inv(new_flat, other_ptr, i)
      {
        assert heap_256_equiv_inv(flat, other_ptr, i);
      }
    }

    lemma heap_w32_write_preserves_w32_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      value: uint32,
      write_ptr: nat, other_ptr: nat)

      requires flat_equiv_inv(flat)
      requires heap_w32_ptr_valid(write_ptr)
      requires heap_w32_ptr_valid(other_ptr)
      requires new_mem == heap_w32_write(write_ptr, value)
      requires new_flat == flat_write_32(flat, write_ptr, value)

      ensures new_mem.equiv_inv_w32(new_flat, other_ptr)
    {
      if other_ptr == write_ptr {
        value_32_from_32(value);
      }
    }

    lemma heap_w32_write_preserves_stack_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      value: uint32,
      write_ptr: nat)

      requires flat_equiv_inv(flat)
      requires heap_w32_ptr_valid(write_ptr)
      requires new_mem == heap_w32_write(write_ptr, value)
      requires new_flat == flat_write_32(flat, write_ptr, value)

      ensures new_mem.equiv_inv_stack(new_flat)
    {
    }

    lemma heap_w32_write_preverses_flat_equiv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      value: uint32,
      write_ptr: nat)

      requires flat_equiv_inv(flat)
      requires heap_w32_ptr_valid(write_ptr)
      requires new_mem == heap_w32_write(write_ptr, value)
      requires new_flat == flat_write_32(flat, write_ptr, value)

      ensures new_mem.flat_equiv_inv(new_flat)
    {
      forall base_ptr | new_mem.heap_b256_ptr_valid(base_ptr)
        ensures new_mem.heap_b256_equiv_inv(new_flat, base_ptr)
      {
        heap_w32_write_preserves_b256_inv(new_mem,
          flat, new_flat, value, write_ptr, base_ptr);
      }
      forall base_ptr | new_mem.heap_w32_ptr_valid(base_ptr)
        ensures new_mem.equiv_inv_w32(new_flat, base_ptr)
      {
        heap_w32_write_preserves_w32_inv(new_mem,
          flat, new_flat, value, write_ptr, base_ptr);
      }

      heap_w32_write_preserves_stack_inv(new_mem,
        flat, new_flat, value, write_ptr);
    }

    lemma stack_write_preserves_b256_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      index: nat, value: uint32,
      base_ptr: nat)

      requires flat_equiv_inv(flat)
      requires index < |stack|
      requires new_mem == stack_write(index, value)
      requires new_flat == flat_write_32(flat, stack_index_ptr(index), value)
      requires heap_b256_ptr_valid(base_ptr)
  
      ensures new_mem.heap_b256_equiv_inv(new_flat, base_ptr)
    {
      var buff := heap[base_ptr].b256;
      var new_buff := new_mem.heap[base_ptr].b256;
      forall i | 0 <= i < |new_buff|
        ensures new_mem.heap_256_equiv_inv(new_flat, base_ptr, i) 
      {
        assert heap_256_equiv_inv(flat, base_ptr, i);
        // var ptr := heap_b256_index_ptr(base_ptr, i);
        // assert flat_read_256(flat, ptr) == flat_read_256(new_flat, ptr);
      }
    }

    lemma stack_write_preserves_w32_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      index: nat, value: uint32,
      other_ptr: nat)

      requires flat_equiv_inv(flat)
      requires index < |stack|
      requires new_mem == stack_write(index, value)
      requires new_flat == flat_write_32(flat, stack_index_ptr(index), value)
      requires heap_w32_ptr_valid(other_ptr)

      ensures new_mem.equiv_inv_w32(new_flat, other_ptr)
    {
    }

    lemma stack_write_preserves_stack_inv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      index: nat, value: uint32)

      requires flat_equiv_inv(flat)
      requires index < |stack|
      requires new_mem == stack_write(index, value)
      requires new_flat == flat_write_32(flat, stack_index_ptr(index), value)
  
      ensures new_mem.equiv_inv_stack(new_flat)
    {
      var new_stack := new_mem.stack;
      forall i | 0 <= i < |new_stack|
        ensures 
          var ptr := stack_index_ptr(i);
          && flat_ptr_valid_32(new_flat, ptr)
          && new_stack[i] == flat_read_32(new_flat, ptr)
          && ptr !in new_mem.heap;
      {
        if i == index {
          value_32_from_32(value);
        }
      }
    }

    lemma stack_write_preverses_flat_equiv(
      new_mem: mem_t,
      flat: flat_t, new_flat: flat_t,
      index: nat, value: uint32)

      requires flat_equiv_inv(flat)
      requires index < |stack|
      requires new_mem == stack_write(index, value)
      requires new_flat == flat_write_32(flat, stack_index_ptr(index), value)

      ensures new_mem.flat_equiv_inv(new_flat)
    {
      forall base_ptr | new_mem.heap_b256_ptr_valid(base_ptr)
        ensures new_mem.heap_b256_equiv_inv(new_flat, base_ptr)
      {
        stack_write_preserves_b256_inv(new_mem,
          flat, new_flat, index, value, base_ptr);
      }
      
      forall base_ptr | new_mem.heap_w32_ptr_valid(base_ptr)
        ensures new_mem.equiv_inv_w32(new_flat, base_ptr)
      {
        stack_write_preserves_w32_inv(new_mem,
          flat, new_flat, index, value, base_ptr);
      }
    
      stack_write_preserves_stack_inv(new_mem, flat, new_flat,
        index, value);
    }
  }
}
