import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:celechron/desktop/screens/exams_screen.dart';
import 'package:celechron/desktop/screens/grades_screen.dart';
import 'package:celechron/desktop/screens/overview_screen.dart';
import 'package:celechron/desktop/screens/settings_screen.dart';
import 'package:celechron/desktop/screens/tasks_screen.dart';
import 'package:celechron/desktop/screens/timetable_screen.dart';
import 'package:celechron/desktop/side_panels.dart';
import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon,
      {this.semesterPicker = false});
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// 顶栏是否显示学期选择
  final bool semesterPicker;
}

const _dests = [
  _Dest('总览', Icons.dashboard_outlined, Icons.dashboard),
  _Dest('课表', Icons.calendar_view_week_outlined, Icons.calendar_view_week,
      semesterPicker: true),
  _Dest('成绩', Icons.school_outlined, Icons.school, semesterPicker: true),
  _Dest('考试', Icons.event_note_outlined, Icons.event_note,
      semesterPicker: true),
  _Dest('任务', Icons.task_alt_outlined, Icons.task_alt),
  _Dest('设置', Icons.settings_outlined, Icons.settings),
];

/// 窗口骨架：[侧边导航 | 顶栏 + 页面 | 作业栏]。页面区域尺寸固定，页面不得整体滚动。
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.store});
  final DesktopStore store;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _index = 0;

  /// 各页作业栏是否展开；课表页默认收起，把宽度让给七天的列
  final Map<int, bool> _homeworkOpenByPage = {1: false};
  bool get _homeworkOpen => _homeworkOpenByPage[_index] ?? true;

  DesktopStore get store => widget.store;

  late final List<Widget> _screens = [
    OverviewScreen(store: store),
    TimetableScreen(store: store),
    GradesScreen(store: store),
    ExamsScreen(store: store),
    TasksScreen(store: store),
    SettingsScreen(store: store),
  ];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// Ctrl+1~6 切页，F5 / Ctrl+R 刷新
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    final kb = HardwareKeyboard.instance;
    if (e.logicalKey == LogicalKeyboardKey.f5 ||
        (kb.isControlPressed && e.logicalKey == LogicalKeyboardKey.keyR)) {
      store.refresh();
      return true;
    }
    if (kb.isControlPressed && !kb.isAltPressed && !kb.isShiftPressed) {
      const digits = [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
      ];
      final i = digits.indexOf(e.logicalKey);
      if (i >= 0) {
        setState(() => _index = i);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    return Scaffold(
      backgroundColor: colors.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(index: _index, onSelect: (i) => setState(() => _index = i)),
          VerticalDivider(width: 1, color: colors.border),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => _TopBar(
                    store: store,
                    title: _dests[_index].label,
                    semesterPicker: _dests[_index].semesterPicker,
                    homeworkOpen: _homeworkOpen,
                    onToggleHomework: () => setState(
                        () => _homeworkOpenByPage[_index] = !_homeworkOpen),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(DS.s4, 0, DS.s4, DS.s4),
                    child: IndexedStack(
                        index: _index,
                        sizing: StackFit.expand,
                        children: _screens),
                  ),
                ),
              ],
            ),
          ),
          if (_homeworkOpen) ...[
            VerticalDivider(width: 1, color: colors.border),
            SizedBox(
                width: DS.homeworkPanelWidth,
                // 总览页正中已放作业，侧栏改放不常看的即将考试
                child: _index == 0
                    ? ExamPanel(store: store)
                    : HomeworkPanel(store: store)),
          ],
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: DS.railWidth,
      color: colors.rail,
      padding: const EdgeInsets.symmetric(vertical: DS.s3, horizontal: DS.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _dests.length; i++) ...[
            if (i == _dests.length - 1) const Spacer(),
            Tooltip(
              message: '${_dests[i].label}  Ctrl+${i + 1}',
              preferBelow: false,
              child: DRow(
                height: 56,
                selected: i == index,
                onTap: () => onSelect(i),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(i == index ? _dests[i].selectedIcon : _dests[i].icon,
                          size: 22, color: i == index ? primary : colors.muted),
                      const SizedBox(height: 3),
                      Text(_dests[i].label,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: i == index ? primary : colors.muted,
                            fontWeight: i == index
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: DS.s1),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.store,
    required this.title,
    required this.semesterPicker,
    required this.homeworkOpen,
    required this.onToggleHomework,
  });

  final DesktopStore store;
  final String title;
  final bool semesterPicker;
  final bool homeworkOpen;
  final VoidCallback onToggleHomework;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final week = store.teachingWeek;
    final sems = store.semesters;
    return SizedBox(
      height: DS.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DS.s4),
        child: Row(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: DS.fsTitle,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(width: DS.s3),
            Text(
              '${fmtDate(store.now)}${week != null ? ' · 第 $week 周' : ''}',
              style: DText.muted(context),
            ),
            if (semesterPicker && sems.isNotEmpty) ...[
              const SizedBox(width: DS.s4),
              _SemesterPicker(store: store),
            ],
            const Spacer(),
            _SyncStatus(store: store),
            const SizedBox(width: DS.s2),
            IconButton(
              tooltip: '刷新（F5）',
              onPressed:
                  store.refreshing || !store.isLoggedIn ? null : store.refresh,
              icon: store.refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 20),
            ),
            IconButton(
              tooltip: homeworkOpen ? '收起侧栏' : '展开侧栏',
              onPressed: onToggleHomework,
              icon: Icon(
                  homeworkOpen
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                  size: 20,
                  color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 学期选择：分段按钮，最多显示全部有数据的学期
class _SemesterPicker extends StatelessWidget {
  const _SemesterPicker({required this.store});
  final DesktopStore store;

  /// "2025-2026秋冬" → "25-26 秋冬"
  static String shortName(String name) => name.length >= 11
      ? '${name.substring(2, 5)}${name.substring(7, 9)} ${name.substring(9)}'
      : name;

  @override
  Widget build(BuildContext context) {
    final sems = store.semesters;
    return PopupMenuButton<int>(
      tooltip: '切换学期',
      initialValue: store.selectedSemesterIndex,
      onSelected: store.selectSemester,
      itemBuilder: (_) => [
        for (var i = 0; i < sems.length; i++)
          PopupMenuItem(
              value: i,
              height: 34,
              child: Text(shortName(sems[i].name),
                  style: const TextStyle(fontSize: DS.fsBody))),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: DS.s3),
        decoration: BoxDecoration(
          color: DSColors.of(context).subtle,
          borderRadius: BorderRadius.circular(DS.radiusSm),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(shortName(store.selectedSemester?.name ?? ''),
              style: DText.strong(context)),
          const SizedBox(width: DS.s1),
          const Icon(Icons.expand_more, size: 18),
        ]),
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.store});
  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    if (!store.isLoggedIn) return Text('未登录', style: DText.muted(context));
    if (store.refreshing) return Text('正在同步…', style: DText.muted(context));
    final at = store.lastRefreshAt;
    final errors = store.lastErrors;
    final label = at == null ? '尚未同步' : '同步于 ${fmtAgo(at, store.now)}';
    if (errors.isEmpty) return Text(label, style: DText.muted(context));
    return TextButton.icon(
      onPressed: () => _showErrors(context, errors),
      style: TextButton.styleFrom(foregroundColor: DS.warning),
      icon: const Icon(Icons.error_outline, size: 16),
      label: Text('$label · ${errors.length} 项异常，点击查看',
          style: const TextStyle(fontSize: DS.fsSmall)),
    );
  }

  /// 列出每个模块的失败原因（去掉面向诊断日志的详细段落）
  static void _showErrors(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步异常', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(
              errors
                  .map((e) =>
                      e.split('<<<CELECHRON_ERROR_DETAIL>>>').first.trim())
                  .join('\n\n'),
              style: const TextStyle(fontSize: DS.fsBody, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭')),
        ],
      ),
    );
  }
}
