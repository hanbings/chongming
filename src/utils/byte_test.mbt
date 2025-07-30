///|
test "utils::byte::byte_to_uint_le" {
  let val = byte_to_uint_le(0x78, 0x56, 0x34, 0x12)
  assert_eq(val, 0x12345678)
}
