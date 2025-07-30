///| Represents a single node in the skip list.  
/// 
/// Contains a key-value pair and forward pointers (`next`) for each level.
/// The length of `next` determines the node's level.
pub struct Node[K, V] {
  key : K
  mut value : V
  next : Array[Node[K, V]?]
}

///| A probabilistic data structure supporting O(log n) search, insert, and delete.
/// 
/// The skip list maintains multiple levels of ordered linked lists.
pub struct SkipList[K, V] {
  mut level : Int       // Current effective height (starts from 1)
  max_level : Int       // Maximum allowed height
  p : Double            // Probability factor for random level generation
  head : Node[K, V]     // Sentinel head node (must have full next array)
}

///|
pub fn[K, V] SkipList::new(min_key : K, min_value : V) -> SkipList[K, V] {
  SkipList::{
    level: 0,
    max_level: 16,
    p: 0.5,
    head: Node::{ key: min_key, value: min_value, next: Array::make(16, None) },
  }
}

///|
pub fn[K, V] random_level(self : SkipList[K, V]) -> Int {
  let mut lvl = 1
  let rng = @random.Rand::new()
  while self.level < self.max_level {
    if rng.double() >= self.p {
      break
    }
    lvl = lvl + 1
  }
  lvl
}

///| Inserts a key-value pair into the skip list.
///
/// If the key already exists in the skip list, its associated value will be updated.
/// Otherwise, a new node is created with a randomly determined level and inserted
/// into the appropriate position in the skip list.
///
/// ### Parameters
/// - `key: K` – The key to insert. Must implement the `Compare` trait.
/// - `value: V` – The value associated with the key.
///
/// ### Behavior
/// 1. Searches for the position where the key should be inserted, from top level to bottom.
/// 2. If the key is already present at level 0, its value is updated.
/// 3. Otherwise, a random level is generated for the new node using geometric distribution.
/// 4. The new node is inserted by rewiring the forward pointers at each active level.
/// 5. The skip list height (`level`) is updated if the new node's level exceeds current height.
///
/// ### Notes
/// - The `update` array temporarily stores the last node visited at each level before insertion.
/// - The `head` node is a dummy sentinel node and not part of the actual data.
/// - All nodes' `next` arrays must be preallocated with `max_level` size to avoid index errors.
///
/// ### Time Complexity
/// - Average case: O(log n)
/// - Worst case: O(n), though highly unlikely due to probabilistic balancing.
///
/// ### Example
/// ```moonbit
/// let sl = @skiplist.SkipList::new(0, "")
/// sl.insert(42, "hello")
/// sl.insert(7, "world")
/// ```
pub fn[K : Compare, V] insert(
  self : SkipList[K, V],
  key : K,
  value : V,
) -> Unit {
  let update : Array[Node[K, V]?] = Array::make(self.max_level, None)
  let mut current = self.head
  let rev : Array[Int] = Array::new()
  for i in 0..<self.max_level {
    rev.push(i)
  }
  let rev = rev.rev()
  for i in rev {
    while current.next[i] is Some(next) {
      if next.key < key {
        current = next
      } else {
        break
      }
    }
    update[i] = Some(current)
  }
  if current.next[0] is Some(next) {
    if next.key == key {
      next.value = value
      return
    }
  }
  let new_level = self.random_level()
  if new_level > self.level {
    for i in self.level..<new_level {
      update[i] = Some(self.head)
    }
    self.level = new_level
  }
  let new_node = Node::{ key, value, next: Array::make(new_level, None) }
  for i in 0..<new_level {
    let prev = update[i]
    if prev is Some(p) {
      new_node.next[i] = p.next[i]
      p.next[i] = Some(new_node)
    }
  }
}

///| Retrieves the value associated with a given key from the skip list.
///
/// Traverses the skip list from top to bottom to locate the node containing the specified key.
/// Returns `Some(value)` if the key exists; otherwise returns `None`.
///
/// ### Parameters
/// - `key: K` – The key to search for. Must implement the `Compare` trait.
///
/// ### Returns
/// - `Some(value: V)` – The value bound to the key, if found.
/// - `None` – If the key is not present in the skip list.
///
/// ### Time Complexity
/// - Average case: O(log n)
/// - Worst case: O(n)
pub fn[K : Compare, V] get(self : SkipList[K, V], key : K) -> V? {
  let mut current = self.head
  let rev : Array[Int] = Array::new()
  for i in 0..<self.max_level {
    rev.push(i)
  }
  let rev = rev.rev()
  for i in rev {
    while current.next[i] is Some(next) {
      if next.key < key {
        current = next
      } else {
        break
      }
    }
  }
  if current.next[0] is Some(next) {
    if next.key == key {
      return Some(next.value)
    }
  }
  None
}

///| Removes a key-value pair from the skip list by key.
///
/// Locates the node containing the specified key and removes it by adjusting
/// the forward pointers at all active levels. If the key is not found, the function
/// returns `false`. If removal succeeds, it returns `true`.
///
/// ### Parameters
/// - `key: K` – The key of the node to remove. Must implement the `Compare` trait.
///
/// ### Returns
/// - `true` if the node was found and removed.
/// - `false` if the key was not found.
///
/// ### Notes
/// - After removal, the skip list's height may shrink if top levels become empty.
///
/// ### Time Complexity
/// - Average case: O(log n)
/// - Worst case: O(n)
pub fn[K : Compare, V] remove(self : SkipList[K, V], key : K) -> Bool {
  let update : Array[Node[K, V]?] = Array::make(self.max_level, None)
  let mut current = self.head
  let rev : Array[Int] = Array::new()
  for i in 0..<self.max_level {
    rev.push(i)
  }
  let rev = rev.rev()
  for i in rev {
    while current.next[i] is Some(next) {
      if next.key < key {
        current = next
      } else {
        break
      }
    }
    update[i] = Some(current)
  }
  if current.next[0] is Some(node) {
    if node.key != key {
      return false
    }
    for i in 0..<self.level {
      let prev = update[i]
      if prev is Some(prev) {
        if prev.next[i] is Some(next) {
          if next.key == key {
            prev.next[i] = next.next[i]
          }
        }
      }
      while self.level > 1 && self.head.next[self.level - 1] is None {
        self.level -= 1
      }
      return true
    }
  }
  return false
}
