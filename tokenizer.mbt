///|
/// Day-part modifier for time expressions.
pub enum Period {
  /// 凌晨 (0-5 o'clock)
  EarlyMorning
  /// 早上
  Morning
  /// 上午
  Forenoon
  /// 中午
  Noon
  /// 下午
  Afternoon
  /// 晚上
  Evening
} derive(Eq)

///|
/// Which calendar boundary a boundary keyword refers to.
pub enum BoundaryKind {
  MonthStart
  MonthEnd
  YearStart
  YearEnd
} derive(Eq)

///|
/// Lexical category of a token in a date expression.
pub enum TokenKind {
  /// A run of ASCII digits, e.g. "2026".
  NumAscii
  /// A run of Chinese numeral characters, e.g. "二〇二六" or "十一".
  NumCn
  /// The character "年".
  Year
  /// The character "月".
  Month
  /// The character "日" or "号".
  Day
  /// A date separator: "-", "/" or ".".
  Separator
  /// A relative-day keyword: 今天(0), 明天(1), 昨天(-1), 后天(2),
  /// 前天(-2), 大后天(3), 大前天(-3). Payload = day offset from context.
  KwRelDay(Int32)
  /// A direction modifier: 下(1), 上(-1), 这/本(0). Each occurrence
  /// counts once, so 下下 is two tokens = +2.
  KwMod(Int32)
  /// A weekday keyword: 周一..周日/周天, 星期X, 礼拜X.
  /// Payload 1 = Monday .. 7 = Sunday.
  KwWeekday(Int32)
  /// A calendar-boundary keyword: 月底/月末/月初/年底/年末/年初.
  KwBoundary(BoundaryKind)
  /// 天 as a day counter, e.g. "三天后".
  KwTian
  /// 个 as a unit linker, e.g. "三个月后".
  KwGe
  /// 后 (after / later).
  KwAfter
  /// 前 (before / earlier).
  KwBefore
  /// 周/星期/礼拜 used as a week counter, e.g. "三周后".
  KwWeekWord
  /// A day-part keyword: 凌晨/早上/上午/中午/下午/晚上.
  KwPeriod(Period)
  /// The hour character "点" (or "时").
  KwHour
  /// The minute character "分".
  KwMin
  /// The second character "秒".
  KwSec
  /// The half-past marker "半", e.g. "9点半".
  KwHalf
  /// The time separator ":" or "：".
  KwColon
  /// A range connector: 至, 到, ~ or ～.
  KwRangeTo
  /// Anything else; consecutive others merge into one token.
  Other
} derive(Eq)

///|
/// One lexical token with its character span in the input.
pub(all) struct Token {
  kind : TokenKind
  text : String
  /// Character offset of the token start in the input.
  start : Int32
  /// Character offset of the token end (exclusive) in the input.
  end : Int32
}

///|
/// Whether consecutive characters of this kind merge into one token.
/// Keywords and separators stay one token each so that patterns can
/// match them precisely.
fn kind_merges(k : TokenKind) -> Bool {
  match k {
    NumAscii | NumCn | Other => true
    _ => false
  }
}

///|
/// Classify a single character (fallback when no keyword matches).
fn classify_char(c : Char) -> TokenKind {
  if ascii_digit_value(c) is Some(_) {
    return NumAscii
  }
  match c {
    '〇'
    | '零'
    | '一'
    | '二'
    | '三'
    | '四'
    | '五'
    | '六'
    | '七'
    | '八'
    | '九'
    | '十'
    | '两' => NumCn
    '年' => Year
    '月' => Month
    '日' | '号' => Day
    '-' | '/' | '.' => Separator
    _ => Other
  }
}

