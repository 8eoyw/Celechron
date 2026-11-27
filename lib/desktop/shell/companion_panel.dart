import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:celechron/model/exam.dart';
import 'package:celechron/model/grade.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/model/todo.dart';
import '../format.dart';
import '../state/desktop_controller.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/common_ui.dart';
import '../widgets/course_palette.dart';

/// Dual-mode Google Workspace-style Right Companion Panel:
/// - Default mode: `待办与近期` (imminent exams + unified homework & task stream).
/// - Inspector mode: in-place Detail / Course Inspector with `← 返回` breadcrumb.
class CompanionPanel extends StatelessWidget {
  const CompanionPanel({
    super.key,
    required this.store,
    required this.controller,
    this.isOverlay = false,
  });

  final DesktopStore store;
  final DesktopController controller;
  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final target = controller.inspector;

    return Container(
      decoration: BoxDecoration(
        color: c.sheet,
        borderRadius: BorderRadius.circular(DesktopRadius.sheet),
        border: Border.all(color: c.hairline),
        boxShadow: isOverlay
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(-4, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: target != null
          ? _InspectorBody(
              store: store,
              controller: controller,
              target: target,
            )
          : controller.destination == DesktopDestination.tasks
              ? _TasksCompanionBody(
                  store: store,
                  controller: controller,
                  isOverlay: isOverlay,
                )
              : _UpNextBody(
                  store: store,
                  controller: controller,
                  isOverlay: isOverlay,
                ),
    );
  }
}

/// Zero-duplication companion shown while the user is in the Tasks workspace:
/// surfaces Today's live schedule + imminent exams instead of repeating the homework list.
class _TasksCompanionBody extends StatelessWidget {
  const _TasksCompanionBody({
    required this.store,
    required this.controller,
    required this.isOverlay,
  });

