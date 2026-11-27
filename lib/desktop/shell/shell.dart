import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:celechron/model/option.dart';
import '../format.dart';
import '../pages/academics/academics_page.dart';
import '../pages/schedule/schedule_page.dart';
import '../pages/tasks/tasks_page.dart';
import '../state/desktop_controller.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/command_palette.dart';
import '../widgets/common_ui.dart';
import '../widgets/login_gate.dart';
import '../widgets/settings_dialog.dart';
import 'companion_panel.dart';

/// Greenfield v4 Google-Native Desktop Shell:
/// - Unified 48px Top Bar (Brand + Semester/Week, centered Ctrl+K Search Pill,
///   Sync status, Companion toggle, Theme toggle, Account/Settings)
/// - Compact M3 Navigation Rail (`+` FAB + 3 destinations: Schedule, Tasks, Academics)
/// - Two tonal elevated Sheets (Main Canvas + adaptive Right Companion Panel)
class DesktopShell extends StatefulWidget {
  const DesktopShell({
    super.key,
    required this.store,
    this.initialDestination = DesktopDestination.schedule,
    this.initialScheduleMode = ScheduleMode.day,
    this.initialAcademicsTab = AcademicsTab.exams,
  });

  final DesktopStore store;
  final DesktopDestination initialDestination;
  final ScheduleMode initialScheduleMode;
  final AcademicsTab initialAcademicsTab;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  late final DesktopController _controller;
  bool _companionCurrentlyVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = DesktopController(
      initialDestination: widget.initialDestination,
      initialScheduleMode: widget.initialScheduleMode,
      initialAcademicsTab: widget.initialAcademicsTab,
      initialDate: widget.store.now,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) return false;
    final widget = focus.context!.widget;
    if (widget is EditableText) return true;
    return focus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _handleGlobalKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (key == LogicalKeyboardKey.escape) {
      if (_controller.inspector != null) {
        _controller.clearInspector();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_isTextInputFocused()) return KeyEventResult.ignored;
    if (!widget.store.isLoggedIn) return KeyEventResult.ignored;

    if (ctrl && key == LogicalKeyboardKey.keyK) {
      showCommandPalette(context, store: widget.store, controller: _controller);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.backslash) {
      _controller.toggleCompanion(
          currentlyVisible: _companionCurrentlyVisible);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.digit1) {
      _controller.setDestination(DesktopDestination.schedule);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.digit2) {
      _controller.setDestination(DesktopDestination.tasks);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.digit3) {
      _controller.setDestination(DesktopDestination.academics);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyR) {
      widget.store.refresh();
      return KeyEventResult.handled;
    }
    if (!ctrl && key == LogicalKeyboardKey.keyT) {
      _controller.goToday(widget.store.now);
      _controller.setScheduleMode(ScheduleMode.day);
      return KeyEventResult.handled;
    }
    if (!ctrl && key == LogicalKeyboardKey.keyN) {
      _controller.createTask(context, widget.store);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: _handleGlobalKey,
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.store, _controller]),
        builder: (context, _) {
          final store = widget.store;
          return Scaffold(
            backgroundColor: c.chrome,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final wideWindow = width >= 1440;
                final railWithLabels = width >= 1200;
                final canDockCompanion = width >= 1120;
                final showDockedCompanion = store.isLoggedIn &&
                    canDockCompanion &&
                    _controller.companionOpen;
                final showOverlayCompanion = store.isLoggedIn &&
                    !canDockCompanion &&
                    _controller.companionUserToggled &&
                    _controller.companionOpen ||
                    (store.isLoggedIn &&
                        !canDockCompanion &&
                        _controller.inspector != null &&
                        _controller.companionOpen);
                final companionWidth = wideWindow ? 344.0 : 316.0;
                _companionCurrentlyVisible =
                    showDockedCompanion || showOverlayCompanion;

                return Column(
                  children: [
                    _TopAppBar(
                      store: store,
                      controller: _controller,
                      compactSearch: width < 1060,
                      companionVisible: _companionCurrentlyVisible,
                    ),
                    Expanded(
                      child: !store.isLoggedIn
                          ? LoginForm(store: store)
                          : Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      0, 0, 12, 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _NavigationRail(
                                        store: store,
                                        controller: _controller,
                                        showLabels: railWithLabels,
                                      ),
                                      // Primary elevated canvas sheet
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: c.sheet,
                                            borderRadius: BorderRadius.circular(
                                                DesktopRadius.sheet),
                                            border:
                                                Border.all(color: c.hairline),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: switch (
                                              _controller.destination) {
                                            DesktopDestination.schedule =>
                                              SchedulePage(
                                                store: store,
                                                controller: _controller,
                                                wideWindow: wideWindow &&
                                                    !showDockedCompanion
                                                    ? true
                                                    : width >= 1480,
                                              ),
                                            DesktopDestination.tasks =>
                                              TasksPage(
                                                store: store,
                                                controller: _controller,
                                              ),
                                            DesktopDestination.academics =>
                                              AcademicsPage(
                                                store: store,
                                                controller: _controller,
                                              ),
                                          },
                                        ),
                                      ),
                                      // Docked Right Companion Panel (>=1120px)
                                      if (showDockedCompanion) ...[
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: companionWidth,
                                          child: CompanionPanel(
                                            store: store,
                                            controller: _controller,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Overlay Companion Drawer (<1120px)
                                if (showOverlayCompanion) ...[
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () {
                                        _controller.clearInspector();
                                        _controller.setCompanionOpen(false,
                                            userAction: true);
                                      },
                                      child: Container(
                                        color: Colors.black
                                            .withValues(alpha: 0.24),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 12,
                                    bottom: 12,
                                    width: 336,
                                    child: CompanionPanel(
                                      store: store,
                                      controller: _controller,
                                      isOverlay: true,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({
    required this.store,
    required this.controller,
    required this.compactSearch,
    required this.companionVisible,
  });

  final DesktopStore store;
  final DesktopController controller;
  final bool compactSearch;
  final bool companionVisible;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = store.lastErrors.isNotEmpty;
    final liveTerm = store.scholar.thisSemester.name;
    final semName = liveTerm.isNotEmpty
        ? liveTerm
        : (store.semesters.isNotEmpty ? store.semesters.first.name : null);
    final weekNo = store.teachingWeek;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: c.chrome,
      child: Row(
        children: [
          // Brand lockup + semester/week pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(DesktopRadius.block),
                ),
                child: Icon(Icons.schedule_rounded, size: 17, color: c.primary),
              ),
              const SizedBox(width: 9),
              Text(
                'Celechron',
                style: DesktopType.strong(context).copyWith(fontSize: 15),
              ),
              if (store.isLoggedIn && semName != null) ...[
                const SizedBox(width: 10),
                ConcentricTag(
                  label: weekNo != null ? '$semName · 第$weekNo周' : semName,
                  radius: DesktopRadius.tag,
                  numeric: true,
                ),
              ],
            ],
          ),
          const Spacer(),
          // Centered Google-style Ctrl+K search pill
          if (store.isLoggedIn && !compactSearch)
            DesktopAction(
              onTap: () => showCommandPalette(
                context,
                store: store,
                controller: controller,
              ),
              backgroundColor: c.surfaceHigh,
              hoverColor: c.surfaceHighest,
              borderRadius: DesktopRadius.pill,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: SizedBox(
                width: 310,
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 16, color: c.text2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '搜索课程、作业、考试或操作…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesktopType.meta(context),
                      ),
                    ),
                    const ConcentricTag(
                      label: 'Ctrl K',
                      radius: DesktopRadius.tag,
                    ),
                  ],
                ),
              ),
            )
          else if (store.isLoggedIn)
            DesktopIconButton(
              icon: Icons.search_rounded,
              tooltip: '搜索与命令面板 (Ctrl+K)',
              onPressed: () => showCommandPalette(
                context,
                store: store,
                controller: controller,
              ),
            ),
          const Spacer(),
          // Right utility cluster: Sync + Companion toggle + Theme + Settings/Account
          if (store.isLoggedIn) ...[
            DesktopAction(
              onTap: () => showSyncStatusDialog(context, store),
              tooltip: hasError
                  ? '同步异常：${store.lastErrors.first}'
                  : '同步状态 · ${updatedAgo(store.lastRefreshAt, store.now)}',
              backgroundColor: hasError ? c.dangerFill : Colors.transparent,
              borderRadius: DesktopRadius.chip,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (store.refreshing)
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: c.primary,
                      ),
                    )
                  else
                    Icon(
                      hasError
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_done_outlined,
                      size: 16,
                      color: hasError ? c.danger : c.text2,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    store.refreshing
                        ? '同步中'
                        : hasError
                            ? '同步失败'
                            : updatedAgo(store.lastRefreshAt, store.now),
                    style: DesktopType.caption(context, numeric: true).copyWith(
                      color: hasError ? c.danger : c.text2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            DesktopIconButton(
              icon: Icons.view_sidebar_outlined,
              tooltip: '展开/收起右侧待办面板 (Ctrl+\\)',
              selected: companionVisible,
              onPressed: () => controller.toggleCompanion(
                  currentlyVisible: companionVisible),
            ),
            const SizedBox(width: 2),
          ],
          DesktopIconButton(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: isDark ? '切换浅色模式' : '切换深色模式',
            onPressed: () => store.setBrightnessMode(
              isDark ? BrightnessMode.light : BrightnessMode.dark,
            ),
          ),
          const SizedBox(width: 2),
          DesktopIconButton(
            icon: Icons.settings_outlined,
            tooltip: '设置与账号',
            onPressed: () => showSettingsDialog(context, store),
          ),
        ],
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.store,
    required this.controller,
    required this.showLabels,
  });

