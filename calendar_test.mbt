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
