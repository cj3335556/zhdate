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
/// Whether every character of `text` is whitespace.
fn is_space_text(text : String) -> Bool {
  for c in text {
    match c {
      ' ' | '\t' | '\n' | '\r' | '　' => ()
      _ => return false
    }
  }
  true
}

///|
/// Whether the gap between two matches consists only of whitespace
/// tokens. Used to merge "明天 下午三点" across a space.
fn gap_is_space(tokens : Array[Token], from : Int32, to : Int32) -> Bool {
  let mut k = from
  while k < to {
    if tokens[k].kind != Other || !is_space_text(tokens[k].text) {
      return false
    }
    k = k + 1
  }
  true
}

///|
/// Resolve a date-shaped candidate covering tokens `[s, e)`. When
/// `t` is `Some`, the match is combined with that time of day and
/// tagged `DateTime`.
fn resolve_date(
  raw : Raw,
  ctx : Context,
  tokens : Array[Token],
  s : Int32,
  e : Int32,
  t : (Int32, Int32, Int32)?,
) -> Result[Match, ParseError] {
  let time = match t {
    None => None
    Some((h, mi, sec)) => {
      if h < 0 || h > 23 || mi < 0 || mi > 59 || sec < 0 || sec > 59 {
        return Err(InvalidTime(h, mi, sec))
      }
      Some({ hour: h, minute: mi, second: sec })
    }
  }
  let has_time = time is Some(_)
  match raw.expr {
    Day(y_opt, month, day, kind) => {
      let y = match y_opt {
        Some(v) => v
        None => ctx.year
      }
      if !is_valid_date(y, month, day) {
        return Err(InvalidDate(y, month, day))
      }
      let k = if has_time {
        DateTime
      } else {
        kind
      }
      Ok(make_match(tokens, s, e, y, month, day, time, k))
    }
    DayOffset(n) => {
      let (y, m, d) = add_days(ctx.year, ctx.month, ctx.day, n)
      let k = if has_time {
        DateTime
      } else {
        Relative
      }
      Ok(make_match(tokens, s, e, y, m, d, time, k))
    }
    Weekday(week_off, w, bare) => {
      let base = monday_of_week(ctx.year, ctx.month, ctx.day) + 7 * week_off
      let (y, m, d) = civil_from_days(base + (w - 1))
      let (y2, m2, d2) = if bare && days_from_civil(y, m, d) < days_from_civil(
        ctx.year,
        ctx.month,
        ctx.day,
      ) {
        // The modifier-less "周三" resolves to the nearest upcoming
        // weekday (today counts).
        add_days(y, m, d, 7)
      } else {
        (y, m, d)
      }
      let k = if has_time {
        DateTime
      } else {
        Relative
      }
      Ok(make_match(tokens, s, e, y2, m2, d2, time, k))
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
      let k = if has_time {
        DateTime
      } else {
        Relative
      }
      Ok(make_match(tokens, s, e, y, m, d, time, k))
    }
    YearShift(n) => {
      let (y, m, d) = shift_months(ctx.year, ctx.month, ctx.day, 12 * n)
      let k = if has_time {
        DateTime
      } else {
        Relative
      }
      Ok(make_match(tokens, s, e, y, m, d, time, k))
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
      let k = if has_time {
        DateTime
      } else {
        Relative
      }
      Ok(make_match(tokens, s, e, y, m, d, time, k))
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
      let k = if has_time {
        DateTime
      } else {
        Relative
      }
      Ok(make_match(tokens, s, e, y, m, d, time, k))
    }
    Time(h, mi, sec) => {
      // Standalone time: the date comes from the context date.
      if h < 0 || h > 23 || mi < 0 || mi > 59 || sec < 0 || sec > 59 {
        return Err(InvalidTime(h, mi, sec))
      }
      let tod : TimeOfDay = { hour: h, minute: mi, second: sec }
      Ok(make_match(
        tokens,
        s,
        e,
        ctx.year,
        ctx.month,
        ctx.day,
        Some(tod),
        Time,
      ))
    }
  }
}

///|
/// Resolve all raw candidates in order, merging a date candidate with
/// an immediately following time candidate ("下周三下午三点").
fn resolve_all(
  raws : Array[Raw],
  ctx : Context,
  tokens : Array[Token],
) -> Array[Result[Match, ParseError]] {
  let out : Array[Result[Match, ParseError]] = []
  let n = raws.length()
  let mut i = 0
  while i < n {
    let r = raws[i]
    match r.expr {
      Time(_, _, _) => {
        out.push(resolve_date(r, ctx, tokens, r.tok_start, r.tok_end, None))
        i = i + 1
      }
      _ => {
        let mut t : (Int32, Int32, Int32)? = None
        let mut consumed = false
        if i + 1 < n {
          match raws[i + 1].expr {
            Time(h, mi, sec) =>
              if gap_is_space(tokens, r.tok_end, raws[i + 1].tok_start) {
                t = Some((h, mi, sec))
                consumed = true
              }
            _ => ()
          }
        }
        let e = if consumed {
          raws[i + 1].tok_end
        } else {
          r.tok_end
        }
        out.push(resolve_date(r, ctx, tokens, r.tok_start, e, t))
        i = if consumed {
          i + 2
        } else {
          i + 1
        }
      }
    }
  }
  out
}

///|
/// Parse the first date expression in `text`.
///
/// Returns the first candidate found, reading left to right:
/// - `Ok(match)` when it resolves to an existing date or datetime;
/// - `Err(InvalidDate)` / `Err(InvalidTime)` when it is date- or
///   time-shaped but impossible, e.g. "2月30日", "25:00";
/// - `Err(NoMatch)` when no date or time expression is present.
///
/// Expressions that omit the year (e.g. "11月17日") take the year
/// from `ctx`, as do all relative expressions ("明天", "下周三").
/// A date followed immediately by a time ("下周三下午三点") is
/// reported as one `DateTime` match.
pub fn parse(text : String, ctx : Context) -> Result[Match, ParseError] {
  let tokens = tokenize(text)
  let raws = scan_raw(tokens)
  let results = resolve_all(raws, ctx, tokens)
  if results.length() == 0 {
    return Err(NoMatch)
  }
  results[0]
}

///|
/// Find every date or time expression in `text` that resolves to an
/// existing value. Candidates like "2月30日" are skipped; use `parse`
/// when you need to distinguish invalid values from missing ones.
pub fn find_all(text : String, ctx : Context) -> Array[Match] {
  let tokens = tokenize(text)
  let out : Array[Match] = []
  for r in resolve_all(scan_raw(tokens), ctx, tokens) {
    match r {
      Ok(m) => out.push(m)
      Err(_) => ()
    }
  }
  out
}
