///|
test "leap years" {
  assert_true(@zhdate.is_leap_year(2024))
  assert_true(@zhdate.is_leap_year(2000))
  assert_false(@zhdate.is_leap_year(2026))
  assert_false(@zhdate.is_leap_year(1900))
  assert_true(@zhdate.is_leap_year(2400))
}

///|
test "days in month" {
  assert_eq(@zhdate.days_in_month(2026, 1), 31)
  assert_eq(@zhdate.days_in_month(2026, 2), 28)
  assert_eq(@zhdate.days_in_month(2024, 2), 29)
  assert_eq(@zhdate.days_in_month(2026, 4), 30)
  assert_eq(@zhdate.days_in_month(2026, 12), 31)
  assert_eq(@zhdate.days_in_month(2026, 13), 0)
  assert_eq(@zhdate.days_in_month(2026, 0), 0)
}

///|
test "valid dates" {
  assert_true(@zhdate.is_valid_date(2026, 11, 17))
  assert_true(@zhdate.is_valid_date(2024, 2, 29))
  assert_false(@zhdate.is_valid_date(2026, 2, 29))
  assert_false(@zhdate.is_valid_date(2026, 2, 30))
  assert_false(@zhdate.is_valid_date(2026, 4, 31))
  assert_false(@zhdate.is_valid_date(2026, 13, 1))
  assert_false(@zhdate.is_valid_date(2026, 0, 1))
  assert_false(@zhdate.is_valid_date(2026, 11, 0))
  assert_false(@zhdate.is_valid_date(2026, 11, 32))
}

///|
test "civil day conversion" {
  assert_eq(@zhdate.days_from_civil(1970, 1, 1), 0)
  assert_eq(@zhdate.days_from_civil(1970, 1, 2), 1)
  assert_eq(@zhdate.days_from_civil(2026, 11, 17), @zhdate.days_from_civil(2026, 11, 16) + 1)
  let (y, m, d) = @zhdate.civil_from_days(0)
  assert_eq(y, 1970)
  assert_eq(m, 1)
  assert_eq(d, 1)
  let (y2, m2, d2) = @zhdate.civil_from_days(@zhdate.days_from_civil(2026, 11, 17))
  assert_eq(y2, 2026)
  assert_eq(m2, 11)
  assert_eq(d2, 17)
}

///|
test "weekday" {
  // 2026-11-17 is a Tuesday.
  assert_eq(@zhdate.weekday(2026, 11, 17), 2)
  assert_eq(@zhdate.weekday(2026, 11, 16), 1)
  assert_eq(@zhdate.weekday(2026, 11, 22), 7)
  assert_eq(@zhdate.weekday(1970, 1, 1), 4)
}

///|
test "add_days" {
  let (y, m, d) = @zhdate.add_days(2026, 11, 17, 3)
  assert_eq(y, 2026)
  assert_eq(m, 11)
  assert_eq(d, 20)
  let (y2, m2, d2) = @zhdate.add_days(2026, 11, 30, 2)
  assert_eq(y2, 2026)
  assert_eq(m2, 12)
  assert_eq(d2, 2)
  let (y3, m3, d3) = @zhdate.add_days(2026, 12, 31, 1)
  assert_eq(y3, 2027)
  assert_eq(m3, 1)
  assert_eq(d3, 1)
  let (y4, m4, d4) = @zhdate.add_days(2024, 2, 28, 1)
  assert_eq(y4, 2024)
  assert_eq(m4, 2)
  assert_eq(d4, 29)
  let (y5, m5, d5) = @zhdate.add_days(2026, 1, 1, -1)
  assert_eq(y5, 2025)
  assert_eq(m5, 12)
  assert_eq(d5, 31)
}

///|
test "shift_months" {
  let (y, m, d) = @zhdate.shift_months(2026, 1, 31, 1)
  assert_eq(y, 2026)
  assert_eq(m, 2)
  assert_eq(d, 28)
  let (y2, m2, d2) = @zhdate.shift_months(2024, 1, 31, 1)
  assert_eq(d2, 29)
  let (y3, m3, d3) = @zhdate.shift_months(2026, 1, 15, -1)
  assert_eq(y3, 2025)
  assert_eq(m3, 12)
  assert_eq(d3, 15)
  let (y4, m4, d4) = @zhdate.shift_months(2026, 3, 31, -1)
  assert_eq(y4, 2026)
  assert_eq(m4, 2)
  assert_eq(d4, 28)
  let (y5, m5, d5) = @zhdate.shift_months(2026, 11, 17, 14)
  assert_eq(y5, 2028)
  assert_eq(m5, 1)
  assert_eq(d5, 17)
}

///|
test "monday_of_week" {
  // 2026-11-17 is Tuesday; its week starts on 2026-11-16.
  assert_eq(@zhdate.monday_of_week(2026, 11, 17), @zhdate.days_from_civil(2026, 11, 16))
  assert_eq(@zhdate.monday_of_week(2026, 11, 16), @zhdate.days_from_civil(2026, 11, 16))
  assert_eq(@zhdate.monday_of_week(2026, 11, 22), @zhdate.days_from_civil(2026, 11, 16))
}
