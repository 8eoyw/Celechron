# Celechron 桌面版 — 页面实现规格

The desktop UI is a new Flutter UI that lives under `lib/desktop/`. It shares the data layer with the mobile app.

Entry point: `lib/main_desktop.dart`. Build with: `flutter build windows -t lib/main_desktop.dart`.

## Hard rules (every page must follow these)

1. **Imports.** Use only `package:flutter/material.dart` and the files in this folder (`store.dart`, `theme.dart`, `widgets.dart`).
   - Do not import anything under `lib/page/` or `lib/design/`. The one exception is `tasks_screen.dart`, which may import `lib/page/task/task_edit_page.dart`.
   - Do not call `Get.find` or `Get.put`.
2. **Data source.** All data comes from `DesktopStore` (passed in as `store`).
   - Wrap the root of the page in `ListenableBuilder(listenable: store, builder: ...)`.
   - Read the store's getters, and call its methods for all changes.
3. **No page-level scrolling.** At a 1200×820 window, the area a page receives is about **830 × 750**.
   - Use `Column` / `Row` + `Expanded` / `Flexible` to split the space into fixed regions.
   - Never put `SingleChildScrollView` or `ListView` at the page root.
   - When there is too much content, only the content area of a single card may use `DScrollArea` for internal scrolling. Alternatively, compute how many items fit from the available height (`LayoutBuilder`: `maxRows = (constraints.maxHeight / DS.rowHeight).floor()`) and show a "还有 N 项" line for the rest.
4. **Desktop interaction.**
   - Clicks, hover and right-click only.
   - No swipe, no long-press, no `Dismissible`, no pull-to-refresh, no bottom sheets.
   - Editing opens in `showDialog`. Secondary actions use `showContextMenu` (widgets.dart).
5. **Styling.**
   - Content blocks always use `DCard` (title + content).
   - Spacing between cards is `DS.s3`.
   - Colors come from `DSColors.of(context)` / `DS.*` / `periodColor()`.
   - Text styles come from `DText.*`.
   - Don't hardcode font sizes or colors. Don't set `fontFamily` (the theme sets it globally).
   - Keep text on a single line with `maxLines: 1, overflow: TextOverflow.ellipsis`,
     except descriptions and adaptive timeline titles/locations described below.
6. **Empty states.**
   - When not logged in or there's no data, show `EmptyHint('...')` and never throw.
   - `store.selectedSemester` may be null.
7. **The class name and constructor are fixed:** `XxxScreen({super.key, required this.store})`, `final DesktopStore store;`.
8. **Code must pass `flutter analyze` with no errors.** Add Chinese comments only where they help, and keep them short.

## Common data types (from lib/model)

### Visual system (desktop refresh)

- `DText.title`: 20 / 600; `DText.cardTitle`: 14 / 600;
  `DText.body`: 13 / 400; `DText.muted`: 12 / secondary. All use tabular figures.
  Preserve the inherited `DS.font` and fallbacks; use `DefaultTextStyle.merge` only.
- KPI rows use `DS.kpiHeight` (100). Every tile uses the neutral card surface and
  1px border, with separate label, value and caption lines. Values/captions scale
  down when needed rather than losing content to ellipsis. Reserve the caption
  line even when empty, so all KPI baselines align. Accent color is a small dot.
- `eventFill` alpha-blends course color over the card to create an **opaque**
  fill (14% light, 22% dark). Timeline blocks use a 3px accent and measure text
  with the inherited font and text scale. Tall blocks show title/time/location
  on separate lines (location may wrap to two); medium blocks combine metadata;
  short blocks show the title, adding time only when it fits. Narrow overlaps
  reserve up to three title lines before metadata and hide time ranges too wide
  to display. Month chips omit time when it would crowd the title.
- Overview uses 08:00–18:00 as its minimum visible range, extending to include
  earlier/later events; empty days show `EmptyHint`. The week view stays 08:00–22:00.
- Homework uses `DS.homeworkRowHeight` and `DS.groupHeaderHeight`. `LayoutBuilder`
  reserves space for a clickable “还有 N 项” footer, never a partial item or an
  orphan group header. The footer opens all items in an internally scrolling
  desktop dialog. `fmtDeadline`, `fmtDeadlineCountdown` and `deadlineColor` must
  receive `store.now`; group labels stay secondary while urgency colors the countdown.
  Rows are 42px with a course-color bar: title/countdown on the first line,
  deadline/course on the second. The date/time has fixed intrinsic width; only
  the course may ellipsize. 26px group headers allow at least five overview rows
  at a 1200×820 window with the demo data.
