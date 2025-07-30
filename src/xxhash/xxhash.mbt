///|
pub struct XxHash32 {
  seed : UInt
  mut v1 : UInt
  mut v2 : UInt
  mut v3 : UInt
  mut v4 : UInt
  mut total_len : Int
  buffer : Array[Byte]
}

///|
const PRIME1 : UInt = 2654435761

///|
const PRIME2 : UInt = 2246822519

///|
const PRIME3 : UInt = 3266489917

///|
const PRIME4 : UInt = 668265263

///|
const PRIME5 : UInt = 374761393

///|
pub fn with_seed(seed : UInt) -> XxHash32 {
  XxHash32::{
    seed,
    v1: @utils.wrapping_add(@utils.wrapping_add(seed, PRIME1), PRIME2),
    v2: @utils.wrapping_add(seed, PRIME2),
    v3: seed,
    v4: @utils.wrapping_sub(seed, PRIME1),
    total_len: 0,
    buffer: Array::new(),
  }
}

///|
fn round(acc : UInt, input : UInt) -> UInt {
  let res = @utils.wrapping_mul(input, PRIME2)
  let mut acc = @utils.wrapping_add(acc, res)
  acc = @utils.rotate_left(acc, 13)
  acc = @utils.wrapping_mul(acc, PRIME1)
  acc
}

///|
pub fn digest(self : XxHash32) -> UInt {
  let mut hash : UInt = 0
  if self.total_len >= 16 {
    hash = @utils.rotate_left(self.v1, 1)
    hash = @utils.wrapping_add(hash, @utils.rotate_left(self.v2, 7))
    hash = @utils.wrapping_add(hash, @utils.rotate_left(self.v3, 12))
    hash = @utils.wrapping_add(hash, @utils.rotate_left(self.v4, 18))
  } else {
    hash = @utils.wrapping_add(self.seed, PRIME5)
  }
  hash = @utils.wrapping_add(hash, self.total_len.reinterpret_as_uint())
  let mut idx = 0
  while idx + 4 <= self.buffer.length() {
    let s = self.buffer[idx:idx + 4]
    let k1 = @utils.byte_to_uint_le(s[0], s[1], s[2], s[3])
    hash = @utils.wrapping_add(hash, @utils.wrapping_mul(k1, PRIME3))
    hash = @utils.rotate_left(hash, 17)
    hash = @utils.wrapping_mul(hash, PRIME4)
    idx = idx + 4
  }
  while idx < self.buffer.length() {
    hash = @utils.wrapping_add(
      hash,
      @utils.wrapping_mul(self.buffer[idx].to_uint(), PRIME5),
    )
    hash = @utils.rotate_left(hash, 11)
    hash = @utils.wrapping_mul(hash, PRIME1)
    idx = idx + 1
  }
  hash = hash ^ (hash >> 15)
  hash = @utils.wrapping_mul(hash, PRIME2)
  hash = hash ^ (hash >> 13)
  hash = @utils.wrapping_mul(hash, PRIME3)
  hash = hash ^ (hash >> 16)
  hash
}

///|
pub fn update(self : XxHash32, input : Array[Byte]) -> Unit {
  let mut input = input
  self.total_len += input.length()
  if !self.buffer.is_empty() {
    let needed = 16 - self.buffer.length()
    if input.length() < needed {
      self.buffer.append(input)
      return
    } else {
      self.buffer.append(input[:needed].to_array())
      let chunk = self.buffer[:16]
      let mut s = chunk[0:4]
      self.v1 = round(self.v1, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      s = chunk[4:8]
      self.v2 = round(self.v2, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      s = chunk[8:12]
      self.v3 = round(self.v3, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      s = chunk[12:16]
      self.v4 = round(self.v4, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
      self.buffer.clear()
      input = input[needed:].to_array()
    }
  }
  while input.length() >= 16 {
    let mut s = input[0:4]
    self.v1 = round(self.v1, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    s = input[4:8]
    self.v2 = round(self.v2, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    s = input[8:12]
    self.v3 = round(self.v3, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    s = input[12:16]
    self.v4 = round(self.v4, @utils.byte_to_uint_le(s[0], s[1], s[2], s[3]))
    input = input[16:].to_array()
  }
  if !input.is_empty() {
    self.buffer.append(input)
  }
}
