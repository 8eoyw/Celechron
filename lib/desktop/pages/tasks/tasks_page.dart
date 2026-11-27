import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/model/todo.dart';
import '../../format.dart';
import '../../state/desktop_controller.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common_ui.dart';
import '../../widgets/course_palette.dart';

enum _TasksFilter { all, homework, personal, fixed, completed }

/// Unified Work & Tasks workspace combining Learning-in-ZJU homework,
/// personal deadline tasks, fixed recurring events, and Auto-Replan.
class TasksPage extends StatefulWidget {
  const TasksPage({
    super.key,
    required this.store,
    required this.controller,
  });

  final DesktopStore store;
  final DesktopController controller;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  _TasksFilter _filter = _TasksFilter.all;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final store = widget.store;
    final ctrl = widget.controller;

    final allTodos = store.todos;
    final courseCounts = <String, int>{};
    for (final t in allTodos) {
      courseCounts[t.course] = (courseCounts[t.course] ?? 0) + 1;
    }
    final activeCourse = ctrl.taskCourseFilter != null &&
            courseCounts.containsKey(ctrl.taskCourseFilter)
        ? ctrl.taskCourseFilter
        : null;

    final filteredTodos = activeCourse == null
        ? allTodos
        : allTodos.where((t) => t.course == activeCourse).toList();
    final pendingTasks = store.pendingDeadlines;
    final fixedTasks = store.fixedTasks;
    final finishedTasks = store.finishedDeadlines;

