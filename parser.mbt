///|
/// How to read the value of a numeral token.
enum NumMode {
  /// Chinese numerals read digit by digit, e.g. "二〇二六" -> 2026 (years).
  YearDigits
  /// Chinese numerals read as multiplicative numbers, e.g. "十七" -> 17
  /// (months and days).
  ValueNumber
}

///|
/// A date-shaped candidate found in the token stream, before validation.
/// `year` is `None` when the expression omits the year ("11月17日").
struct RawDate {
  year : Int32?
  month : Int32
  /// Resolved day; `1` for year-month forms.
  day : Int32
  kind : MatchKind
  /// First token index of the expression.
  tok_start : Int32
  /// Token index just past the expression.
  tok_end : Int32
}

///|
fn is_num(t : Token) -> Bool {
  t.kind == NumAscii || t.kind == NumCn
}

///|
/// A number token that can stand for a year in separator forms:
/// 3-4 ASCII digits, e.g. "2026" or "026".
fn is_year_shaped(t : Token) -> Bool {
  t.kind == NumAscii && (t.text.length() == 3 || t.text.length() == 4)
}

///|
/// Read the integer value of a numeral token under the given reading mode.
fn read_num(t : Token, mode : NumMode) -> Int32? {
  match t.kind {
    NumAscii => parse_ascii_int(t.text)
    NumCn =>
      match mode {
        YearDigits => parse_cn_digits(t.text)
        ValueNumber => parse_cn_number(t.text)
      }
    _ => None
  }
}

///|
/// Try to match one date expression starting at token `i`.
/// Patterns are tried longest-first. Returns the candidate together with
/// the token index just past it, or `None` when no pattern matches.
fn match_at(tokens : Array[Token], i : Int32) -> RawDate? {
  let n = tokens.length()
  // NUM YEAR NUM MONTH NUM DAY — "2026年11月17日" / "二〇二六年十一月十七日"
  if i + 6 <= n &&
    is_num(tokens[i]) &&
    tokens[i + 1].kind == Year &&
    is_num(tokens[i + 2]) &&
    tokens[i + 3].kind == Month &&
    is_num(tokens[i + 4]) &&
    tokens[i + 5].kind == Day {
    guard read_num(tokens[i], YearDigits) is Some(y) else { return None }
    guard read_num(tokens[i + 2], ValueNumber) is Some(m) else { return None }
    guard read_num(tokens[i + 4], ValueNumber) is Some(d) else { return None }
    return Some({
      year: Some(y),
      month: m,
      day: d,
      kind: FullDate,
      tok_start: i,
      tok_end: i + 6,
    })
  }
  // NUM YEAR NUM MONTH NUM — "2026年11月17"
  if i + 5 <= n &&
    is_num(tokens[i]) &&
    tokens[i + 1].kind == Year &&
    is_num(tokens[i + 2]) &&
    tokens[i + 3].kind == Month &&
    is_num(tokens[i + 4]) {
    guard read_num(tokens[i], YearDigits) is Some(y) else { return None }
    guard read_num(tokens[i + 2], ValueNumber) is Some(m) else { return None }
    guard read_num(tokens[i + 4], ValueNumber) is Some(d) else { return None }
    return Some({
      year: Some(y),
      month: m,
      day: d,
      kind: FullDate,
      tok_start: i,
      tok_end: i + 5,
    })
  }
  // NUM MONTH NUM DAY — "11月17日" / "十一月十七日"
  if i + 4 <= n &&
    is_num(tokens[i]) &&
    tokens[i + 1].kind == Month &&
    is_num(tokens[i + 2]) &&
    tokens[i + 3].kind == Day {
    guard read_num(tokens[i], ValueNumber) is Some(m) else { return None }
    guard read_num(tokens[i + 2], ValueNumber) is Some(d) else { return None }
    return Some({
      year: None,
      month: m,
      day: d,
      kind: MonthDay,
      tok_start: i,
      tok_end: i + 4,
    })
  }
  // NUM YEAR NUM MONTH — "2026年11月"
  if i + 4 <= n &&
    is_num(tokens[i]) &&
    tokens[i + 1].kind == Year &&
    is_num(tokens[i + 2]) &&
    tokens[i + 3].kind == Month {
    guard read_num(tokens[i], YearDigits) is Some(y) else { return None }
    guard read_num(tokens[i + 2], ValueNumber) is Some(m) else { return None }
    return Some({
      year: Some(y),
      month: m,
      day: 1,
      kind: YearMonth,
      tok_start: i,
      tok_end: i + 4,
    })
  }
  // NUM MONTH NUM — "11月17"
  if i + 3 <= n &&
    is_num(tokens[i]) &&
    tokens[i + 1].kind == Month &&
    is_num(tokens[i + 2]) {
    guard read_num(tokens[i], ValueNumber) is Some(m) else { return None }
    guard read_num(tokens[i + 2], ValueNumber) is Some(d) else { return None }
    return Some({
      year: None,
      month: m,
      day: d,
      kind: MonthDay,
      tok_start: i,
      tok_end: i + 3,
    })
  }
  // NUM SEP NUM SEP NUM — "2026-11-17" / "2026/11/17" / "2026.11.17"
  if i + 5 <= n &&
    is_year_shaped(tokens[i]) &&
    tokens[i + 1].kind == Separator &&
    tokens[i + 2].kind == NumAscii &&
    tokens[i + 3].kind == Separator &&
    tokens[i + 4].kind == NumAscii {
    guard read_num(tokens[i], YearDigits) is Some(y) else { return None }
    guard read_num(tokens[i + 2], ValueNumber) is Some(m) else { return None }
    guard read_num(tokens[i + 4], ValueNumber) is Some(d) else { return None }
    return Some({
      year: Some(y),
      month: m,
      day: d,
      kind: FullDate,
      tok_start: i,
      tok_end: i + 5,
    })
  }
  // NUM SEP NUM — "2026-11"
  if i + 3 <= n &&
    is_year_shaped(tokens[i]) &&
    tokens[i + 1].kind == Separator &&
    tokens[i + 2].kind == NumAscii {
    guard read_num(tokens[i], YearDigits) is Some(y) else { return None }
    guard read_num(tokens[i + 2], ValueNumber) is Some(m) else { return None }
    return Some({
      year: Some(y),
      month: m,
      day: 1,
      kind: YearMonth,
      tok_start: i,
      tok_end: i + 3,
    })
  }
  None
}

///|
/// Scan the whole token stream for date candidates, longest match first
/// at each position and without overlapping.
fn scan_raw(tokens : Array[Token]) -> Array[RawDate] {
  let out : Array[RawDate] = []
  let n = tokens.length()
  let mut i = 0
  while i < n {
    match match_at(tokens, i) {
      Some(raw) => {
        out.push(raw)
        i = raw.tok_end
      }
      None => i = i + 1
    }
  }
  out
}
