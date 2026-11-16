# Desktop UI implementation

[REDESIGN.md](REDESIGN.md) is the single design source of truth. Section 6 amendments override earlier sections. The Paper implementation lives in `theme/`, `widgets/`, `shell/` and `pages/`.

- Read data and perform mutations only through `DesktopStore`. Pages subscribe with `ListenableBuilder`; never access Get, Hive or HTTP directly.
- Read time from `store.now`, never `DateTime.now()` in widgets. Use `format.dart` and `calendarDaysBetween` for dates, including midnight/year boundaries.
- Use `PaperColors`, `PaperType` and `Paper` tokens. Information uses `text`/`text2`; `text3` is reserved for hints and decoration. Course tints are opaque blends over surface.
- Use `DefaultTextStyle.merge` to preserve the theme font. All numerals use tabular figures.
- Two-line homework rows use `homeworkRowHeightOf(context)` and `MediaQuery.textScalerOf(context)`; never hard-code a row height that clips scaled text. Always show the absolute due date. Primary action opens the course activity; missing course IDs fall back to the courses home page.
- The shell owns navigation, global shortcuts and collapse behavior. Ignore navigation shortcuts while editing text. `PaperAction` provides hover and keyboard focus rings.
- Pages own their 72px header and internal list scrolling. The shell has no top bar or persistent right panel.
- Phase 2 replaces the `// PHASE2` legacy bodies in calendar/exams/grades/tasks. Retain `CalendarPageState.openDay` and `handleKey` hooks (or compatible equivalents). Retain legacy imports until those bodies are replaced, including task editing and context menus.
- `test_desktop/harness.dart` derives the page matrix from `DesktopPage.values`. Both tests render all pages in light/dark at 1000×700, 1200×820 and 1600×1000. Fixtures are synthetic and do not read personal databases. PNGs are named `<size>_<theme>_<page>.png`.