    final showHomework =
        _filter == _TasksFilter.all || _filter == _TasksFilter.homework;
    final showPersonal =
        _filter == _TasksFilter.all || _filter == _TasksFilter.personal;
    final showFixed =
        _filter == _TasksFilter.all || _filter == _TasksFilter.fixed;
    final showCompleted = _filter == _TasksFilter.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top contextual header
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              Text('任务与作业',
                  style: DesktopType.title(context).copyWith(fontSize: 17)),
              const SizedBox(width: 10),
              Text(
                '${allTodos.length} 项作业 · ${pendingTasks.length} 项待办',
                style: DesktopType.meta(context, numeric: true),
              ),
              const Spacer(),
              DesktopAction(
                onTap: store.isLoggedIn
                    ? () async {
                        await store.replan();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已按截止时间重新规划学习块'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                tooltip: '将截止任务自动排入空闲时段',
                borderColor: c.hairline,
                borderRadius: DesktopRadius.chip,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_outlined,
                        size: 15, color: c.primary),
                    const SizedBox(width: 5),
                    Text('自动规划',
                        style:
                            DesktopType.meta(context).copyWith(color: c.text1)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DesktopAction(
                onTap: store.isLoggedIn
                    ? () => ctrl.createTask(context, store)
                    : null,
                backgroundColor: c.primary,
                hoverColor: c.primary.withValues(alpha: 0.9),
                borderRadius: DesktopRadius.chip,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: c.onPrimary),
                    const SizedBox(width: 4),
                    Text(
                      '新建任务',
                      style: DesktopType.strong(context)
                          .copyWith(fontSize: 12.5, color: c.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Filter chip bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _FilterChip(
                      label: '全部',
                      count: allTodos.length +
                          pendingTasks.length +
                          fixedTasks.length,
                      selected: _filter == _TasksFilter.all,
                      onTap: () => setState(() => _filter = _TasksFilter.all),
                    ),
                    _FilterChip(
                      label: '学在浙大',
                      count: allTodos.length,
                      selected: _filter == _TasksFilter.homework,
                      onTap: () =>
                          setState(() => _filter = _TasksFilter.homework),
                    ),
                    _FilterChip(
                      label: '个人截止',
                      count: pendingTasks.length,
                      selected: _filter == _TasksFilter.personal,
                      onTap: () =>
                          setState(() => _filter = _TasksFilter.personal),
                    ),
                    _FilterChip(
                      label: '固定日程',
                      count: fixedTasks.length,
                      selected: _filter == _TasksFilter.fixed,
                      onTap: () => setState(() => _filter = _TasksFilter.fixed),
                    ),
                    _FilterChip(
                      label: '已完成',
                      count: finishedTasks.length,
                      selected: _filter == _TasksFilter.completed,
                      onTap: () =>
                          setState(() => _filter = _TasksFilter.completed),
                    ),
                  ],
                ),
              ),
              if (showHomework && courseCounts.isNotEmpty) ...[
                const SizedBox(width: 10),
                _CourseFilterDropdown(
                  courseCounts: courseCounts,
                  selected: activeCourse,
                  onSelected: ctrl.setTaskCourseFilter,
                ),
              ],
            ],
          ),
        ),
        // Content list
        Expanded(
          child: store.initialLoading
              ? const LoadingSkeleton()
              : _buildBody(
                  context,
                  filteredTodos: filteredTodos,
                  pendingTasks: pendingTasks,
                  fixedTasks: fixedTasks,
                  finishedTasks: finishedTasks,
                  showHomework: showHomework,
                  showPersonal: showPersonal,
                  showFixed: showFixed,
                  showCompleted: showCompleted,
                ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<Todo> filteredTodos,
    required List<Task> pendingTasks,
    required List<Task> fixedTasks,
    required List<Task> finishedTasks,
    required bool showHomework,
    required bool showPersonal,
    required bool showFixed,
    required bool showCompleted,
  }) {
    final c = DesktopColors.of(context);
    final store = widget.store;
    final ctrl = widget.controller;

    if (showCompleted) {
      if (finishedTasks.isEmpty) {
        return const EmptyStateView(
          title: '暂无已完成任务',
          subtitle: '勾选完成的个人截止任务会归档在这里',
          icon: Icons.task_alt_rounded,
        );
      }
      return DesktopScrollArea(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading('已完成 (${finishedTasks.length})'),
            for (final task in finishedTasks)
              _TaskListRow(
                task: task,
                now: store.now,
                onTap: () => ctrl.inspect(TaskInspectorTarget(task)),
                onEdit: () => ctrl.openTaskEditor(context, store, task),
                onToggle: () => store.toggleTaskCompleted(task),
                onDelete: () => store.deleteTask(task),
              ),
          ],
        ),
      );
    }

    final isEmpty = (!showHomework || filteredTodos.isEmpty) &&
        (!showPersonal || pendingTasks.isEmpty) &&
        (!showFixed || fixedTasks.isEmpty);

    if (isEmpty) {
      final title = _filter == _TasksFilter.homework
          ? '没有待交作业'
          : _filter == _TasksFilter.fixed
              ? '暂无固定日程'
              : '暂无待办任务';
      return EmptyStateView(
        title: title,
        subtitle: _filter == _TasksFilter.homework
            ? '学在浙大当前没有未完成的作业'
            : '点击右上角「新建任务」或按 N 快速添加',
        icon: Icons.checklist_rounded,
      );
    }

    // Group filtered todos by urgency
    final grouped = <TodoGroup, List<Todo>>{};
    for (final t in filteredTodos) {
      grouped.putIfAbsent(store.groupOf(t), () => []).add(t);
    }

    return DesktopScrollArea(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHomework && filteredTodos.isNotEmpty) ...[
            for (final group in TodoGroup.values)
              if (grouped[group]?.isNotEmpty == true) ...[
                SectionHeading(
                  '学在浙大 · ${todoGroupName[group]!}',
                  color: group == TodoGroup.overdue ? c.danger : null,
                  trailing: Text(
                    '${grouped[group]!.length} 项',
                    style: DesktopType.caption(context, numeric: true),
                  ),
                ),
                for (final todo in grouped[group]!)
                  HomeworkItemRow(
                    todo: todo,
                    now: store.now,
                    onTap: () => ctrl.inspect(TodoInspectorTarget(todo)),
                  ),
                const SizedBox(height: 14),
              ],
          ],
          if (showPersonal && pendingTasks.isNotEmpty) ...[
            SectionHeading(
              '个人截止任务',
              trailing: Text(
                '${pendingTasks.length} 项',
                style: DesktopType.caption(context, numeric: true),
              ),
            ),
            for (final task in pendingTasks)
              _TaskListRow(
                task: task,
                now: store.now,
                onTap: () => ctrl.inspect(TaskInspectorTarget(task)),
                onEdit: () => ctrl.openTaskEditor(context, store, task),
                onToggle: () => store.toggleTaskCompleted(task),
                onDelete: () => store.deleteTask(task),
              ),
            const SizedBox(height: 14),
          ],
          if (showFixed && fixedTasks.isNotEmpty) ...[
            SectionHeading(
              '固定日程',
              trailing: Text(
                '${fixedTasks.length} 项',
                style: DesktopType.caption(context, numeric: true),
              ),
            ),
            for (final task in fixedTasks)
              _TaskListRow(
                task: task,
                now: store.now,
                onTap: () => ctrl.inspect(TaskInspectorTarget(task)),
                onEdit: () => ctrl.openTaskEditor(context, store, task),
                onToggle: () => store.toggleTaskCompleted(task),
                onDelete: () => store.deleteTask(task),
              ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return DesktopAction(
      onTap: onTap,
      selected: selected,
      borderColor: selected ? null : c.hairline,
      borderRadius: DesktopRadius.chip,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: DesktopType.meta(context).copyWith(
              color: selected ? c.primary : c.text1,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: DesktopType.caption(context, numeric: true).copyWith(
              color: selected ? c.primary : c.text3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseFilterDropdown extends StatelessWidget {
  const _CourseFilterDropdown({
    required this.courseCounts,
    required this.selected,
    required this.onSelected,
  });

  final Map<String, int> courseCounts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return PopupMenuButton<String>(
      tooltip: '按课程筛选作业',
      color: c.sheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopRadius.popover),
        side: BorderSide(color: c.hairline),
      ),
      onSelected: (v) => onSelected(v == '__all__' ? null : v),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: '__all__',
          height: 36,
          child: Text('全部课程', style: DesktopType.body(context)),
        ),
        const PopupMenuDivider(height: 1),
        for (final entry in courseCounts.entries)
          PopupMenuItem<String>(
            value: entry.key,
            height: 36,
            child: Text(
              '${entry.key}（${entry.value}）',
              style: DesktopType.body(context),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected != null ? c.selectedFill : c.surfaceLow,
          borderRadius: BorderRadius.circular(DesktopRadius.chip),
          border: Border.all(
              color: selected != null ? c.selectedBorder : c.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded,
                size: 14, color: selected != null ? c.primary : c.text2),
            const SizedBox(width: 5),
            Text(
              selected ?? '全部课程',
              style: DesktopType.meta(context).copyWith(
                color: selected != null ? c.primary : c.text1,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: c.text2),
          ],
        ),
      ),
    );
  }
}

/// Clean Homework list row with text-scaler safety, course dot, countdown,
/// and right-click context menu (`在浏览器打开`, `复制标题`).
class HomeworkItemRow extends StatelessWidget {
  const HomeworkItemRow({
    super.key,
    required this.todo,
    required this.now,
    this.onTap,
  });

  final Todo todo;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final swatch = CoursePalette.of(context, todo.course);

    return DesktopAction(
      onTap: onTap ?? () => openHomework(todo),
      onDoubleTap: () => openHomework(todo),
      tooltip:
          '${todo.name}\n${todo.course} · ${todo.endTime == null ? '无截止时间' : fmtDeadline(todo.endTime!, now)}',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: swatch.bar,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
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
                        style: DesktopType.strong(context),
                      ),
                    ),
                    if (todo.endTime != null) ...[
                      const SizedBox(width: 8),
                      DeadlineCountdown(target: todo.endTime!, now: now),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        todo.course,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesktopType.meta(context),
                      ),
                    ),
                    Text(' · ', style: DesktopType.meta(context)),
                    Text(
                      todo.endTime == null
                          ? '无截止时间'
                          : fmtDeadline(todo.endTime!, now),
                      maxLines: 1,
                      style: DesktopType.meta(context, numeric: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          DesktopIconButton(
            icon: Icons.open_in_new_rounded,
            tooltip: '在学在浙大打开',
            size: 15,
            boxSize: 28,
            color: c.text3,
            onPressed: () => openHomework(todo),
          ),
        ],
      ),
    );
  }
}

