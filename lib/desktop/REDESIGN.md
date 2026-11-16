# Celechron Desktop v2 — full redesign spec ("Paper")

This replaces the current desktop UI completely. Throw away the old look and the old layout
(KPI tiles, card-in-card dashboard, persistent right homework panel, top bar). Keep only the
data layer (`store.dart`, `lib/model`, `lib/http`) and the entry point `lib/main_desktop.dart`.

Target feel: a calm, keyboard-friendly desktop calendar/planner in the spirit of Notion Calendar,
Things 3 and Linear — content sits on a paper-like canvas, separated by whitespace and hairlines,
not boxed into cards. Typography and alignment carry the hierarchy; color is reserved for course
identity, "now", and urgency. No marketing copy, no explanatory paragraphs, no emoji.

## 1. Information architecture

| Key | Page | Purpose |
|---|---|---|
| Ctrl+1 | 今天 | What matters today and this week: agenda, homework due soon, next exams |
| Ctrl+2 | 日程 | Calendar: 周 / 月 / 课时 views |
| Ctrl+3 | 作业 | Full homework list (new first-class page) |
| Ctrl+4 | 考试 | Upcoming + past exams |
| Ctrl+5 | 成绩 | GPA summary, per-semester grades |
| Ctrl+6 | 任务 | User tasks (deadline tasks + fixed schedule) |
| Ctrl+, | 设置 | Account, appearance, GPA display, about |

Global: Ctrl+K command palette, F5 / Ctrl+R refresh, Ctrl+\ toggle sidebar collapse.
The old right-hand homework panel and the top bar are removed. Semester picker and sync status
move into the sidebar footer.

## 2. Shell

```
┌──────────────────┬───────────────────────────────────────────────────────┐
│ Celechron        │  Headline                              [page actions] │  page header 72px
│ ┌──────────────┐ │  subline                                              │
│ │⌕ 搜索   Ctrl K│ ├───────────────────────────────────────────────────────┤
│ └──────────────┘ │                                                       │
│  ◉ 今天          │                                                       │
│  ▦ 日程          │                  page body                            │
│  ✎ 作业      11  │                                                       │
│  ◷ 考试       2  │                                                       │
│  ◈ 成绩          │                                                       │
│  ☑ 任务          │                                                       │
│                  │                                                       │
│  2026年11月  ‹ › │                                                       │
│  一 二 三 四 五 六 日 │                                                   │
│  mini month grid │                                                       │
│                  │                                                       │
│ ──────────────── │                                                       │
│  26-27 秋冬 ▾    │                                                       │
│  第 10 周        │                                                       │
│  ● 刚刚同步  ⟳   │                                                       │
│  ⚙ 设置          │                                                       │
└──────────────────┴───────────────────────────────────────────────────────┘
```

- Sidebar width 232, background `sidebar` token, right hairline. Collapses to a 60px icon rail
  automatically when window width < 1080, or manually via Ctrl+\ (collapsed: icons only, tooltips,
  mini calendar hidden, footer shows only sync dot + settings icon).
- Nav item: height 32, radius 6, icon 18 + label 14/500. Hover: `hover` token fill. Active: `surface`
  fill + 1px hairline + text weight 600 (a "raised paper" pill, not an accent-colored blob).
  Trailing count in text3 (作业 = pending count, 考试 = exams within 14 days; omit when 0).
  Overdue homework → count turns `danger`.
- Search field (fake input, opens palette): height 30, radius 6, `surface` fill, hairline, placeholder
  "搜索" + kbd hint "Ctrl K" in text3.
- Mini month calendar: 7 columns, cell 26px, day number 12px. Today = accent filled circle with white
  number. Days outside the month in text3. Under the number, up to 2 dots: accent dot = homework due
  that day, danger dot = exam that day. Click a day → 日程 week view of that day. ‹ › change month.
- Footer: semester dropdown (store.semesters / selectSemester), "第 N 周" (store.teachingWeek; hide
  when null), sync row: status dot (success when ok, warning when refreshing with a small spinner,
  danger when store.lastErrors non-empty) + "刚刚同步 / N 分钟前同步 / 同步中… / 同步失败" + refresh
  icon button; failure tooltip lists lastErrors. Then 设置 nav item and the username in text3.
- Page header (owned by each page, height 72, horizontal padding 32): headline (H1) + subline (meta)
  on the left, page actions on the right. Body padding: 0 32 24 32.
