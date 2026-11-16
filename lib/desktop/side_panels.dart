import 'package:flutter/material.dart';

import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';
import 'package:celechron/model/todo.dart';

/// 右侧栏外框：与顶栏同高的标题行 + 栏内内容；总览页放即将考试，其它页放作业
class SidePanel extends StatelessWidget {
  const SidePanel({
    super.key,
    required this.store,
    required this.title,
    required this.count,
    required this.child,
    this.trailing,
  });

  final DesktopStore store;
  final String title;
  final int Function() count;
  final String? Function()? trailing;
  final Widget Function() child;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    return Container(
      color: colors.rail,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final extra = trailing?.call();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: DS.topBarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DS.s4),
                  child: Row(children: [
                    Text(title, style: DText.cardTitle(context)),
                    const SizedBox(width: DS.s2),
                    Pill('${count()}',
                        color: Theme.of(context).colorScheme.primary),
                    const Spacer(),
                    if (extra != null)
                      Flexible(
                          child: Text(extra,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DText.muted(context))),
                  ]),
                ),
              ),
              Divider(height: 1, color: colors.border),
              Expanded(child: child()),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────── 作业 ─────────────────────────

/// 作业侧栏
class HomeworkPanel extends StatelessWidget {
  const HomeworkPanel({super.key, required this.store});
  final DesktopStore store;

  @override
  Widget build(BuildContext context) => SidePanel(
        store: store,
        title: '作业',
        count: () => store.todos.length,
        trailing: () => store.isLoggedIn
            ? '更新于 ${fmtAgo(store.homeworkUpdatedAt, store.now)}'
            : null,
        child: () => HomeworkList(store: store),
      );
}

/// Fit complete groups/rows, reserving a footer before adding any item.
class HomeworkList extends StatelessWidget {
  const HomeworkList({super.key, required this.store});
  final DesktopStore store;

  static Color groupColor(TodoGroup g) => switch (g) {
        TodoGroup.overdue => DS.danger,
        TodoGroup.within24h => DS.warning,
        TodoGroup.thisWeek => const Color(0xFF5265CB),
        TodoGroup.later || TodoGroup.noDeadline => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final groups = store.todosGrouped;
    if (store.todos.isEmpty) {
      return const EmptyHint('没有待交作业', icon: Icons.check_circle_outline);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final rows = <Widget>[];
      var used = 0.0;
      var shown = 0;
      final total = store.todos.length;
      for (final entry in groups.entries) {
        var first = true;
        for (final todo in entry.value) {
          final rowHeight =
              homeworkRowHeightOf(context) +
              (first ? DS.groupHeaderHeight : 0);
          final footer = shown + 1 < total ? DS.rowHeight : 0;
          if (used + rowHeight + footer > constraints.maxHeight) {
            final hidden = total - shown;
            rows.add(SizedBox(
                height: constraints.maxHeight - used < DS.rowHeight
                    ? constraints.maxHeight - used
                    : DS.rowHeight,
                child: TextButton(
                  style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: DS.s2)),
                  onPressed: () => _showAll(context),
                  child: Text('还有 $hidden 项', style: DText.muted(context)),
                )));
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
          }
          if (first) {
            rows.add(SizedBox(
                height: DS.groupHeaderHeight,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DS.s2),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            '${todoGroupName[entry.key]}  ·  ${entry.value.length}',
                            style: DText.muted(context)
                                .copyWith(letterSpacing: 0.6),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)))));
          }
          rows.add(_HomeworkRow(todo: todo, store: store));
          used += rowHeight;
          shown++;
          first = false;
        }
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    });
  }

  void _showAll(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('全部作业', style: DText.title(context)),
          content: SizedBox(
              width: 520,
              height: 520,
              child: ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => DScrollArea(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            for (final entry in store.todosGrouped.entries) ...[
                              SizedBox(
                                  height: DS.groupHeaderHeight,
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                          '${todoGroupName[entry.key]}  ·  ${entry.value.length}',
                                          style: DText.muted(context)))),
                              for (final todo in entry.value)
                                _HomeworkRow(todo: todo, store: store),
                            ]
                          ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'))
          ],
        ),
      );
}

class _HomeworkRow extends StatelessWidget {
  const _HomeworkRow({required this.todo, required this.store});
  final Todo todo;
  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    final end = todo.endTime;
    return Tooltip(
      message:
          '${todo.course}\n${todo.name}${end != null ? '\n截止 ${fmtDate(end)} ${fmtTime(end)}' : ''}',
      waitDuration: const Duration(milliseconds: 600),
      child: DRow(
        height: homeworkRowHeightOf(context),
        child: ColorBarTile(
          color: DS.colorFor(todo.course),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(todo.name,
                        style: DText.strong(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (end != null) ...[
                  const SizedBox(width: DS.s2),
                  Text(fmtDeadlineCountdown(end, store.now),
                      style: DText.muted(context).copyWith(
                          color: deadlineColor(context, end, store.now))),
                ],
              ]),
              const SizedBox(height: DS.s1),
              Row(children: [
                Text(end == null ? '无截止时间' : fmtDeadline(end, store.now),
                    style: DText.muted(context), maxLines: 1, softWrap: false),
                Expanded(
                    child: Text(' · ${todo.course}',
                        style: DText.muted(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── 即将考试 ─────────────────────────

/// 即将考试侧栏（总览页）：所有学期中尚未结束的考试
class ExamPanel extends StatelessWidget {
  const ExamPanel({super.key, required this.store});
  final DesktopStore store;

  @override
  Widget build(BuildContext context) => SidePanel(
        store: store,
        title: '即将考试',
        count: () => store.upcomingExams.length,
        child: () {
          final exams = store.upcomingExams;
          if (exams.isEmpty) {
            return const EmptyHint('暂无考试', icon: Icons.event_note_outlined);
          }
          return DScrollArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(DS.s2, DS.s2, DS.s2, DS.s3),
              child: Column(children: [
                for (final e in exams)
                  UpcomingExamRow(entry: e, now: store.now),
              ]),
            ),
          );
        },
      );
}

/// 即将考试行：课名 + 倒计时 / 日期 时间 地点
class UpcomingExamRow extends StatelessWidget {
  const UpcomingExamRow({super.key, required this.entry, required this.now});

  final ExamEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final exam = entry.exam;
    final days = calendarDaysBetween(now, entry.start);
    // 两行：侧栏较窄，单行放不下课名
    return DRow(
      height: 44,
      child: ColorBarTile(
        color: DS.colorFor(exam.name),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(exam.name,
                      style: DText.strong(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              Text(days <= 0 ? '今天' : '$days 天后',
                  style: DText.muted(context).copyWith(
                      color: days <= 7 ? DS.danger : null,
                      fontWeight: FontWeight.w600)),
            ]),
            Text(
                '${fmtDate(entry.start)} ${fmtRange(entry.start, entry.end)}'
                '${(exam.location ?? '').isEmpty ? '' : ' · ${exam.location}'}',
                style: DText.muted(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
