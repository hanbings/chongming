///| XXHash 32-bit non-cryptographic hash algorithm state.
/// 
/// XXHash is an extremely fast non-cryptographic hash algorithm, working at speeds close to RAM limits.
/// This implementation provides the 32-bit version of XXHash with incremental updates and final digest computation.
/// The algorithm is designed for speed while maintaining good distribution properties.
/// 
/// ### Features
/// - Extremely fast hashing performance
/// - Incremental updates with buffering
/// - Configurable seed for different hash sequences
/// - Good avalanche and distribution properties
/// - Optimized for 32-bit platforms
pub struct XxHash32 {
  seed : UInt // Initial seed value for the hash function
  mut v1 : UInt // First accumulator state
  mut v2 : UInt // Second accumulator state
  mut v3 : UInt // Third accumulator state
  mut v4 : UInt // Fourth accumulator state
  mut total_len : Int // Total number of bytes processed
  buffer : Array[Byte] // Buffer for incomplete 16-byte blocks
}

///| First prime constant used in XXHash algorithm
const PRIME1 : UInt = 2654435761

///| Second prime constant used in XXHash algorithm
const PRIME2 : UInt = 2246822519

///| Third prime constant used in XXHash algorithm
const PRIME3 : UInt = 3266489917

///| Fourth prime constant used in XXHash algorithm
const PRIME4 : UInt = 668265263

///| Fifth prime constant used in XXHash algorithm
const PRIME5 : UInt = 374761393

///| Creates a new XXHash32 instance with the specified seed.
///
/// The seed allows you to generate different hash sequences for the same input data.
/// XXHash uses four internal accumulators initialized with different combinations of the seed
/// and prime constants to ensure good distribution.
///
/// ### Parameters
/// - `seed: UInt` – Initial seed value for the hash function
///
/// ### Returns
/// - `XxHash32` – New hash instance ready for incremental updates
///
/// ### Initialization
/// The four accumulators are initialized as follows:
/// - v1 = seed + PRIME1 + PRIME2
/// - v2 = seed + PRIME2
/// - v3 = seed
/// - v4 = seed - PRIME1
///
/// ### Example
/// ```moonbit
/// let _hasher = @xxhash.with_seed(0)  // Zero seed
/// let _hasher2 = @xxhash.with_seed(12345)  // Custom seed
/// ```
pub fn with_seed(seed : UInt) -> XxHash32 {
  XxHash32::{
    seed,
    v1: @utils.wrapping_add(@utils.wrapping_add(seed, PRIME1), PRIME2),
    v2: @utils.wrapping_add(seed, PRIME2),
    v3: seed,
    v4: @utils.wrapping_sub(seed, PRIME1),
    total_len: 0,
    buffer: Array::new(),
  }
}

///| Internal round function for processing 32-bit blocks.
///
/// Applies the core XXHash mixing algorithm to a 32-bit value and an accumulator.
/// This function is used to process each 32-bit chunk of input data.
///
/// ### Parameters
/// - `acc: UInt` – Current accumulator value
/// - `input: UInt` – 32-bit input value to mix
///
/// ### Returns
/// - `UInt` – Updated accumulator value
///
/// ### Algorithm
/// 1. Multiply input by PRIME2
/// 2. Add result to accumulator
/// 3. Rotate accumulator left by 13 bits
/// 4. Multiply accumulator by PRIME1
fn round(acc : UInt, input : UInt) -> UInt {
  let res = @utils.wrapping_mul(input, PRIME2)
  let mut acc = @utils.wrapping_add(acc, res)
  acc = @utils.rotate_left(acc, 13)
  acc = @utils.wrapping_mul(acc, PRIME1)
  acc
}

