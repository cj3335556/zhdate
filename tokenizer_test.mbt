///|
test "tokenize ascii date" {
  let ts = @zhdate.tokenize("2026年11月17日")
  assert_eq(ts.length(), 6)
  assert_true(ts[0].kind is @zhdate.TokenKind::NumAscii)
  assert_eq(ts[0].text, "2026")
  assert_true(ts[1].kind is @zhdate.TokenKind::Year)
  assert_true(ts[2].kind is @zhdate.TokenKind::NumAscii)
  assert_eq(ts[2].text, "11")
  assert_true(ts[3].kind is @zhdate.TokenKind::Month)
  assert_eq(ts[4].text, "17")
  assert_true(ts[5].kind is @zhdate.TokenKind::Day)
}

///|
test "tokenize chinese date" {
  let ts = @zhdate.tokenize("二〇二六年十一月十七日")
  assert_eq(ts.length(), 6)
  assert_true(ts[0].kind is @zhdate.TokenKind::NumCn)
  assert_eq(ts[0].text, "二〇二六")
  assert_eq(ts[2].text, "十一")
  assert_eq(ts[4].text, "十七")
}

///|
test "tokenize separators and other" {
  let ts = @zhdate.tokenize("会议定在2026-11/17")
  assert_eq(ts.length(), 6)
  assert_true(ts[0].kind is @zhdate.TokenKind::Other)
  assert_eq(ts[0].text, "会议定在")
  assert_eq(ts[0].start, 0)
  assert_eq(ts[0].end, 4)
  assert_true(ts[1].kind is @zhdate.TokenKind::NumAscii)
  assert_eq(ts[1].start, 4)
  assert_true(ts[2].kind is @zhdate.TokenKind::Separator)
  assert_eq(ts[2].text, "-")
  assert_eq(ts[4].text, "/")
  assert_eq(ts[5].text, "17")
}

///|
test "tokenize offsets are char offsets" {
  let ts = @zhdate.tokenize("a年b")
  assert_eq(ts.length(), 3)
  assert_eq(ts[0].start, 0)
  assert_eq(ts[1].start, 1)
  assert_eq(ts[1].end, 2)
  assert_eq(ts[2].start, 2)
  assert_eq(ts[2].end, 3)
}

///|
test "tokenize empty string" {
  assert_eq(@zhdate.tokenize("").length(), 0)
}
