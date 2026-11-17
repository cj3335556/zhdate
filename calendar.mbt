///|
/// Whether `y` is a leap year in the Gregorian calendar.
pub fn is_leap_year(y : Int) -> Bool {
  (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
}

///|
/// Number of days in `month` of year `y` (Gregorian).
/// Returns 0 when `month` is outside 1..12.
pub fn days_in_month(y : Int, month : Int) -> Int {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(y) {
      29
    } else {
      28
    }
    _ => 0
  }
}

///|
/// Whether (`y`, `month`, `day`) is an existing Gregorian date.
pub fn is_valid_date(y : Int, month : Int, day : Int) -> Bool {
  if month < 1 || month > 12 {
    return false
  }
  day >= 1 && day <= days_in_month(y, month)
}