- Tomorrow rows give names the full flexible line; time/location share the next
  line. Exam table rows combine date/time and put location/seat beneath the name.
- Navigation uses an accent icon pill and subtle hover. Main/side headers share
  `DS.topBarHeight`; cards use `DS.cardHeaderHeight`. Content stays inside fixed
  regions; only card/dialog content may scroll.

- `Period`:
  - `type` (PeriodType.classes/test/user/flow/virtual), `summary` (title), `location`, `description`, `startTime`, `endTime` (DateTime).
  - Classes and exams have already been expanded into concrete times.
- `Semester`:
  - `name` (e.g. "2025-2026秋冬"), `courses` (Map<String, Course>), `courseCount`, `courseCredit`, `exams`, `grades`, `gpa` (List<double>, same meaning as store.gpa).
  - `firstHalfName` / `secondHalfName` (e.g. 秋/冬).
  - `firstHalfSessionCount` / `secondHalfSessionCount` (class hours every two weeks).
- `Course`: `name`, `teacher`, `sessions`, `exams`, `grade` (Grade?), `confirmed`.
- `Grade`:
  - `name`, `credit` (double), `original` (original score string, e.g. "优秀" / "85"), `hundredPoint` (int), `fourPoint` (4.3 scale), `fourPointLegacy` (4.0 scale), `gpaIncluded`.
  - `fivePoint`: if this field is missing, use `GpaHelper` or `hundredPoint`. Prefer `original`, `hundredPoint` and `fourPoint`.
- `Exam`: `name`, `type` (ExamType.midterm/finalExam), `time` (List<DateTime>, [start, end]), `location`, `seat` (may be null).
- `ExamEntry` (store.dart): `exam`, `semester`, `start`, `end`.
- `Todo`: `name`, `course`, `endTime` (may be null).
- `Task`:
  - `summary`, `type` (TaskType.deadline/fixed/fixedlegacy), `status` (TaskStatus.running/suspended/completed/failed/deleted/outdated), `startTime`, `endTime`, `location`, `description`, `timeNeeded`, `timeSpent`.
  - `getProgress()` returns a 0–100 double.

## DesktopStore API

See `store.dart`. The members used most often:

- `now`, `isLoggedIn`, `username`, `refreshing`, `refresh()`, `logout()`, `onLoggedIn()`
- `semesters`, `selectedSemester`, `selectedSemesterIndex`, `selectSemester(i)`, `teachingWeek`
- `thisMonday`, `periodsOfDay(d)`, `periodsOfWeek(monday)` (7 lists), `todayPeriods`, `ongoing`, `nextPeriod`, `specialDateOf(d)`
- `examsOf(semester)`, `upcomingExams`
- `gpa` ([五分制, 四分制4.3, 四分制4.0, 百分制]), `majorGpa`, `majorCredit`, `earnedCredit`, `gradesOf(semester)`
- `todos`, `todosGrouped`
- `pendingDeadlines`, `finishedDeadlines`, `fixedTasks`, `toggleTaskCompleted(t)`, `deleteTask(t)`, `saveTask(original, edited)`, `replan()`

## Page specs

The shell already provides: the left navigation, a top bar (title / date / teaching week / semester picker / sync status / refresh), and the right-hand homework panel. **Pages do not render a title of their own.**

### overview_screen.dart — 总览 (default page)

- KPI row: `DS.kpiHeight`, next event (flex 2), five-point GPA, four-point GPA,
  earned credits and upcoming homework (flex 1 each).
- Below: today timeline (flex 3), homework and tomorrow (right column, flex 2).
  The shell's overview side panel shows upcoming exams.
- Today uses 08:00–18:00, extending to include earlier/later events. Empty days
  show `EmptyHint`. Each opaque block uses the adaptive timeline layout above.
- Tomorrow has 54px rows, with the full flexible name above time/location;
  reserve a footer row when more items remain.
- The timeline uses `LayoutBuilder` to compute pixels per minute = height /
  ((endHour - startHour) × 60). Clamp each block to the visible range.
- Blocks that overlap in time are laid out side by side in columns.
- Clicking a block opens a `showDialog` with full details: name, time, location, description.

### timetable_screen.dart — 课表 (week view)

- The page's top row (height 36) holds: ◀ previous week / this week / next week ▶ buttons, plus the date range of the selected week. The default week is `store.thisMonday`. Page state lives in a StatefulWidget.
- Below that is a full-height grid:
  - left time-axis column 44px;
  - 7 equal-width day columns, each with a header showing 周一 10/13, plus `specialDateOf` holiday labels;
  - today's column is highlighted.
