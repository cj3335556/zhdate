///|
/// Format an integer as at least two digits.
fn pad2(n : Int) -> String {
  if n < 10 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
/// Format a parsed date as "YYYY-MM-DD".
fn fmt_date(y : Int, mo : Int, d : Int) -> String {
  y.to_string() + "-" + pad2(mo) + "-" + pad2(d)
}

///|
/// Parse `text` and print the outcome.
fn show(text : String, ctx : @zhdate.Context) -> Unit {
  match @zhdate.parse(text, ctx) {
    Ok(m) => println("  [" + fmt_date(m.year, m.month, m.day) + "] \"" + text + "\"")
    Err(@zhdate.ParseError::InvalidDate(y, mo, d)) =>
      println("  [invalid " + fmt_date(y, mo, d) + "] \"" + text + "\"")
    Err(@zhdate.ParseError::NoMatch) =>
      println("  [no date] \"" + text + "\"")
  }
}

///|
/// Demo of the zhdate library. Run with `moon run cmd/main`.
fn main {
  let ctx : @zhdate.Context = { year: 2026, month: 11, day: 17 }
  println("zhdate demo — context: " + fmt_date(ctx.year, ctx.month, ctx.day))
  println("parse:")
  show("2026年11月17日", ctx)
  show("二〇二六年十一月十七日", ctx)
  show("2026-11-17", ctx)
  show("11月17日", ctx)
  show("十月一日", ctx)
  show("2026年11月", ctx)
  show("请于2026年12月1日前提交材料", ctx)
  show("2026年2月30日", ctx)
  show("今天天气不错", ctx)
  println("find_all:")
  let ms = @zhdate.find_all("11月17日开会，2026-12-01截止，2月30日无效", ctx)
  for m in ms {
    println("  [" + fmt_date(m.year, m.month, m.day) + "] \"" + m.text + "\"")
  }
}
