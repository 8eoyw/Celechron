import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:celechron/model/option.dart';
import '../format.dart';
import '../state/desktop_controller.dart';
import '../store.dart';
import '../theme/tokens.dart';
import 'common_ui.dart';

class _PaletteItem {
  const _PaletteItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.onSelect,
    this.keywords = '',
  });

  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final VoidCallback onSelect;
  final String keywords;
}

Future<void> showCommandPalette(
  BuildContext context, {
  required DesktopStore store,
  required DesktopController controller,
}) =>
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) => CommandPalette(
        store: store,
        controller: controller,
      ),
    );

/// Frosted M3 + Antigravity Command Palette (`Ctrl+K`) searching courses,
/// homework, exams, personal tasks, grades, and workspace actions.
class CommandPalette extends StatefulWidget {
  const CommandPalette({
    super.key,
    required this.store,
    required this.controller,
  });

  final DesktopStore store;
  final DesktopController controller;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() => _selected = 0));
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<_PaletteItem> _buildAllItems(BuildContext context) {
    final store = widget.store;
    final ctrl = widget.controller;
    final items = <_PaletteItem>[];

    // Quick navigation & actions
    items.addAll([
      _PaletteItem(
        title: '回到今天',
        subtitle: '跳转到今日时间轴',
        category: '操作',
        icon: Icons.today_rounded,
        keywords: 'today schedule 日程 今天',
        onSelect: () {
          ctrl.goToday(store.now);
          ctrl.setScheduleMode(ScheduleMode.day);
        },
      ),
      _PaletteItem(
        title: '新建个人任务 / 固定日程',
        subtitle: '打开任务编辑器 (N)',
        category: '操作',
        icon: Icons.add_task_rounded,
        keywords: 'new task create 新建 任务 日程',
        onSelect: () => ctrl.createTask(context, store),
      ),
      _PaletteItem(
        title: '切换到日程 · 周视图',
        subtitle: '7 天比例课表',
        category: '导航',
        icon: Icons.calendar_view_week_rounded,
        keywords: 'week calendar 周视图 课表',
        onSelect: () => ctrl.setScheduleMode(ScheduleMode.week),
      ),
      _PaletteItem(
        title: '切换到任务与作业',
        subtitle: '学在浙大作业 · 个人任务 · 自动规划',
        category: '导航',
        icon: Icons.checklist_rounded,
        keywords: 'tasks homework due 任务 作业',
        onSelect: () => ctrl.setDestination(DesktopDestination.tasks),
      ),
      _PaletteItem(
        title: '切换到学业 · 成绩与绩点',
        subtitle: 'GPA · 学期成绩单',
        category: '导航',
        icon: Icons.school_outlined,
        keywords: 'grades gpa academics 成绩 绩点',
        onSelect: () => ctrl.setAcademicsTab(AcademicsTab.grades),
      ),
      _PaletteItem(
        title: '切换到学业 · 课时统计',
        subtitle: '16 周课量分布与课程进度',
        category: '导航',
        icon: Icons.bar_chart_rounded,
        keywords: 'hours workload 课时 统计',
        onSelect: () => ctrl.setAcademicsTab(AcademicsTab.hours),
      ),
      _PaletteItem(
        title: '立即同步数据',
        subtitle: '刷新课表、作业、考试与成绩',
        category: '操作',
        icon: Icons.sync_rounded,
        keywords: 'sync refresh 同步 刷新',
        onSelect: () => store.refresh(),
      ),
      _PaletteItem(
        title: store.brightnessMode == BrightnessMode.dark
            ? '切换为浅色主题'
            : '切换为深色主题',
        subtitle: '即时切换外观模式',
        category: '外观',
        icon: Icons.contrast_rounded,
        keywords: 'theme dark light 主题 浅色 深色',
        onSelect: () => store.setBrightnessMode(
          store.brightnessMode == BrightnessMode.dark
              ? BrightnessMode.light
              : BrightnessMode.dark,
        ),
      ),
    ]);

    // Homework items
    for (final todo in store.todos) {
      items.add(_PaletteItem(
        title: todo.name,
        subtitle:
            '${todo.course}${todo.endTime == null ? '' : ' · ${fmtDeadline(todo.endTime!, store.now)}'}',
        category: '作业',
        icon: Icons.assignment_outlined,
        keywords: '${todo.name} ${todo.course} 作业 homework',
        onSelect: () {
          ctrl.setDestination(DesktopDestination.tasks);
          ctrl.inspect(TodoInspectorTarget(todo));
        },
      ));
    }

    // Courses in current/selected semester
    final seenCourses = <String>{};
    for (final s in store.semesters) {
      for (final course in s.courses.values) {
        if (!seenCourses.add(course.name)) continue;
        items.add(_PaletteItem(
          title: course.name,
          subtitle: [
            if ((course.teacher ?? '').isNotEmpty) course.teacher!,
            if (course.credit > 0) '${course.credit.toStringAsFixed(1)} 学分',
            s.name,
          ].join(' · '),
          category: '课程',
          icon: Icons.menu_book_outlined,
          keywords: '${course.name} ${course.teacher ?? ''} 课程',
          onSelect: () => ctrl.inspect(CourseInspectorTarget(course.name)),
        ));
      }
    }

    // Exams
    for (final entry in store.upcomingExams) {
      items.add(_PaletteItem(
        title: '${entry.exam.name}（考试）',
        subtitle:
            '${fmtDate(entry.start)} ${fmtRange(entry.start, entry.end)} · ${entry.exam.location ?? ''}',
        category: '考试',
        icon: Icons.event_note_outlined,
        keywords: '${entry.exam.name} 考试 exam ${entry.exam.location ?? ''}',
        onSelect: () {
          ctrl.setAcademicsTab(AcademicsTab.exams);
          ctrl.inspect(ExamInspectorTarget(entry));
        },
      ));
    }

    // Local personal tasks
    for (final task in [...store.pendingDeadlines, ...store.fixedTasks]) {
      items.add(_PaletteItem(
        title: task.summary.isEmpty ? '(未命名任务)' : task.summary,
        subtitle: fmtDeadline(task.endTime, store.now),
        category: '任务',
        icon: Icons.task_alt_rounded,
        keywords: '${task.summary} ${task.location} 任务',
        onSelect: () {
          ctrl.setDestination(DesktopDestination.tasks);
          ctrl.inspect(TaskInspectorTarget(task));
        },
      ));
    }

    return items;
  }

  List<_PaletteItem> _filter(List<_PaletteItem> all, String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return all.take(10).toList();
    final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    return all
        .where((item) {
          final hay =
              '${item.title} ${item.subtitle} ${item.category} ${item.keywords}'
                  .toLowerCase();
          return terms.every(hay.contains);
        })
        .take(14)
        .toList();
  }

  void _activate(List<_PaletteItem> results) {
    if (results.isEmpty) return;
    final chosen = results[_selected.clamp(0, results.length - 1)];
    Navigator.of(context).pop();
    chosen.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _filter(_buildAllItems(context), _query.text);
    final clampedIdx =
        results.isEmpty ? 0 : _selected.clamp(0, results.length - 1);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      alignment: const Alignment(0, -0.35),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
              results.isNotEmpty) {
            setState(() => _selected = (_selected + 1) % results.length);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
              results.isNotEmpty) {
            setState(() =>
                _selected = (_selected - 1 + results.length) % results.length);
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _activate(results);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesktopRadius.dialog),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 560,
              constraints: const BoxConstraints(maxHeight: 460),
              decoration: BoxDecoration(
                color: c.sheet.withValues(alpha: isDark ? 0.92 : 0.96),
                borderRadius: BorderRadius.circular(DesktopRadius.dialog),
                border: Border.all(color: c.hairline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search input bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 19, color: c.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _query,
                            focusNode: _focus,
                            autofocus: true,
                            onSubmitted: (_) => _activate(results),
                            style: DesktopType.body(context)
                                .copyWith(fontSize: 14.5),
                            decoration: InputDecoration(
                              hintText: '搜索课程、作业、考试、任务或快捷命令…',
                              hintStyle: DesktopType.meta(context)
                                  .copyWith(fontSize: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                        const ConcentricTag(
                          label: 'Esc',
                          radius: DesktopRadius.tag,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: c.hairline),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateView(
                        title: '没有找到匹配的结果',
                        compact: true,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          final active = index == clampedIdx;
                          return DesktopAction(
                            onTap: () {
                              Navigator.of(context).pop();
                              item.onSelect();
                            },
                            selected: active,
                            borderRadius: DesktopRadius.block,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 17,
                                  color: active ? c.primary : c.text2,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: DesktopType.strong(context)
                                            .copyWith(fontSize: 13),
                                      ),
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: DesktopType.caption(context,
                                            numeric: true),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConcentricTag(
                                  label: item.category,
                                  radius: DesktopRadius.tag,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