///|
/// Try to match a known keyword at `chars[i:]`, longest first.
/// Returns the token kind and the keyword length in characters.
fn keyword_at(
  chars : Array[Char],
  i : Int32,
  n : Int32
) -> (TokenKind, Int32)? {
  if i + 3 <= n {
    match chars_to_string(chars, i, i + 3) {
      "大后天" => return Some((KwRelDay(3), 3))
      "大前天" => return Some((KwRelDay(-3), 3))
      "星期一" => return Some((KwWeekday(1), 3))
      "星期二" => return Some((KwWeekday(2), 3))
      "星期三" => return Some((KwWeekday(3), 3))
      "星期四" => return Some((KwWeekday(4), 3))
      "星期五" => return Some((KwWeekday(5), 3))
      "星期六" => return Some((KwWeekday(6), 3))
      "星期日" | "星期天" => return Some((KwWeekday(7), 3))
      "礼拜一" => return Some((KwWeekday(1), 3))
      "礼拜二" => return Some((KwWeekday(2), 3))
      "礼拜三" => return Some((KwWeekday(3), 3))
      "礼拜四" => return Some((KwWeekday(4), 3))
      "礼拜五" => return Some((KwWeekday(5), 3))
      "礼拜六" => return Some((KwWeekday(6), 3))
      "礼拜日" | "礼拜天" => return Some((KwWeekday(7), 3))
      _ => ()
    }
  }
  if i + 2 <= n {
    match chars_to_string(chars, i, i + 2) {
      "今天" | "今日" => return Some((KwRelDay(0), 2))
      "明天" => return Some((KwRelDay(1), 2))
      "昨天" | "昨日" => return Some((KwRelDay(-1), 2))
      "后天" => return Some((KwRelDay(2), 2))
      "前天" => return Some((KwRelDay(-2), 2))
      "月底" | "月末" => return Some((KwBoundary(MonthEnd), 2))
      "月初" => return Some((KwBoundary(MonthStart), 2))
      "年底" | "年末" => return Some((KwBoundary(YearEnd), 2))
      "年初" => return Some((KwBoundary(YearStart), 2))
      "周一" => return Some((KwWeekday(1), 2))
      "周二" => return Some((KwWeekday(2), 2))
      "周三" => return Some((KwWeekday(3), 2))
      "周四" => return Some((KwWeekday(4), 2))
      "周五" => return Some((KwWeekday(5), 2))
      "周六" => return Some((KwWeekday(6), 2))
      "周日" | "周天" => return Some((KwWeekday(7), 2))
      "星期" | "礼拜" => return Some((KwWeekWord, 2))
      "凌晨" => return Some((KwPeriod(EarlyMorning), 2))
      "早上" | "早晨" => return Some((KwPeriod(Morning), 2))
      "上午" => return Some((KwPeriod(Forenoon), 2))
      "中午" => return Some((KwPeriod(Noon), 2))
      "下午" => return Some((KwPeriod(Afternoon), 2))
      "晚上" => return Some((KwPeriod(Evening), 2))
      _ => ()
    }
  }
  match chars[i] {
    '下' => Some((KwMod(1), 1))
    '上' => Some((KwMod(-1), 1))
    '这' | '本' => Some((KwMod(0), 1))
    '个' => Some((KwGe, 1))
    '天' => Some((KwTian, 1))
    '后' => Some((KwAfter, 1))
    '前' => Some((KwBefore, 1))
    '周' => Some((KwWeekWord, 1))
    '点' | '时' => Some((KwHour, 1))
    '分' => Some((KwMin, 1))
    '秒' => Some((KwSec, 1))
    '半' => Some((KwHalf, 1))
    ':' | '：' => Some((KwColon, 1))
    '至' | '到' | '~' | '～' => Some((KwRangeTo, 1))
    _ => None
  }
}

///|
/// Convert `chars[start:end]` into a String.
fn chars_to_string(chars : Array[Char], start : Int32, end : Int32) -> String {
  let mut s = ""
  let mut i = start
  while i < end {
    s = s + chars[i].to_string()
    i = i + 1
  }
  s
}

///|
/// Split `text` into tokens covering every character exactly once.
/// Known keywords are matched greedily (longest first).
pub fn tokenize(text : String) -> Array[Token] {
  let chars : Array[Char] = []
  for c in text {
    chars.push(c)
  }
  let tokens : Array[Token] = []
  let n = chars.length()
  let mut i = 0
  while i < n {
    if keyword_at(chars, i, n) is Some((k, len)) {
      tokens.push({
        kind: k,
        text: chars_to_string(chars, i, i + len),
        start: i,
        end: i + len,
      })
      i = i + len
    } else {
      let k = classify_char(chars[i])
      let mut j = i + 1
      if kind_merges(k) {
        // Stop the run at any character that starts a keyword.
        while j < n &&
          keyword_at(chars, j, n) is None &&
          classify_char(chars[j]) == k {
          j = j + 1
        }
      }
      tokens.push({
        kind: k,
        text: chars_to_string(chars, i, j),
        start: i,
        end: j,
      })
      i = j
    }
  }
  tokens
}
