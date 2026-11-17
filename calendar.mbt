///|
/// Whether `y` is a leap year in the Gregorian calendar.
pub fn is_leap_year(y : Int32) -> Bool {
  (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
}

///|
/// Number of days in `month` of year `y` (Gregorian).
/// Returns 0 when `month` is outside 1..12.
pub fn days_in_month(y : Int32, month : Int32) -> Int32 {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(y) { 29 } else { 28 }
    _ => 0
  }
}

///|
/// Whether (`y`, `month`, `day`) is an existing Gregorian date.
pub fn is_valid_date(y : Int32, month : Int32, day : Int32) -> Bool {
  if month < 1 || month > 12 {
    return false
  }
  day >= 1 && day <= days_in_month(y, month)
}

///|
/// Days since 1970-01-01 for a Gregorian date (1970-01-01 is day 0).
/// Based on Howard Hinnant's civil calendar algorithms.
pub fn days_from_civil(y : Int32, month : Int32, d : Int32) -> Int32 {
  let y2 = if month <= 2 {
    y - 1
  } else {
    y
  }
  let era = (if y2 >= 0 {
    y2
  } else {
    y2 - 399
  }) / 400
  let yoe = y2 - era * 400
  let doy = (153 * ((month + 9) % 12) + 2) / 5 + d - 1
  let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
}

///|
/// Gregorian date (`y`, `month`, `d`) for a day number since 1970-01-01.
pub fn civil_from_days(z : Int32) -> (Int32, Int32, Int32) {
  let z2 = z + 719468
  let era = (if z2 >= 0 {
    z2
  } else {
    z2 - 146096
  }) / 146097
  let doe = z2 - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let y = yoe + era * 400
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let d = doy - (153 * mp + 2) / 5 + 1
  let m = if mp < 10 {
    mp + 3
  } else {
    mp - 9
  }
  if m <= 2 {
    (y + 1, m, d)
  } else {
    (y, m, d)
  }
}

///|
/// Weekday of a Gregorian date: 1 = Monday .. 7 = Sunday.
pub fn weekday(y : Int32, month : Int32, d : Int32) -> Int32 {
  let r = (days_from_civil(y, month, d) + 3) % 7
  if r < 0 {
    r + 7 + 1
  } else {
    r + 1
  }
}

///|
/// Add `n` days to a Gregorian date.
pub fn add_days(y : Int32, month : Int32, d : Int32, n : Int32) -> (Int32, Int32, Int32) {
  civil_from_days(days_from_civil(y, month, d) + n)
}

///|
/// Add `n` months to a Gregorian date, clamping the day of month
/// (e.g. Jan 31 + 1 month = Feb 28/29).
pub fn shift_months(y : Int32, month : Int32, d : Int32, n : Int32) -> (Int32, Int32, Int32) {
  let total = y * 12 + (month - 1) + n
  let ny = total / 12
  let nm = total % 12 + 1
  let max_d = days_in_month(ny, nm)
  let nd = if d < max_d {
    d
  } else {
    max_d
  }
  (ny, nm, nd)
}

///|
/// Monday (as day number since 1970-01-01) of the week containing the
/// given date. Weeks start on Monday.
pub fn monday_of_week(y : Int32, month : Int32, d : Int32) -> Int32 {
  days_from_civil(y, month, d) - (weekday(y, month, d) - 1)
}
