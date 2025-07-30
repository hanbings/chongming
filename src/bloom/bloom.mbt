///| A probabilistic data structure for efficiently testing whether an element is a member of a set.
/// 
/// Bloom filters use multiple hash functions to map elements to multiple positions in a bit array.
/// When querying, if all mapped positions are 1, the element is considered to possibly exist;
/// if any position is 0, the element definitely does not exist.
/// Bloom filters may have false positives (false alarms) but never false negatives (misses).
pub struct BloomFilter {
  bits : Array[BitView] // Bit array for storing element existence information
  num_bits : UInt // Total number of bits in the bit array
  num_hashes : Int // Number of hash functions used
}

///| Square of natural logarithm, used for calculating optimal bit array size
const LN_2 : Double = 0.69314718056

///| Initial value for FNV hash algorithm
const FNV : Int = 0x811C9DC5

///| Prime factor for FNV hash algorithm
const FNV_PRIME : UInt = 0x01000193

///| Creates a new Bloom filter instance.
///
/// Calculates the optimal bit array size and number of hash functions based on
/// the expected number of elements and desired false positive rate.
///
/// ### Parameters
/// - `expected_items: Int64` – Expected number of elements to be inserted
/// - `false_positive_rate: Double` – Desired false positive rate (decimal between 0 and 1)
///
/// ### Returns
/// - `BloomFilter` – Newly created Bloom filter instance
///
/// ### Algorithm
/// 1. Calculate optimal bit array size using formula: m = -n * ln(p) / (ln(2)^2)
/// 2. Calculate optimal number of hash functions using formula: k = m/n * ln(2)
/// 3. Convert bit array size to bytes and initialize
///
/// ### Example
/// ```moonbit
/// let _bloom = @bloom.new(100_000_000, 0.01)  // Expect 100M elements, 1% false positive rate
/// ```
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

///| Computes two hash values for the given data.
///
/// Uses XXHash and FNV hash algorithms to generate two different hash values,
/// which will be used to generate multiple hash functions.
///
/// ### Parameters
/// - `data: Array[Byte]` – Data to be hashed
///
/// ### Returns
/// - `(UInt, UInt)` – Tuple of two hash values
///
/// ### Algorithm
/// 1. Generate first hash value using XXHash algorithm
/// 2. Generate second hash value using FNV-1a algorithm
/// 3. Return both hash values for subsequent linear combination
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

///| Sets the bit at the specified position in the bit array to 1.
///
/// ### Parameters
/// - `self: BloomFilter` – Bloom filter instance
/// - `bit: Int` – Position of the bit to set
fn set_bit(self : BloomFilter, bit : Int) -> Unit {
  let byte_index = bit / 8
  let bit_offset = bit % 8
  self.bits[byte_index].set(bit_offset)
}

///| Gets the value of the bit at the specified position in the bit array.
///
/// ### Parameters
/// - `self: BloomFilter` – Bloom filter instance
/// - `bit: Int` – Position of the bit to query
///
/// ### Returns
/// - `Bool` – Value of the bit at the specified position (true for 1, false for 0)
fn get_bit(self : BloomFilter, bit : Int) -> Bool {
  let byte_index = bit / 8
  let bit_offset = bit % 8
  self.bits[byte_index].get(bit_offset)
}

///| Inserts an element into the Bloom filter.
///
/// Computes multiple hash values for the element and sets the corresponding bits to 1.
/// If the element already exists, repeated insertion has no side effects.
///
/// ### Parameters
/// - `self: BloomFilter` – Bloom filter instance
/// - `item: Array[Byte]` – Element to insert (as byte array)
///
/// ### Algorithm
/// 1. Compute two base hash values for the element
/// 2. Generate multiple hash values through linear combination: hash_i = h1 + i * h2
/// 3. Map each hash value to corresponding position in the bit array
/// 4. Set bits at these positions to 1
///
/// ### Time Complexity
/// - O(k), where k is the number of hash functions
///
/// ### Example
/// ```moonbit
/// let bloom = @bloom.new(1000, 0.01)
/// bloom.insert("hello".to_bytes().to_array())
/// ```
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

///| Checks whether an element possibly exists in the Bloom filter.
///
/// Computes multiple hash values for the element and checks if all corresponding bits are 1.
/// If all bits are 1, returns true (element may exist);
/// if any bit is 0, returns false (element definitely does not exist).
///
/// ### Parameters
/// - `self: BloomFilter` – Bloom filter instance
/// - `item: Array[Byte]` – Element to query (as byte array)
///
/// ### Returns
/// - `Bool` – true if element may exist, false if element definitely does not exist
///
/// ### Properties
/// - **False Positives**: May return true even if element does not exist
/// - **No False Negatives**: Never occurs; if element has been inserted, will always return true
///
/// ### Time Complexity
/// - O(k), where k is the number of hash functions
///
/// ### Example
/// ```moonbit
/// let bloom = @bloom.new(1000, 0.01)
/// bloom.insert("hello".to_bytes().to_array())
/// let _exists = bloom.contains("hello".to_bytes().to_array())  // true
/// let _not_exists = bloom.contains("world".to_bytes().to_array())  // false
/// ```
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
