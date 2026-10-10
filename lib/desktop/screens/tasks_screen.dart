import 'package:flutter/material.dart';

import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';

import 'package:celechron/model/task.dart';
import 'package:celechron/page/task/task_edit_page.dart';

/// 任务页：待办 DDL / 已完成 / 日程 三列，行高 40，支持编辑对话框与右键菜单。规格见 lib/desktop/DESIGN.md
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.store});

  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _column(context, '待办 DDL', store.pendingDeadlines,
                emptyHint: '暂无待办', isDdl: true, onNew: () => _newTask(context)),
            SizedBox(width: DS.s3),
            _column(context, '已完成', store.finishedDeadlines,
                emptyHint: '暂无已完成任务', isDdl: true),
            SizedBox(width: DS.s3),
            _column(context, '日程', store.fixedTasks, emptyHint: '暂无日程'),
          ],
        );
      },
    );
  }

  Widget _column(
    BuildContext context,
    String title,
    List<Task> tasks, {
    required String emptyHint,
    bool isDdl = false,
    VoidCallback? onNew,
  }) {
    return Expanded(
      child: DCard(
        title: title,
        trailing: onNew == null ? null : _newButton(context, onNew),
        child: tasks.isEmpty
            ? EmptyHint(emptyHint)
            : DScrollArea(
                child: Column(
                  children: [
                    for (final t in tasks)
                      DRow(
                        height: 40,
                        onTap: () => _openEditDialog(context, t),
                        onSecondaryTapUp: (details) =>
                            _showTaskMenu(context, details, t),
                        child: _TaskRow(
                          task: t,
                          now: store.now,
                          showProgress: isDdl,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _newButton(BuildContext context, VoidCallback onNew) {
    return TextButton(
      onPressed: onNew,
      child: Text('+ 新建', style: DText.body(context)),
    );
  }

  Future<void> _newTask(BuildContext context) async {
    final now = DateTime.now();
    final newTask = Task(endTime: now, startTime: now, repeatEndsTime: now);
    newTask.reset();
    await _openEditDialog(context, newTask);
  }

  Future<void> _openEditDialog(BuildContext context, Task task) async {
    final res = await showDialog<Task?>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 560,
          height: 640,
          child: TaskEditPage(task),
        ),
      ),
    );
    if (res != null) {
      // 编辑页返回的 Task 可能是 deleted（删除），saveTask 内部会处理
      store.saveTask(task, res);
    }
  }

  void _showTaskMenu(
    BuildContext context,
    TapUpDetails details,
    Task task,
  ) {
    final items = <(String, IconData, VoidCallback, bool)>[
      ('编辑', Icons.edit_outlined, () => _openEditDialog(context, task), false),
      if (task.type == TaskType.deadline)
        (
          task.status == TaskStatus.completed ? '标记未完成' : '标记完成',
          task.status == TaskStatus.completed ? Icons.undo : Icons.check_circle,
          () => store.toggleTaskCompleted(task),
          false
        ),
      ('删除', Icons.delete_outline, () => store.deleteTask(task), true),
    ];
    showContextMenu(context, details.globalPosition, items);
  }
}

/// 任务行：色点 + 标题 + 截止时间/开始时间；DDL 行附细进度条
class _TaskRow extends StatelessWidget {
  const _TaskRow(
      {required this.task, required this.now, this.showProgress = false});

  final Task task;
  final DateTime now;
  final bool showProgress;

  Color _taskColor(Task t) =>
      t.type == TaskType.deadline ? DS.colorFor(t.summary) : DS.success;

  @override
  Widget build(BuildContext context) {
    final color = _taskColor(task);
    final timeText = task.type == TaskType.deadline
        ? fmtRelative(task.endTime, now)
        : fmtTime(task.startTime) + ' - ' + fmtTime(task.endTime);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: DS.s2),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
            Expanded(
                child: Text(task.summary.isEmpty ? '(未命名)' : task.summary,
                    style: DText.strong(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            SizedBox(width: DS.s2),
            SizedBox(
                width: 96,
                child: Text(timeText,
                    style: DText.muted(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        if (showProgress)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: LinearProgressIndicator(
                value: task.getProgress(),
                minHeight: 3,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15)),
          ),
      ],
    );
  }
}
