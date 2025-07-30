///| Murmur3 32-bit non-cryptographic hash algorithm state.
/// 
/// Murmur3 is a fast, high-quality hash function designed for general-purpose hashing.
/// This implementation supports incremental updates with byte arrays and final digest computation.
/// The algorithm is optimized for speed while maintaining good distribution properties.
/// 
/// ### Features
/// - Fast non-cryptographic hashing
/// - Incremental updates
/// - Configurable seed for different hash sequences
/// - Good distribution and avalanche properties
pub(all) struct Murmur3_32 {
  mut seed : UInt // Initial seed value for the hash function
  mut hash : UInt // Current hash state
  mut length : UInt // Total number of bytes processed
  tail : Array[Byte] // Buffer for incomplete 4-byte blocks
}

///| First mixing constant used in the Murmur3 algorithm
const C1 : UInt = 0xcc9e2d51

///| Second mixing constant used in the Murmur3 algorithm
const C2 : UInt = 0x1b873593

///| Creates a new Murmur3_32 hash instance with the specified seed.
///
/// The seed allows you to generate different hash sequences for the same input data,
/// which is useful for preventing hash-based attacks and ensuring hash diversity.
///
/// ### Parameters
/// - `seed: UInt` – Initial seed value for the hash function
///
/// ### Returns
/// - `Murmur3_32` – New hash instance ready for incremental updates
///
/// ### Example
/// ```moonbit
/// let _hasher = @murmur3.with_seed(0)  // Zero seed
/// let _hasher2 = @murmur3.with_seed(12345)  // Custom seed
/// ```
pub fn with_seed(seed : UInt) -> Murmur3_32 {
  Murmur3_32::{ seed, hash: seed, length: 0, tail: Array::new() }
}

///| Adds data to the hash computation incrementally.
///
/// This function processes data in 4-byte blocks, buffering any remaining bytes
/// for the next update call. The hash state is updated as data is processed.
///
/// ### Parameters
/// - `self: Murmur3_32` – Hash instance to update
/// - `data: Array[Byte]` – Byte array to add to the hash computation
///
/// ### Algorithm
/// 1. If there are leftover bytes from previous updates, try to complete a 4-byte block
/// 2. Process complete 4-byte blocks using the mixing function
/// 3. Buffer any remaining bytes (<4) for the next update
///
/// ### Notes
/// - Multiple calls to update can be made before calling digest
/// - The order of updates matters for the final hash value
/// - Empty data arrays are handled gracefully
///
/// ### Example
/// ```moonbit
/// let hasher = @murmur3.with_seed(0)
/// hasher.update("hello".to_bytes().to_array())
/// hasher.update("world".to_bytes().to_array())
/// ```
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

///| Finalizes the hash computation and returns the 32-bit hash value.
///
/// This function processes any remaining buffered bytes and applies the final
/// mixing step to produce the complete hash value.
///
/// ### Parameters
/// - `self: Murmur3_32` – Hash instance to finalize
///
/// ### Returns
/// - `UInt` – 32-bit hash value
///
/// ### Algorithm
/// 1. Combine any remaining tail bytes into a 32-bit value
/// 2. Apply mixing to the tail bytes if present
/// 3. XOR the hash with the total length
/// 4. Apply final mixing (fmix32) to produce the result
///
/// ### Notes
/// - This function should be called only once after all data has been added
/// - The hash instance can be reused by calling update again after digest
/// - The result is a 32-bit unsigned integer
///
/// ### Example
/// ```moonbit
/// let hasher = @murmur3.with_seed(0)
/// hasher.update("hello world".to_bytes().to_array())
/// let _hash = hasher.digest()  // Get final hash value
/// ```
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

///| Internal mixing function for 32-bit blocks.
///
/// Applies the core Murmur3 mixing algorithm to a 32-bit value,
/// updating the hash state with the mixed result.
///
/// ### Parameters
/// - `self: Murmur3_32` – Hash instance to update
/// - `k: UInt` – 32-bit value to mix into the hash
///
/// ### Algorithm
/// 1. Multiply by C1 constant
/// 2. Rotate left by 15 bits
/// 3. Multiply by C2 constant
/// 4. XOR with current hash state
/// 5. Rotate hash left by 13 bits
/// 6. Multiply hash by 5 and add constant
fn mix_k(self : Murmur3_32, k : UInt) -> Unit {
  let mut k = @utils.wrapping_mul(k, C1)
  k = @utils.rotate_left(k, 15)
  k = @utils.wrapping_mul(k, C2)
  self.hash = self.hash ^ k
  self.hash = @utils.rotate_left(self.hash, 13)
  self.hash = @utils.wrapping_mul(self.hash, 5)
  self.hash = @utils.wrapping_add(self.hash, 0xe6546b64)
}

///| Final mixing function for 32-bit hash values.
///
/// Applies the final mixing step to ensure good distribution and avalanche properties.
/// This is the final step in the Murmur3 algorithm.
///
/// ### Parameters
/// - `h: UInt` – 32-bit hash value to finalize
///
/// ### Returns
/// - `UInt` – Finalized 32-bit hash value
///
/// ### Algorithm
/// 1. XOR with right-shifted value (16 bits)
/// 2. Multiply by constant 0x85ebca6b
/// 3. XOR with right-shifted value (13 bits)
/// 4. Multiply by constant 0xc2b2ae35
/// 5. XOR with right-shifted value (16 bits)
fn fmix32(h : UInt) -> UInt {
  let mut h = h ^ (h >> 16)
  h = @utils.wrapping_mul(h, 0x85ebca6b)
  h = h ^ (h >> 13)
  h = @utils.wrapping_mul(h, 0xc2b2ae35)
  h = h ^ (h >> 16)
  h
}
