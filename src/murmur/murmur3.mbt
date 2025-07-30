///| Murmur3 32-bit non-cryptographic hash algorithm state.
/// Supports incremental updates with byte arrays and final digest computation.
/// Useful for fast hashing of arbitrary data.
pub(all) struct Murmur3_32 {
  mut seed : UInt
  mut hash : UInt
  mut length : UInt
  tail : Array[Byte]
}

///|
const C1 : UInt = 0xcc9e2d51

///|
const C2 : UInt = 0x1b873593

///|
pub fn with_seed(seed : UInt) -> Murmur3_32 {
  Murmur3_32::{ seed, hash: seed, length: 0, tail: Array::new() }
}

///|
pub fn update(self : Murmur3_32, data : Array[Byte]) -> Unit {
  let mut data = data
  // If tail buffer has leftover bytes, try to fill up a 4-byte block
  if !self.tail.is_empty() {
    let needed = 4 - self.tail.length()
    if data.length() >= needed {
      self.tail.append(data[:needed].to_array())
      let s = self.tail[:4]
      let k = @utils.byte_to_uint_le(s[0], s[1], s[2], s[3])
      self.mix_k(k)
      self.tail.clear()
      data = data[needed:].to_array()
      self.length += 4
    } else {
      // Not enough bytes to complete a block, keep buffering
      self.tail.append(data)
      return
    }
  }

  // Process remaining data in 4-byte blocks
  while data.length() >= 4 {
    let s = data[:4]
    let k = @utils.byte_to_uint_le(s[0], s[1], s[2], s[3])
    self.mix_k(k)
    self.length += 4
    data = data[4:].to_array()
  }

  // Buffer leftover bytes (<4)
  self.tail.append(data)
}

///|
pub fn digest(self : Murmur3_32) -> UInt {
  let mut k : UInt = 0
  // Combine leftover tail bytes into a UInt using little-endian order
  for i, b in self.tail.iter() {
    let shift = b.to_uint() << (8 * i)
    k = k | shift
  }
  if !self.tail.is_empty() {
    // Mix the remaining bytes
    k = @utils.wrapping_mul(k, C1)
    k = @utils.rotate_left(k, 15)
    k = @utils.wrapping_mul(k, C2)
    self.hash = self.hash ^ k
  }
  self.length = self.length + self.tail.length().reinterpret_as_uint()

  // fmix step
  self.hash = self.hash ^ self.length
  self.hash = fmix32(self.hash)
  self.hash
}

///|
fn mix_k(self : Murmur3_32, k : UInt) -> Unit {
  let mut k = @utils.wrapping_mul(k, C1)
  k = @utils.rotate_left(k, 15)
  k = @utils.wrapping_mul(k, C2)
  self.hash = self.hash ^ k
  self.hash = @utils.rotate_left(self.hash, 13)
  self.hash = @utils.wrapping_mul(self.hash, 5)
  self.hash = @utils.wrapping_add(self.hash, 0xe6546b64)
}

///|
fn fmix32(h : UInt) -> UInt {
  let mut h = h ^ (h >> 16)
  h = @utils.wrapping_mul(h, 0x85ebca6b)
  h = h ^ (h >> 13)
  h = @utils.wrapping_mul(h, 0xc2b2ae35)
  h = h ^ (h >> 16)
  h
}
