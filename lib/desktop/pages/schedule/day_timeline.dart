import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/model/todo.dart';
import '../../format.dart';
import '../../state/desktop_controller.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common_ui.dart';
import '../../widgets/course_palette.dart';
import '../../widgets/time_grid_metrics.dart';

/// Strictly time-proportional Day (or adaptive Today + Tomorrow on wide screens)
/// timeline with Dual Clock + ZJU Period gutter, elapsed-time dimming,
/// free-gap `+ 规划` affordance, and right-gutter deadline ticks.
class ScheduleDayTimeline extends StatefulWidget {
  const ScheduleDayTimeline({
    super.key,
    required this.store,
    required this.controller,
    required this.twoDayMode,
  });

  final DesktopStore store;
  final DesktopController controller;
  final bool twoDayMode;

  @override
  State<ScheduleDayTimeline> createState() => _ScheduleDayTimelineState();
}

class _ScheduleDayTimelineState extends State<ScheduleDayTimeline> {
  final ScrollController _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayStatusLine(DateTime day, List<Period> periods, DateTime now) {
    final isToday = _isSameDay(day, now);
    if (periods.isEmpty) {
      return isToday ? '今天没有课' : '当日没有课';
    }
    if (isToday) {
      final ongoing = periods
          .where((p) => !p.startTime.isAfter(now) && p.endTime.isAfter(now))
          .toList();
      if (ongoing.isNotEmpty) {
        final p = ongoing.first;
        final left = p.endTime.difference(now).inMinutes;
        return '正在进行 · ${p.summary}（剩 $left 分钟）';
      }
      final upcoming = periods.where((p) => p.startTime.isAfter(now)).toList();
      if (upcoming.isNotEmpty) {
        final p = upcoming.first;
        final wait = p.startTime.difference(now).inMinutes;
        final waitStr =
            wait >= 60 ? '${wait ~/ 60} 小时 ${wait % 60} 分钟后' : '$wait 分钟后';
        return '下一节 · ${p.summary} · ${fmtTime(p.startTime)}（$waitStr）';
      }
      return '今日课程已结束';
    }
    return '共 ${periods.length} 项安排 · 首节 ${fmtTime(periods.first.startTime)}';
  }

