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

///|
test "tokenize relative keywords" {
  let ts = @zhdate.tokenize("明天")
  assert_eq(ts.length(), 1)
  assert_true(ts[0].kind is @zhdate.TokenKind::KwRelDay(1))
  let ts2 = @zhdate.tokenize("大后天")
  assert_true(ts2[0].kind is @zhdate.TokenKind::KwRelDay(3))
  let ts3 = @zhdate.tokenize("昨天")
  assert_true(ts3[0].kind is @zhdate.TokenKind::KwRelDay(-1))
}

///|
test "tokenize weekday keywords" {
  let ts = @zhdate.tokenize("下周三")
  assert_eq(ts.length(), 2)
  assert_true(ts[0].kind is @zhdate.TokenKind::KwMod(1))
  assert_true(ts[1].kind is @zhdate.TokenKind::KwWeekday(3))
  let ts2 = @zhdate.tokenize("星期日")
  assert_true(ts2[0].kind is @zhdate.TokenKind::KwWeekday(7))
  let ts3 = @zhdate.tokenize("礼拜天")
  assert_true(ts3[0].kind is @zhdate.TokenKind::KwWeekday(7))
  let ts4 = @zhdate.tokenize("周日")
  assert_true(ts4[0].kind is @zhdate.TokenKind::KwWeekday(7))
}

///|
test "tokenize counter keywords" {
  let ts = @zhdate.tokenize("三天后")
  assert_eq(ts.length(), 3)
  assert_true(ts[0].kind is @zhdate.TokenKind::NumCn)
  assert_true(ts[1].kind is @zhdate.TokenKind::KwTian)
  assert_true(ts[2].kind is @zhdate.TokenKind::KwAfter)
  let ts2 = @zhdate.tokenize("两周前")
  assert_true(ts2[0].kind is @zhdate.TokenKind::NumCn)
  assert_true(ts2[1].kind is @zhdate.TokenKind::KwWeekWord)
  assert_true(ts2[2].kind is @zhdate.TokenKind::KwBefore)
  let ts3 = @zhdate.tokenize("三个月后")
  assert_true(ts3[1].kind is @zhdate.TokenKind::KwGe)
}

///|
test "tokenize boundary keywords" {
  let ts = @zhdate.tokenize("下月底")
  assert_eq(ts.length(), 2)
  assert_true(ts[0].kind is @zhdate.TokenKind::KwMod(1))
  assert_true(
    ts[1].kind is @zhdate.TokenKind::KwBoundary(@zhdate.BoundaryKind::MonthEnd),
  )
  let ts2 = @zhdate.tokenize("年底")
  assert_true(
    ts2[0].kind is @zhdate.TokenKind::KwBoundary(@zhdate.BoundaryKind::YearEnd),
  )
  let ts3 = @zhdate.tokenize("下个月底")
  assert_eq(ts3.length(), 3)
  assert_true(
    ts3[2].kind is @zhdate.TokenKind::KwBoundary(@zhdate.BoundaryKind::MonthEnd),
  )
}

///|
test "keywords win over single chars" {
  // "今天" is one keyword, not Other + KwTian.
  let ts = @zhdate.tokenize("今天")
  assert_eq(ts.length(), 1)
  // "2026年底": number + boundary keyword.
  let ts2 = @zhdate.tokenize("2026年底")
  assert_eq(ts2.length(), 2)
  assert_true(ts2[0].kind is @zhdate.TokenKind::NumAscii)
  assert_true(
    ts2[1].kind is @zhdate.TokenKind::KwBoundary(@zhdate.BoundaryKind::YearEnd),
  )
}
