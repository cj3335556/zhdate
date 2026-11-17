///|
/// Format an integer as at least two digits.
fn pad2(n : Int32) -> String {
  if n < 10 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
/// Format a parsed date as "YYYY-MM-DD".
fn fmt_date(y : Int32, mo : Int32, d : Int32) -> String {
  y.to_string() + "-" + pad2(mo) + "-" + pad2(d)
}

///|
/// Format a parsed match as "YYYY-MM-DD" or "YYYY-MM-DD HH:MM:SS".
fn fmt_match(m : @zhdate.Match) -> String {
  match m.time {
    None => fmt_date(m.year, m.month, m.day)
    Some(t) =>
      fmt_date(m.year, m.month, m.day) +
      " " +
      pad2(t.hour) +
      ":" +
      pad2(t.minute) +
      ":" +
      pad2(t.second)
  }
}

///|
/// Parse `text` and print the outcome.
fn show(text : String, ctx : @zhdate.Context) -> Unit {
  match @zhdate.parse(text, ctx) {
    Ok(m) => println("  [" + fmt_match(m) + "] \"" + text + "\"")
    Err(@zhdate.ParseError::InvalidDate(y, mo, d)) =>
      println("  [invalid " + fmt_date(y, mo, d) + "] \"" + text + "\"")
    Err(@zhdate.ParseError::InvalidTime(h, mi, s)) =>
      println(
        "  [invalid " +
        h.to_string() +
        ":" +
        pad2(mi) +
        ":" +
        pad2(s) +
        "] \"" +
        text +
        "\"",
      )
    Err(@zhdate.ParseError::NoMatch) => println("  [no date] \"" + text + "\"")
  }
}

///|
/// Demo of the zhdate library. Run with `moon run cmd/main`.
fn main {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17, }
  println("zhdate demo — context: " + fmt_date(ctx.year, ctx.month, ctx.day))
  println("absolute dates:")
  show("2026年11月17日", ctx)
  show("二〇二六年十一月十七日", ctx)
  show("2026-11-17", ctx)
  show("11月17日", ctx)
  show("十月一日", ctx)
  show("请于2026年12月1日前提交材料", ctx)
  show("2026年2月30日", ctx)
  println("relative dates:")
  show("明天", ctx)
  show("三天后", ctx)
  show("下周三", ctx)
  show("月底", ctx)
  show("下个月17日", ctx)
  println("times:")
  show("下午三点", ctx)
  show("15:30", ctx)
  show("9点半", ctx)
  show("25:00", ctx)
  println("datetimes:")
  show("下周三下午三点", ctx)
  show("明天15:30", ctx)
  println("ranges:")
  for
    r in @zhdate.find_ranges(
      "下周一至周三，11月17日至19日，下午三点至五点", ctx,
    ) {
    println(
      "  [" +
      fmt_match(r.from) +
      " .. " +
      fmt_match(r.to) +
      "] \"" +
      r.text +
      "\"",
    )
  }
  println("find_all:")
  let ms = @zhdate.find_all(
    "明天下午三点开会，11月17日截止，2月30日无效", ctx,
  )
  for m in ms {
    println("  [" + fmt_match(m) + "] \"" + m.text + "\"")
  }
}