  void _ensureInitialScroll(
      TimeGridMetrics metrics, List<Period> primaryPeriods, bool showingToday) {
    if (_didInitialScroll) return;
    _didInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;
      double targetMin;
      if (showingToday) {
        final n = widget.store.now;
        final nowTarget = (n.hour * 60 + n.minute - 90).toDouble();
        final ongoing = primaryPeriods
            .where((p) => !p.startTime.isAfter(n) && p.endTime.isAfter(n))
            .toList();
        if (ongoing.isNotEmpty) {
          final startMin = (ongoing.first.startTime.hour * 60 +
                  ongoing.first.startTime.minute -
                  25)
              .toDouble();
          targetMin = math.min(nowTarget, startMin);
        } else {
          targetMin = nowTarget;
        }
      } else if (primaryPeriods.isNotEmpty) {
        final first = primaryPeriods.first.startTime;
        targetMin = (first.hour * 60 + first.minute - 45).toDouble();
      } else {
        targetMin = 8 * 60;
      }
      final offset = metrics.minuteToY(targetMin).clamp(0.0, maxExtent);
      _scrollController.jumpTo(offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final store = widget.store;
    final ctrl = widget.controller;
    final day1 = ctrl.focusedDay;
    final day2 = day1.add(const Duration(days: 1));
    final days = widget.twoDayMode ? [day1, day2] : [day1];

    final dayPeriods = [for (final d in days) store.agendaPeriodsOn(d)];
    final dayTodos = [for (final d in days) store.todosOn(d)];
    final allPeriods = [for (final list in dayPeriods) ...list];

    final showingToday = days.any((d) => _isSameDay(d, store.now));
    final metrics = TimeGridMetrics.forPeriods(
      allPeriods,
      now: showingToday ? store.now : null,
      pxPerMin: 0.90,
    );
    final periodMarkers = zjuPeriodMarkersOf(store.selectedSemester);
    final gutterWidth = ctrl.showPeriodAxis ? 80.0 : 54.0;

    _ensureInitialScroll(metrics, allPeriods, showingToday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Day column header strip
        Container(
          padding: EdgeInsets.fromLTRB(gutterWidth, 10, 14, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < days.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(
                  child: _DayColumnHeader(
                    day: days[i],
                    now: store.now,
                    statusLine:
                        _dayStatusLine(days[i], dayPeriods[i], store.now),
                    specialLabel: store.specialDateOf(days[i]),
                    dueCount: dayTodos[i].length,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Scrollable strictly time-proportional grid body
        Expanded(
          child: DesktopScrollArea(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 10, bottom: 20, right: 14),
            child: SizedBox(
              height: metrics.totalHeight + 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dual-Axis Time Gutter (Clock + ZJU Period 1–13)
                  SizedBox(
                    width: gutterWidth,
                    height: metrics.totalHeight,
                    child: _TimeAxisGutter(
                      metrics: metrics,
                      periodMarkers: periodMarkers,
                      showPeriods: ctrl.showPeriodAxis,
                      now: showingToday ? store.now : null,
                    ),
                  ),
                  // One or Two proportional Day Columns sharing exact metrics
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(
                      child: _SingleDayColumn(
                        day: days[i],
                        isToday: _isSameDay(days[i], store.now),
                        now: store.now,
                        metrics: metrics,
                        periods: dayPeriods[i],
                        todosDue: dayTodos[i],
                        store: store,
                        controller: ctrl,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayColumnHeader extends StatelessWidget {
  const _DayColumnHeader({
    required this.day,
    required this.now,
    required this.statusLine,
    required this.specialLabel,
    required this.dueCount,
  });

  final DateTime day;
  final DateTime now;
  final String statusLine;
  final String? specialLabel;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final dayRel = calendarDaysBetween(now, day);
    final badgeLabel = switch (dayRel) {
      0 => '今天',
      1 => '明天',
      -1 => '昨天',
      _ => null,
    };

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isToday ? c.primary : c.surfaceHigh,
            borderRadius: BorderRadius.circular(DesktopRadius.block),
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: DesktopType.section(context).copyWith(
              color: isToday ? c.onPrimary : c.text1,
              fontFeatures: DesktopType.tabular,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${day.month}月${day.day}日 ${weekdayName(day.weekday)}',
                    style: DesktopType.strong(context, numeric: true),
                  ),
                  if (badgeLabel != null) ...[
                    const SizedBox(width: 6),
                    ConcentricTag(
                      label: badgeLabel,
                      foreground: isToday ? c.primary : c.text2,
                      background: isToday ? c.selectedFill : c.surfaceHigh,
                      radius: DesktopRadius.tag,
                    ),
                  ],
                  if (specialLabel != null) ...[
                    const SizedBox(width: 6),
                    ConcentricTag(
                      label: specialLabel!,
                      foreground: c.warning,
                      background: c.warningFill,
                      radius: DesktopRadius.tag,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                statusLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DesktopType.meta(context, numeric: true),
              ),
            ],
          ),
        ),
        if (dueCount > 0) ...[
          const SizedBox(width: 8),
          ConcentricTag(
            label: '$dueCount 项截止',
            foreground: c.warning,
            background: c.warningFill,
            radius: DesktopRadius.tag,
            numeric: true,
          ),
        ],
      ],
    );
  }
}

class _TimeAxisGutter extends StatelessWidget {
  const _TimeAxisGutter({
    required this.metrics,
    required this.periodMarkers,
    required this.showPeriods,
    this.now,
  });

  final TimeGridMetrics metrics;
  final List<ZjuPeriodMarker> periodMarkers;
  final bool showPeriods;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final firstHour = (metrics.startMinute / 60).ceil();
    final lastHour = metrics.endMinute ~/ 60;
    final nowMin = now == null ? null : now!.hour * 60 + now!.minute;
    final nowY = nowMin == null ? null : metrics.minuteToY(nowMin.toDouble());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Clock hours (skip label collided by the live now badge)
        for (var h = firstHour; h <= lastHour; h++)
          if (nowY == null || (metrics.minuteToY(h * 60.0) - nowY).abs() >= 16)
            Positioned(
              top: metrics.minuteToY(h * 60.0) - 8,
              left: 8,
              width: 40,
              child: Text(
                '${two(h)}:00',
                textAlign: TextAlign.right,
                style: DesktopType.caption(context, numeric: true),
              ),
            ),
        // ZJU Period markers (1..13) aligned to exact real start minutes
        if (showPeriods)
          for (final m in periodMarkers)
            if (m.startMinute >= metrics.startMinute &&
                m.startMinute <= metrics.endMinute - 15)
              Positioned(
                top: metrics.minuteToY(m.startMinute.toDouble()) + 2,
                right: 6,
                child: Container(
                  width: 20,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceLow,
                    borderRadius: BorderRadius.circular(DesktopRadius.tag),
                  ),
                  child: Text(
                    '${m.index}',
                    style: DesktopType.caption(context, numeric: true).copyWith(
                      fontSize: 10.5,
                      color: c.text3,
                    ),
                  ),
                ),
              ),
        // Exact current time badge aligned with now-line (4px radius, never oval)
        if (now != null &&
            nowMin! >= metrics.startMinute &&
            nowMin <= metrics.endMinute)
          Positioned(
            top: nowY! - 10,
            left: 6,
            child: Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(DesktopRadius.tag),
              ),
              child: Text(
                fmtTime(now!),
                style: DesktopType.caption(context, numeric: true).copyWith(
                  color: c.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SingleDayColumn extends StatelessWidget {
  const _SingleDayColumn({
    required this.day,
    required this.isToday,
    required this.now,
    required this.metrics,
    required this.periods,
    required this.todosDue,
    required this.store,
    required this.controller,
  });

  final DateTime day;
  final bool isToday;
  final DateTime now;
  final TimeGridMetrics metrics;
  final List<Period> periods;
  final List<Todo> todosDue;
  final DesktopStore store;
  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final placed = packPeriods(periods);
    final gaps = findFreeGaps(day, periods);
    final nowY = isToday ? metrics.timeToY(now, day) : null;
    final hasNow = nowY != null && nowY >= 0 && nowY <= metrics.totalHeight;
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
    final isEntirelyPast = !isToday && dayEnd.isBefore(now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth;
        final tickReserve = todosDue.isNotEmpty ? 16.0 : 0.0;
        final laneWidth = math.max(120.0, colWidth - tickReserve);

        return SizedBox(
          width: colWidth,
          height: metrics.totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Background gridlines (full hours + subtle half hours)
              Positioned.fill(
                child: CustomPaint(
                  painter: _TimelineGridPainter(
                    metrics: metrics,
                    hourColor: c.gridHour,
                    halfColor: c.gridHalf,
                  ),
                ),
              ),
              // 2. Past-time scrim above now line
              if (hasNow)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: nowY.clamp(0.0, metrics.totalHeight),
                  child: IgnorePointer(
                    child: Container(color: c.pastScrim),
                  ),
                )
              else if (isEntirelyPast)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(color: c.pastScrim),
                  ),
                ),
              // 3. Double-tap empty background to create a fixed event at that time
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTapDown: (details) {
                    if (!store.isLoggedIn) return;
                    final rawMin = metrics.yToMinute(details.localPosition.dy);
                    final snapped =
                        ((rawMin / 30).round() * 30).clamp(0, 23 * 60);
                    final start = DateTime(
                      day.year,
                      day.month,
                      day.day,
                      snapped ~/ 60,
                      snapped % 60,
                    );
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
              // 4. Free-gap inline `+ 规划` affordance
              for (final gap in gaps)
                _buildGapAffordance(context, gap, laneWidth),
              // 5. Empty-day gentle centered cue (never hides the proportional grid)
              if (periods.isEmpty)
                Positioned(
                  top: metrics.minuteToY(10 * 60.0),
                  left: 16,
                  right: 16 + tickReserve,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: c.surfaceLow,
                      borderRadius: BorderRadius.circular(DesktopRadius.card),
                      border: Border.all(color: c.hairline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined, size: 18, color: c.text3),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isToday
                                ? '今天没有安排课程，双击空白时段可添加日程'
                                : '当日暂无安排，双击空白时段可添加日程',
                            style: DesktopType.meta(context),
                          ),
                        ),
                        if (store.isLoggedIn)
                          DesktopAction(
                            onTap: () => controller.createTask(
                              context,
                              store,
                              type: TaskType.fixed,
                              start: DateTime(day.year, day.month, day.day, 10),
                              end: DateTime(day.year, day.month, day.day, 11),
                            ),
                            borderColor: c.hairline,
                            borderRadius: DesktopRadius.badge,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Text(
                              '+ 添加日程',
                              style: DesktopType.meta(context)
                                  .copyWith(color: c.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              // 6. Strictly proportional Period blocks
              for (final item in placed)
                _buildPeriodBlock(context, item, laneWidth),
              // 7. Right-gutter deadline ticks (no duplicate cards on the grid)
              for (final todo in todosDue)
                if (todo.endTime != null)
                  _buildDeadlineTick(context, todo, colWidth),
              // 8. Live `now` indicator line across the active day
              if (hasNow)
                Positioned(
                  top: nowY - 4,
                  left: -4,
                  right: 0,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(height: 2, color: c.primary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGapAffordance(
      BuildContext context, FreeGap gap, double laneWidth) {
    final c = DesktopColors.of(context);
    final top = metrics.timeToY(gap.start, day) + 6;
    final bottom = metrics.timeToY(gap.end, day) - 6;
    final h = bottom - top;
    if (h < 34) return const SizedBox.shrink();
    final mins = gap.duration.inMinutes;
    final durText = mins >= 60
        ? '${mins ~/ 60}小时${mins % 60 > 0 ? '${mins % 60}分' : ''}'
        : '$mins分';

    return Positioned(
      top: top + (h - 28) / 2,
      left: 8,
      width: math.max(120.0, laneWidth - 16),
      height: 28,
      child: Row(
        children: [
          Text(
            '空闲 ${fmtRange(gap.start, gap.end)} · $durText',
            style: DesktopType.caption(context, numeric: true).copyWith(
              color: c.text3.withValues(alpha: 0.78),
            ),
          ),
          if (store.isLoggedIn) ...[
            const SizedBox(width: 8),
            DesktopAction(
              onTap: () => controller.createTask(
                context,
                store,
                type: TaskType.fixed,
                start: gap.start,
                end: gap.start.add(const Duration(hours: 1)),
              ),
              borderRadius: DesktopRadius.tag,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '+ 规划',
                style: DesktopType.caption(context).copyWith(
                  color: c.primary.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodBlock(
      BuildContext context, PlacedPeriod placed, double laneWidth) {
    final p = placed.period;
    final top = metrics.timeToY(p.startTime, day);
    final height = metrics.durationHeight(p.endTime.difference(p.startTime));
    const colGap = 4.0;
    final cellW = (laneWidth - 8 - colGap * (placed.columnCount - 1)) /
        placed.columnCount;
    final left = 4.0 + placed.column * (cellW + colGap);

    final isSelected = switch (controller.inspector) {
      PeriodInspectorTarget(period: final sel) => sel.summary == p.summary &&
          sel.startTime == p.startTime &&
          sel.endTime == p.endTime,
      CourseInspectorTarget(courseName: final name) => name == p.summary,
      _ => false,
    };
    final isHoveredCourse = controller.hoveredCourseName == p.summary;

    return Positioned(
      top: top,
      left: left,
      width: math.max(56.0, cellW),
      height: height,
      child: _TimelinePeriodBlock(
        period: p,
        now: now,
        height: height,
        selected: isSelected,
        highlighted: isHoveredCourse,
        onTap: () {
          if (p.type == PeriodType.classes) {
            controller.inspect(CourseInspectorTarget(p.summary));
          } else {
            controller.inspect(PeriodInspectorTarget(p));
          }
        },
        onHoverChanged: (hover) =>
            controller.setHoveredCourse(hover ? p.summary : null),
      ),
    );
  }

  Widget _buildDeadlineTick(BuildContext context, Todo todo, double colWidth) {
    final c = DesktopColors.of(context);
    final due = todo.endTime!;
    final rawY = metrics.timeToY(due, day).clamp(4.0, metrics.totalHeight - 18);
    final overdue = due.isBefore(now);
    final isHighlighted = controller.hoveredTodoId == todo.id ||
        (controller.inspector is TodoInspectorTarget &&
            (controller.inspector! as TodoInspectorTarget).todo.id == todo.id);
    final tickColor = overdue ? c.danger : c.warning;

    return Positioned(
      top: rawY - 7,
      right: 2,
      child: Semantics(
        label: '截止 ${todo.name} ${fmtTime(due)}',
        button: true,
        child: Tooltip(
          message: '截止 ${fmtTime(due)} · ${todo.name}（${todo.course}）',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => controller.setHoveredTodo(todo.id),
            onExit: (_) => controller.setHoveredTodo(null),
            child: GestureDetector(
              onTap: () => controller.inspect(TodoInspectorTarget(todo)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                width: isHighlighted ? 8 : 5,
                height: 16,
                decoration: BoxDecoration(
                  color: tickColor,
                  borderRadius: BorderRadius.circular(2.5),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: tickColor.withValues(alpha: 0.45),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelinePeriodBlock extends StatefulWidget {
  const _TimelinePeriodBlock({
    required this.period,
    required this.now,
    required this.height,
    required this.selected,
    required this.highlighted,
    required this.onTap,
    required this.onHoverChanged,
  });

  final Period period;
  final DateTime now;
  final double height;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;
  final ValueChanged<bool> onHoverChanged;

  @override
  State<_TimelinePeriodBlock> createState() => _TimelinePeriodBlockState();
}

class _TimelinePeriodBlockState extends State<_TimelinePeriodBlock> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final p = widget.period;
    final isExam = p.type == PeriodType.test;
    final isUser = p.type == PeriodType.user;
    final isFlow = p.type == PeriodType.flow;

    final swatch = isExam
        ? CoursePalette.exam(context)
        : isFlow
            ? CoursePalette.flow(context)
            : CoursePalette.of(context, p.summary);

    final isPast = !p.endTime.isAfter(widget.now);
    final isOngoing =
        !p.startTime.isAfter(widget.now) && p.endTime.isAfter(widget.now);
    final elapsedFraction = isOngoing
        ? (widget.now.difference(p.startTime).inSeconds /
                math.max(1, p.endTime.difference(p.startTime).inSeconds))
            .clamp(0.0, 1.0)
        : 0.0;

    final baseFill = isUser ? c.sheet : swatch.fill;
    final effectiveFill = isPast
        ? Color.lerp(baseFill, c.sheet, 0.35)!
        : (_hovered || widget.highlighted)
            ? Color.alphaBlend(c.hover, baseFill)
            : baseFill;

    final border = widget.selected
        ? Border.all(color: c.primary, width: 1.6)
        : isUser
            ? Border.all(color: swatch.bar.withValues(alpha: 0.65), width: 1)
            : isFlow
                ? Border.all(color: c.primary.withValues(alpha: 0.35), width: 1)
                : null;

    final compact = widget.height < 48;
    final spacious = widget.height >= 78;
    final tooltipText = [
      p.summary,
      fmtRange(p.startTime, p.endTime),
      if (p.location.isNotEmpty) p.location,
      if (p.description.isNotEmpty) p.description,
    ].join('\n');

    return Semantics(
      label: '${p.summary} ${fmtRange(p.startTime, p.endTime)} ${p.location}',
      button: true,
      child: Tooltip(
        message: tooltipText,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() => _hovered = true);
            widget.onHoverChanged(true);
          },
          onExit: (_) {
            setState(() => _hovered = false);
            widget.onHoverChanged(false);
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesktopRadius.block),
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveFill,
                  borderRadius: BorderRadius.circular(DesktopRadius.block),
                  border: border,
                ),
                child: Stack(
                  children: [
                    // Elapsed portion of an ongoing block softly dims toward surface
                    if (isOngoing && elapsedFraction > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: widget.height * elapsedFraction,
                        child: Container(
                          color: c.sheet.withValues(alpha: 0.28),
                        ),
                      ),
                    // Inset rounded 3px vertical accent bar (never clipped by corners)
                    Positioned(
                      left: 4,
                      top: 6,
                      bottom: 6,
                      width: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isPast
                              ? swatch.bar.withValues(alpha: 0.5)
                              : swatch.bar,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                    // Block content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        13,
                        compact ? 4 : 7,
                        10,
                        compact ? 4 : 6,
                      ),
                      child: Opacity(
                        opacity: isPast ? 0.65 : 1.0,
                        child: compact
                            ? Row(
                                children: [
                                  if (isExam) ...[
                                    ConcentricTag(
                                      label: '考试',
                                      foreground: swatch.ink,
                                      background:
                                          swatch.bar.withValues(alpha: 0.2),
                                      radius: DesktopRadius.tag,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      p.summary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          DesktopType.strong(context).copyWith(
                                        fontSize: 12.5,
                                        color: isUser ? c.text1 : swatch.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    fmtRange(p.startTime, p.endTime),
                                    style: DesktopType.caption(context,
                                            numeric: true)
                                        .copyWith(
                                      color: isUser ? c.text2 : swatch.meta,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isExam) ...[
                                        ConcentricTag(
                                          label: '考试',
                                          foreground: swatch.ink,
                                          background: swatch.bar
                                              .withValues(alpha: 0.22),
                                          radius: DesktopRadius.tag,
                                        ),
                                        const SizedBox(width: 6),
                                      ] else if (isFlow) ...[
                                        ConcentricTag(
                                          label: '规划',
                                          foreground: c.primary,
                                          background: c.selectedFill,
                                          radius: DesktopRadius.tag,
                                        ),
                                        const SizedBox(width: 6),
                                      ] else if (isUser) ...[
                                        ConcentricTag(
                                          label: '日程',
                                          foreground: swatch.ink,
                                          background: swatch.fill,
                                          radius: DesktopRadius.tag,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          p.summary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: DesktopType.strong(context)
                                              .copyWith(
                                            fontSize: 13,
                                            color:
                                                isUser ? c.text1 : swatch.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fmtRange(p.startTime, p.endTime),
                                        style: DesktopType.caption(context,
                                                numeric: true)
                                            .copyWith(
                                          color: isUser ? c.text2 : swatch.meta,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (p.location.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: isUser ? c.text3 : swatch.meta,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            p.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: DesktopType.meta(context)
                                                .copyWith(
                                              fontSize: 12,
                                              color: isUser
                                                  ? c.text2
                                                  : swatch.meta,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (spacious && p.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      p.description.replaceAll('\n', ' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          DesktopType.caption(context).copyWith(
                                        color: (isUser ? c.text3 : swatch.meta)
                                            .withValues(alpha: 0.85),
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

class _TimelineGridPainter extends CustomPainter {
  const _TimelineGridPainter({
    required this.metrics,
    required this.hourColor,
    required this.halfColor,
  });

  final TimeGridMetrics metrics;
  final Color hourColor;
  final Color halfColor;

  @override
  void paint(Canvas canvas, Size size) {
    final hourPaint = Paint()
      ..color = hourColor
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = halfColor
      ..strokeWidth = 1;

    final firstHalf = (metrics.startMinute / 30).ceil() * 30;
    for (var m = firstHalf; m <= metrics.endMinute; m += 30) {
      final y = metrics.minuteToY(m.toDouble());
      final isHour = m % 60 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isHour ? hourPaint : halfPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineGridPainter oldDelegate) =>
      oldDelegate.metrics != metrics ||
      oldDelegate.hourColor != hourColor ||
      oldDelegate.halfColor != halfColor;
}