  final DesktopStore store;
  final DesktopController controller;
  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final today = store.agendaPeriodsOn(store.now);
    final imminentExams = store.upcomingExams
        .where((e) => calendarDaysBetween(store.now, e.start) <= 14)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              Text('今日与近期考试', style: DesktopType.section(context)),
              const Spacer(),
              if (isOverlay)
                DesktopIconButton(
                  icon: Icons.close_rounded,
                  tooltip: '关闭面板 (Esc)',
                  size: 16,
                  boxSize: 28,
                  onPressed: () =>
                      controller.setCompanionOpen(false, userAction: true),
                ),
            ],
          ),
        ),
        Expanded(
          child: DesktopScrollArea(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imminentExams.isNotEmpty) ...[
                  SectionHeading(
                    '近期考试',
                    color: c.warning,
                    trailing:
                        Text('14 天内', style: DesktopType.caption(context)),
                  ),
                  for (final entry in imminentExams.take(3)) ...[
                    _ImminentExamTile(
                      entry: entry,
                      now: store.now,
                      onTap: () =>
                          controller.inspect(ExamInspectorTarget(entry)),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 12),
                ],
                SectionHeading(
                  '今日日程',
                  trailing: DesktopAction(
                    onTap: () =>
                        controller.setDestination(DesktopDestination.schedule),
                    borderRadius: DesktopRadius.tag,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '时间轴',
                      style: DesktopType.caption(context)
                          .copyWith(color: c.primary),
                    ),
                  ),
                ),
                if (today.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('今天没有排课，可专心推进待办任务',
                        style: DesktopType.meta(context)),
                  )
                else
                  for (final p in today) ...[
                    _CompactAgendaTile(
                      period: p,
                      now: store.now,
                      onTap: () {
                        if (p.type == PeriodType.classes) {
                          controller.inspect(CourseInspectorTarget(p.summary));
                        } else {
                          controller.inspect(PeriodInspectorTarget(p));
                        }
                      },
                    ),
                    const SizedBox(height: 5),
                  ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceLow,
                    borderRadius: BorderRadius.circular(DesktopRadius.card),
                    border: Border.all(color: c.hairline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: c.text3),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '点击左侧任意作业或任务，可在此直接查看详情、跳转学在浙大或编辑进度。',
                          style: DesktopType.caption(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactAgendaTile extends StatelessWidget {
  const _CompactAgendaTile({
    required this.period,
    required this.now,
    required this.onTap,
  });

  final Period period;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final swatch = period.type == PeriodType.test
        ? CoursePalette.exam(context)
        : CoursePalette.of(context, period.summary);
    final past = !period.endTime.isAfter(now);

    return DesktopAction(
      onTap: onTap,
      backgroundColor: c.surfaceLow,
      borderColor: c.hairline,
      borderRadius: DesktopRadius.block,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Opacity(
        opacity: past ? 0.6 : 1.0,
        child: Row(
          children: [
            Container(
              width: 3,
              height: 26,
              decoration: BoxDecoration(
                color: swatch.bar,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesktopType.strong(context).copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    [
                      fmtRange(period.startTime, period.endTime),
                      if (period.location.isNotEmpty) period.location,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesktopType.caption(context, numeric: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpNextBody extends StatelessWidget {
  const _UpNextBody({
    required this.store,
    required this.controller,
    required this.isOverlay,
  });

  final DesktopStore store;
  final DesktopController controller;
  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final imminentExams = store.upcomingExams
        .where((e) => calendarDaysBetween(store.now, e.start) <= 14)
        .toList();
    final groupedTodos = store.todosGrouped;
    final pendingTasks = store.pendingDeadlines;
    final overdueCount = (groupedTodos[TodoGroup.overdue]?.length ?? 0) +
        pendingTasks.where((t) => t.endTime.isBefore(store.now)).length;
    final totalOpen = store.todos.length + pendingTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel header
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              Text('待办与近期', style: DesktopType.section(context)),
              const SizedBox(width: 8),
              if (overdueCount > 0)
                ConcentricTag(
                  label: '已逾期 $overdueCount',
                  foreground: c.danger,
                  background: c.dangerFill,
                  radius: DesktopRadius.tag,
                  numeric: true,
                )
              else if (totalOpen > 0)
                ConcentricTag(
                  label: '$totalOpen',
                  radius: DesktopRadius.tag,
                  numeric: true,
                ),
              const Spacer(),
              DesktopIconButton(
                icon: Icons.auto_awesome_outlined,
                tooltip: '重新自动规划学习时段',
                size: 16,
                boxSize: 28,
                onPressed: store.isLoggedIn
                    ? () async {
                        await store.replan();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已重新生成学习规划时段'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
              ),
              if (isOverlay)
                DesktopIconButton(
                  icon: Icons.close_rounded,
                  tooltip: '关闭面板 (Esc)',
                  size: 16,
                  boxSize: 28,
                  onPressed: () =>
                      controller.setCompanionOpen(false, userAction: true),
                ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: store.initialLoading
              ? const LoadingSkeleton(rows: 5)
              : (imminentExams.isEmpty &&
                      groupedTodos.isEmpty &&
                      pendingTasks.isEmpty)
                  ? EmptyStateView(
                      title: '近期没有待办事项',
                      subtitle: '作业与个人截止任务会汇总在这里',
                      icon: Icons.check_circle_outline_rounded,
                      compact: true,
                      action: store.isLoggedIn
                          ? DesktopAction(
                              onTap: () =>
                                  controller.createTask(context, store),
                              borderColor: c.hairline,
                              borderRadius: DesktopRadius.chip,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Text(
                                '+ 新建任务',
                                style: DesktopType.meta(context)
                                    .copyWith(color: c.primary),
                              ),
                            )
                          : null,
                    )
                  : DesktopScrollArea(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Pinned imminent exams (<= 14 days)
                          if (imminentExams.isNotEmpty) ...[
                            SectionHeading(
                              '近期考试',
                              color: c.warning,
                              trailing: Text(
                                '14 天内',
                                style: DesktopType.caption(context),
                              ),
                            ),
                            for (final entry in imminentExams.take(3)) ...[
                              _ImminentExamTile(
                                entry: entry,
                                now: store.now,
                                onTap: () => controller
                                    .inspect(ExamInspectorTarget(entry)),
                              ),
                              const SizedBox(height: 6),
                            ],
                            const SizedBox(height: 10),
                          ],
                          // Pending personal deadlines
                          if (pendingTasks.isNotEmpty) ...[
                            SectionHeading(
                              '个人任务',
                              trailing: DesktopAction(
                                onTap: () => controller
                                    .setDestination(DesktopDestination.tasks),
                                borderRadius: DesktopRadius.tag,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: Text(
                                  '管理',
                                  style: DesktopType.caption(context)
                                      .copyWith(color: c.primary),
                                ),
                              ),
                            ),
                            for (final task in pendingTasks.take(5)) ...[
                              _CompanionTaskTile(
                                task: task,
                                now: store.now,
                                onToggle: () => store.toggleTaskCompleted(task),
                                onTap: () => controller
                                    .inspect(TaskInspectorTarget(task)),
                              ),
                              const SizedBox(height: 4),
                            ],
                            const SizedBox(height: 12),
                          ],
                          // Learning-in-ZJU Homework grouped by urgency
                          for (final entry in groupedTodos.entries) ...[
                            SectionHeading(
                              todoGroupName[entry.key]!,
                              color: entry.key == TodoGroup.overdue
                                  ? c.danger
                                  : null,
                              trailing: Text(
                                '${entry.value.length}',
                                style:
                                    DesktopType.caption(context, numeric: true),
                              ),
                            ),
                            for (final todo in entry.value) ...[
                              _CompanionTodoTile(
                                todo: todo,
                                now: store.now,
                                highlighted:
                                    controller.hoveredTodoId == todo.id,
                                onHover: (h) => controller
                                    .setHoveredTodo(h ? todo.id : null),
                                onTap: () => controller
                                    .inspect(TodoInspectorTarget(todo)),
                              ),
                              const SizedBox(height: 3),
                            ],
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ImminentExamTile extends StatelessWidget {
  const _ImminentExamTile({
    required this.entry,
    required this.now,
    required this.onTap,
  });

  final ExamEntry entry;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = CoursePalette.exam(context);
    final exam = entry.exam;
    final seat = exam.seat?.trim();
    return DesktopAction(
      onTap: onTap,
      backgroundColor: swatch.fill,
      borderRadius: DesktopRadius.block,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: swatch.bar,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exam.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesktopType.strong(context)
                            .copyWith(fontSize: 12.5, color: swatch.ink),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConcentricTag(
                      label: examCountdown(entry.start, now),
                      foreground: swatch.ink,
                      background: swatch.bar.withValues(alpha: 0.22),
                      radius: DesktopRadius.tag,
                      numeric: true,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    '${fmtDate(entry.start)} ${fmtTime(entry.start)}',
                    if ((exam.location ?? '').isNotEmpty) exam.location!,
                    if (seat != null && seat.isNotEmpty) '座$seat',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.caption(context, numeric: true)
                      .copyWith(color: swatch.meta),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionTaskTile extends StatelessWidget {
  const _CompanionTaskTile({
    required this.task,
    required this.now,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final completed = task.status == TaskStatus.completed;
    return DesktopAction(
      onTap: onTap,
      borderRadius: DesktopRadius.block,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              completed
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 17,
              color: completed ? c.primary : c.text3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.summary.isEmpty ? '(未命名任务)' : task.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.strong(context).copyWith(
                    fontSize: 12.5,
                    color: completed ? c.text3 : c.text1,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fmtDeadline(task.endTime, now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.caption(context, numeric: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          DeadlineCountdown(target: task.endTime, now: now),
        ],
      ),
    );
  }
}

class _CompanionTodoTile extends StatelessWidget {
  const _CompanionTodoTile({
    required this.todo,
    required this.now,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
  });

  final Todo todo;
  final DateTime now;
  final bool highlighted;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = CoursePalette.of(context, todo.course);
    return DesktopAction(
      onTap: onTap,
      onDoubleTap: () => openHomework(todo),
      onHoverChanged: onHover,
      selected: highlighted,
      onSecondaryTapDown: (details) async {
        final action = await showDesktopContextMenu(
          context,
          details.globalPosition,
          const {0: '在浏览器打开', 1: '复制标题'},
        );
        if (action == 0) await openHomework(todo);
        if (action == 1) {
          await Clipboard.setData(ClipboardData(text: todo.name));
        }
      },
      borderRadius: DesktopRadius.block,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: swatch.bar,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        todo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesktopType.strong(context)
                            .copyWith(fontSize: 12.5),
                      ),
                    ),
                    if (todo.endTime != null) ...[
                      const SizedBox(width: 6),
                      DeadlineCountdown(target: todo.endTime!, now: now),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    todo.course,
                    if (todo.endTime != null) fmtDeadline(todo.endTime!, now),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.caption(context, numeric: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── In-place Detail & Course Inspector ─────────────────────────

class _InspectorBody extends StatelessWidget {
  const _InspectorBody({
    required this.store,
    required this.controller,
    required this.target,
  });

  final DesktopStore store;
  final DesktopController controller;
  final InspectorTarget target;

  String get _headerTitle => switch (target) {
        CourseInspectorTarget() => '课程详情',
        PeriodInspectorTarget() => '日程详情',
        TodoInspectorTarget() => '作业详情',
        TaskInspectorTarget() => '任务详情',
        ExamInspectorTarget() => '考试详情',
      };

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              DesktopAction(
                onTap: controller.clearInspector,
                tooltip: '返回待办列表 (Esc)',
                borderRadius: DesktopRadius.chip,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 16, color: c.text2),
                    const SizedBox(width: 4),
                    Text('待办', style: DesktopType.meta(context)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('/', style: DesktopType.caption(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _headerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.section(context),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DesktopScrollArea(
            padding: const EdgeInsets.all(16),
            child: switch (target) {
              CourseInspectorTarget(courseName: final name) =>
                _CourseInspectorContent(
                  courseName: name,
                  store: store,
                  controller: controller,
                ),
              PeriodInspectorTarget(period: final p) => _PeriodInspectorContent(
                  period: p,
                  store: store,
                  controller: controller,
                ),
              TodoInspectorTarget(todo: final todo) => _TodoInspectorContent(
                  todo: todo,
                  store: store,
                  controller: controller,
                ),
              TaskInspectorTarget(task: final task) => _TaskInspectorContent(
                  task: task,
                  store: store,
                  controller: controller,
                ),
              ExamInspectorTarget(entry: final entry) => _ExamInspectorContent(
                  entry: entry,
                  store: store,
                  controller: controller,
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _CourseInspectorContent extends StatelessWidget {
  const _CourseInspectorContent({
    required this.courseName,
    required this.store,
    required this.controller,
  });

  final String courseName;
  final DesktopStore store;
  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final swatch = CoursePalette.of(context, courseName);

    // Join course metadata, hours, homework, exams, and grade across store.
    final sem = store.selectedSemester ??
        (store.semesters.isNotEmpty ? store.semesters.first : null);
    final courseObj =
        sem?.courses.values.where((e) => e.name == courseName).firstOrNull;
    final hours = sem == null
        ? null
        : store
            .hoursOf(sem)
            .courses
            .where((e) => e.name == courseName)
            .firstOrNull;
    final relatedTodos =
        store.todos.where((t) => t.course == courseName).toList();
    final relatedExams = [
      for (final s in store.scholar.semesters) ...store.examsOf(s),
    ].where((e) => e.exam.name == courseName).toList();
    Grade? relatedGrade;
    for (final s in store.semesters) {
      final hit = s.grades.where((g) => g.name == courseName).firstOrNull;
      if (hit != null) {
        relatedGrade = hit;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: swatch.bar,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(courseName,
                      style:
                          DesktopType.title(context).copyWith(fontSize: 16.5)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if ((courseObj?.teacher ?? '').isNotEmpty)
                        ConcentricTag(
                          label: courseObj!.teacher!,
                          radius: DesktopRadius.tag,
                        ),
                      if (courseObj != null && courseObj.credit > 0)
                        ConcentricTag(
                          label: '${courseObj.credit.toStringAsFixed(1)} 学分',
                          foreground: swatch.ink,
                          background: swatch.fill,
                          radius: DesktopRadius.tag,
                          numeric: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Hours progress
        if (hours != null && hours.total > 0) ...[
          const SectionHeading('本学期课时进度'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surfaceLow,
              borderRadius: BorderRadius.circular(DesktopRadius.card),
              border: Border.all(color: c.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '已上 ${hours.done} / ${hours.total} 节',
                      style: DesktopType.strong(context, numeric: true),
                    ),
                    const Spacer(),
                    Text(
                      '${(hours.done / hours.total * 100).round()}%',
                      style:
                          DesktopType.mono(context).copyWith(color: swatch.bar),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (hours.done / hours.total).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: c.hairline,
                    color: swatch.bar,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '共 ${hours.weeks.length} 个教学周 · 均 ${hours.perWeek.toStringAsFixed(1)} 节/周',
                  style: DesktopType.caption(context, numeric: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Related homework
        SectionHeading(
          '关联作业',
          trailing: Text('${relatedTodos.length}',
              style: DesktopType.caption(context, numeric: true)),
        ),
        if (relatedTodos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('暂无待交作业', style: DesktopType.meta(context)),
          )
        else ...[
          for (final todo in relatedTodos) ...[
            DesktopAction(
              onTap: () => openHomework(todo),
              backgroundColor: c.surfaceLow,
              borderColor: c.hairline,
              borderRadius: DesktopRadius.block,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(todo.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DesktopType.strong(context)
                                .copyWith(fontSize: 12.5)),
                        if (todo.endTime != null)
                          Text(fmtDeadline(todo.endTime!, store.now),
                              style:
                                  DesktopType.caption(context, numeric: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded, size: 14, color: c.text3),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
        ],
        // Related exams
        if (relatedExams.isNotEmpty) ...[
          const SectionHeading('考试安排'),
          for (final entry in relatedExams) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surfaceLow,
                borderRadius: BorderRadius.circular(DesktopRadius.block),
                border: Border.all(color: c.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ConcentricTag(
                        label:
                            entry.exam.type == ExamType.midterm ? '期中' : '期末',
                        foreground: c.warning,
                        background: c.warningFill,
                        radius: DesktopRadius.tag,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${fmtDate(entry.start)} ${fmtRange(entry.start, entry.end)}',
                          style: DesktopType.meta(context, numeric: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if ((entry.exam.location ?? '').isNotEmpty)
                        entry.exam.location!,
                      if ((entry.exam.seat ?? '').isNotEmpty)
                        '座位号 ${entry.exam.seat}',
                    ].join(' · '),
                    style: DesktopType.caption(context, numeric: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
        ],
        // Grade record if available
        if (relatedGrade != null) ...[
          const SectionHeading('已出成绩'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surfaceLow,
              borderRadius: BorderRadius.circular(DesktopRadius.block),
              border: Border.all(color: c.hairline),
            ),
            child: Row(
              children: [
                Text(
                  store.maskGpa(relatedGrade.original),
                  style: DesktopType.title(context)
                      .copyWith(fontFeatures: DesktopType.tabular),
                ),
                const SizedBox(width: 12),
                Text(
                  '五分制 ${store.maskGpa(relatedGrade.fivePoint.toStringAsFixed(1))}',
                  style: DesktopType.meta(context, numeric: true),
                ),
                const Spacer(),
                Text(
                  '${relatedGrade.credit.toStringAsFixed(1)} 学分',
                  style: DesktopType.caption(context, numeric: true),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PeriodInspectorContent extends StatelessWidget {
  const _PeriodInspectorContent({
    required this.period,
    required this.store,
    required this.controller,
  });

  final Period period;
  final DesktopStore store;
  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final linkedTask = period.fromUid == null
        ? null
        : store.fixedTasks.where((t) => t.uid == period.fromUid).firstOrNull;
    final mins = period.endTime.difference(period.startTime).inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(period.summary,
            style: DesktopType.title(context).copyWith(fontSize: 16.5)),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.schedule_rounded,
          text:
              '${fmtDate(period.startTime)} · ${fmtRange(period.startTime, period.endTime)}（$mins 分钟）',
          numeric: true,
        ),
        if (period.location.isNotEmpty)
          _InfoRow(icon: Icons.location_on_outlined, text: period.location),
        if (period.description.isNotEmpty)
          _InfoRow(icon: Icons.notes_rounded, text: period.description),
        if (linkedTask != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DesktopAction(
                  onTap: () =>
                      controller.openTaskEditor(context, store, linkedTask),
                  backgroundColor: c.primaryContainer,
                  borderRadius: DesktopRadius.chip,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      '编辑日程',
                      style: DesktopType.strong(context)
                          .copyWith(color: c.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DesktopAction(
                onTap: () {
                  store.deleteTask(linkedTask);
                  controller.clearInspector();
                },
                borderColor: c.hairline,
                borderRadius: DesktopRadius.chip,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  '删除',
                  style: DesktopType.meta(context).copyWith(color: c.danger),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TodoInspectorContent extends StatelessWidget {
  const _TodoInspectorContent({
    required this.todo,
    required this.store,
    required this.controller,
  });

  final Todo todo;
  final DesktopStore store;
  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(todo.name,
            style: DesktopType.title(context).copyWith(fontSize: 16.5)),
        const SizedBox(height: 8),
        if (todo.endTime != null) ...[
          Row(
            children: [
              DeadlineCountdown(target: todo.endTime!, now: store.now),
              const SizedBox(width: 8),
              Text(
                fmtDeadline(todo.endTime!, store.now),
                style: DesktopType.meta(context, numeric: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _InfoRow(icon: Icons.menu_book_outlined, text: todo.course),
        const SizedBox(height: 16),
        DesktopAction(
          onTap: () => openHomework(todo),
          backgroundColor: c.primary,
          hoverColor: c.primary.withValues(alpha: 0.9),
          borderRadius: DesktopRadius.chip,
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(
            child: Text(
              '在学在浙大打开 ↗',
              style: DesktopType.strong(context).copyWith(color: c.onPrimary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DesktopAction(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: todo.name));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制作业标题'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderColor: c.hairline,
                borderRadius: DesktopRadius.chip,
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Center(
                  child: Text('复制标题', style: DesktopType.meta(context)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DesktopAction(
                onTap: () =>
                    controller.inspect(CourseInspectorTarget(todo.course)),
                borderColor: c.hairline,
                borderRadius: DesktopRadius.chip,
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Center(
                  child: Text('查看课程', style: DesktopType.meta(context)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaskInspectorContent extends StatelessWidget {
  const _TaskInspectorContent({
    required this.task,
    required this.store,
    required this.controller,
  });

  final Task task;
  final DesktopStore store;
  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final completed = task.status == TaskStatus.completed;
    final progress = task.getProgress().clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          task.summary.isEmpty ? '(未命名任务)' : task.summary,
          style: DesktopType.title(context).copyWith(fontSize: 16.5),
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.event_outlined,
          text: task.type == TaskType.deadline
              ? '截止 · ${fmtDeadline(task.endTime, store.now)}'
              : '${fmtDeadline(task.startTime, store.now)} – ${fmtTime(task.endTime)}',
          numeric: true,
        ),
        if (task.location.isNotEmpty)
          _InfoRow(icon: Icons.location_on_outlined, text: task.location),
        if (task.description.isNotEmpty)
          _InfoRow(icon: Icons.notes_rounded, text: task.description),
        if (task.type == TaskType.deadline) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Text('完成进度', style: DesktopType.caption(context)),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: DesktopType.mono(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: c.hairline,
              color: c.primary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (task.type == TaskType.deadline) ...[
          DesktopAction(
            onTap: () => store.toggleTaskCompleted(task),
            backgroundColor: c.primaryContainer,
            borderRadius: DesktopRadius.chip,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                completed ? '标记为未完成' : '标记为已完成',
                style: DesktopType.strong(context)
                    .copyWith(color: c.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: DesktopAction(
                onTap: () => controller.openTaskEditor(context, store, task),
                borderColor: c.hairline,
                borderRadius: DesktopRadius.chip,
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Center(
                  child: Text('编辑', style: DesktopType.meta(context)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DesktopAction(
                onTap: () {
                  store.deleteTask(task);
                  controller.clearInspector();
                },
                borderColor: c.hairline,
                borderRadius: DesktopRadius.chip,
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Center(
                  child: Text(
                    '删除',
                    style: DesktopType.meta(context).copyWith(color: c.danger),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExamInspectorContent extends StatelessWidget {
  const _ExamInspectorContent({
    required this.entry,
    required this.store,
    required this.controller,
  });

  final ExamEntry entry;
  final DesktopStore store;
  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final exam = entry.exam;
    final upcoming = entry.end.isAfter(store.now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ConcentricTag(
              label: exam.type == ExamType.midterm ? '期中考试' : '期末考试',
              foreground: c.warning,
              background: c.warningFill,
              radius: DesktopRadius.tag,
            ),
            if (upcoming) ...[
              const SizedBox(width: 8),
              ConcentricTag(
                label: '距开考 ${examCountdown(entry.start, store.now)}',
                foreground: c.primary,
                background: c.selectedFill,
                radius: DesktopRadius.tag,
                numeric: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(exam.name,
            style: DesktopType.title(context).copyWith(fontSize: 16.5)),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.schedule_rounded,
          text: '${fmtDate(entry.start)} · ${fmtRange(entry.start, entry.end)}',
          numeric: true,
        ),
        if ((exam.location ?? '').isNotEmpty)
          _InfoRow(icon: Icons.location_on_outlined, text: exam.location!),
        if ((exam.seat ?? '').isNotEmpty)
          _InfoRow(
            icon: Icons.event_seat_outlined,
            text: '座位号 ${exam.seat}',
            numeric: true,
          ),
        _InfoRow(
            icon: Icons.calendar_today_outlined, text: entry.semester.name),
        const SizedBox(height: 16),
        DesktopAction(
          onTap: () => controller.inspect(CourseInspectorTarget(exam.name)),
          borderColor: c.hairline,
          borderRadius: DesktopRadius.chip,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text('查看完整课程详情', style: DesktopType.meta(context)),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.numeric = false,
  });

  final IconData icon;
  final String text;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: c.text3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: DesktopType.body(context, numeric: numeric),
            ),
          ),
        ],
      ),
    );
  }
}
