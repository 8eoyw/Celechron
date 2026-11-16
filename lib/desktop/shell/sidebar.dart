import 'package:flutter/material.dart';
import '../format.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/list_row.dart';
import 'navigation.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar(
      {super.key,
      required this.store,
      required this.collapsed,
      required this.selected,
      required this.onNavigate,
      required this.onSearch,
      required this.onOpenDay});
  final DesktopStore store;
  final bool collapsed;
  final DesktopPage selected;
  final ValueChanged<DesktopPage> onNavigate;
  final VoidCallback onSearch;
  final ValueChanged<DateTime> onOpenDay;
  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    return Container(
        width: collapsed ? 60 : 232,
        decoration: BoxDecoration(
            color: c.sidebar,
            border: Border(right: BorderSide(color: c.hairline))),
        padding:
            EdgeInsets.symmetric(horizontal: collapsed ? 8 : 16, vertical: 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              height: 32,
              child: collapsed
                  ? Tooltip(
                      message: 'Celechron',
                      child: Icon(Icons.auto_stories_outlined,
                          size: 22, color: c.text2))
                  : Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('Celechron', style: PaperType.h2(context)))),
          const SizedBox(height: 12),
          PaperAction(
              onTap: onSearch,
              tooltip: collapsed ? '搜索 · Ctrl K' : null,
              selected: true,
              child: SizedBox(
                  height: 30,
                  child: Row(
                      mainAxisAlignment: collapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (!collapsed) const SizedBox(width: 8),
                        Icon(Icons.search, size: 16, color: c.text3),
                        if (!collapsed) ...[
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('搜索',
                                  style: PaperType.meta(context)
                                      .copyWith(color: c.text3))),
                          Text('Ctrl K',
                              style: PaperType.meta(context)
                                  .copyWith(color: c.text3)),
                          const SizedBox(width: 8)
                        ]
                      ]))),
          const SizedBox(height: 16),
          for (final page
              in DesktopPage.values.where((p) => p != DesktopPage.settings))
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _nav(context, page)),
          // 迷你月历放不下（矮窗口或文字放大）时整块隐藏，不让侧栏溢出
          Expanded(
              child: collapsed
                  ? const SizedBox.shrink()
                  : LayoutBuilder(
                      builder: (context, constraints) => constraints
                                  .maxHeight >=
                              MediaQuery.textScalerOf(context).scale(16 + 236)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Align(
                                  alignment: Alignment.topCenter,
                                  child: MiniCalendar(
                                      store: store, onOpenDay: onOpenDay)))
                          : const SizedBox.shrink())),
          const Divider(),
          const SizedBox(height: 12),
          if (!collapsed && store.teachingWeek != null)
            Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text('第 ${store.teachingWeek} 周',
                    style: PaperType.meta(context))),
          _sync(context),
          const SizedBox(height: 8),
          _nav(context, DesktopPage.settings),
          if (!collapsed && store.username.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Text(store.username,
                    style: PaperType.meta(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
        ]));
  }

  Widget _nav(BuildContext context, DesktopPage page) {
    final c = PaperColors.of(context);
    final count = page == DesktopPage.homework
        ? store.todos.length
        : page == DesktopPage.exams
            ? store.upcomingExams
                .where((e) => calendarDaysBetween(store.now, e.start) <= 14)
                .length
            : 0;
    final overdue = page == DesktopPage.homework &&
        store.todos.any((t) => t.endTime?.isBefore(store.now) ?? false);
    return PaperAction(
        onTap: () => onNavigate(page),
        tooltip:
            collapsed ? '${page.label}${count > 0 ? ' · $count' : ''}' : null,
        selected: selected == page,
        child: SizedBox(
            height: 32,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 8),
                child: Row(
                    mainAxisAlignment: collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(page.icon, size: 18, color: c.text2),
                      if (!collapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(page.label,
                                style: PaperType.body(context).copyWith(
                                    fontWeight: selected == page
                                        ? FontWeight.w600
                                        : FontWeight.w500))),
                        if (count > 0)
                          Text('$count',
                              style: PaperType.meta(context).copyWith(
                                  color: overdue ? c.danger : c.text2))
                      ]
                    ]))));
  }

  Widget _sync(BuildContext context) {
    final c = PaperColors.of(context);
    final failed = store.lastErrors.isNotEmpty;
    final label = failed
        ? '同步失败'
        : store.refreshing
            ? '同步中…'
            : !store.isLoggedIn
                ? '未登录'
                : store.lastRefreshAt == null
                    ? '尚未同步'
                    : '${updatedAgo(store.lastRefreshAt, store.now)}同步';
    final dot = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: failed
                ? c.danger
                : store.refreshing
                    ? c.warning
                    : !store.isLoggedIn
                        ? c.text2
                        : c.success));
    return Tooltip(
        message: failed ? store.lastErrors.join('\n') : label,
        child: collapsed
            ? PaperAction(
                onTap: store.refresh,
                child: SizedBox(height: 28, child: Center(child: dot)))
            : Row(children: [
                const SizedBox(width: 8),
                if (store.refreshing && !failed)
                  SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: c.warning))
                else
                  dot,
                const SizedBox(width: 8),
                Expanded(
                    child: Text(label,
                        style: PaperType.meta(context)
                            .copyWith(color: failed ? c.danger : null),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                PaperIconButton(
                    icon: Icons.refresh,
                    tooltip: '刷新 · F5',
                    onPressed: store.refresh)
              ]));
  }
}

class MiniCalendar extends StatefulWidget {
  const MiniCalendar({super.key, required this.store, required this.onOpenDay});
  final DesktopStore store;
  final ValueChanged<DateTime> onOpenDay;
  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late DateTime month = DateTime(widget.store.now.year, widget.store.now.month);
  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    final first = DesktopStore.mondayOf(month);
    return Column(children: [
      Row(children: [
        Expanded(
            child: Text('${month.year}年${month.month}月',
                style: PaperType.meta(context))),
        PaperIconButton(
            icon: Icons.chevron_left,
            tooltip: '上个月',
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month - 1))),
        PaperIconButton(
            icon: Icons.chevron_right,
            tooltip: '下个月',
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month + 1)))
      ]),
      const SizedBox(height: 4),
      Row(children: [
        for (final day in '一二三四五六日'.split(''))
          Expanded(
              child: Center(child: Text(day, style: PaperType.meta(context))))
      ]),
      const SizedBox(height: 4),
      for (var week = 0; week < 6; week++)
        Row(children: [
          for (var day = 0; day < 7; day++)
            Expanded(
                child:
                    _day(context, first.add(Duration(days: week * 7 + day)), c))
        ])
    ]);
  }

  Widget _day(BuildContext context, DateTime date, PaperColors c) {
    final today = calendarDaysBetween(widget.store.now, date) == 0;
    final homework = widget.store.todosOn(date).isNotEmpty;
    final exam = widget.store.examsOn(date).isNotEmpty;
    return PaperAction(
        onTap: () => widget.onOpenDay(date),
        tooltip: fmtDate(date),
        child: SizedBox(
            height: 26,
            child: Column(children: [
              Container(
                  width: 19,
                  height: 19,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: today ? c.accent : null),
                  child: Text('${date.day}',
                      style: PaperType.meta(context).copyWith(
                          fontSize: 12,
                          height: 1.2,
                          color: today
                              ? const Color(0xFFFFFFFF)
                              : date.month != month.month
                                  ? c.text3
                                  : c.text2))),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (homework) _dot(c.accent),
                if (exam) _dot(c.danger)
              ])
            ])));
  }

  Widget _dot(Color color) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)));
}
