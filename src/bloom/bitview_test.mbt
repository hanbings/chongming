///|
test "bloom:bitview::simple" {
  let bits = bit_view(0)
  let res = bits.get(0)
  assert_false(res)
  let bits = bit_view(255)
  let res = bits.get(0)
  assert_true(res)
  bits.clear(0)
  let res = bits.get(0)
  assert_false(res)
}
