///|
test "skiplist::simple" {
  let skips = @skiplist.SkipList::new(0, 0)
  skips.insert(1, 2)
  skips.insert(3, 4)
  let res = skips.get(1)
  assert_eq(res, Some(2))
  let res = skips.get(3)
  assert_eq(res, Some(4))
  let res = skips.remove(1)
  assert_true(res)
  let res = skips.get(1)
  assert_eq(res, None)
}