  final DesktopStore store;
  final DesktopController controller;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final openWorkCount = store.todos.length + store.pendingDeadlines.length;
    final hasOverdue = store.todos.any(
            (t) => t.endTime != null && t.endTime!.isBefore(store.now)) ||
        store.pendingDeadlines.any((t) => t.endTime.isBefore(store.now));

    return SizedBox(
      width: showLabels ? 80 : 68,
      child: Column(
        children: [
          const SizedBox(height: 4),
          // M3 Rounded-Square FAB (+ Create)
          Tooltip(
            message: '新建任务或日程 (N)',
            child: DesktopAction(
              onTap: () => controller.createTask(context, store),
              backgroundColor: c.primaryContainer,
              hoverColor: Color.alphaBlend(c.hover, c.primaryContainer),
              borderRadius: 14,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: c.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _RailItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today_rounded,
            label: '日程',
            shortcut: 'Ctrl+1',
            selected: controller.destination == DesktopDestination.schedule,
            showLabel: showLabels,
            onTap: () => controller.setDestination(DesktopDestination.schedule),
          ),
          const SizedBox(height: 10),
          _RailItem(
            icon: Icons.task_alt_outlined,
            selectedIcon: Icons.task_alt_rounded,
            label: '任务',
            shortcut: 'Ctrl+2',
            badge: openWorkCount > 0 ? '$openWorkCount' : null,
            badgeUrgent: hasOverdue,
            selected: controller.destination == DesktopDestination.tasks,
            showLabel: showLabels,
            onTap: () => controller.setDestination(DesktopDestination.tasks),
          ),
          const SizedBox(height: 10),
          _RailItem(
            icon: Icons.school_outlined,
            selectedIcon: Icons.school_rounded,
            label: '学业',
            shortcut: 'Ctrl+3',
            selected: controller.destination == DesktopDestination.academics,
            showLabel: showLabels,
            onTap: () => controller.setDestination(DesktopDestination.academics),
          ),
          const Spacer(),
          // Subtle account badge at rail footer
          Tooltip(
            message: '账号 ${store.username} · 打开设置',
            child: DesktopAction(
              onTap: () => showSettingsDialog(context, store),
              borderRadius: DesktopRadius.block,
              padding: const EdgeInsets.all(6),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(DesktopRadius.block),
                  border: Border.all(color: c.hairline),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 17,
                  color: c.text2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.shortcut,
    required this.selected,
    required this.showLabel,
    required this.onTap,
    this.badge,
    this.badgeUrgent = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String shortcut;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;
  final String? badge;
  final bool badgeUrgent;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Tooltip(
      message: '$label ($shortcut)',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: showLabel ? 72 : 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      width: 52,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? c.railIndicator : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        selected ? selectedIcon : icon,
                        size: 20,
                        color: selected ? c.onRailIndicator : c.text2,
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: -3,
                        right: 2,
                        child: Container(
                          height: 16,
                          constraints: const BoxConstraints(minWidth: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: badgeUrgent ? c.danger : c.surfaceHighest,
                            borderRadius:
                                BorderRadius.circular(DesktopRadius.tag),
                          ),
                          child: Text(
                            badge!,
                            style: DesktopType.caption(context, numeric: true)
                                .copyWith(
                              fontSize: 10,
                              color: badgeUrgent ? c.onPrimary : c.text1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showLabel) ...[
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: DesktopType.caption(context).copyWith(
                      color: selected ? c.text1 : c.text2,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
