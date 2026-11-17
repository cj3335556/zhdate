///|
test "match full date with units" {
  let ts = tokenize("2026年11月17日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is Day(Some(2026), 11, 17, FullDate) else { panic() }
  assert_eq(raw.tok_start, 0)
  assert_eq(raw.tok_end, 6)
}

///|
test "match full chinese date" {
  let ts = tokenize("二〇二六年十一月十七日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is Day(Some(2026), 11, 17, FullDate) else { panic() }
}

///|
test "match month day" {
  let ts = tokenize("11月17日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is Day(None, 11, 17, MonthDay) else { panic() }
  let ts2 = tokenize("十月一日")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is Day(None, 10, 1, MonthDay) else { panic() }
}

///|
test "match year month and separator forms" {
  let ts = tokenize("2026年11月")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is Day(Some(2026), 11, 1, YearMonth) else { panic() }
  let ts2 = tokenize("2026-11-17")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is Day(Some(2026), 11, 17, FullDate) else { panic() }
  assert_eq(raw2.tok_end, 5)
  let ts3 = tokenize("2026-11")
  guard match_at(ts3, 0) is Some(raw3) else { panic() }
  guard raw3.expr is Day(Some(2026), 11, 1, YearMonth) else { panic() }
}

///|
test "match relative day keywords" {
  let ts = tokenize("明天")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is DayOffset(1) else { panic() }
  let ts2 = tokenize("大后天")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is DayOffset(3) else { panic() }
}

///|
test "match day and week offsets" {
  let ts = tokenize("三天后")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is DayOffset(3) else { panic() }
  assert_eq(raw.tok_end, 3)
  let ts2 = tokenize("两周前")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is DayOffset(-14) else { panic() }
  let ts3 = tokenize("3天前")
  guard match_at(ts3, 0) is Some(raw3) else { panic() }
  guard raw3.expr is DayOffset(-3) else { panic() }
}

///|
test "match month and year offsets" {
  let ts = tokenize("三个月后")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is MonthShift(3, None) else { panic() }
  assert_eq(raw.tok_end, 4)
  let ts2 = tokenize("三月后")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is MonthShift(3, None) else { panic() }
  let ts3 = tokenize("两年后")
  guard match_at(ts3, 0) is Some(raw3) else { panic() }
  guard raw3.expr is YearShift(2) else { panic() }
}

///|
test "match weekday with modifiers" {
  let ts = tokenize("下周三")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is Weekday(1, 3, false) else { panic() }
  assert_eq(raw.tok_end, 2)
  let ts2 = tokenize("周三")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is Weekday(0, 3, true) else { panic() }
  let ts3 = tokenize("下下周一")
  guard match_at(ts3, 0) is Some(raw3) else { panic() }
  guard raw3.expr is Weekday(2, 1, false) else { panic() }
  let ts4 = tokenize("上个星期日")
  guard match_at(ts4, 0) is Some(raw4) else { panic() }
  guard raw4.expr is Weekday(-1, 7, false) else { panic() }
}

///|
test "match boundaries" {
  let ts = tokenize("下月底")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is BoundaryRel(1, MonthEnd) else { panic() }
  let ts2 = tokenize("月底")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is BoundaryRel(0, MonthEnd) else { panic() }
  let ts3 = tokenize("11月底")
  guard match_at(ts3, 0) is Some(raw3) else { panic() }
  guard raw3.expr is BoundaryAbs(11, MonthEnd) else { panic() }
  let ts4 = tokenize("2026年底")
  guard match_at(ts4, 0) is Some(raw4) else { panic() }
  guard raw4.expr is BoundaryAbs(2026, YearEnd) else { panic() }
}

///|
test "match month shift with day" {
  let ts = tokenize("下个月17日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  guard raw.expr is MonthShift(1, Some(17)) else { panic() }
  assert_eq(raw.tok_end, 5)
  let ts2 = tokenize("上月15号")
  guard match_at(ts2, 0) is Some(raw2) else { panic() }
  guard raw2.expr is MonthShift(-1, Some(15)) else { panic() }
}

///|
test "scan_raw finds multiple and skips noise" {
  let ts = tokenize("会开在11月17日，或者2026-12-01")
  let raws = scan_raw(ts)
  assert_eq(raws.length(), 2)
  let ts2 = tokenize("明天开会，三天后截止")
  let raws2 = scan_raw(ts2)
  assert_eq(raws2.length(), 2)
}

///|
test "no match on non-date text" {
  assert_eq(scan_raw(tokenize("天气不错")).length(), 0)
  assert_eq(scan_raw(tokenize("下周")).length(), 0)
}