///| Finalizes the hash computation and returns the 32-bit hash value.
///
/// This function processes any remaining buffered bytes and applies the final
/// mixing steps to produce the complete hash value.
///
/// ### Parameters
/// - `self: XxHash32` – Hash instance to finalize
///
/// ### Returns
/// - `UInt` – 32-bit hash value
///
/// ### Algorithm
/// 1. Combine the four accumulators based on total length
/// 2. Add total length to the hash
/// 3. Process remaining bytes in 4-byte chunks
/// 4. Process any remaining individual bytes
/// 5. Apply final avalanche mixing (XOR and multiply operations)
///
/// ### Notes
/// - This function should be called only once after all data has been added
/// - The hash instance can be reused by calling update again after digest
/// - The result is a 32-bit unsigned integer
///
/// ### Example
/// ```moonbit
/// let hasher = @xxhash.with_seed(0)
/// hasher.update("Hello, xxHash!".to_bytes().to_array())
/// let _hash = hasher.digest()  // Get final hash value
/// ```
pub fn digest(self : XxHash32) -> UInt {
  let mut hash : UInt = 0
  if self.total_len >= 16 {
    hash = @utils.rotate_left(self.v1, 1)
    hash = @utils.wrapping_add(hash, @utils.rotate_left(self.v2, 7))
    hash = @utils.wrapping_add(hash, @utils.rotate_left(self.v3, 12))
    hash = @utils.wrapping_add(hash, @utils.rotate_left(self.v4, 18))
  } else {
    hash = @utils.wrapping_add(self.seed, PRIME5)
  }
  hash = @utils.wrapping_add(hash, self.total_len.reinterpret_as_uint())
  let mut idx = 0
  while idx + 4 <= self.buffer.length() {
    let s = self.buffer[idx:idx + 4]
    let k1 = @utils.byte_to_uint_le(s[0], s[1], s[2], s[3])
    hash = @utils.wrapping_add(hash, @utils.wrapping_mul(k1, PRIME3))
    hash = @utils.rotate_left(hash, 17)
    hash = @utils.wrapping_mul(hash, PRIME4)
    idx = idx + 4
  }
  while idx < self.buffer.length() {
    hash = @utils.wrapping_add(
      hash,
      @utils.wrapping_mul(self.buffer[idx].to_uint(), PRIME5),
    )
    hash = @utils.rotate_left(hash, 11)
    hash = @utils.wrapping_mul(hash, PRIME1)
    idx = idx + 1
  }
  hash = hash ^ (hash >> 15)
  hash = @utils.wrapping_mul(hash, PRIME2)
  hash = hash ^ (hash >> 13)
  hash = @utils.wrapping_mul(hash, PRIME3)
  hash = hash ^ (hash >> 16)
  hash
}

///| Adds data to the hash computation incrementally.
///
/// This function processes data in 16-byte blocks, buffering any remaining bytes
/// for the next update call. The four internal accumulators are updated as data is processed.
///
/// ### Parameters
/// - `self: XxHash32` – Hash instance to update
/// - `input: Array[Byte]` – Byte array to add to the hash computation
///
/// ### Algorithm
/// 1. If there are leftover bytes from previous updates, try to complete a 16-byte block
/// 2. Process complete 16-byte blocks using the round function on each 32-bit chunk
/// 3. Buffer any remaining bytes (<16) for the next update
///
/// ### Notes
/// - Multiple calls to update can be made before calling digest
/// - The order of updates matters for the final hash value
/// - Empty input arrays are handled gracefully
/// - Each 16-byte block is processed as four 32-bit chunks
///
/// ### Example
/// ```moonbit
/// let hasher = @xxhash.with_seed(0)
/// hasher.update("Hello".to_bytes().to_array())
/// hasher.update(", xxHash!".to_bytes().to_array())
/// ```
pub fn update(self : XxHash32, input : Array[Byte]) -> Unit {
  let mut input = input
  self.total_len += input.length()
  if !self.buffer.is_empty() {
    let needed = 16 - self.buffer.length()
    if input.length() < needed {
      self.buffer.append(input)
      return
    } else {
      self.buffer.append(input[:needed].to_array())
      let chunk = self.buffer[:16]
      let mut s = chunk[0:4]
      self.v1 = round(self.v1, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      s = chunk[4:8]
      self.v2 = round(self.v2, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      s = chunk[8:12]
      self.v3 = round(self.v3, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      s = chunk[12:16]
      self.v4 = round(self.v4, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      self.buffer.clear()
      input = input[needed:].to_array()
    }
  }
  while input.length() >= 16 {
    let mut s = input[0:4]
    self.v1 = round(self.v1, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    s = input[4:8]
    self.v2 = round(self.v2, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    s = input[8:12]
    self.v3 = round(self.v3, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    s = input[12:16]
    self.v4 = round(self.v4, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    input = input[16:].to_array()
  }
  if !input.is_empty() {
    self.buffer.append(input)
  }
}
