///|
/// How to read the value of a numeral token.
priv enum NumMode {
  /// Chinese numerals read digit by digit, e.g. "二〇二六" -> 2026 (years).
  YearDigits
  /// Chinese numerals read as multiplicative numbers, e.g. "十七" -> 17
  /// (months and days).
  ValueNumber
}

///|
/// A date expression candidate before resolution against the context.
/// Payloads are positional:
/// - `Day(y?, month, day, kind)`: concrete parts; year `None` means
///   "take from context";
/// - `DayOffset(n)`: ± n days from the context ("三天后", "明天");
/// - `Weekday(week_off, w, bare)`: weekday `w` (1 = Mon .. 7 = Sun),
///   `week_off` weeks from the context week (0 = this week), `bare`
///   marks the modifier-less form "周三" (nearest upcoming weekday);
/// - `MonthShift(n, day?)`: ± n months, optional fixed day of month
///   ("下个月17日");
/// - `YearShift(n)`: ± n years ("两年后");
/// - `BoundaryRel(n, b)`: calendar boundary ± n months/years
///   ("月底", "下月底", "下年底");
  /// - `BoundaryAbs(num, b)`: boundary of a named month/year ("11月底",
  ///   "2026年底");
  /// - `Time(h, m, s, bare)`: a time of day with the hour already
  ///   adjusted for its day-part ("下午三点" -> 15); `bare` marks a
  ///   time written without a day-part ("5点" in "下午三点至五点");
  /// - `DayOnly(day)`: a shorthand day of month ("17日至19日"的"19日"),
  ///   taking month and year from the context.
priv enum RawExpr {
  Day(Int32?, Int32, Int32, MatchKind)
  DayOffset(Int32)
  Weekday(Int32, Int32, Bool)
  MonthShift(Int32, Int32?)
  YearShift(Int32)
  BoundaryRel(Int32, BoundaryKind)
  BoundaryAbs(Int32, BoundaryKind)
  Time(Int32, Int32, Int32, Bool)
  DayOnly(Int32)
}

///|
/// A candidate expression with its token span.
priv struct Raw {
  expr : RawExpr
  tok_start : Int32
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
/// Match the absolute date patterns at token `i` (longest first).
fn match_abs(tokens : Array[Token], i : Int32) -> Raw? {
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
      expr: Day(Some(y), m, d, FullDate),
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
      expr: Day(Some(y), m, d, FullDate),
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
      expr: Day(None, m, d, MonthDay),
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
      expr: Day(Some(y), m, 1, YearMonth),
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
      expr: Day(None, m, d, MonthDay),
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
      expr: Day(Some(y), m, d, FullDate),
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
      expr: Day(Some(y), m, 1, YearMonth),
      tok_start: i,
      tok_end: i + 3,
    })
  }
  None
}

///|
/// Consume a run of (KwMod KwGe?) pairs starting at `i`.
/// Returns (sum of modifiers, next token index, modifier count).
fn scan_mods(tokens : Array[Token], i : Int32) -> (Int32, Int32, Int32) {
  let n = tokens.length()
  let mut j = i
  let mut sum = 0
  let mut count = 0
  while j < n {
    match tokens[j].kind {
      KwMod(v) => {
        sum = sum + v
        count = count + 1
        j = j + 1
        if j < n && tokens[j].kind == KwGe {
          j = j + 1
        }
      }
      _ => break
    }
  }
  (sum, j, count)
}

///|
/// "明天" / "后天" / "大前天" ...
fn match_rel_day(tokens : Array[Token], i : Int32) -> Raw? {
  match tokens[i].kind {
    KwRelDay(k) => Some({ expr: DayOffset(k), tok_start: i, tok_end: i + 1 })
    _ => None
  }
}

///|
/// "三天后" / "3天前" — NUM 天 后|前
fn match_day_offset(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  if i + 3 <= n && is_num(tokens[i]) && tokens[i + 1].kind == KwTian {
    guard read_num(tokens[i], ValueNumber) is Some(v) else { return None }
    match tokens[i + 2].kind {
      KwAfter =>
        Some({ expr: DayOffset(v), tok_start: i, tok_end: i + 3 })
      KwBefore =>
        Some({ expr: DayOffset(-v), tok_start: i, tok_end: i + 3 })
      _ => None
    }
  } else {
    None
  }
}

