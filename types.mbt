///|
/// Reference date used to resolve expressions that omit parts,
/// e.g. "11月17日" inherits the year from the context.
pub(all) struct Context {
  year : Int32
  month : Int32
  day : Int32
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
}

///|
/// Why parsing produced no usable date.
pub enum ParseError {
  /// No date-like expression was found.
  NoMatch
  /// A date-shaped expression was found but the date does not exist,
  /// e.g. "2月30日". Fields are year, month, day as written.
  InvalidDate(Int32, Int32, Int32)
}
