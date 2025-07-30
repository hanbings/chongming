///|
test "bloom::simple" {
  let bloom = @bloom.new(100_000_000, 0.01)
  bloom.insert("hello".to_bytes().to_array())
  bloom.insert("world".to_bytes().to_array())
  let res = bloom.contains("hello".to_bytes().to_array())
  assert_true(res)
  let res = bloom.contains("world!".to_bytes().to_array())
  assert_false(res)
}
