# zhdate

中文自然语言日期解析库（MoonBit）。把中文文本里的日期、时间和区间表达式解析为结构化数据。

```moonbit
let ctx : Context = { year: 2026, month: 11, day: 17 }
guard parse("会议在下周三下午三点开始", ctx) is Ok(m) else {
  panic()
}
// m.text = "下周三下午三点", m.year = 2026, m.month = 11, m.day = 25
// m.time = Some({ hour: 15, minute: 0, second: 0 }), kind = DateTime
```

## 功能

- **绝对日期**：`2026年11月17日`、`二〇二六年十一月十七日`、`2026-11-17`、`11月17日`
- **相对日期**：`明天`、`三天后`、`下周三`、`月底`、`下个月17日`
- **时间**：`下午三点`、`15:30`、`9点半`、`中午`
- **日期+时间**：`下周三下午三点`（自动合并为一个匹配）
- **区间**：`下周一至周三`、`11月17日至19日`、`下午三点至五点`（右侧省略式自动继承左侧范围）
- 从文本中批量抽取（`find_all` / `find_ranges`），非法值明确报错（`InvalidDate` / `InvalidTime`）
- 纯计算、无 I/O、多后端可用（wasm / native / js）

### 支持的写法

| 类别 | 示例 | 结果（上下文 2026-11-17 星期二） |
|---|---|---|
| 年月日 + 单位 | `2026年11月17日`、`2026年11月17号` | 2026-11-17 |
| 中文数字全式 | `二〇二六年十一月十七日` | 2026-11-17 |
| 分隔符式 | `2026-11-17`、`2026/11/17`、`2026.11.17` | 2026-11-17 |
| 年月 / 分隔符年月 | `2026年11月`、`2026-11` | 2026-11-01 |
| 月日（推断年份） | `11月17日`、`十月一日` | 2026-11-17 / 2026-10-01 |
| 相对日 | `今天`/`明天`/`昨天`/`后天`/`前天`/`大后天`/`大前天` | ±0..3 天 |
| 天数偏移 | `三天后`、`3天前`、`两天后` | ±N 天 |
| 周偏移 | `两周后`、`一周前`、`三星期后` | ±7N 天 |
| 星期 | `下周三`、`上周一`、`本周三`、`周三`、`星期日`、`下下周一` | 对应星期的日期 |
| 月/年偏移 | `三个月后`、`两个月前`、`两年后`、`三月后` | 月/年平移 |
| 月末月初 | `月底`、`下月底`、`上个月初`、`11月底`、`三月初` | 月末/月初日期 |
| 年末年初 | `年底`、`下年底`、`2026年底`、`二〇二七年初` | 年末/年初日期 |
| 月+日 | `下个月17日`、`上月15号` | 平移月份 + 指定日 |
| 时刻 | `15:30`、`15:30:45`、`15点30分`、`15点30分45秒` | 15:30[:45] |
| 半点 | `9点半`、`三点半` | 09:30 |
| 时段 + 时刻 | `下午三点`、`上午9点20分`、`晚上8点`、`凌晨2点`、`中午` | 24 小时制时刻 |
| 日期 + 时刻 | `下周三下午三点`、`明天15:30`、`2026年11月17日上午9点` | DateTime 合并匹配 |
| 区间 | `下周一至周三`、`11月17日至19日`、`17日 ~ 19日`、`下午三点至五点` | 起止两个 Match |

### 解析语义

- **年份推断**：省略年份的表达式取上下文 `Context` 的年份，不做跨年推断。
- **年月形式**：`2026年11月` 解析为该月 1 日。
- **星期规则**：`下周X`/`上周X`/`本周X` 严格按周一为起点的自然周计算；省略修饰的 `周X` 解析为最近的未来该星期（今天命中则为今天）。
- **时段规则**：`下午/晚上 + 1..12` 转 24 小时制（`下午三点` → 15:00，`晚上12点` → 0:00）；大于 12 的数字视为 24 小时制原样保留；省略时段的小时按字面解析。
- **区间右侧省略式**：`11月17日至19日` 的 `19日`、`下周一至周三` 的 `周三`、`下午三点至五点` 的 `五点` 分别继承左侧的月份、周范围和昼夜时段；右侧为完整表达式（`明天`、`下周三`、`2026-11-20`）时按上下文正常解析。
- **非法值**：`parse` 返回 `Err(InvalidDate)`（如 `2月30日`）或 `Err(InvalidTime)`（如 `25:00`）；`find_all` / `find_ranges` 跳过非法值。
- **无匹配**：`Err(NoMatch)`。
- **字符偏移**：`Match.start` / `Match.end` 为按字符计数的区间，`Match.text` 为原文切片。

## 安装

```bash
moon add cj3335556/zhdate
```

## API

| 名称 | 说明 |
|---|---|
| `parse(text, ctx) -> Result[Match, ParseError]` | 解析第一个日期/时间表达式 |
| `find_all(text, ctx) -> Array[Match]` | 提取所有合法日期/时间表达式 |
| `parse_range(text, ctx) -> Result[Range, ParseError]` | 解析第一个区间 |
| `find_ranges(text, ctx) -> Array[Range]` | 提取所有区间 |
| `Context { year, month, day }` | 解析上下文（参考日期） |
| `Match { text, start, end, year, month, day, time, kind }` | 解析结果 |
| `TimeOfDay { hour, minute, second }` | 时刻 |
| `Range { text, start, end, from, to }` | 区间（两端为 Match） |
| `MatchKind` | `FullDate` / `YearMonth` / `MonthDay` / `Relative` / `Time` / `DateTime` |
| `ParseError` | `NoMatch` / `InvalidDate(y, m, d)` / `InvalidTime(h, m, s)` |
| `tokenize(text) -> Array[Token]` | 分词器（数字/关键词/分隔符/其他） |
| `parse_cn_number` / `parse_cn_digits` / `parse_ascii_int` | 数字解析工具 |
| `is_leap_year` / `days_in_month` / `is_valid_date` | 公历校验 |
| `days_from_civil` / `civil_from_days` / `add_days` / `shift_months` / `weekday` | 公历运算 |

## 运行示例

```bash
moon run cmd/main
```

## 暂不支持

- 农历日期（历法计算可配合 [tyme4mb](https://mooncakes.io/docs/justinwongcn/tyme4mb)）
- 英文日期表达式（可配合 dateutil 等）
- 时区数据库与跨时区推断（可配合 chrono_tz）
- 模糊限定词（"大约月底"）与整句 NLP

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
