///|
test "utils::math::wrapping_mul" {
  assert_eq(wrapping_mul(0xFFFF_FFFF, 2), 0xFFFF_FFFE)
  assert_eq(wrapping_mul(123456789, 987654321), 4227814277)
}

///|
test "utils::math::wrapping_add" {
  assert_eq(wrapping_add(0xFFFF_FFFF, 1), 0)
  assert_eq(wrapping_add(0x12345678, 0x87654321), 0x99999999)
}

///|
test "utils::math::rotate_left" {
  assert_eq(rotate_left(0x12345678, 4), 0x23456781)
  assert_eq(rotate_left(0x80000000, 1), 1)
  assert_eq(rotate_left(0x00000001, 31), 0x80000000)
}
