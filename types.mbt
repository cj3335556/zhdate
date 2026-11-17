///|
/// Reference date used to resolve expressions that omit parts,
/// e.g. "11月17日" inherits the year from the context.
pub(all) struct Context {
  year : Int32
  month : Int32
  day : Int32
}

///|
/// A time of day: hour in 0..23, minute/second in 0..59.
pub(all) struct TimeOfDay {
  hour : Int32
  minute : Int32
  second : Int32
}

///|
/// A date or time range recognized in the input text,
/// e.g. "下周一至周三", "11月17日至19日".
pub(all) struct Range {
  /// The matched substring covering both endpoints and the connector.
  text : String
  /// Character offset of the range start in the input.
  start : Int32
  /// Character offset of the range end (exclusive) in the input.
  end : Int32
  /// The start endpoint ("下周一", "11月17日").
  from : Match
  /// The end endpoint ("周三", "19日").
  to : Match
}

///|
/// A date expression recognized in the input text.
pub(all) struct Match {
  /// The matched substring.
  text : String
  /// Character offset of the match start in the input.
  start : Int32
  /// Character offset of the match end (exclusive) in the input.
  end : Int32
  year : Int32
  month : Int32
  day : Int32
  /// Time of day when the expression carries one ("下午三点",
  /// "下周三下午三点"), otherwise `None`.
  time : TimeOfDay?
  kind : MatchKind
}

///|
/// Which shape of date expression produced a match.
pub enum MatchKind {
  /// "2026年11月17日" / "二〇二六年十一月十七日" / "2026-11-17"
  FullDate
  /// "2026年11月" / "2026-11"
  YearMonth
  /// "11月17日" / "十一月十七日" (year inferred from context)
  MonthDay
  /// A relative expression resolved against the context date,
  /// e.g. "明天", "三天后", "下周三", "月底", "下个月17日".
  Relative
  /// A bare time-of-day expression, e.g. "下午三点", "15:30".
  /// The date part is taken from the context date.
  Time
  /// A date expression combined with a time, e.g. "下周三下午三点".
  DateTime
}

///|
/// Why parsing produced no usable date or time.
pub enum ParseError {
  /// No date-like or time-like expression was found.
  NoMatch
  /// A date-shaped expression was found but the date does not exist,
  /// e.g. "2月30日". Fields are year, month, day as written.
  InvalidDate(Int32, Int32, Int32)
  /// A time-shaped expression was found but the time does not exist,
  /// e.g. "25:00". Fields are hour, minute, second as written.
  InvalidTime(Int32, Int32, Int32)
}
