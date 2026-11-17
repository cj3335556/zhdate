///|
fn ctx_2026() -> @zhdate.Context {
  { year: 2026, month: 6, day: 1, }
}

///|
test "parse full date" {
  guard @zhdate.parse("2026年11月17日", ctx_2026()) is Ok(m) else { panic() }
  assert_eq(m.year, 2026)
  assert_eq(m.month, 11)
  assert_eq(m.day, 17)
  assert_eq(m.text, "2026年11月17日")
  assert_eq(m.start, 0)
  assert_eq(m.end, 11)
}

///|
test "parse chinese full date" {
  guard @zhdate.parse("二〇二六年十一月十七日", ctx_2026()) is Ok(m) else {
    panic()
  }
  assert_eq(m.year, 2026)
  assert_eq(m.month, 11)
  assert_eq(m.day, 17)
}

///|
test "parse separator date" {
  guard @zhdate.parse("deadline 2026-11-17 done", ctx_2026()) is Ok(m) else {
    panic()
  }
  assert_eq(m.year, 2026)
  assert_eq(m.month, 11)
  assert_eq(m.day, 17)
  assert_eq(m.text, "2026-11-17")
  assert_eq(m.start, 9)
  assert_eq(m.end, 19)
}

///|
test "parse infers year from context" {
  guard @zhdate.parse("11月17日", ctx_2026()) is Ok(m) else { panic() }
  assert_eq(m.year, 2026)
  assert_eq(m.month, 11)
  assert_eq(m.day, 17)
}

///|
test "parse chinese month day" {
  guard @zhdate.parse("十月一日", ctx_2026()) is Ok(m) else { panic() }
  assert_eq(m.year, 2026)
  assert_eq(m.month, 10)
  assert_eq(m.day, 1)
}

///|
test "parse year month" {
  guard @zhdate.parse("2026年11月", ctx_2026()) is Ok(m) else { panic() }
  assert_eq(m.year, 2026)
  assert_eq(m.month, 11)
  assert_eq(m.day, 1)
}

///|
test "parse invalid date" {
  guard @zhdate.parse("2026年2月30日", ctx_2026())
    is Err(@zhdate.ParseError::InvalidDate(y, mo, d)) else {
    panic()
  }
  assert_eq(y, 2026)
  assert_eq(mo, 2)
  assert_eq(d, 30)
}

///|
test "parse no match" {
  assert_true(
    @zhdate.parse("今天天气不错", ctx_2026())
    is Err(@zhdate.ParseError::NoMatch),
  )
}

///|
test "find_all extracts multiple dates" {
  let ms = @zhdate.find_all(
    "11月17日开会，2026-12-01截止，2月30日无效",
    ctx_2026(),
  )
  assert_eq(ms.length(), 2)
  assert_eq(ms[0].month, 11)
  assert_eq(ms[0].day, 17)
  assert_eq(ms[1].year, 2026)
  assert_eq(ms[1].month, 12)
  assert_eq(ms[1].day, 1)
}

///|
test "find_all empty" {
  assert_eq(@zhdate.find_all("没有日期", ctx_2026()).length(), 0)
}
