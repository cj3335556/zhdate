///|
test "ranges: weekday shorthand" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse_range("下周一至周三", ctx) is Ok(r) else { panic() }
  assert_eq(r.from.year, 2026)
  assert_eq(r.from.month, 11)
  assert_eq(r.from.day, 23)
  assert_eq(r.to.month, 11)
  assert_eq(r.to.day, 25)
  assert_eq(r.text, "下周一至周三")
}

///|
test "ranges: day-of-month shorthand" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse_range("11月17日至19日", ctx) is Ok(r) else { panic() }
  assert_eq(r.from.day, 17)
  assert_eq(r.to.year, 2026)
  assert_eq(r.to.month, 11)
  assert_eq(r.to.day, 19)
  guard @zhdate.parse_range("十七日至十九日", ctx) is Ok(r2) else {
    panic()
  }
  assert_eq(r2.from.day, 17)
  assert_eq(r2.to.day, 19)
}

///|
test "ranges: full forms on both sides" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse_range("2026-11-17至2026-11-20", ctx) is Ok(r) else {
    panic()
  }
  assert_eq(r.from.day, 17)
  assert_eq(r.to.day, 20)
  guard @zhdate.parse_range("明天到下周五", ctx) is Ok(r2) else {
    panic()
  }
  assert_eq(r2.from.day, 18)
  assert_eq(r2.to.day, 27)
}

///|
test "ranges: connectors and spacing" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse_range("17日 ~ 19日", ctx) is Ok(r) else { panic() }
  assert_eq(r.from.day, 17)
  assert_eq(r.to.day, 19)
  guard @zhdate.parse_range("17日到19日", ctx) is Ok(r2) else { panic() }
  assert_eq(r2.to.day, 19)
}

///|
test "ranges: times inherit the day half" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse_range("下午三点至五点", ctx) is Ok(r) else {
    panic()
  }
  guard r.from.time is Some(t1) else { panic() }
  guard r.to.time is Some(t2) else { panic() }
  assert_eq(t1.hour, 15)
  assert_eq(t2.hour, 17)
  // Explicit day-parts are kept as written.
  guard @zhdate.parse_range("晚上11点至凌晨2点", ctx) is Ok(r2) else {
    panic()
  }
  guard r2.to.time is Some(t3) else { panic() }
  assert_eq(t3.hour, 2)
}

///|
test "ranges: datetime endpoint carries the time" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse_range("明天上午9点至11点", ctx) is Ok(r) else {
    panic()
  }
  assert_eq(r.from.day, 18)
  guard r.to.time is Some(t) else { panic() }
  assert_eq(t.hour, 11)
  assert_eq(r.to.day, 18)
}

///|
test "ranges: find_ranges and no-range text" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  let rs = @zhdate.find_ranges("11月17日至19日，下周三至周五", ctx)
  assert_eq(rs.length(), 2)
  assert_eq(rs[0].from.day, 17)
  assert_eq(rs[1].to.day, 27)
  assert_true(
    @zhdate.parse_range("明天开会", ctx) is Err(@zhdate.ParseError::NoMatch),
  )
}
