///|
/// Whether `input` resolves to the date (`y`, `mo`, `d`).
fn is_rel_date(input : String, ctx : @zhdate.Context, y : Int32, mo : Int32, d : Int32) -> Bool {
  match @zhdate.parse(input, ctx) {
    Ok(m) => m.year == y && m.month == mo && m.day == d
    Err(_) => false
  }
}

///|
test "relative: day keywords" {
  // Context: 2026-11-17 (Tuesday).
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  assert_true(is_rel_date("今天", ctx, 2026, 11, 17))
  assert_true(is_rel_date("今日", ctx, 2026, 11, 17))
  assert_true(is_rel_date("明天", ctx, 2026, 11, 18))
  assert_true(is_rel_date("昨天", ctx, 2026, 11, 16))
  assert_true(is_rel_date("后天", ctx, 2026, 11, 19))
  assert_true(is_rel_date("前天", ctx, 2026, 11, 15))
  assert_true(is_rel_date("大后天", ctx, 2026, 11, 20))
  assert_true(is_rel_date("大前天", ctx, 2026, 11, 14))
}

///|
test "relative: day and week offsets" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  assert_true(is_rel_date("三天后", ctx, 2026, 11, 20))
  assert_true(is_rel_date("3天前", ctx, 2026, 11, 14))
  assert_true(is_rel_date("两天后", ctx, 2026, 11, 19))
  assert_true(is_rel_date("十天后", ctx, 2026, 11, 27))
  assert_true(is_rel_date("两周后", ctx, 2026, 12, 1))
  assert_true(is_rel_date("一周前", ctx, 2026, 11, 10))
  assert_true(is_rel_date("三星期后", ctx, 2026, 12, 8))
  assert_true(is_rel_date("一个月后", ctx, 2026, 12, 17))
  assert_true(is_rel_date("三个月后", ctx, 2027, 2, 17))
  assert_true(is_rel_date("两个月前", ctx, 2026, 9, 17))
  assert_true(is_rel_date("两年后", ctx, 2028, 11, 17))
  assert_true(is_rel_date("一年前", ctx, 2025, 11, 17))
}

///|
test "relative: weekdays" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  // This week starts on Monday 2026-11-16.
  assert_true(is_rel_date("下周三", ctx, 2026, 11, 25))
  assert_true(is_rel_date("上周一", ctx, 2026, 11, 9))
  assert_true(is_rel_date("本周三", ctx, 2026, 11, 18))
  assert_true(is_rel_date("下周日", ctx, 2026, 11, 29))
  assert_true(is_rel_date("下下周一", ctx, 2026, 11, 30))
  assert_true(is_rel_date("上个星期日", ctx, 2026, 11, 15))
  assert_true(is_rel_date("下个星期五", ctx, 2026, 11, 27))
  // Bare "周三" is the nearest upcoming Wednesday (this week's, since
  // it has not passed yet); bare "周一" has passed, so it rolls over.
  assert_true(is_rel_date("周三", ctx, 2026, 11, 18))
  assert_true(is_rel_date("周一", ctx, 2026, 11, 23))
  assert_true(is_rel_date("星期日", ctx, 2026, 11, 22))
  assert_true(is_rel_date("礼拜六", ctx, 2026, 11, 21))
}

///|
test "relative: boundaries" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  assert_true(is_rel_date("月底", ctx, 2026, 11, 30))
  assert_true(is_rel_date("下月底", ctx, 2026, 12, 31))
  assert_true(is_rel_date("上月底", ctx, 2026, 10, 31))
  assert_true(is_rel_date("月初", ctx, 2026, 11, 1))
  assert_true(is_rel_date("下个月初", ctx, 2026, 12, 1))
  assert_true(is_rel_date("年底", ctx, 2026, 12, 31))
  assert_true(is_rel_date("年初", ctx, 2026, 1, 1))
  assert_true(is_rel_date("下年底", ctx, 2027, 12, 31))
  assert_true(is_rel_date("下下年初", ctx, 2028, 1, 1))
  assert_true(is_rel_date("11月底", ctx, 2026, 11, 30))
  assert_true(is_rel_date("三月初", ctx, 2026, 3, 1))
  assert_true(is_rel_date("2026年底", ctx, 2026, 12, 31))
  assert_true(is_rel_date("二〇二七年初", ctx, 2027, 1, 1))
}

///|
test "relative: month shift with day" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  assert_true(is_rel_date("下个月17日", ctx, 2026, 12, 17))
  assert_true(is_rel_date("上月15号", ctx, 2026, 10, 15))
  assert_true(is_rel_date("下下个月3日", ctx, 2027, 1, 3))
  assert_true(is_rel_date("下个月底", ctx, 2026, 12, 31))
}

///|
test "relative: day clamping and year boundaries" {
  // Jan 31 + 1 month clamps to Feb 28.
  let ctx : @zhdate.Context = { year: 2026, month: 1, day: 31 }
  assert_true(is_rel_date("一个月后", ctx, 2026, 2, 28))
  // Cross-year month shift.
  let ctx2 : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  assert_true(is_rel_date("两个月后", ctx2, 2027, 1, 17))
  assert_true(is_rel_date("13个月后", ctx2, 2027, 12, 17))
}

///|
test "relative: inside longer text" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  guard @zhdate.parse("请在三天后提交材料", ctx) is Ok(m) else {
    panic()
  }
  assert_eq(m.text, "三天后")
  assert_eq(m.year, 2026)
  assert_eq(m.month, 11)
  assert_eq(m.day, 20)
  guard @zhdate.parse("下周三开会", ctx) is Ok(m2) else {
    panic()
  }
  assert_eq(m2.text, "下周三")
  assert_eq(m2.day, 25)
  assert_true(m2.kind is @zhdate.MatchKind::Relative)
}