///|
/// "三周后" / "两周前" — NUM 周|星期|礼拜 后|前
fn match_week_offset(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  if i + 3 <= n && is_num(tokens[i]) && tokens[i + 1].kind == KwWeekWord {
    guard read_num(tokens[i], ValueNumber) is Some(v) else { return None }
    match tokens[i + 2].kind {
      KwAfter =>
        Some({ expr: DayOffset(7 * v), tok_start: i, tok_end: i + 3 })
      KwBefore =>
        Some({ expr: DayOffset(-7 * v), tok_start: i, tok_end: i + 3 })
      _ => None
    }
  } else {
    None
  }
}

///|
/// "三个月后" / "三月后" — NUM 个? 月 后|前
fn match_month_offset(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  if i + 4 <= n &&
    is_num(tokens[i]) &&
    tokens[i + 1].kind == KwGe &&
    tokens[i + 2].kind == Month {
    guard read_num(tokens[i], ValueNumber) is Some(v) else { return None }
    match tokens[i + 3].kind {
      KwAfter =>
        Some({ expr: MonthShift(v, None), tok_start: i, tok_end: i + 4 })
      KwBefore =>
        Some({ expr: MonthShift(-v, None), tok_start: i, tok_end: i + 4 })
      _ => None
    }
  } else if i + 3 <= n && is_num(tokens[i]) && tokens[i + 1].kind == Month {
    guard read_num(tokens[i], ValueNumber) is Some(v) else { return None }
    match tokens[i + 2].kind {
      KwAfter =>
        Some({ expr: MonthShift(v, None), tok_start: i, tok_end: i + 3 })
      KwBefore =>
        Some({ expr: MonthShift(-v, None), tok_start: i, tok_end: i + 3 })
      _ => None
    }
  } else {
    None
  }
}

///|
/// "两年后" / "三个年前" — NUM 个? 年 后|前 (numeral ≤ 999 so that
/// "2026年后" is not misread as "2026 years later").
fn match_year_offset(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  if i + 4 <= n &&
    is_num(tokens[i]) &&
    tokens[i + 1].kind == KwGe &&
    tokens[i + 2].kind == Year {
    guard read_num(tokens[i], ValueNumber) is Some(v) else { return None }
    if v > 999 {
      return None
    }
    match tokens[i + 3].kind {
      KwAfter =>
        Some({ expr: YearShift(v), tok_start: i, tok_end: i + 4 })
      KwBefore =>
        Some({ expr: YearShift(-v), tok_start: i, tok_end: i + 4 })
      _ => None
    }
  } else if i + 3 <= n && is_num(tokens[i]) && tokens[i + 1].kind == Year {
    guard read_num(tokens[i], ValueNumber) is Some(v) else { return None }
    if v > 999 {
      return None
    }
    match tokens[i + 2].kind {
      KwAfter =>
        Some({ expr: YearShift(v), tok_start: i, tok_end: i + 3 })
      KwBefore =>
        Some({ expr: YearShift(-v), tok_start: i, tok_end: i + 3 })
      _ => None
    }
  } else {
    None
  }
}

///|
/// "下周三" / "周三" / "下下周一" — (下|上|这|本)个? * 周X
fn match_weekday(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  let (sum, j, count) = scan_mods(tokens, i)
  if j < n {
    match tokens[j].kind {
      KwWeekday(w) =>
        Some({
          expr: Weekday(sum, w, count == 0),
          tok_start: i,
          tok_end: j + 1,
        })
      _ => None
    }
  } else {
    None
  }
}

///|
/// "月底" / "下月底" / "上个月初" / "年底" — (下|上|这|本)个? 边界
fn match_boundary_rel(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  let (sum, j, _count) = scan_mods(tokens, i)
  if j < n {
    match tokens[j].kind {
      KwBoundary(b) =>
        Some({
          expr: BoundaryRel(sum, b),
          tok_start: i,
          tok_end: j + 1,
        })
      _ => None
    }
  } else {
    None
  }
}

