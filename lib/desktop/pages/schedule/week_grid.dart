import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/model/task.dart';
import '../../format.dart';
import '../../state/desktop_controller.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common_ui.dart';
import '../../widgets/course_palette.dart';
import '../../widgets/time_grid_metrics.dart';

/// Google Calendar-style 7-day strictly time-proportional Week grid.
class ScheduleWeekGrid extends StatefulWidget {
  const ScheduleWeekGrid({
    super.key,
    required this.store,
    required this.controller,
  });

  final DesktopStore store;
  final DesktopController controller;

  @override
  State<ScheduleWeekGrid> createState() => _ScheduleWeekGridState();
}

class _ScheduleWeekGridState extends State<ScheduleWeekGrid> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final store = widget.store;
    final ctrl = widget.controller;
    final monday = DesktopStore.mondayOf(ctrl.focusedDay);
    final days = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    final weekPeriods = [for (final d in days) store.agendaPeriodsOn(d)];
    final all = [for (final list in weekPeriods) ...list];
    final hasToday = days.any((d) => _sameDay(d, store.now));

    final metrics = TimeGridMetrics.forPeriods(
      all,
      now: hasToday ? store.now : null,
      pxPerMin: 0.78,
    );
    final markers = zjuPeriodMarkersOf(store.selectedSemester);
    final gutterW = ctrl.showPeriodAxis ? 74.0 : 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 7-day column header row
        Container(
          padding: EdgeInsets.fromLTRB(gutterW, 8, 12, 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _WeekDayHeader(
                    day: days[i],
                    isToday: _sameDay(days[i], store.now),
                    isFocused: _sameDay(days[i], ctrl.focusedDay),
                    dueCount: store.todosOn(days[i]).length,
                    special: store.specialDateOf(days[i]),
                    onTap: () {
                      ctrl.focusDay(days[i]);
                      ctrl.setScheduleMode(ScheduleMode.day);
                    },
                  ),
                ),
            ],
          ),
        ),
        // Scrollable proportional 7-column body
        Expanded(
          child: DesktopScrollArea(
            controller: _scroll,
            padding: const EdgeInsets.only(top: 8, bottom: 20, right: 12),
            child: SizedBox(
              height: metrics.totalHeight + 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: gutterW,
                    height: metrics.totalHeight,
                    child: _WeekGutter(
                      metrics: metrics,
                      markers: markers,
                      showPeriods: ctrl.showPeriodAxis,
                    ),
                  ),
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _WeekColumn(
                        day: days[i],
                        isToday: _sameDay(days[i], store.now),
                        now: store.now,
                        metrics: metrics,
                        periods: weekPeriods[i],
                        store: store,
                        controller: ctrl,
                        isFirst: i == 0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekDayHeader extends StatelessWidget {
  const _WeekDayHeader({
    required this.day,
    required this.isToday,
    required this.isFocused,
    required this.dueCount,
    required this.special,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isFocused;
  final int dueCount;
  final String? special;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return DesktopAction(
      onTap: onTap,
      tooltip: '切换到 ${day.month}/${day.day} 日视图',
      borderRadius: DesktopRadius.chip,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekdayName(day.weekday),
                style: DesktopType.caption(context).copyWith(
                  color: isToday ? c.primary : c.text2,
                ),
              ),
              if (dueCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday
                  ? c.primary
                  : isFocused
                      ? c.selectedFill
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(DesktopRadius.badge),
            ),
            child: Text(
              '${day.day}',
              style: DesktopType.strong(context, numeric: true).copyWith(
                fontSize: 13,
                color: isToday
                    ? c.onPrimary
                    : isFocused
                        ? c.primary
                        : c.text1,
              ),
            ),
          ),
          if (special != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                special!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DesktopType.caption(context)
                    .copyWith(fontSize: 10, color: c.warning),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekGutter extends StatelessWidget {
  const _WeekGutter({
    required this.metrics,
    required this.markers,
    required this.showPeriods,
  });

  final TimeGridMetrics metrics;
  final List<ZjuPeriodMarker> markers;
  final bool showPeriods;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final firstH = (metrics.startMinute / 60).ceil();
    final lastH = metrics.endMinute ~/ 60;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var h = firstH; h <= lastH; h++)
          Positioned(
            top: metrics.minuteToY(h * 60.0) - 7,
            left: 6,
            width: 38,
            child: Text(
              '${two(h)}:00',
              textAlign: TextAlign.right,
              style: DesktopType.caption(context, numeric: true)
                  .copyWith(fontSize: 11),
            ),
          ),
        if (showPeriods)
          for (final m in markers)
            if (m.startMinute >= metrics.startMinute &&
                m.startMinute <= metrics.endMinute - 15)
              Positioned(
                top: metrics.minuteToY(m.startMinute.toDouble()) + 1,
                right: 5,
                child: Text(
                  '${m.index}',
                  style: DesktopType.caption(context, numeric: true)
                      .copyWith(fontSize: 10, color: c.text3),
                ),
              ),
      ],
    );
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.day,
    required this.isToday,
    required this.now,
    required this.metrics,
    required this.periods,
    required this.store,
    required this.controller,
    required this.isFirst,
  });

  final DateTime day;
  final bool isToday;
  final DateTime now;
  final TimeGridMetrics metrics;
  final List<Period> periods;
  final DesktopStore store;
  final DesktopController controller;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final placed = packPeriods(periods);
    final nowY = isToday ? metrics.timeToY(now, day) : null;
    final hasNow = nowY != null && nowY >= 0 && nowY <= metrics.totalHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final colW = constraints.maxWidth;
        return Container(
          height: metrics.totalHeight,
          decoration: BoxDecoration(
            color: isToday ? c.primary.withValues(alpha: 0.045) : null,
            border: Border(
              left: BorderSide(color: c.hairline.withValues(alpha: 0.8)),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WeekHourPainter(
                    metrics: metrics,
                    hourColor: c.gridHour,
                    halfColor: c.gridHalf,
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTapDown: (details) {
                    if (!store.isLoggedIn) return;
                    final raw = metrics.yToMinute(details.localPosition.dy);
                    final snapped = ((raw / 30).round() * 30).clamp(0, 23 * 60);
                    final start = DateTime(day.year, day.month, day.day,
                        snapped ~/ 60, snapped % 60);
                    controller.createTask(
                      context,
                      store,
                      type: TaskType.fixed,
                      start: start,
                      end: start.add(const Duration(hours: 1)),
                    );
                  },
                ),
              ),
              for (final item in placed) _buildBlock(context, item, colW),
              if (hasNow)
                Positioned(
                  top: nowY - 1,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(height: 2, color: c.primary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlock(BuildContext context, PlacedPeriod item, double colW) {
    final c = DesktopColors.of(context);
    final p = item.period;
    final top = metrics.timeToY(p.startTime, day);
    final height = metrics.durationHeight(p.endTime.difference(p.startTime));
    const pad = 2.0;
    final w = math.max(
        24.0, (colW - pad * 2 - (item.columnCount - 1) * 2) / item.columnCount);
    final left = pad + item.column * (w + 2);
    final isExam = p.type == PeriodType.test;
    final isUser = p.type == PeriodType.user;
    final isFlow = p.type == PeriodType.flow;
    final swatch = isExam
        ? CoursePalette.exam(context)
        : isFlow
            ? CoursePalette.flow(context)
            : CoursePalette.of(context, p.summary);
    final isPast = !p.endTime.isAfter(now);
    final isHighlighted = controller.hoveredCourseName == p.summary;

    return Positioned(
      top: top,
      left: left,
      width: w,
      height: height,
      child: Tooltip(
        message: [
          p.summary,
          fmtRange(p.startTime, p.endTime),
          if (p.location.isNotEmpty) p.location,
        ].join('\n'),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => controller.setHoveredCourse(p.summary),
          onExit: (_) => controller.setHoveredCourse(null),
          child: GestureDetector(
            onTap: () {
              if (p.type == PeriodType.classes) {
                controller.inspect(CourseInspectorTarget(p.summary));
              } else {
                controller.inspect(PeriodInspectorTarget(p));
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesktopRadius.badge),
              child: Container(
                decoration: BoxDecoration(
                  color: isPast
                      ? Color.lerp(isUser ? c.sheet : swatch.fill, c.sheet, 0.32)
                      : isHighlighted
                          ? Color.alphaBlend(
                              c.hover, isUser ? c.sheet : swatch.fill)
                          : (isUser ? c.sheet : swatch.fill),
                  borderRadius: BorderRadius.circular(DesktopRadius.badge),
                  border: isUser
                      ? Border.all(color: swatch.bar.withValues(alpha: 0.65))
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 3,
                      top: 4,
                      bottom: 4,
                      width: 2.5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: swatch.bar,
                          borderRadius: BorderRadius.circular(1.25),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(9, 4, 5, 4),
                      child: Opacity(
                        opacity: isPast ? 0.65 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.summary,
                              maxLines: height >= 60 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesktopType.strong(context).copyWith(
                                fontSize: 11.5,
                                height: 1.22,
                                color: isUser ? c.text1 : swatch.ink,
                              ),
                            ),
                            if (height >= 46 && p.location.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                p.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DesktopType.caption(context).copyWith(
                                  fontSize: 10.5,
                                  color: isUser ? c.text2 : swatch.meta,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekHourPainter extends CustomPainter {
  const _WeekHourPainter({
    required this.metrics,
    required this.hourColor,
    required this.halfColor,
  });

  final TimeGridMetrics metrics;
  final Color hourColor;
  final Color halfColor;

  @override
  void paint(Canvas canvas, Size size) {
    final hp = Paint()
      ..color = hourColor
      ..strokeWidth = 1;
    final sp = Paint()
      ..color = halfColor
      ..strokeWidth = 1;
    final first = (metrics.startMinute / 30).ceil() * 30;
    for (var m = first; m <= metrics.endMinute; m += 30) {
      final y = metrics.minuteToY(m.toDouble());
      canvas.drawLine(Offset(0, y), Offset(size.width, y), m % 60 == 0 ? hp : sp);
    }
  }

  @override
  bool shouldRepaint(covariant _WeekHourPainter old) =>
      old.metrics != metrics ||
      old.hourColor != hourColor ||
      old.halfColor != halfColor;
}
