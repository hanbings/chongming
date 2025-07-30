///|
pub struct BloomFilter {
  bits : Array[BitView]
  num_bits : UInt
  num_hashes : Int
}

///|
const LN_2 : Double = 0.69314718056

///|
const FNV : Int = 0x811C9DC5

///|
const FNV_PRIME : UInt = 0x01000193

///|
pub fn new(expected_items : Int64, false_positive_rate : Double) -> BloomFilter {
  let ln2_squared = LN_2 * LN_2
  let m = (-expected_items.to_double() *
  @math.ln(false_positive_rate) /
  ln2_squared).ceil()
  let k = (m / expected_items.to_double() * LN_2).ceil()
  let byte_len = (m + 7) / 8
  BloomFilter::{
    bits: Array::make(byte_len.to_int(), bit_view(0)),
    num_bits: m.to_uint(),
    num_hashes: k.to_int(),
  }
}

///|
fn hashes(data : Array[Byte]) -> (UInt, UInt) {
  let h1 = @xxhash.with_seed(0)
  h1.update(data)
  let h1 = h1.digest()
  let mut h2 = FNV
  for b in data {
    h2 = h2 ^ b.to_int()
    h2 = @utils.wrapping_mul(h2.reinterpret_as_uint(), FNV_PRIME).reinterpret_as_int()
  }
  (h1, h2.reinterpret_as_uint())
}

///|
fn set_bit(self : BloomFilter, bit : Int) -> Unit {
  let byte_index = bit / 8
  let bit_offset = bit % 8
  self.bits[byte_index].set(bit_offset)
}

///|
fn get_bit(self : BloomFilter, bit : Int) -> Bool {
  let byte_index = bit / 8
  let bit_offset = bit % 8
  self.bits[byte_index].get(bit_offset)
}

///|
pub fn insert(self : BloomFilter, item : Array[Byte]) -> Unit {
  let (h1, h2) = hashes(item)
  for i in 0..<self.num_hashes {
    let bit = @utils.wrapping_add(
        h1,
        @utils.wrapping_mul(i.reinterpret_as_uint(), h2),
      ) %
      self.num_bits
    self.set_bit(bit.reinterpret_as_int())
  }
}

///|
pub fn contains(self : BloomFilter, item : Array[Byte]) -> Bool {
  let (h1, h2) = hashes(item)
  for i in 0..<self.num_hashes {
    let bit = @utils.wrapping_add(
        h1,
        @utils.wrapping_mul(i.reinterpret_as_uint(), h2),
      ) %
      self.num_bits
    if !self.get_bit(bit.reinterpret_as_int()) {
      return false
    }
  }
  true
}
