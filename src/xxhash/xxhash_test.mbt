///|
test "xxhash::with_zero_seed" {
  let hasher = with_seed(0)
  hasher.update([
    'H', 'e', 'l', 'l', 'o', ',', ' ', 'x', 'x', 'H', 'a', 's', 'h', '!',
  ])
  let hash = hasher.digest()
  assert_eq(hash, 0x4bbbeba2)
}

///|
test "xxhash::with_seed" {
  let hasher = with_seed(114514)
  hasher.update([
    'H', 'e', 'l', 'l', 'o', ',', ' ', 'x', 'x', 'H', 'a', 's', 'h', '!',
  ])
  let hash = hasher.digest()
  assert_eq(hash, 0xd277ebd2)
}