- Page switch: 120ms fade. Hover/selection transitions 150ms ease-out. Nothing bouncy.
- Not logged in: every page body shows a centered login form (学号 / 密码 / 登录 button, error line),
  360px wide, instead of empty widgets.

## 3. Visual tokens

Font: `Microsoft YaHei UI` with the existing fallbacks. Always use `DefaultTextStyle.merge`, never
`DefaultTextStyle(style:)` (drops the theme font; this machine's system UI font is monospace).
All numerals use `FontFeature.tabularFigures()`.

Type scale (size / weight / line-height):
- display 28/600/1.2 — 今天 page date headline
- h1 20/600/1.3 — page headlines
- h2 15/600/1.35 — section titles where needed
- body 14/400/1.45, bodyStrong 14/600
- meta 12.5/400 color text2
- label 11.5/600 color text3, letterSpacing 0.4 — section labels ("作业 · 7 天内")
- number 26/600 tabular — big figures (GPA strip, exam day counts)

Spacing: 4-based (4, 8, 12, 16, 20, 24, 32, 40). Radius: 6 small (chips, nav, inputs), 8 blocks,
12 popovers/dialogs. Shadows only on popovers/dialogs/palette (blur 24, y 8, black 10% light / 40% dark).

Colors:

| token | light | dark |
|---|---|---|
| canvas | #F7F7F5 | #151517 |
| sidebar | #F0F0EE | #1A1A1D |
| surface | #FFFFFF | #1E1E22 |
| hover | #0000000A (4% black) | #FFFFFF0D |
| hairline | #E7E7E4 | #2B2B30 |
| hairlineStrong | #D5D5D0 | #3A3A40 |
| text | #1C1C1A | #ECECEA |
| text2 | #6A6A65 | #A3A39E |
| text3 | #9C9C96 | #6E6E6A |
| accent | #2F5BEA | #7B98FF |
| accentSoft | accent @ 10% over surface | accent @ 18% over surface |
| danger / now | #E5484D | #FF6B70 |
| warning | #C56A00 | #F5A524 |
| success | #1F9D55 | #3DD68C |

Course colors — 10 hues, assigned by stable hash of course name (keep `colorFor` idea):
#3E63DD blue, #12A594 teal, #30A46C green, #8DA336 olive, #D6A100 amber, #E5732E orange,
#E5484D red, #D6409F pink, #8E4EC6 purple, #6E56CF violet.
For each hue derive (all opaque, via `Color.alphaBlend` over `surface`):
- bar = hue (dark mode: lighten 12%)
- tint = hue @ 11% (light) / 20% (dark) over surface
- ink (title text on tint) = hue darkened to ~35% lightness (light) / lightened to ~80% (dark)
Never use translucent fills on top of grid lines.

## 4. Pages

### 4.1 今天

```
11月16日 周一                                                    (display)
第 10 周 · 秋学期 · 立冬 (special date if any)                    (meta)

日程                                      │ 作业 · 7 天内                    查看全部 →
 08:00  ▍数据结构基础                       │ 已逾期 1                                (danger label)
 09:35  ▍紫金港东1A-201 · 陈老师            │  ● 实验报告一          数字逻辑   已逾期 2 天
 ── 12:04 ─────────────────────── (now)   │ 今天
 13:25  ▍马克思主义基本原理                  │  ● 第3次上机实验        数据结构   23:59  11 小时
 15:50  ▍紫金港东1B-104                     │ 明天
 23:59  ○ 截止 · 第3次上机实验               │  ● 习题课作业 4         离散数学   15:59
                                          │ 周三 11/18
明天                                       │  ● 第二章习题           概率论     23:59
 08:00 离散数学及其应用 · 紫金港东2-302       │
 10:00 羽毛球（初级）· 紫金港风雨操场         │ 考试
                                          │  2 天   离散数学及其应用  11/18 周三 14:00 · 紫金港西2-104
                                          │  52 天  马克思主义基本原理  1/7 周四 14:00
                                          │
                                          │ 学业   五分制 4.17 · 四分制 3.81 · 学分 42  👁
```

- Two columns, 3fr | 2fr, separated by a vertical hairline with 32px gutters. No cards.
- 日程 (agenda, not an hour grid): chronological list of today's classes, exams, fixed user tasks
  and homework due today (homework rows: hollow circle icon, "截止 · title", at due time).
  Row: time column 56px (start in bodyStrong, end in meta below) | 3px course-color bar (full row
  height, radius 2) | title bodyStrong + "location · teacher" meta. Exams get a small danger
  "考试" chip after the title. Past rows: all text text3, bar 40% opacity. Ongoing row: tint
  background. "Now" divider: danger 1px line with a small "12:04" label at left, inserted between
  rows at the current time. Click row → detail popover.
- When today's items are all done or none exist: one meta line ("今天没有课" / "今天的课已结束"), and
  the 明天 section moves up. 明天 section: compact single-line rows "08:00  title · location".
  Fit rows to height (LayoutBuilder); never clip half a row; overflow → "还有 N 项" link → 日程.
- Right column, three sections with label headers:
  - 作业 · 7 天内: grouped by calendar day (已逾期 / 今天 / 明天 / 周X M/D). Row 36px single line:
    course-color dot | title (body, ellipsis) | course short name (meta, ellipsis, max 96px) |
    due time "23:59" (meta) | countdown right-aligned 64px: <24h warning "11 小时", overdue danger
    "已逾期 2 天", else text2 "3 天". "查看全部 →" in header right goes to 作业 page.
    Fit to height with "还有 N 项" footer.
  - 考试: next 3 upcoming exams: day count as number (26/600; "今天"/"明天" when 0/1 calendar days;
    danger when ≤1 day, warning ≤3) | name bodyStrong + "11/18 周三 14:00–16:00 · 紫金港西2-104" meta.
    None → "近期没有考试".
  - 学业: one meta line "五分制 4.17 · 四分制 3.81 · 学分 42" + eye toggle (store.gpaHidden/maskGpa).

### 4.2 日程

Header: headline "2026年11月" (month of the visible range), subline "第 10 周 · 11/16 – 11/22".
Actions: segmented control [周 | 月 | 课时] + [‹] [今天] [›]. Keys: ←/→ prev/next, T today,
W week, M month.

Week view (on a `surface` panel with radius 8 and hairline border, fills the body):
```
        │ 周一 16 │ 周二 17 │ 周三 18 │ 周四 19 │ 周五 20 │ 周六 21 │ 周日 22 │
截止     │ ✎ 第3次… │ ✎ 习题… │        │ ✎ 第二… │         │        │        │   all-day lane
08:00 ─ ┼─────────┼─────────┼─────────┼─────────┼─────────┼────────┼────────┤
        │         │▍离散数学│▍学术英语│▍数据结构│         │        │        │
```
- Day header: weekday (meta) + day number (h2). Today: number in accent filled circle; today column
  background accentSoft at 40% strength. Special dates (holidays) shown as a small label under the
  day header in text3.
- "截止" all-day lane: homework due that day as chips (accent tint, "✎ title", single line), max 2
  per day + "+N" chip; lane height fits the busiest day (max 2 rows). Hover chip → tooltip with
  full title, course and due time. Hide the lane when the visible week has no deadlines.
- Hour range: from the earliest to the latest class hour in the visible week, padded by 1h, clamped to
  at least 08:00–18:00. Row heights fill the available height exactly (no scroll).
- Grid: hour lines hairline; half-hour lines hairline at 50% opacity. Time gutter 52px, labels meta,
  aligned to the line.
- Weekend columns: same width as weekdays when they have events, otherwise 0.55×.
- Event blocks: opaque tint, 3px left bar, radius 6, padding 6/8, 2px gap from column edges.
  Content by height: ≥64px: title (13/600 ink, up to 2 lines) / time / location (meta);
  40–63px: title / "time · location"; <40px: title only. Overlaps are laid out side by side.
  Exams: danger bar and a "考试" mini label. Hover: tint darkens 4%. Click → detail popover anchored
  to the block (name, time, location, teacher, weeks/description), Esc closes.
- Now line: danger 1.5px across today's column with a 6px dot at the gutter edge.

Month view: 6×7 grid on a surface panel. Cell: day number top-left (today in accent circle, other
months text3), up to 3 lines "● 08:00 课程名" (dot = course color; exams danger; deadlines "✎ title"
in accent), then "+N". Click cell → week view of that day.

课时 view: per selected semester, a table: 课程 | 学分 | 已上 / 总课时 | progress bar (course color,
4px, radius 2) | 每周. Header line: "已上 120 / 总 256 课时". Use existing `store.hoursOf`.

### 4.3 作业

Header: "作业", subline "11 项待交 · 更新于 3 分钟前" (store.homeworkUpdatedAt). Actions: course
filter dropdown ("全部课程 ▾", lists courses that have homework with counts) + refresh icon.

Body: single list, max width 880, left-aligned; scrolls internally (only this list scrolls).
Groups with label headers: 已逾期 (danger) / 今天 / 明天 / one group per day for the next 7 days
("周三 11/18") / 之后 / 无截止时间. Row 52px, two lines:
- line 1: course-color dot | title (bodyStrong, ellipsis) | countdown right (same colors as 今天)
- line 2 (indented under title): course name · "周三 23:59" (meta)
Hover row → `hover` fill. Right-click → context menu: 复制标题, 复制课程名. Empty → "没有待交作业".
Row height must scale with `MediaQuery.textScalerOf(context)`.

### 4.4 考试

Header: "考试", subline "<semester name> · N 场". Actions: none (semester from sidebar).
Body: list, max width 880, internal scroll. Upcoming first, then a "已结束" label and past exams in
text3. Row 72px:
```
 ┌────┐
 │ 18 │  离散数学及其应用  [期末]                              2 天
 │11月│  周三 14:00–16:00 · 紫金港西2-104 · 座位 23
 └────┘
```
Date block 48×48 radius 8, tint of the course color, day number h2 ink + month label meta.
Countdown uses calendar days (calendarDaysBetween): 今天 / 明天 / N 天; danger ≤1, warning ≤3.

### 4.5 成绩

Header: "成绩", subline "已获 42 学分". Actions: eye toggle.
Summary strip (no boxes): five figures separated by vertical hairlines, each = label (label style)
above number (number style): 五分制 · 四分制 (4.3) with "4.0 制 3.90" meta under it · 百分制 ·
主修均绩 with "33 学分" meta · 已获学分.
Below: two columns. Left 240px: semester list (name bodyStrong, "GPA 4.38 · 20.5 学分" meta),
selected = surface pill like the nav; GPA trend line chart under the list (accent line, points,
labels), fits remaining height. Right: table for the selected semester on a surface panel:
课程 | 学分 | 成绩 | 五分制 | 4.3 | 百分制. Row 40px, hairline separators, hover fill. Score
badge: ≥90 success tint, 80–89 accent tint, 70–79 warning tint, <70 danger tint. Table scrolls
internally if needed. Respect store.gpaHidden / maskGpa for all GPA figures.

### 4.6 任务

Header: "任务", subline "N 项进行中". Actions: "+ 新建" button (opens the existing
`lib/page/task/task_edit_page.dart` dialog flow as today).
Body two columns: 截止任务 (pending: title, due "周三 23:59", progress bar from getProgress,
checkbox to complete; completed collapsed under "已完成 N" toggle) | 固定日程 (title, time range,
repeat info). Right-click menus as today (edit, complete, delete).

### 4.7 设置

Single column, max width 640, sections with label headers and hairline separators:
账号 (学号, 退出登录 with confirm dialog; login form when logged out) · 外观 (segmented 浅色/深色/跟随系统
via store.setBrightnessMode) · 成绩 (首页隐藏 GPA switch) · 关于 (版本 / fuse version, GitHub link).

### 4.8 Command palette (Ctrl+K)

Modal 560px wide, top 18% of window, surface, radius 12, shadow. Input 44px. Results grouped with
label headers: 页面, 作业, 考试, 课程 (from selected semester). Fuzzy-ish match (contains, case-
insensitive, also matches course name). ↑/↓ move, Enter select, Esc close. Selecting: page → navigate;
作业 → 作业 page scrolled to and briefly highlighting that row; 考试 → 考试 page; 课程 → 日程 week of
its next session. Max 8 results per group.

### 4.9 Popovers & dialogs

Detail popover for periods: 300px, surface, radius 12, shadow; title h2 with course-color bar,
rows of icon + meta text. Dialogs (login, confirm, task edit): radius 12, 24px padding.

## 5. Implementation structure

```
lib/desktop/
  store.dart                (keep; add small helpers only, e.g. todosOn(day), examsOn(day))
  format.dart               fmtTime, fmtDeadline, calendarDaysBetween, countdown text
  theme/tokens.dart         colors (light/dark), type, spacing, radii, course palette
  theme/app_theme.dart      ThemeData for light/dark
  shell/shell.dart          layout, shortcuts, page switching, collapse logic
  shell/sidebar.dart        nav, search field, mini calendar, footer
  shell/command_palette.dart
  widgets/                  section_label, list rows, segmented, countdown, popover, login_form,
                            empty_state, scroll_area, context_menu
  pages/today_page.dart
  pages/calendar/calendar_page.dart, week_view.dart, month_view.dart, hours_view.dart
  pages/homework_page.dart, exams_page.dart, grades_page.dart, tasks_page.dart, settings_page.dart
  DESIGN.md                 rewrite to describe the new system (delete this REDESIGN.md at the end
                            or keep it as the design doc — keep one source of truth)
```
Delete the old `screens/`, `widgets.dart`, `side_panels.dart`, `theme.dart`, `shell.dart` once replaced.
Pages read data only from `DesktopStore` and wrap in `ListenableBuilder`. Use `store.now` (ticks every
30s), never `DateTime.now()` in widgets. Deadlines/exams day labels use calendar days, not `inDays`
of a Duration. Window min size stays; verify at 1000×700, 1200×820 and 1600×1000: no overflow, no
page-level scrolling except the explicitly scrollable lists.

## 6. Amendments after review (these OVERRIDE sections 1–5)

1. **Week view min density.** Each hour gets at least 44px. If the range does not fit, the grid
   area (below the sticky day header + 截止 lane) scrolls vertically inside the panel; on open it
   scrolls so that the current time (or the first event) is visible. Hour range = earliest/latest of
   **all timed items** in the visible week (classes, exams, user tasks), padded 1h, at least 08:00–18:00.
   Weekend columns: always the same width as weekdays (drop the 0.55× rule).
2. **Homework rows everywhere are two lines** (今天 right column too): line 1 = dot + title + countdown
   right; line 2 = course name · absolute due "周三 11/18 23:59". Row height 44 × text scale.
3. **Preserve behavior until replaced.** Keep login flow, task editing (`lib/page/task/task_edit_page.dart`
   dialog), task context menus, .ics/other existing actions, brightness mode, GPA hide. Delete old files
   only after the new page compiles and covers them.
4. **Homework primary action.** Add `courseId` (int?, from `course_id`) and `type` (String?, from
   `type`) to `lib/model/todo.dart` (parse in fromJson, write in toJson; keep the UTC→local fix). Click
   a homework row → open `https://courses.zju.edu.cn/course/{courseId}/learning-activity#/{id}` with
   url_launcher (already a dependency); when courseId is null, open `https://courses.zju.edu.cn/user/index`.
   Context menu: 在浏览器打开, 复制标题. Always show absolute due date next to the countdown.
5. **Height allocation, 今天 page.** Left column: agenda takes all height and scrolls internally if
   needed; 明天 section only shown when today's remaining items ≤ 3, max 4 rows. Right column: 考试
   (max 3 rows, fixed height, hidden if none) and 学业 (one line) are pinned at the bottom; 作业 takes
   the rest and scrolls internally, with "查看全部 →" in its header. Grades page: semester list scrolls;
   GPA chart fixed 140px under it, hidden when window height < 760.
6. **Semester picker** moves out of the sidebar into the page header actions of 日程 (all views),
   考试 and 成绩 (one shared dropdown widget). Sidebar footer keeps "第 N 周" + sync row only.
   Manual Ctrl+\ toggle overrides the auto-collapse until the window crosses the 1080 threshold again.
7. **Scope cuts for this pass.** Command palette searches pages, 作业 and 考试 only; selecting navigates
   to the page (no scroll-to-row highlight, no course navigation). Mini calendar keeps homework/exam dots.
8. **Contrast & input.** Any text that carries information (past exams, course names, meta) uses text2,
   never text3; text3 only for decorative/hint text (placeholders, kbd hints, out-of-month days).
   Global shortcuts (digits, T/W/M, arrows) are ignored while a TextField has focus; Ctrl+K/F5 always work.
   Every interactive element has a visible focus ring (accent, 2px) for keyboard navigation.
   Colors written as `Color(0xAARRGGBB)`.
9. **States.** Loading (first refresh, no data yet): skeleton rows (hairline-colored bars), not spinners.
   Offline / refresh failed: data stays visible; sidebar sync row turns danger with tooltip listing
   errors. Default page on launch = 今天; remember the last selected 日程 view (周/月/课时) in memory.
