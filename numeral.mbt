///|
/// Value of a Chinese digit character (〇/零/一..九), or `None`.
fn cn_digit_value(c : Char) -> Int? {
  match c {
    '〇' | '零' => Some(0)
    '一' => Some(1)
    '二' => Some(2)
    '三' => Some(3)
    '四' => Some(4)
    '五' => Some(5)
    '六' => Some(6)
    '七' => Some(7)
    '八' => Some(8)
    '九' => Some(9)
    _ => None
  }
}

///|
/// Value of an ASCII digit character ('0'..'9'), or `None`.
fn ascii_digit_value(c : Char) -> Int? {
  match c {
    '0' => Some(0)
    '1' => Some(1)
    '2' => Some(2)
    '3' => Some(3)
    '4' => Some(4)
    '5' => Some(5)
    '6' => Some(6)
    '7' => Some(7)
    '8' => Some(8)
    '9' => Some(9)
    _ => None
  }
}

///|
/// Fold a string of digit characters into an integer using `digit_of`.
/// Returns `None` for empty input or any non-digit character.
fn digits_fold(s : String, digit_of : (Char) -> Int?) -> Int? {
  if s.length() == 0 {
    return None
  }
  let mut result = 0
  for c in s {
    guard digit_of(c) is Some(v) else {
      return None
    }
    result = result * 10 + v
  }
  Some(result)
}

///|
/// Parse a Chinese numeral written digit by digit, e.g. "二〇二六" -> 2026.
/// This is the form used for years in date expressions.
pub fn parse_cn_digits(s : String) -> Int? {
  digits_fold(s, cn_digit_value)
}

///|
/// Parse a Chinese numeral in multiplicative form (0..99),
/// e.g. "十" -> 10, "十一" -> 11, "二十三" -> 23, "三十一" -> 31.
/// This is the form used for months and days in date expressions.
pub fn parse_cn_number(s : String) -> Int? {
  let chars = []
  for c in s {
    chars.push(c)
  }
  let n = chars.length()
  if n == 0 {
    return None
  }
  if n == 1 {
    if chars[0] == '十' {
      return Some(10)
    }
    return cn_digit_value(chars[0])
  }
  if n == 2 {
    if chars[0] == '十' {
      guard cn_digit_value(chars[1]) is Some(v) else {
        return None
      }
      if v == 0 {
        return None
      }
      return Some(10 + v)
    }
    if chars[1] == '十' {
      guard cn_digit_value(chars[0]) is Some(v) else {
        return None
      }
      if v == 0 {
        return None
      }
      return Some(v * 10)
    }
    return None
  }
  if n == 3 {
    if chars[1] == '十' {
      guard cn_digit_value(chars[0]) is Some(tens) else {
        return None
      }
      guard cn_digit_value(chars[2]) is Some(ones) else {
        return None
      }
      if tens == 0 || ones == 0 {
        return None
      }
      return Some(tens * 10 + ones)
    }
  }
  None
}

///|
/// Parse a string of ASCII digits into an integer, e.g. "17" -> 17.
/// Returns `None` for empty input or any non-digit character.
pub fn parse_ascii_int(s : String) -> Int? {
  digits_fold(s, ascii_digit_value)
}
