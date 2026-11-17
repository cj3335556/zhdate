///|
/// Whether `input` resolves to the datetime `y-m-d h:mi:s`.
fn is_dt(
  input : String,
  ctx : @zhdate.Context,
  y : Int32,
  mo : Int32,
  d : Int32,
  h : Int32,
  mi : Int32,
  s : Int32,
) -> Bool {
  match @zhdate.parse(input, ctx) {
    Ok(m) => {
      if !(m.kind is @zhdate.MatchKind::DateTime) {
        return false
      }
      if !(m.year == y && m.month == mo && m.day == d) {
        return false
      }
      match m.time {
        Some(t) => t.hour == h && t.minute == mi && t.second == s
        None => false
      }
    }
    Err(_) => false
  }
}

///|
test "combo: relative date + time" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_dt("下周三下午三点", ctx, 2026, 11, 25, 15, 0, 0))
  assert_true(is_dt("明天15:30", ctx, 2026, 11, 18, 15, 30, 0))
  assert_true(is_dt("三天后下午三点半", ctx, 2026, 11, 20, 15, 30, 0))
  assert_true(is_dt("月底晚上8点", ctx, 2026, 11, 30, 20, 0, 0))
}

///|
test "combo: absolute date + time" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_dt("2026年11月17日上午9点", ctx, 2026, 11, 17, 9, 0, 0))
  assert_true(is_dt("11月17日8点半", ctx, 2026, 11, 17, 8, 30, 0))
  assert_true(is_dt("2026-12-01 15:30", ctx, 2026, 12, 1, 15, 30, 0))
  assert_true(is_dt("十月一日中午", ctx, 2026, 10, 1, 12, 0, 0))
}

///|
test "combo: whitespace between date and time is allowed" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_dt("明天 下午三点", ctx, 2026, 11, 18, 15, 0, 0))
  assert_true(is_dt("11月17日　9:00", ctx, 2026, 11, 17, 9, 0, 0))
}

///|
test "combo: full text span is reported" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse("会议在下周三下午三点开始", ctx) is Ok(m) else {
    panic()
  }
  assert_eq(m.text, "下周三下午三点")
  assert_eq(m.start, 3)
  assert_true(m.kind is @zhdate.MatchKind::DateTime)
  guard m.time is Some(t) else { panic() }
  assert_eq(t.hour, 15)
}

///|
test "combo: non-adjacent date and time stay separate" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  // Words in between block the merge; parse returns the date only.
  guard @zhdate.parse("下周三开会，下午三点另行通知", ctx)
    is Ok(m) else {
    panic()
  }
  assert_eq(m.text, "下周三")
  assert_true(m.kind is @zhdate.MatchKind::Relative)
  let ms = @zhdate.find_all("下周三开会，下午三点另行通知", ctx)
  assert_eq(ms.length(), 2)
  assert_true(ms[1].kind is @zhdate.MatchKind::Time)
}

///|
test "combo: find_all merges pairs" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  let ms = @zhdate.find_all("明天下午三点和后天上午九点", ctx)
  assert_eq(ms.length(), 2)
  assert_true(ms[0].kind is @zhdate.MatchKind::DateTime)
  assert_eq(ms[0].year, 2026)
  assert_eq(ms[0].month, 11)
  assert_eq(ms[0].day, 18)
  assert_true(ms[1].kind is @zhdate.MatchKind::DateTime)
  assert_eq(ms[1].day, 19)
}
