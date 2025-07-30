///| Performs wrapping (modulo 2³²) multiplication of two unsigned integers.
/// 
/// This function simulates 32-bit unsigned integer multiplication. The product
/// is truncated to the lower 32 bits, discarding overflow bits.
///
/// ### Examples
/// ```
/// assert_eq(wrapping_mul(0xFFFF_FFFF, 2), 0xFFFF_FFFE)
/// assert_eq(wrapping_mul(123456789, 987654321), 4227814277)
/// ```
pub fn wrapping_mul(a : UInt, b : UInt) -> UInt {
  ((a.to_uint64() * b.to_uint64()) & 0xFFFF_FFFF).to_uint()
}

///| Performs wrapping (modulo 2³²) multiplication of two signed integers.
/// 
/// This function treats both signed integers as unsigned 64-bit, multiplies
/// them, and truncates the result to the lower 32 bits. The final result is
/// reinterpreted as a signed 32-bit integer.
/// 
/// ### Examples
/// ```
/// assert_eq(wrapping_mul_int(-1, 2), -2)
/// assert_eq(wrapping_mul_int(123456, -654321), -173166336)
/// ```
pub fn wrapping_mul_int(a : Int, b : Int) -> Int {
  ((a.to_uint64() * b.to_uint64()) & 0xFFFF_FFFF)
  .reinterpret_as_int64()
  .to_int()
}

///| Performs wrapping (modulo 2³²) addition of two unsigned integers.
/// 
/// This function simulates 32-bit unsigned integer addition. The result is
/// truncated to the lower 32 bits, wrapping on overflow.
///
/// # Examples
/// ```
/// assert_eq(wrapping_add(0xFFFF_FFFF, 1), 0)
/// assert_eq(wrapping_add(0x12345678, 0x87654321), 0x99999999)
/// ```
pub fn wrapping_add(a : UInt, b : UInt) -> UInt {
  let sum = (a.to_int64() + b.to_int64()).reinterpret_as_uint64().to_uint()
  sum & 0xFFFF_FFFF
}

///| Performs wrapping (modulo 2³²) addition of two signed integers.
/// 
/// This function adds two signed integers, reinterprets the result as a 32-bit
/// unsigned integer with wrapping semantics.
/// 
/// ### Examples
/// ```
/// assert_eq(wrapping_add_int(2147483647, 1), 2147483648)
/// assert_eq(wrapping_add_int(-1, -1), 4294967294)
/// ```
pub fn wrapping_add_int(a : Int, b : Int) -> UInt {
  let sum = (a.to_int64() + b.to_int64()).reinterpret_as_uint64().to_uint()
  sum & 0xFFFF_FFFF
}

///| Performs wrapping (modulo 2³²) subtraction of two unsigned integers.
///
/// This function simulates 32-bit unsigned integer subtraction. The result is
/// truncated to the lower 32 bits, wrapping on underflow.
///
/// # Examples
/// ```
/// assert_eq(wrapping_sub(0, 1), 0xFFFF_FFFF)
/// assert_eq(wrapping_sub(0x12345678, 0x87654321), 0x8ACF1357)
/// ```
pub fn wrapping_sub(a : UInt, b : UInt) -> UInt {
  let diff = (a.to_int64() - b.to_int64()).reinterpret_as_uint64().to_uint()
  diff & 0xFFFF_FFFF
}

///| Rotates a 32-bit unsigned integer to the left by a given number of bits.
///
/// Bits shifted out from the left end are wrapped around to the right end.
/// The shift amount is taken modulo 32.
///
/// # Examples
/// ```
/// assert_eq(rotate_left(0x12345678, 4), 0x23456781)
/// assert_eq(rotate_left(0x80000000, 1), 1)
/// assert_eq(rotate_left(0x00000001, 31), 0x80000000)
/// ```
pub fn rotate_left(value : UInt, shift : UInt) -> UInt {
  let amt = (shift % 32).reinterpret_as_int()
  (value << amt) | (value >> (32 - amt))
}
