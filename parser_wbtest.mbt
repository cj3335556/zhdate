///|
test "match full date with units" {
  let ts = tokenize("2026年11月17日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  assert_eq(raw.year, Some(2026))
  assert_eq(raw.month, 11)
  assert_eq(raw.day, 17)
  assert_true(raw.kind is FullDate)
  assert_eq(raw.tok_start, 0)
  assert_eq(raw.tok_end, 6)
}

///|
test "match full chinese date" {
  let ts = tokenize("二〇二六年十一月十七日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  assert_eq(raw.year, Some(2026))
  assert_eq(raw.month, 11)
  assert_eq(raw.day, 17)
  assert_true(raw.kind is FullDate)
}

///|
test "match full date without day unit" {
  let ts = tokenize("2026年11月17")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  assert_eq(raw.year, Some(2026))
  assert_eq(raw.day, 17)
  assert_eq(raw.tok_end, 5)
}

///|
test "match month day" {
  let ts = tokenize("11月17日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  assert_eq(raw.year, None)
  assert_eq(raw.month, 11)
  assert_eq(raw.day, 17)
  assert_true(raw.kind is MonthDay)
}

///|
test "match month day chinese" {
  let ts = tokenize("十月一日")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  assert_eq(raw.month, 10)
  assert_eq(raw.day, 1)
  assert_true(raw.kind is MonthDay)
}

///|
test "match year month" {
  let ts = tokenize("2026年11月")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  assert_eq(raw.year, Some(2026))
  assert_eq(raw.month, 11)
  assert_eq(raw.day, 1)
  assert_true(raw.kind is YearMonth)
}

///|
test "match separator forms" {
  let ts = tokenize("2026-11-17")
  guard match_at(ts, 0) is Some(raw) else { panic() }
  assert_eq(raw.year, Some(2026))
  assert_eq(raw.month, 11)
  assert_eq(raw.day, 17)
  assert_eq(raw.tok_end, 5)
  let ts2 = tokenize("2026/11/17")
  assert_true(match_at(ts2, 0) is Some(_))
  let ts3 = tokenize("2026-11")
  guard match_at(ts3, 0) is Some(raw3) else { panic() }
  assert_true(raw3.kind is YearMonth)
}

///|
test "separator form without year shape is not matched" {
  // "11-17" is ambiguous (month-day); feature 1 does not match it.
  let ts = tokenize("11-17")
  assert_true(match_at(ts, 0) is None)
}

///|
test "scan_raw finds multiple and skips noise" {
  let ts = tokenize("会开在11月17日，或者2026-12-01")
  let raws = scan_raw(ts)
  assert_eq(raws.length(), 2)
  assert_eq(raws[0].month, 11)
  assert_eq(raws[0].day, 17)
  assert_eq(raws[1].year, Some(2026))
  assert_eq(raws[1].month, 12)
  assert_eq(raws[1].day, 1)
}

///|
test "no match on non-date text" {
  let ts = tokenize("今天天气不错")
  assert_eq(scan_raw(ts).length(), 0)
}
