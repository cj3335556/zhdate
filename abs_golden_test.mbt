///|
/// Whether `input` parses to the date (`y`, `mo`, `d`).
fn is_date(
  input : String,
  ctx : @zhdate.Context,
  y : Int32,
  mo : Int32,
  d : Int32,
) -> Bool {
  match @zhdate.parse(input, ctx) {
    Ok(m) => m.year == y && m.month == mo && m.day == d
    Err(_) => false
  }
}

///|
/// Whether `input` parses to the invalid date (`y`, `mo`, `d`).
fn is_invalid_date(
  input : String,
  ctx : @zhdate.Context,
  y : Int32,
  mo : Int32,
  d : Int32,
) -> Bool {
  match @zhdate.parse(input, ctx) {
    Err(@zhdate.ParseError::InvalidDate(ey, emo, ed)) =>
      ey == y && emo == mo && ed == d
    _ => false
  }
}

///|
test "golden: full dates with year" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(is_date("2026年11月17日", ctx, 2026, 11, 17))
  assert_true(is_date("2026年11月17号", ctx, 2026, 11, 17))
  assert_true(is_date("2026年11月17", ctx, 2026, 11, 17))
  assert_true(is_date("2026年1月1日", ctx, 2026, 1, 1))
  assert_true(is_date("2026年12月31日", ctx, 2026, 12, 31))
  assert_true(is_date("999年1月1日", ctx, 999, 1, 1))
  assert_true(is_date("2024年2月29日", ctx, 2024, 2, 29))
}

///|
test "golden: chinese numerals" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(is_date("二〇二六年十一月十七日", ctx, 2026, 11, 17))
  assert_true(is_date("二零二六年十一月十七号", ctx, 2026, 11, 17))
  assert_true(
    is_date("二〇二六年十二月三十一日", ctx, 2026, 12, 31),
  )
  assert_true(is_date("二〇二四年二月二十九日", ctx, 2024, 2, 29))
  assert_true(is_date("二〇二六年一月一日", ctx, 2026, 1, 1))
  assert_true(is_date("二〇二六年十月十日", ctx, 2026, 10, 10))
  assert_true(is_date("二〇二六年三月二十日", ctx, 2026, 3, 20))
  assert_true(is_date("二〇二六年七月三十一日", ctx, 2026, 7, 31))
}

///|
test "golden: mixed numerals" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(is_date("2026年十一月十七日", ctx, 2026, 11, 17))
  assert_true(is_date("二〇二六年11月17日", ctx, 2026, 11, 17))
  assert_true(is_date("2026年二月十四日", ctx, 2026, 2, 14))
}

///|
test "golden: separator forms" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(is_date("2026-11-17", ctx, 2026, 11, 17))
  assert_true(is_date("2026/11/17", ctx, 2026, 11, 17))
  assert_true(is_date("2026.11.17", ctx, 2026, 11, 17))
  assert_true(is_date("2026-11", ctx, 2026, 11, 1))
  assert_true(is_date("2026/11", ctx, 2026, 11, 1))
}

///|
test "golden: month-day forms inherit year from context" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(is_date("11月17日", ctx, 2026, 11, 17))
  assert_true(is_date("11月17号", ctx, 2026, 11, 17))
  assert_true(is_date("11月17", ctx, 2026, 11, 17))
  assert_true(is_date("十月一日", ctx, 2026, 10, 1))
  assert_true(is_date("十一月十七日", ctx, 2026, 11, 17))
  assert_true(is_date("一月一日", ctx, 2026, 1, 1))
  let ctx2 : @zhdate.Context = { year: 2025, month: 12, day: 31, }
  assert_true(is_date("2月28日", ctx2, 2025, 2, 28))
}

///|
test "golden: year-month forms resolve to first day" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(is_date("2026年11月", ctx, 2026, 11, 1))
  assert_true(is_date("二〇二六年十一月", ctx, 2026, 11, 1))
}

///|
test "golden: invalid dates" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(is_invalid_date("2026年2月30日", ctx, 2026, 2, 30))
  assert_true(is_invalid_date("2026年2月29日", ctx, 2026, 2, 29))
  assert_true(is_invalid_date("2026年13月1日", ctx, 2026, 13, 1))
  assert_true(is_invalid_date("2026年11月32日", ctx, 2026, 11, 32))
  assert_true(is_invalid_date("2月30日", ctx, 2026, 2, 30))
  assert_true(is_invalid_date("2026年4月31日", ctx, 2026, 4, 31))
  assert_true(is_invalid_date("2026-13-01", ctx, 2026, 13, 1))
}

///|
test "golden: no match" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  assert_true(
    @zhdate.parse("天气不错", ctx) is Err(@zhdate.ParseError::NoMatch),
  )
  assert_true(@zhdate.parse("", ctx) is Err(@zhdate.ParseError::NoMatch))
  assert_true(@zhdate.parse("开会", ctx) is Err(@zhdate.ParseError::NoMatch))
  assert_true(@zhdate.parse("下周", ctx) is Err(@zhdate.ParseError::NoMatch))
}

///|
test "golden: date inside longer text" {
  let ctx : @zhdate.Context = { year: 2026, month: 6, day: 1, }
  guard @zhdate.parse("请于2026年11月17日前提交材料", ctx) is Ok(m) else {
    panic()
  }
  assert_eq(m.year, 2026)
  assert_eq(m.month, 11)
  assert_eq(m.day, 17)
  assert_eq(m.text, "2026年11月17日")
}