///|
/// "下个月17日" / "上月15号" — (下|上)个? 月 NUM 日?
fn match_month_shift(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  let (sum, j, count) = scan_mods(tokens, i)
  if count == 0 {
    return None
  }
  if j + 1 < n && tokens[j].kind == Month && is_num(tokens[j + 1]) {
    guard read_num(tokens[j + 1], ValueNumber) is Some(d) else { return None }
    let mut end = j + 2
    if end < n && tokens[end].kind == Day {
      end = end + 1
    }
    return Some({
      expr: MonthShift(sum, Some(d)),
      tok_start: i,
      tok_end: end,
    })
  }
  None
}

///|
/// "11月底" / "三月初" / "2026年底" — NUM 边界
fn match_boundary_abs(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  if i + 2 <= n && is_num(tokens[i]) {
    match tokens[i + 1].kind {
      KwBoundary(b) => {
        let mode = match b {
          MonthStart | MonthEnd => ValueNumber
          YearStart | YearEnd => YearDigits
        }
        guard read_num(tokens[i], mode) is Some(v) else { return None }
        Some({
          expr: BoundaryAbs(v, b),
          tok_start: i,
          tok_end: i + 2,
        })
      }
      _ => None
    }
  } else {
    None
  }
}

///|
/// Optional leading day-part of a time expression.
/// Returns the period (if any) and the next token index.
fn eat_period(tokens : Array[Token], i : Int32) -> (Period?, Int32) {
  if i < tokens.length() {
    match tokens[i].kind {
      KwPeriod(p) => (Some(p), i + 1)
      _ => (None, i)
    }
  } else {
    (None, i)
  }
}

///|
/// Adjust a written hour by its day-part. Hours greater than 12 are
/// already 24-hour values and are kept as written.
fn apply_period(p : Period?, h : Int32) -> Int32 {
  if h > 12 {
    return h
  }
  match p {
    None => h
    Some(EarlyMorning) =>
      if h == 12 {
        0
      } else {
        h
      }
    Some(Morning) | Some(Forenoon) =>
      if h == 12 {
        12
      } else {
        h
      }
    Some(Noon) | Some(Afternoon) =>
      if h == 12 {
        12
      } else {
        h + 12
      }
    Some(Evening) =>
      if h == 12 {
        0
      } else {
        h + 12
      }
  }
}

