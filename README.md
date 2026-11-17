# zhdate

中文自然语言日期解析库（MoonBit）。把中文文本里的日期表达式解析为结构化日期。

```moonbit
let ctx : Context = { year: 2026, month: 11, day: 17 }
guard parse("请于2026年11月17日前提交材料", ctx) is Ok(m) else {
  panic()
}
// m.text = "2026年11月17日", m.year = 2026, m.month = 11, m.day = 17
```

## 功能

- 从文本中**定位并解析**日期表达式（`parse` 取第一个，`find_all` 取全部）
- 中文数字与阿拉伯数字混写均可识别（"二〇二六年十一月十七日" / "2026年11月17日"）
- 省略年份的表达式从上下文推断年份（"11月17日"）
- 校验日期合法性（"2026年2月30日" 报 `InvalidDate`，而不是错误解析）
- 纯计算、无 I/O、多后端可用（wasm / native / js）

### 支持的写法（绝对日期）

| 写法 | 示例 | 结果（上下文 2026 年） |
|---|---|---|
| 年月日 + 单位 | `2026年11月17日`、`2026年11月17号` | 2026-11-17 |
| 中文数字全式 | `二〇二六年十一月十七日` | 2026-11-17 |
| 年月日无"日" | `2026年11月17` | 2026-11-17 |
| 分隔符式 | `2026-11-17`、`2026/11/17`、`2026.11.17` | 2026-11-17 |
| 分隔符年月 | `2026-11` | 2026-11-01 |
| 年月 | `2026年11月`、`二〇二六年十一月` | 2026-11-01 |
| 月日（推断年份） | `11月17日`、`十月一日` | 2026-11-17 / 2026-10-01 |
| 混合写法 | `2026年十一月十七日`、`二〇二六年11月17日` | 2026-11-17 |

### 解析语义

- **年份推断**：省略年份的表达式取上下文 `Context` 的年份，不做跨年推断（例如"12月31日"在 2026-11 的上下文中仍解析为 2026-12-31）。
- **年月形式**：`2026年11月` 解析为该月 1 日。
- **非法日期**：`parse` 返回 `Err(InvalidDate(y, m, d))`（如 `2月30日`、`2026年13月1日`）；`find_all` 跳过这类候选。
- **无日期**：`parse` 返回 `Err(NoMatch)`。
- **字符偏移**：`Match.start` / `Match.end` 为按字符计数的区间，`Match.text` 为原文切片。

## 安装

```bash
moon add cj3335556/zhdate
```

## API

| 名称 | 说明 |
|---|---|
| `parse(text, ctx) -> Result[Match, ParseError]` | 解析第一个日期表达式 |
| `find_all(text, ctx) -> Array[Match]` | 提取所有合法日期表达式 |
| `Context { year, month, day }` | 解析上下文（参考日期） |
| `Match { text, start, end, year, month, day, kind }` | 解析结果 |
| `MatchKind` | `FullDate` / `YearMonth` / `MonthDay` |
| `ParseError` | `NoMatch` / `InvalidDate(y, m, d)` |
| `tokenize(text) -> Array[Token]` | 分词器（数字/年月日/分隔符/其他） |
| `parse_cn_number` / `parse_cn_digits` / `parse_ascii_int` | 数字解析工具 |
| `is_leap_year` / `days_in_month` / `is_valid_date` | 公历日历工具 |

## 运行示例

```bash
moon run cmd/main
```

## 计划支持（暂未实现）

- 相对日期：明天、三天后、下周三、月底
- 时间：下午三点、15:30
- 日期区间：下周一至周三
- 农历日期（`tyme4mb` 已提供历法能力，本库以解析为主）

## 参考

日期表达式的语法设计与测试用例思路参考了以下项目（均为独立实现，未复制代码）：

- [dateparser](https://github.com/scrapinghub/dateparser)（BSD-3-Clause）— 多语言日期解析的语法覆盖
- [chrono](https://github.com/wanasit/chrono)（MIT）— 中文/英文日期表达式的识别规则

## 开发

```bash
moon check   # 类型检查
moon test    # 运行测试
moon fmt     # 格式化
```

## License

Apache-2.0
