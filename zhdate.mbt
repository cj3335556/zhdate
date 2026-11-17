///|
/// Concatenate the source text of tokens in `tokens[start:end]`.
fn chars_join(tokens : Array[Token], start : Int32, end : Int32) -> String {
  let mut s = ""
  let mut i = start
  while i < end {
    s = s + tokens[i].text
    i = i + 1
  }
  s
}

///|
/// Build a `Match` covering tokens `[tok_start, tok_end)` from a
/// resolved date, optional time and kind.
fn make_match(
  tokens : Array[Token],
  tok_start : Int32,
  tok_end : Int32,
  y : Int32,
  m : Int32,
  d : Int32,
  time : TimeOfDay?,
  kind : MatchKind,
) -> Match {
  {
    text: chars_join(tokens, tok_start, tok_end),
    start: tokens[tok_start].start,
    end: tokens[tok_end - 1].end,
    year: y,
    month: m,
    day: d,
    time: time,
    kind: kind,
  }
}

///|
/// Resolve a raw candidate against the context date.
fn resolve_raw(
  raw : Raw,
  ctx : Context,
  tokens : Array[Token],
) -> Result[Match, ParseError] {
  let s = raw.tok_start
  let e = raw.tok_end
  match raw.expr {
    Day(y_opt, month, day, kind) => {
      let y = match y_opt {
        Some(v) => v
        None => ctx.year
      }
      if !is_valid_date(y, month, day) {
        return Err(InvalidDate(y, month, day))
      }
      Ok(make_match(tokens, s, e, y, month, day, None, kind))
    }
    DayOffset(n) => {
      let (y, m, d) = add_days(ctx.year, ctx.month, ctx.day, n)
      Ok(make_match(tokens, s, e, y, m, d, None, Relative))
    }
    Weekday(week_off, w, bare) => {
      let base = monday_of_week(ctx.year, ctx.month, ctx.day) + 7 * week_off
      let (y, m, d) = civil_from_days(base + (w - 1))
      if bare {
        // The modifier-less "周三" resolves to the nearest upcoming
        // weekday (today counts).
        if days_from_civil(y, m, d) < days_from_civil(ctx.year, ctx.month, ctx.day) {
          let (y2, m2, d2) = add_days(y, m, d, 7)
          return Ok(make_match(tokens, s, e, y2, m2, d2, None, Relative))
        }
      }
      Ok(make_match(tokens, s, e, y, m, d, None, Relative))
    }
    MonthShift(n, day_opt) => {
      let (y, m, kept) = shift_months(ctx.year, ctx.month, ctx.day, n)
      let d = match day_opt {
        Some(v) => v
        None => kept
      }
      if !is_valid_date(y, m, d) {
        return Err(InvalidDate(y, m, d))
      }
      Ok(make_match(tokens, s, e, y, m, d, None, Relative))
    }
    YearShift(n) => {
      let (y, m, d) = shift_months(ctx.year, ctx.month, ctx.day, 12 * n)
      Ok(make_match(tokens, s, e, y, m, d, None, Relative))
    }
    BoundaryRel(n, b) => {
      let (y, m, d) = match b {
        MonthStart => {
          let (y2, m2, _) = shift_months(ctx.year, ctx.month, ctx.day, n)
          (y2, m2, 1)
        }
        MonthEnd => {
          let (y2, m2, _) = shift_months(ctx.year, ctx.month, ctx.day, n)
          (y2, m2, days_in_month(y2, m2))
        }
        YearStart => (ctx.year + n, 1, 1)
        YearEnd => (ctx.year + n, 12, 31)
      }
      Ok(make_match(tokens, s, e, y, m, d, None, Relative))
    }
    BoundaryAbs(num, b) => {
      let (y, m, d) = match b {
        MonthStart => (ctx.year, num, 1)
        MonthEnd => (ctx.year, num, days_in_month(ctx.year, num))
        YearStart => (num, 1, 1)
        YearEnd => (num, 12, 31)
      }
      if !is_valid_date(y, m, d) {
        return Err(InvalidDate(y, m, d))
      }
      Ok(make_match(tokens, s, e, y, m, d, None, Relative))
    }
    Time(h, mi, sec) => {
      if h < 0 || h > 23 || mi < 0 || mi > 59 || sec < 0 || sec > 59 {
        return Err(InvalidTime(h, mi, sec))
      }
      // A bare time takes its date from the context date.
      let time : TimeOfDay = { hour: h, minute: mi, second: sec }
      Ok(make_match(
        tokens,
        s,
        e,
        ctx.year,
        ctx.month,
        ctx.day,
        Some(time),
        Time,
      ))
    }
  }
}

///|
/// Parse the first date expression in `text`.
///
/// Returns the first candidate found, reading left to right:
/// - `Ok(match)` when it resolves to an existing date;
/// - `Err(InvalidDate)` when it is date-shaped but impossible,
///   e.g. "2月30日";
/// - `Err(NoMatch)` when no date expression is present.
///
/// Expressions that omit the year (e.g. "11月17日") take the year
/// from `ctx`, as do all relative expressions ("明天", "下周三").
pub fn parse(text : String, ctx : Context) -> Result[Match, ParseError] {
  let tokens = tokenize(text)
  let raws = scan_raw(tokens)
  if raws.length() == 0 {
    return Err(NoMatch)
  }
  resolve_raw(raws[0], ctx, tokens)
}

///|
/// Find every date expression in `text` that resolves to an existing
/// date. Candidates like "2月30日" are skipped; use `parse` when you
/// need to distinguish invalid dates from missing ones.
pub fn find_all(text : String, ctx : Context) -> Array[Match] {
  let tokens = tokenize(text)
  let out : Array[Match] = []
  for raw in scan_raw(tokens) {
    match resolve_raw(raw, ctx, tokens) {
      Ok(m) => out.push(m)
      Err(_) => ()
    }
  }
  out
}
