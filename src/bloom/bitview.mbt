///|
pub struct BitView {
  mut bits : Byte
}

///|
pub fn bit_view(bits : Byte) -> BitView {
  BitView::{ bits, }
}

///|
pub fn value(self : BitView) -> Byte {
  self.bits
}

///|
pub fn set(self : BitView, i : Int) -> Unit {
  self.bits = self.bits | (1 << i)
}

///|
pub fn clear(self : BitView, i : Int) -> Unit {
  self.bits = self.bits ^ (1 << i)
}

///|
pub fn get(self : BitView, i : Int) -> Bool {
  (self.bits & (1 << i)) != 0
}
