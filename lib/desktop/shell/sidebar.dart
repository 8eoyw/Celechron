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
      this.onToggleCollapse,
      this.onOpenDay});
  final DesktopStore store;
  final bool collapsed;
  final DesktopPage selected;
  final ValueChanged<DesktopPage> onNavigate;
  final VoidCallback onSearch;
  final VoidCallback? onToggleCollapse;
  final ValueChanged<DateTime>? onOpenDay;

  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    final exams = store.isLoggedIn ? store.upcomingExams : const <ExamEntry>[];
    final topBarH = MediaQuery.textScalerOf(context)
        .scale(Paper.topBarHeight)
        .clamp(Paper.topBarHeight, double.infinity);

    return Container(
        width: collapsed ? 56 : 218,
        color: c.sidebar,
        padding: EdgeInsets.fromLTRB(
            collapsed ? 8 : 10, 0, collapsed ? 8 : 10, 10),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Top 46px chrome bar — pixel-aligned with PageHeader on the right.
          SizedBox(
              height: topBarH,
              child: collapsed
                  ? Center(
                      child: PaperIconButton(
                          icon: Icons.view_sidebar_outlined,
                          tooltip: '展开侧栏 · Ctrl \\',
                          onPressed: onToggleCollapse))
                  : Row(children: [
                      const SizedBox(width: 8),
                      Icon(Icons.auto_stories_outlined,
                          size: 17, color: c.text),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('Celechron',
                              style: PaperType.h2(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      PaperIconButton(
                          icon: Icons.view_sidebar_outlined,
                          tooltip: '收起侧栏 · Ctrl \\',
                          onPressed: onToggleCollapse),
                      PaperIconButton(
                          icon: Icons.search_rounded,
                          tooltip: '搜索 · Ctrl K',
                          onPressed: onSearch)
                    ])),
          const SizedBox(height: 2),
          // Antigravity-style translucent quick-action search pill.
          if (collapsed)
            PaperIconButton(
                icon: Icons.search_rounded,
                tooltip: '搜索 · Ctrl K',
                onPressed: onSearch)
          else
            Container(
                decoration: BoxDecoration(
                    color: c.glassControl,
                    borderRadius: BorderRadius.circular(Paper.smallRadius)),
                child: PaperAction(
                    onTap: onSearch,
                    borderRadius: Paper.smallRadius,
                    child: SizedBox(
                        height: 32,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(children: [
                              Icon(Icons.search_rounded,
                                  size: 15, color: c.text3),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text('快速搜索',
                                      style: PaperType.meta(context)
                                          .copyWith(color: c.text2))),
                              Text('Ctrl K',
                                  style: PaperType.meta(context).copyWith(
                                      fontSize: 11, color: c.text3))
                            ]))))),
          const SizedBox(height: 12),
          for (final page
              in DesktopPage.values.where((p) => p != DesktopPage.settings))
            Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _nav(context, page)),
          // Lower-left sidebar: Antigravity-style single-line upcoming exams list.
          Expanded(
              child: collapsed || exams.isEmpty
                  ? const SizedBox.shrink()
                  : LayoutBuilder(builder: (context, bounds) {
                      final scale = MediaQuery.textScalerOf(context).scale(1);
                      final rowH = 30.0 * scale;
                      final headerH = 24.0 * scale;
                      final avail = bounds.maxHeight - headerH - 20;
                      final maxRows = (avail / rowH)
                          .floor()
                          .clamp(0, exams.length)
                          .clamp(0, 6);
                      if (maxRows <= 0) return const SizedBox.shrink();
                      final clipped = exams.length > maxRows;
                      Widget list = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final exam in exams.take(maxRows))
                              _examItem(context, exam, c, rowH)
                          ]);
                      if (clipped) {
                        list = ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [0.0, 0.78, 1.0],
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFFFFFFF),
                                      Color(0x33FFFFFF)
                                    ]).createShader(rect),
                            child: list);
                      }
                      return Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 6, bottom: 4),
                                    child: Text('近期考试',
                                        style: PaperType.label(context)
                                            .copyWith(fontSize: 11))),
                                list
                              ]));
                    })),
          // Persistent compact GPA summary in lower-left (when logged in & expanded).
          if (!collapsed && store.isLoggedIn && store.earnedCredit > 0) ...[
            const SizedBox(height: 6),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: c.glassControl,
                    borderRadius: BorderRadius.circular(Paper.smallRadius)),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          'GPA ${store.maskGpa(store.gpa[0].toStringAsFixed(2))} · ${store.earnedCredit.toStringAsFixed(0)} 学分',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PaperType.meta(context)
                              .copyWith(fontSize: 11.5, color: c.text2))),
                  PaperIconButton(
                      icon: store.gpaHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      tooltip: '显示或隐藏 GPA',
                      onPressed: store.toggleGpaHidden)
                ])),
          ],
          const SizedBox(height: 6),
          if (!collapsed) _sync(context),
          const SizedBox(height: 2),
          _nav(context, DesktopPage.settings),
        ]));
  }

  Widget _examItem(
      BuildContext context, ExamEntry entry, PaperColors c, double height) {
    final days = calendarDaysBetween(store.now, entry.start);
    final badgeColor = days <= 1
        ? c.danger
        : days <= 3
            ? c.warning
            : c.text3;
    return PaperAction(
        onTap: () => onNavigate(DesktopPage.exams),
        borderRadius: Paper.smallRadius,
        tooltip:
            '${entry.exam.name}\n${fmtDate(entry.start)} ${fmtRange(entry.start, entry.end)}${entry.exam.location == null ? '' : ' · ${entry.exam.location}'}',
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
            height: height,
            child: Row(children: [
              Expanded(
                  child: Text(entry.exam.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PaperType.meta(context)
                          .copyWith(fontSize: 12.5, color: c.text2))),
              const SizedBox(width: 8),
              Text(examCountdown(entry.start, store.now),
                  style: PaperType.meta(context).copyWith(
                      fontSize: 11.5,
                      fontWeight:
                          days <= 3 ? FontWeight.w600 : FontWeight.w400,
                      color: badgeColor))
            ])));
  }

  Color _syncDotColor(PaperColors c) {
    if (store.lastErrors.isNotEmpty) return c.danger;
    if (store.refreshing) return c.warning;
    if (!store.isLoggedIn) return c.text3;
    return c.success;
  }

  Widget _nav(BuildContext context, DesktopPage page) {
    final c = PaperColors.of(context);
    final active = selected == page;
    final count = page == DesktopPage.homework
        ? store.todos.length
        : page == DesktopPage.exams
            ? store.upcomingExams
                .where((e) => calendarDaysBetween(store.now, e.start) <= 14)
                .length
            : 0;
    final overdue = page == DesktopPage.homework &&
        store.todos.any((t) => t.endTime?.isBefore(store.now) ?? false);
    final isSettings = page == DesktopPage.settings;
    final tip = collapsed
        ? '${page.label}${count > 0 ? ' · $count' : ''}${isSettings && store.username.isNotEmpty ? ' · ${store.username}' : ''}'
        : (isSettings && store.username.isNotEmpty
            ? '账号 ${store.username}'
            : null);
    return PaperAction(
        onTap: () => onNavigate(page),
        tooltip: tip,
        selected: active,
        borderRadius: Paper.smallRadius,
        child: SizedBox(
            height: 32,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10),
                child: Row(
                    mainAxisAlignment: collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      if (collapsed && isSettings)
                        Stack(clipBehavior: Clip.none, children: [
                          Icon(page.icon,
                              size: 16,
                              color: active ? c.selectionInk : c.text2),
                          Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _syncDotColor(c))))
                        ])
                      else
                        Icon(page.icon,
                            size: 16,
                            color: active ? c.selectionInk : c.text2),
                      if (!collapsed) ...[
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(page.label,
                                style: PaperType.body(context).copyWith(
                                    fontSize: 13,
                                    color: active ? c.selectionInk : c.text2,
                                    fontWeight: active
                                        ? FontWeight.w500
                                        : FontWeight.w400))),
                        if (count > 0)
                          Text('$count',
                              style: PaperType.meta(context).copyWith(
                                  fontSize: 11.5,
                                  fontWeight: overdue
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: overdue ? c.danger : c.text3))
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
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: _syncDotColor(c)));
    return Tooltip(
        message: failed ? store.lastErrors.join('\n') : label,
        child: Row(children: [
          const SizedBox(width: 10),
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
                  style: PaperType.meta(context).copyWith(
                      fontSize: 11.5, color: failed ? c.danger : c.text3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          PaperIconButton(
              icon: Icons.refresh_rounded,
              tooltip: '刷新 · F5',
              onPressed: store.refresh)
        ]));
  }
}
