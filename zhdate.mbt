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
/// Build a `Match` from a raw candidate: fill the missing year from the
/// context and validate the resulting date.
fn resolve_raw(
  raw : RawDate,
  ctx : Context,
  tokens : Array[Token],
) -> Result[Match, ParseError] {
  let year = match raw.year {
    Some(y) => y
    None => ctx.year
  }
  if !is_valid_date(year, raw.month, raw.day) {
    return Err(InvalidDate(year, raw.month, raw.day))
  }
  let text = chars_join(tokens, raw.tok_start, raw.tok_end)
  Ok({
    text,
    start: tokens[raw.tok_start].start,
    end: tokens[raw.tok_end - 1].end,
    year,
    month: raw.month,
    day: raw.day,
    kind: raw.kind,
  })
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
/// from `ctx`.
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