class _TaskListRow extends StatelessWidget {
  const _TaskListRow({
    required this.task,
    required this.now,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final isDeadline = task.type == TaskType.deadline;
    final completed = task.status == TaskStatus.completed;
    final swatch = CoursePalette.of(context, task.summary);
    final progress = isDeadline ? task.getProgress().clamp(0.0, 1.0) : 0.0;

    final repeat = switch (task.repeatType) {
      TaskRepeatType.norepeat => '单次',
      TaskRepeatType.days => '每 ${task.repeatPeriod} 天',
      TaskRepeatType.month => '每月 ${task.startTime.day} 日',
      TaskRepeatType.year => '每年 ${task.startTime.month}/${task.startTime.day}',
    };

    return DesktopAction(
      onTap: onTap,
      onDoubleTap: onEdit,
      onSecondaryTapDown: (details) async {
        final action = await showDesktopContextMenu(
          context,
          details.globalPosition,
          {
            'edit': '编辑',
            if (isDeadline) 'toggle': completed ? '标记未完成' : '标记完成',
            'delete': '删除',
          },
        );
        if (action == 'edit') onEdit();
        if (action == 'toggle') onToggle();
        if (action == 'delete') onDelete();
      },
      borderRadius: DesktopRadius.block,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          if (isDeadline)
            DesktopIconButton(
              icon: completed
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              tooltip: completed ? '标记未完成' : '标记完成',
              size: 18,
              boxSize: 28,
              color: completed ? c.primary : c.text3,
              onPressed: onToggle,
            )
          else
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child:
                  Icon(Icons.event_repeat_rounded, size: 17, color: swatch.bar),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.summary.isEmpty ? '(未命名)' : task.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.strong(context).copyWith(
                    color: completed ? c.text3 : c.text1,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDeadline
                      ? fmtDeadline(task.endTime, now)
                      : [
                          '${fmtDeadline(task.startTime, now)} – ${fmtTime(task.endTime)}',
                          repeat,
                          if (task.location.isNotEmpty) task.location,
                        ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.meta(context, numeric: true),
                ),
                if (isDeadline && !completed) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3.5,
                      backgroundColor: c.hairline,
                      color: swatch.bar,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDeadline && !completed) ...[
            const SizedBox(width: 10),
            DeadlineCountdown(target: task.endTime, now: now),
          ],
          const SizedBox(width: 6),
          DesktopIconButton(
            icon: Icons.edit_outlined,
            tooltip: '编辑',
            size: 15,
            boxSize: 28,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