- The vertical axis is 08:00–22:00 and fills the available height. Periods are positioned exactly like the overview timeline.
- Block content follows the adaptive timeline layout above; prioritize readable
  titles in overlapping columns and separate locations when height permits.
- Clicking a block shows the details dialog.
- Exams (PeriodType.test) use a red accent and an "【考试】" title prefix.

### grades_screen.dart — 成绩

- KPI row (`DS.kpiHeight`), 6 tiles:
  - 五分制 `gpa[0]`;
  - 四分制 `gpa[1]` (sub: 4.0 scale `gpa[2]`);
  - 百分制 `gpa[3]`;
  - 主修均绩 `majorGpa`;
  - 主修学分 `majorCredit`;
  - 已获学分 `earnedCredit`.
  - Two decimal places.
- Below that, left/right split:
  - **Left, width 240:** DCard "学期", listing all `store.semesters`. Each row shows the semester's short name, its GPA (`semester.gpa[0]`) and credits. Clicking a row calls `selectSemester`. The selected row is highlighted. Use internal scrolling if there are too many rows.
  - **Right, Expanded:** DCard "{学期名} 成绩" table with a header row and these columns: 课程 / 学分 / 成绩 (original) / 百分制 / 四分制.
    - Row height 40; shared `Pill` score chips, hover, subtle separators.
    - Sort by score, high to low.
    - If the table is longer than the card, the table body scrolls inside the card with `DScrollArea`; the header stays fixed.
    - Show `gpaIncluded == false` rows with muted text.
- Add a semester GPA trend: a simple line chart (`CustomPainter`) drawn at the bottom of the left DCard, height 90, using semester `gpa[0]` in order from oldest to newest.

### exams_screen.dart — 考试

- Two columns side by side:
  - **Left (flex 7):** DCard "{学期名} 考试", a table of `store.examsOf(selectedSemester)`.
    - 62px rows: combined date/time, flexible name with location/seat beneath,
      type Pill, countdown (fmtRelative or "已结束").
    - Finished exams in muted text.
  - **Right (flex 3):** DCard "倒计时": the next 6 of `store.upcomingExams` as neutral cards. Each shows the full course name, days remaining, date/time and location; only its content area may scroll.

### tasks_screen.dart — 任务

- Three columns side by side (equal width): DCard "待办 DDL" (`pendingDeadlines`), DCard "已完成" (`finishedDeadlines`), DCard "日程" (`fixedTasks`).
- Each row:
  - color dot, title, due/start time;
  - DDL rows also show a thin progress bar (`getProgress()`).
  - Rows are compact: height 40.
- Clicking a row opens the edit dialog:
  - `showDialog` containing `Dialog(child: SizedBox(width: 560, height: 640, child: TaskEditPage(task)))`.
  - `TaskEditPage` returns a Task through Navigator.pop.
  - Apply the result with `store.saveTask(task, result)`.
- Right-click menu: 编辑 / 标记完成 (or 标记未完成; DDL only) / 删除 (destructive).
- The "待办" card title bar has a trailing "+ 新建" button that creates a new Task the same way as the mobile app:

  ```dart
  Task(endTime: now, startTime: now, repeatEndsTime: now)..reset()
  ```

  Then open the edit dialog. If a Task comes back, call `saveTask(newTask, result)`.
- Use internal scrolling inside each column when its content is too long.

### settings_screen.dart — 设置

- Two-column layout:
  - **Left:** DCard "账号"
    - When logged in: student ID, a 退出登录 button (with a confirmation dialog), and a 立即同步 button.
    - When not logged in: an inline login form (student ID + password + login button). See the "登录" section below.
  - **Right:** DCard "外观", a light / dark / follow-system selector with three options, which modifies the option's `brightnessMode`. The store needs to expose `brightnessMode` and `setBrightnessMode(BrightnessMode)`; if these are missing, add them to store.dart, writing the database via `Get.find<DatabaseHelper>(tag:'db').setOption(...)`. First check whether DatabaseHelper has a matching method; the mobile version is in lib/page/option/option_controller.dart.
- "关于" card: version info and a link to the project.

#### Login

See the mobile `lib/page/option/login_page.dart`. Its core logic is:

1. Set `scholar.username` / `scholar.password`.
2. `await scholar.login()`. The return value is a list of errors; all null means success.
3. Save the credentials (follow whatever the mobile version does).

Wrap this as a method `Future<String?> login(String user, String pass)` in store.dart that returns an error message or null. Call `onLoggedIn()` and `refresh()` after success.
