import 'package:flutter/material.dart';
import '../../model/task.dart';
import '../../page/task/task_edit_page.dart';
import '../format.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/context_menu.dart';
import '../widgets/course_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_row.dart';
import '../widgets/page_header.dart';
import '../widgets/scroll_area.dart';
import '../widgets/section_label.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.store});
  final DesktopStore store;
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool completedExpanded = false;

  Future<void> _edit(Task task) async {
    final result = await showDialog<Task?>(
        context: context,
        builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Paper.popoverRadius)),
            child:
                SizedBox(width: 560, height: 640, child: TaskEditPage(task))));
    if (result != null) widget.store.saveTask(task, result);
  }

  void _newTask() {
    final now = widget.store.now;
    final task = Task(endTime: now, startTime: now, repeatEndsTime: now)
      ..reset();
    // reset also initializes the UID and editor defaults. Keep the page clock.
    task.endTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    task.startTime = task.endTime;
    task.repeatEndsTime = DateTime(now.year, now.month, now.day);
    _edit(task);
  }

  Future<void> _menu(Task task, Offset position) async {
    final action = await paperContextMenu(context, position, {
      'edit': '编辑',
      if (task.type == TaskType.deadline)
        'complete': task.status == TaskStatus.completed ? '标记未完成' : '标记完成',
      'delete': '删除'
    });
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _edit(task);
      case 'complete':
        widget.store.toggleTaskCompleted(task);
      case 'delete':
        widget.store.deleteTask(task);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final pending = store.pendingDeadlines;
        final finished = store.finishedDeadlines;
        final fixed = store.fixedTasks;
        return PaperPage(
            store: store,
            header: PageHeader(
                title: '任务',
                subtitle: '${pending.length} 项进行中',
                actions: [
                  PaperAction(
                      onTap: store.isLoggedIn ? _newTask : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text('+ 新建', style: PaperType.strong(context)))
                ]),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                  child: Column(children: [
                SectionLabel('截止任务 · ${pending.length}'),
                Expanded(
                    child: ScrollArea(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                      if (pending.isEmpty) const EmptyState('暂无待办任务'),
                      for (final task in pending) _row(context, task),
                      const SizedBox(height: 16),
                      PaperAction(
                          onTap: () => setState(
                              () => completedExpanded = !completedExpanded),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Icon(
                                completedExpanded
                                    ? Icons.expand_more
                                    : Icons.chevron_right,
                                size: 16,
                                color: PaperColors.of(context).text2),
                            const SizedBox(width: 4),
                            Text('已完成 ${finished.length}',
                                style: PaperType.label(context))
                          ])),
                      if (completedExpanded) ...[
                        if (finished.isEmpty) const EmptyState('暂无已完成任务'),
                        for (final task in finished) _row(context, task)
                      ]
                    ])))
              ])),
              const SizedBox(width: 32),
              VerticalDivider(
                  width: 1, color: PaperColors.of(context).hairline),
              const SizedBox(width: 32),
              Expanded(
                  child: Column(children: [
                SectionLabel('固定日程 · ${fixed.length}'),
                Expanded(
                    child: fixed.isEmpty
                        ? const EmptyState('暂无固定日程')
                        : ScrollArea(
                            child: Column(children: [
                            for (final task in fixed) _row(context, task)
                          ])))
              ]))
            ]));
      });

  Widget _row(BuildContext context, Task task) {
    final c = PaperColors.of(context);
    final course = CourseColors(context, task.summary);
    final deadline = task.type == TaskType.deadline;
    final completed = task.status == TaskStatus.completed;
    final overdue = !completed && task.endTime.isBefore(widget.store.now);
    final progress = deadline ? task.getProgress() : 0.0;
    final repeat = switch (task.repeatType) {
      TaskRepeatType.norepeat => '不重复',
      TaskRepeatType.days => '每 ${task.repeatPeriod} 天',
      TaskRepeatType.month => '每月 ${task.startTime.day} 日',
      TaskRepeatType.year =>
        '${task.startTime.month}月${task.startTime.day}日 每年',
    };
    final time = deadline
        ? '${fmtDeadline(task.endTime, widget.store.now)}${task.status == TaskStatus.failed ? ' · 已过期' : ''}'
        : '${fmtDeadline(task.startTime, widget.store.now)}–${calendarDaysBetween(task.startTime, task.endTime) == 0 ? fmtTime(task.endTime) : fmtDeadline(task.endTime, widget.store.now)}';
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => _menu(task, details.globalPosition),
        child: Container(
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.hairline))),
            child: Row(children: [
              if (deadline) ...[
                Semantics(
                    label: completed ? '标记未完成' : '标记完成',
                    checked: completed,
                    child: PaperIconButton(
                        icon: completed
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank,
                        tooltip: completed ? '标记未完成' : '标记完成',
                        onPressed: () =>
                            widget.store.toggleTaskCompleted(task))),
                const SizedBox(width: 8)
              ],
              Expanded(
                  child: PaperAction(
                      onTap: () => _edit(task),
                      tooltip: [
                        task.summary,
                        time,
                        task.location,
                        task.description
                      ].where((s) => s.isNotEmpty).join('\n'),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(task.summary.isEmpty ? '(未命名)' : task.summary,
                                style: PaperType.strong(context).copyWith(
                                    color: completed ? c.text2 : c.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(time,
                                style: PaperType.meta(context).copyWith(
                                    color: deadline && overdue
                                        ? c.danger
                                        : c.text2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (deadline) ...[
                              const SizedBox(height: 8),
                              Semantics(
                                  label: '任务进度',
                                  value:
                                      '${((progress.isFinite ? progress : 0) * 100).round()}%',
                                  child: LinearProgressIndicator(
                                      value: progress.isFinite ? progress : 0,
                                      minHeight: 4,
                                      borderRadius: BorderRadius.circular(2),
                                      color: completed ? c.text2 : course.bar,
                                      backgroundColor: c.hairline))
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                  [
                                    repeat,
                                    if (task.repeatType !=
                                        TaskRepeatType.norepeat)
                                      '至 ${fmtDate(task.repeatEndsTime)}',
                                    if (task.location.isNotEmpty) task.location
                                  ].join(' · '),
                                  style: PaperType.meta(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                            ]
                          ]))),
              const SizedBox(width: 4),
              Builder(
                  builder: (context) => PaperIconButton(
                      icon: Icons.more_horiz,
                      tooltip: '任务操作',
                      onPressed: () {
                        final box = context.findRenderObject()! as RenderBox;
                        _menu(task,
                            box.localToGlobal(Offset(0, box.size.height)));
                      }))
            ])));
  }
}
