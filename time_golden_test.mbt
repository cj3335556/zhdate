///|
/// Whether `input` resolves to the time (`h`, `mi`, `s`) on the context date.
fn is_time(
  input : String,
  ctx : @zhdate.Context,
  h : Int32,
  mi : Int32,
  s : Int32,
) -> Bool {
  match @zhdate.parse(input, ctx) {
    Ok(m) =>
      match m.time {
        Some(t) =>
          t.hour == h &&
          t.minute == mi &&
          t.second == s &&
          m.year == ctx.year &&
          m.month == ctx.month &&
          m.day == ctx.day
        None => false
      }
    Err(_) => false
  }
}

///|
/// Whether `input` fails with `InvalidTime(h, mi, s)`.
fn is_invalid_time(
  input : String,
  ctx : @zhdate.Context,
  h : Int32,
  mi : Int32,
  s : Int32,
) -> Bool {
  match @zhdate.parse(input, ctx) {
    Err(@zhdate.ParseError::InvalidTime(eh, em, es)) =>
      eh == h && em == mi && es == s
    _ => false
  }
}

///|
test "time: colon forms" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_time("15:30", ctx, 15, 30, 0))
  assert_true(is_time("15:30:45", ctx, 15, 30, 45))
  assert_true(is_time("9:05", ctx, 9, 5, 0))
  assert_true(is_time("0:00", ctx, 0, 0, 0))
  assert_true(is_time("23:59:59", ctx, 23, 59, 59))
  assert_true(is_time("12:30", ctx, 12, 30, 0))
  assert_true(is_time("九点", ctx, 9, 0, 0))
}

///|
test "time: hour-minute-second forms" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_time("15点30分", ctx, 15, 30, 0))
  assert_true(is_time("15点30分45秒", ctx, 15, 30, 45))
  assert_true(is_time("15点30", ctx, 15, 30, 0))
  assert_true(is_time("15点", ctx, 15, 0, 0))
  assert_true(is_time("二十一点", ctx, 21, 0, 0))
  assert_true(is_time("九点二十分", ctx, 9, 20, 0))
}

///|
test "time: half past" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_time("3点半", ctx, 3, 30, 0))
  assert_true(is_time("9点半", ctx, 9, 30, 0))
  assert_true(is_time("三点半", ctx, 3, 30, 0))
}

///|
test "time: day parts" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_time("下午三点", ctx, 15, 0, 0))
  assert_true(is_time("下午三点半", ctx, 15, 30, 0))
  assert_true(is_time("上午9点20分", ctx, 9, 20, 0))
  assert_true(is_time("晚上8点", ctx, 20, 0, 0))
  assert_true(is_time("凌晨2点", ctx, 2, 0, 0))
  assert_true(is_time("早上6点半", ctx, 6, 30, 0))
  assert_true(is_time("中午", ctx, 12, 0, 0))
  assert_true(is_time("中午12点", ctx, 12, 0, 0))
  assert_true(is_time("中午1点", ctx, 13, 0, 0))
  assert_true(is_time("下午12点", ctx, 12, 0, 0))
  assert_true(is_time("晚上12点", ctx, 0, 0, 0))
  assert_true(is_time("下午13点30分", ctx, 13, 30, 0))
}

///|
test "time: invalid times" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  assert_true(is_invalid_time("25:00", ctx, 25, 0, 0))
  assert_true(is_invalid_time("15点70分", ctx, 15, 70, 0))
  assert_true(is_invalid_time("10:30:99", ctx, 10, 30, 99))
}

///|
test "time: inside longer text" {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  guard @zhdate.parse("会议在下午三点开始", ctx) is Ok(m) else {
    panic()
  }
  assert_eq(m.text, "下午三点")
  assert_true(m.kind is @zhdate.MatchKind::Time)
  guard m.time is Some(t) else { panic() }
  assert_eq(t.hour, 15)
}
