import 'package:flutter/material.dart';
import 'package:celechron/model/period.dart';
import '../../format.dart';
import '../../state/desktop_controller.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common_ui.dart';
import '../../widgets/course_palette.dart';

/// Clean Google Calendar month grid. Clicking a day selects it; clicking a
/// chip inspects that event; double-clicking a day opens it in Day timeline.
class ScheduleMonthGrid extends StatelessWidget {
  const ScheduleMonthGrid({
    super.key,
    required this.store,
    required this.controller,
  });

  final DesktopStore store;
  final DesktopController controller;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final focus = controller.focusedDay;
    final firstOfMonth = DateTime(focus.year, focus.month, 1);
    final startMonday = DesktopStore.mondayOf(firstOfMonth);
    final lastOfMonth = DateTime(focus.year, focus.month + 1, 0);
    final totalDays = lastOfMonth.difference(startMonday).inDays + 1;
    final rowCount = (totalDays / 7).ceil().clamp(5, 6);

    return Column(
      children: [
        // Weekday header strip
        Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              for (var wd = 1; wd <= 7; wd++)
                Expanded(
                  child: Center(
                    child: Text(
                      weekdayName(wd),
                      style: DesktopType.caption(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Month grid cells
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellHeight = constraints.maxHeight / rowCount;
              final maxChips = cellHeight >= 115
                  ? 3
                  : cellHeight >= 85
                      ? 2
                      : 1;
              return Column(
                children: [
                  for (var r = 0; r < rowCount; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            Expanded(
                              child: _MonthCell(
                                day: startMonday.add(Duration(days: r * 7 + col)),
                                currentMonth: focus.month,
                                isToday: _sameDay(
                                  startMonday.add(Duration(days: r * 7 + col)),
                                  store.now,
                                ),
                                isSelected: _sameDay(
                                  startMonday.add(Duration(days: r * 7 + col)),
                                  focus,
                                ),
                                maxChips: maxChips,
                                store: store,
                                controller: controller,
                                showLeftBorder: col > 0,
                                showTopBorder: r > 0,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.day,
    required this.currentMonth,
    required this.isToday,
    required this.isSelected,
    required this.maxChips,
    required this.store,
    required this.controller,
    required this.showLeftBorder,
    required this.showTopBorder,
  });

  final DateTime day;
  final int currentMonth;
  final bool isToday;
  final bool isSelected;
  final int maxChips;
  final DesktopStore store;
  final DesktopController controller;
  final bool showLeftBorder;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final inMonth = day.month == currentMonth;
    final periods = store.agendaPeriodsOn(day);
    final todos = store.todosOn(day);
    final special = store.specialDateOf(day);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.focusDay(day),
      onDoubleTap: () {
        controller.focusDay(day);
        controller.setScheduleMode(ScheduleMode.day);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
        decoration: BoxDecoration(
          color: isSelected
              ? c.selectedFill.withValues(alpha: 0.45)
              : !inMonth
                  ? c.surfaceLow.withValues(alpha: 0.55)
                  : Colors.transparent,
          border: Border(
            left: showLeftBorder
                ? BorderSide(color: c.hairline)
                : BorderSide.none,
            top: showTopBorder
                ? BorderSide(color: c.hairline)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? c.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(DesktopRadius.tag),
                  ),
                  child: Text(
                    '${day.day}',
                    style: DesktopType.caption(context, numeric: true).copyWith(
                      color: isToday
                          ? c.onPrimary
                          : inMonth
                              ? c.text1
                              : c.text3.withValues(alpha: 0.55),
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (special != null) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      special,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesktopType.caption(context)
                          .copyWith(fontSize: 10, color: c.warning),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (todos.isNotEmpty)
                  Tooltip(
                    message: '${todos.length} 项作业截止',
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            for (var i = 0; i < periods.length && i < maxChips; i++) ...[
              _MonthEventChip(
                period: periods[i],
                onTap: () {
                  final p = periods[i];
                  if (p.type == PeriodType.classes) {
                    controller.inspect(CourseInspectorTarget(p.summary));
                  } else {
                    controller.inspect(PeriodInspectorTarget(p));
                  }
                },
              ),
              const SizedBox(height: 2),
            ],
            if (periods.length > maxChips)
              Text(
                '+${periods.length - maxChips} 项',
                style: DesktopType.caption(context, numeric: true)
                    .copyWith(fontSize: 10.5, color: c.text3),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthEventChip extends StatelessWidget {
  const _MonthEventChip({required this.period, required this.onTap});
  final Period period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = period.type == PeriodType.test
        ? CoursePalette.exam(context)
        : period.type == PeriodType.flow
            ? CoursePalette.flow(context)
            : CoursePalette.of(context, period.summary);
    return DesktopAction(
      onTap: onTap,
      borderRadius: DesktopRadius.tag,
      backgroundColor: swatch.fill,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 10,
            decoration: BoxDecoration(
              color: swatch.bar,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              period.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesktopType.caption(context).copyWith(
                fontSize: 11,
                color: swatch.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