///|
/// Match a time-of-day expression at token `i` (longest first).
/// Forms: "15:30[:45]", "15点30分[45秒]", "15点30", "3点半", "15点",
/// "下午三点", and bare "中午".
fn match_time(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  let (p, j) = eat_period(tokens, i)
  // NUM KwHour NUM KwMin NUM KwSec — "15点30分45秒"
  if j + 6 <= n &&
    is_num(tokens[j]) &&
    tokens[j + 1].kind == KwHour &&
    is_num(tokens[j + 2]) &&
    tokens[j + 3].kind == KwMin &&
    is_num(tokens[j + 4]) &&
    tokens[j + 5].kind == KwSec {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    guard read_num(tokens[j + 2], ValueNumber) is Some(m) else { return None }
    guard read_num(tokens[j + 4], ValueNumber) is Some(s) else { return None }
    return Some({
      expr: Time(apply_period(p, h), m, s, p is None),
      tok_start: i,
      tok_end: j + 6,
    })
  }
  // NUM KwColon NUM KwColon NUM — "15:30:45"
  if j + 5 <= n &&
    is_num(tokens[j]) &&
    tokens[j + 1].kind == KwColon &&
    is_num(tokens[j + 2]) &&
    tokens[j + 3].kind == KwColon &&
    is_num(tokens[j + 4]) {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    guard read_num(tokens[j + 2], ValueNumber) is Some(m) else { return None }
    guard read_num(tokens[j + 4], ValueNumber) is Some(s) else { return None }
    return Some({
      expr: Time(apply_period(p, h), m, s, p is None),
      tok_start: i,
      tok_end: j + 5,
    })
  }
  // NUM KwHour NUM KwMin — "15点30分"
  if j + 4 <= n &&
    is_num(tokens[j]) &&
    tokens[j + 1].kind == KwHour &&
    is_num(tokens[j + 2]) &&
    tokens[j + 3].kind == KwMin {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    guard read_num(tokens[j + 2], ValueNumber) is Some(m) else { return None }
    return Some({
      expr: Time(apply_period(p, h), m, 0, p is None),
      tok_start: i,
      tok_end: j + 4,
    })
  }
  // NUM KwHour NUM — "15点30"
  if j + 3 <= n && is_num(tokens[j]) && tokens[j + 1].kind == KwHour && is_num(
    tokens[j + 2],
  ) {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    guard read_num(tokens[j + 2], ValueNumber) is Some(m) else { return None }
    return Some({
      expr: Time(apply_period(p, h), m, 0, p is None),
      tok_start: i,
      tok_end: j + 3,
    })
  }
  // NUM KwColon NUM — "15:30"
  if j + 3 <= n &&
    is_num(tokens[j]) &&
    tokens[j + 1].kind == KwColon &&
    is_num(tokens[j + 2]) {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    guard read_num(tokens[j + 2], ValueNumber) is Some(m) else { return None }
    return Some({
      expr: Time(apply_period(p, h), m, 0, p is None),
      tok_start: i,
      tok_end: j + 3,
    })
  }
  // NUM KwHour KwHalf — "3点半"
  if j + 3 <= n &&
    is_num(tokens[j]) &&
    tokens[j + 1].kind == KwHour &&
    tokens[j + 2].kind == KwHalf {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    return Some({
      expr: Time(apply_period(p, h), 30, 0, p is None),
      tok_start: i,
      tok_end: j + 3,
    })
  }
  // NUM KwHour — "15点" / "下午三点"
  if j + 2 <= n && is_num(tokens[j]) && tokens[j + 1].kind == KwHour {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    return Some({
      expr: Time(apply_period(p, h), 0, 0, p is None),
      tok_start: i,
      tok_end: j + 2,
    })
  }
  // NUM KwHalf — "三点半" written without 点
  if j + 2 <= n && is_num(tokens[j]) && tokens[j + 1].kind == KwHalf {
    guard read_num(tokens[j], ValueNumber) is Some(h) else { return None }
    return Some({
      expr: Time(apply_period(p, h), 30, 0, p is None),
      tok_start: i,
      tok_end: j + 2,
    })
  }
  // Bare "中午" — noon
  if p is Some(Noon) {
    return Some({ expr: Time(12, 0, 0, false), tok_start: i, tok_end: i + 1 })
  }
  None
}

///|
/// "19日" / "十九号" — a shorthand day of month for ranges.
fn match_day_only(tokens : Array[Token], i : Int32) -> Raw? {
  let n = tokens.length()
  if i + 2 <= n && is_num(tokens[i]) && tokens[i + 1].kind == Day {
    guard read_num(tokens[i], ValueNumber) is Some(d) else { return None }
    Some({ expr: DayOnly(d), tok_start: i, tok_end: i + 2 })
  } else {
    None
  }
}

///|
/// Match the relative date patterns at token `i` (longest first).
fn match_rel(tokens : Array[Token], i : Int32) -> Raw? {
  if match_month_shift(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_day_offset(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_week_offset(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_month_offset(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_year_offset(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_weekday(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_boundary_rel(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_boundary_abs(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_day_only(tokens, i) is Some(r) {
    return Some(r)
  }
  match_rel_day(tokens, i)
}

///|
/// Try to match one date expression starting at token `i`.
/// Absolute patterns are tried before relative ones, then times;
/// within each group longer patterns win. Returns the candidate with
/// its token span.
fn match_at(tokens : Array[Token], i : Int32) -> Raw? {
  if match_abs(tokens, i) is Some(r) {
    return Some(r)
  }
  if match_rel(tokens, i) is Some(r) {
    return Some(r)
  }
  match_time(tokens, i)
}

///|
/// Scan the whole token stream for date candidates, longest match first
/// at each position and without overlapping.
fn scan_raw(tokens : Array[Token]) -> Array[Raw] {
  let out : Array[Raw] = []
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
