import 'package:flutter/material.dart';
import '../../state/desktop_controller.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common_ui.dart';
import 'day_timeline.dart';
import 'month_grid.dart';
import 'week_grid.dart';

/// Primary Schedule workspace unifying Day (adaptive Today+Tomorrow on wide
/// displays), Week, and Month views inside a single elevated canvas sheet.
class SchedulePage extends StatelessWidget {
  const SchedulePage({
    super.key,
    required this.store,
    required this.controller,
    required this.wideWindow,
  });

  final DesktopStore store;
  final DesktopController controller;
  final bool wideWindow;

  String _rangeLabel(DateTime focused, ScheduleMode mode, bool twoDay) {
    switch (mode) {
      case ScheduleMode.day:
        if (twoDay) {
          final next = focused.add(const Duration(days: 1));
          return '${focused.year}年${focused.month}月${focused.day}日 – ${next.month}月${next.day}日';
        }
        return '${focused.year}年${focused.month}月${focused.day}日';
      case ScheduleMode.week:
        final mon = DesktopStore.mondayOf(focused);
        final sun = mon.add(const Duration(days: 6));
        if (mon.month == sun.month) {
          return '${mon.year}年${mon.month}月${mon.day}–${sun.day}日';
        }
        return '${mon.month}月${mon.day}日 – ${sun.month}月${sun.day}日';
      case ScheduleMode.month:
        return '${focused.year}年${focused.month}月';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final mode = controller.scheduleMode;
    final focused = controller.focusedDay;
    final twoDay = wideWindow && mode == ScheduleMode.day;
    final weekNo = store.teachingWeekOn(focused);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact contextual schedule toolbar inside the canvas sheet
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              DesktopAction(
                onTap: () => controller.goToday(store.now),
                tooltip: '回到今天 (T)',
                borderColor: c.hairline,
                borderRadius: DesktopRadius.chip,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                child: Text('今天', style: DesktopType.strong(context)),
              ),
              const SizedBox(width: 6),
              DesktopIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: '上一页',
                onPressed: () => controller.stepDate(-1),
              ),
              DesktopIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: '下一页',
                onPressed: () => controller.stepDate(1),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _rangeLabel(focused, mode, twoDay),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.title(context).copyWith(
                      fontSize: 16.5, fontFeatures: DesktopType.tabular),
                ),
              ),
              if (weekNo != null) ...[
                const SizedBox(width: 8),
                ConcentricTag(
                  label: '第 $weekNo 周',
                  foreground: c.primary,
                  background: c.selectedFill,
                  radius: DesktopRadius.tag,
                  numeric: true,
                ),
              ],
              const Spacer(),
              if (mode != ScheduleMode.month) ...[
                DesktopAction(
                  onTap: controller.togglePeriodAxis,
                  selected: controller.showPeriodAxis,
                  tooltip: '显示/隐藏浙大节次刻度 (1–13节)',
                  borderRadius: DesktopRadius.chip,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_list_numbered_rounded,
                        size: 14,
                        color: controller.showPeriodAxis ? c.primary : c.text2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '节次',
                        style: DesktopType.meta(context).copyWith(
                          color:
                              controller.showPeriodAxis ? c.primary : c.text2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              DesktopSegmented<ScheduleMode>(
                compact: true,
                items: const {
                  ScheduleMode.day: '日',
                  ScheduleMode.week: '周',
                  ScheduleMode.month: '月',
                },
                value: mode,
                onChanged: controller.setScheduleMode,
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: store.initialLoading
              ? const LoadingSkeleton()
              : switch (mode) {
                  ScheduleMode.day => ScheduleDayTimeline(
                      store: store,
                      controller: controller,
                      twoDayMode: twoDay,
                    ),
                  ScheduleMode.week => ScheduleWeekGrid(
                      store: store,
                      controller: controller,
                    ),
                  ScheduleMode.month => ScheduleMonthGrid(
                      store: store,
                      controller: controller,
                    ),
                },
        ),
      ],
    );
  }
}
