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
                    Text(title,
                        style: TextStyle(
                            fontSize: DS.fsTitle,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(width: DS.s2),
                    Pill('${count()}',
                        color: Theme.of(context).colorScheme.primary),
                    const Spacer(),
                    if (extra != null) Text(extra, style: DText.muted(context)),
                  ]),
                ),
              ),
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

/// 学在浙大作业按截止时间分组，两行紧凑显示；区域内可滚动
class HomeworkList extends StatelessWidget {
  const HomeworkList({super.key, required this.store});
  final DesktopStore store;

  static Color groupColor(TodoGroup g) => switch (g) {
        TodoGroup.overdue => DS.danger,
        TodoGroup.within24h => DS.warning,
        TodoGroup.thisWeek => const Color(0xFF4F7CFF),
        TodoGroup.later || TodoGroup.noDeadline => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final groups = store.todosGrouped;
    if (store.todos.isEmpty) {
      return const EmptyHint('没有待交作业', icon: Icons.check_circle_outline);
    }
    return DScrollArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DS.s2, 0, DS.s2, DS.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.s2, DS.s3, DS.s2, DS.s1),
                child: Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: groupColor(entry.key),
                          shape: BoxShape.circle)),
                  const SizedBox(width: DS.s2),
                  Text('${todoGroupName[entry.key]}  ${entry.value.length}',
                      style: DText.muted(context)
                          .copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
              for (final t in entry.value)
                _HomeworkRow(
                    todo: t, store: store, color: groupColor(entry.key)),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeworkRow extends StatelessWidget {
  const _HomeworkRow(
      {required this.todo, required this.store, required this.color});
  final Todo todo;
  final DesktopStore store;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final end = todo.endTime;
    return Tooltip(
      message:
          '${todo.course}\n${todo.name}${end != null ? '\n截止 ${fmtDate(end)} ${fmtTime(end)}' : ''}',
      waitDuration: const Duration(milliseconds: 600),
      child: DRow(
        height: 44,
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
                if (end != null)
                  Text(fmtRelative(end, store.now),
                      style: DText.muted(context).copyWith(color: color)),
              ]),
              Text(
                '${todo.course}${end != null ? ' · ${fmtDate(end)} ${fmtTime(end)}' : ''}',
                style: DText.muted(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
    final days = entry.start.difference(now).inDays;
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
