///|
test "murmur3::with_zero_seed" {
  let hasher = with_seed(0)
  hasher.update(['h', 'e', 'l', 'l', 'o', ' '])
  hasher.update(['w', 'o', 'r', 'l', 'd'])
  let hash = hasher.digest()
  assert_eq(hash, 0x5e928f0f)
}

///|
test "murmur3::with_seed" {
  let hasher = with_seed(114514)
  hasher.update(['h', 'e', 'l', 'l', 'o', ' '])
  hasher.update(['w', 'o', 'r', 'l', 'd'])
  let hash = hasher.digest()
  assert_eq(hash, 0xc7a233db)
}