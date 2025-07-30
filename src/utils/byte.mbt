///| Converts four bytes into a 32-bit unsigned integer using little-endian order.
///
/// This means the first byte `a` is the least significant byte (lowest 8 bits),
/// the second byte `b` is shifted left by 8 bits,
/// the third byte `c` is shifted left by 16 bits,
/// and the fourth byte `d` is shifted left by 24 bits (most significant byte).
///
/// # Parameters
/// - `a`, `b`, `c`, `d`: The input bytes in order from least significant to most significant.
///
/// # Returns
/// A 32-bit unsigned integer composed from the four bytes.
///
/// # Example
/// ```
/// let val = byte_to_uint_le(0x78, 0x56, 0x34, 0x12)
/// assert_eq(val, 0x12345678)
/// // val == 0x12345678
/// ```
pub fn byte_to_uint_le(a : Byte, b : Byte, c : Byte, d : Byte) -> UInt {
  a.to_uint() | (b.to_uint() << 8) | (c.to_uint() << 16) | (d.to_uint() << 24)
}
