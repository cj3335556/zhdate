///|
test "parse_cn_number basic" {
  assert_eq(@zhdate.parse_cn_number("一"), Some(1))
  assert_eq(@zhdate.parse_cn_number("九"), Some(9))
  assert_eq(@zhdate.parse_cn_number("〇"), Some(0))
  assert_eq(@zhdate.parse_cn_number("十"), Some(10))
}

///|
test "parse_cn_number tens" {
  assert_eq(@zhdate.parse_cn_number("十一"), Some(11))
  assert_eq(@zhdate.parse_cn_number("十七"), Some(17))
  assert_eq(@zhdate.parse_cn_number("二十"), Some(20))
  assert_eq(@zhdate.parse_cn_number("三十"), Some(30))
}

///|
test "parse_cn_number compound" {
  assert_eq(@zhdate.parse_cn_number("二十三"), Some(23))
  assert_eq(@zhdate.parse_cn_number("三十一"), Some(31))
  assert_eq(@zhdate.parse_cn_number("十二"), Some(12))
}

///|
test "parse_cn_number rejects invalid" {
  assert_true(@zhdate.parse_cn_number("") is None)
  assert_true(@zhdate.parse_cn_number("十十") is None)
  assert_true(@zhdate.parse_cn_number("二十3") is None)
  assert_true(@zhdate.parse_cn_number("十零") is None)
  assert_true(@zhdate.parse_cn_number("〇十") is None)
  assert_true(@zhdate.parse_cn_number("一百") is None)
}

///|
test "parse_cn_digits" {
  assert_eq(@zhdate.parse_cn_digits("二〇二六"), Some(2026))
  assert_eq(@zhdate.parse_cn_digits("二零二六"), Some(2026))
  assert_eq(@zhdate.parse_cn_digits("一九四九"), Some(1949))
  assert_eq(@zhdate.parse_cn_digits("〇"), Some(0))
  assert_true(@zhdate.parse_cn_digits("") is None)
  assert_true(@zhdate.parse_cn_digits("二a") is None)
  assert_true(@zhdate.parse_cn_digits("十") is None)
}

///|
test "parse_ascii_int" {
  assert_eq(@zhdate.parse_ascii_int("17"), Some(17))
  assert_eq(@zhdate.parse_ascii_int("0"), Some(0))
  assert_eq(@zhdate.parse_ascii_int("2026"), Some(2026))
  assert_true(@zhdate.parse_ascii_int("") is None)
  assert_true(@zhdate.parse_ascii_int("12a") is None)
}
