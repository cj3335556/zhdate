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
/// Keywords and separators stay one character per token so that
/// patterns can match them precisely.
fn kind_merges(k : TokenKind) -> Bool {
  match k {
    NumAscii | NumCn | Other => true
    Year | Month | Day | Separator => false
  }
}

///|
/// Classify a single character.
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
    | '十' => NumCn
    '年' => Year
    '月' => Month
    '日' | '号' => Day
    '-' | '/' | '.' => Separator
    _ => Other
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
pub fn tokenize(text : String) -> Array[Token] {
  let chars : Array[Char] = []
  for c in text {
    chars.push(c)
  }
  let tokens : Array[Token] = []
  let n = chars.length()
  let mut i = 0
  while i < n {
    let k = classify_char(chars[i])
    let mut j = i + 1
    if kind_merges(k) {
      while j < n && classify_char(chars[j]) == k {
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
  tokens
}
