import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/period.dart';
import '../../model/todo.dart';
import '../format.dart';
import '../store.dart';
import '../shell/navigation.dart';
import '../theme/tokens.dart';
import '../widgets/course_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/homework_row.dart';
import '../widgets/homework_list.dart';
import '../widgets/list_row.dart';
import '../widgets/page_header.dart';
import '../widgets/popover.dart';
import '../widgets/scroll_area.dart';
import '../widgets/section_label.dart';

const _timelineGutter = 58.0;

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.store, required this.onNavigate});
  final DesktopStore store;
  final ValueChanged<DesktopPage> onNavigate;

  List<Period> _timedAgenda(DateTime day) => store
      .agendaPeriodsOn(day)
      .where((p) => p.type != PeriodType.flow && p.type != PeriodType.virtual)
      .toList();

  List<Period> _tomorrowAgenda(DateTime day) => [
        ..._timedAgenda(day),
        for (final t in store.todosOn(day))
          Period(
              uid: 'homework-${t.id}',
              summary: '截止 · ${t.name}',
              startTime: t.endTime!,
              endTime: t.endTime!,
              location: t.course,
              description: '',
              type: PeriodType.virtual),
      ]..sort((a, b) => a.startTime.compareTo(b.startTime));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = store.now;
        final semester = store.scholar.thisSemester;
        final timedToday =
            store.isLoggedIn ? _timedAgenda(now) : const <Period>[];
        final ongoingNow = timedToday
            .where((p) => !p.startTime.isAfter(now) && p.endTime.isAfter(now))
            .toList();
        final nextUp =
            timedToday.where((p) => p.startTime.isAfter(now)).toList();

        return PaperPage(
            store: store,
            header: PageHeader(
                title: '${now.month}月${now.day}日 ${weekdayName(now.weekday)}',
                display: true,
                subtitle: [
                  if (store.teachingWeek != null) '第 ${store.teachingWeek} 周',
                  if (semester.name.length >= 11)
                    '${store.teachingWeek != null && store.teachingWeek! > 8 ? semester.secondHalfName : semester.firstHalfName}学期',
                  if (store.specialDateOf(now) != null)
                    store.specialDateOf(now)!
                ].join(' · '),
                actions: [
                  if (store.isLoggedIn && ongoingNow.isNotEmpty)
                    _glanceChip(
                        context,
                        dotColor: ongoingNow.first.type == PeriodType.test
                            ? PaperColors.of(context).danger
                            : CourseColors(context, ongoingNow.first.summary)
                                .bar,
                        label:
                            '进行中 · ${ongoingNow.first.summary} · ${_fmtRemaining(ongoingNow.first.endTime.difference(now))}')
                  else if (store.isLoggedIn && nextUp.isNotEmpty)
                    _glanceChip(
                        context,
                        dotColor:
                            CourseColors(context, nextUp.first.summary).bar,
                        label:
                            '下一节 · ${nextUp.first.summary} ${fmtTime(nextUp.first.startTime)}')
                ]),
            child: LayoutBuilder(builder: (context, bounds) {
              final railWidth =
                  (bounds.maxWidth * 0.34).clamp(290.0, 380.0);
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _timelinePane(context, timedToday)),
                    Container(
                        width: 1, color: PaperColors.of(context).hairline),
                    SizedBox(width: railWidth, child: _inspectorRail(context))
                  ]);
            }));
      });

  Widget _glanceChip(BuildContext context,
      {required Color dotColor, required String label}) {
    final c = PaperColors.of(context);
    return Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: c.glassControl,
            borderRadius: BorderRadius.circular(Paper.smallRadius)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaperType.meta(context)
                      .copyWith(fontSize: 12, color: c.text2)))
        ]));
  }

  Widget _timelinePane(BuildContext context, List<Period> timedToday) {
    final c = PaperColors.of(context);
    final now = store.now;
    final todayDeadlines = store.todosOn(now);
    final remainingTimed =
        timedToday.where((p) => p.endTime.isAfter(now)).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Full-bleed pane sub-header bar (44px) with inline deadline chips.
      Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.hairline))),
          child: Row(children: [
            Text('今日日程', style: PaperType.cardTitle(context)),
            const SizedBox(width: 8),
            if (timedToday.isNotEmpty)
              Text(
                  remainingTimed == 0
                      ? '今日课程已结束'
                      : '${timedToday.length} 项',
                  style: PaperType.meta(context).copyWith(color: c.text3)),
            if (todayDeadlines.isNotEmpty)
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            for (var i = 0;
                                i < math.min(2, todayDeadlines.length);
                                i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              _inlineDeadlineChip(context, todayDeadlines[i]),
                            ],
                            if (todayDeadlines.length > 2) ...[
                              const SizedBox(width: 6),
                              PaperAction(
                                  borderRadius: Paper.chipRadius,
                                  onTap: () => onNavigate(DesktopPage.homework),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  child: Text('+${todayDeadlines.length - 2}',
                                      style: PaperType.meta(context)
                                          .copyWith(fontSize: 11.5)))
                            ]
                          ]))))
          ])),
      if (timedToday.isEmpty) ...[
        const Expanded(
            child: EmptyState('今天没有课',
                icon: Icons.event_available_rounded,
                subtitle: '可以自由安排学习计划或查看右侧待交作业')),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _nowInline(context))
      ] else
        Expanded(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: _TodayTimeline(
                    day: DateTime(now.year, now.month, now.day),
                    now: now,
                    periods: timedToday)))
    ]);
  }

  Widget _inlineDeadlineChip(BuildContext context, Todo todo) {
    final c = PaperColors.of(context);
    final end = todo.endTime!;
    final color = end.isBefore(store.now)
        ? c.danger
        : end.difference(store.now) <= const Duration(hours: 24)
            ? c.warning
            : c.accent;
    return Tooltip(
        message:
            '今日截止 · ${todo.name}\n${todo.course} · ${fmtDeadline(end, store.now)}',
        child: Container(
            decoration: BoxDecoration(
                color: color.withValues(alpha: c.dark ? .14 : .11),
                borderRadius: BorderRadius.circular(Paper.chipRadius)),
            child: PaperAction(
                borderRadius: Paper.chipRadius,
                onTap: () => openHomework(todo),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_outlined, size: 12, color: color),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(todo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PaperType.meta(context)
                              .copyWith(fontSize: 11.5, color: color))),
                  const SizedBox(width: 5),
                  Text(fmtTime(end),
                      style: PaperType.meta(context).copyWith(
                          fontSize: 11, color: color.withValues(alpha: .82)))
                ]))));
  }

  Widget _nowInline(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Text(fmtTime(store.now),
            style: PaperType.meta(context)
                .copyWith(color: PaperColors.of(context).danger)),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: PaperColors.of(context).danger))
      ]));

  Widget _inspectorRail(BuildContext context) {
    final c = PaperColors.of(context);
    final now = store.now;
    final todos = store.todos
        .where((t) =>
            t.endTime != null && calendarDaysBetween(now, t.endTime!) <= 7)
        .toList();
    final tomorrow =
        _tomorrowAgenda(DateTime(now.year, now.month, now.day + 1));
    final tomorrowShown = tomorrow.take(4).toList();

    return Container(
        color: c.rail,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Top inspector section: Homework due within 7 days.
          Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.hairline))),
              child: Row(children: [
                Text('待交作业', style: PaperType.cardTitle(context)),
                const SizedBox(width: 6),
                Text('7 天内',
                    style: PaperType.meta(context).copyWith(color: c.text3)),
                const Spacer(),
                PaperAction(
                    borderRadius: Paper.smallRadius,
                    onTap: () => onNavigate(DesktopPage.homework),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text('查看全部 →',
                        style: PaperType.meta(context)
                            .copyWith(fontSize: 11.5, color: c.accent)))
              ])),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 8, 8),
                  child: todos.isEmpty
                      ? const EmptyState('没有待交作业',
                          icon: Icons.check_circle_outline_rounded,
                          subtitle: '未来 7 天内暂无待提交作业')
                      : _TodayHomework(
                          todos: todos,
                          now: now,
                          onOpenAll: () => onNavigate(DesktopPage.homework)))),
          Container(height: 1, color: c.hairline),
          // Bottom inspector section: Tomorrow preview.
          Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Text('明天预告', style: PaperType.cardTitle(context)),
                      const Spacer(),
                      if (tomorrow.length > tomorrowShown.length)
                        PaperAction(
                            borderRadius: Paper.smallRadius,
                            onTap: () => onNavigate(DesktopPage.calendar),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text(
                                '还有 ${tomorrow.length - tomorrowShown.length} 项 →',
                                style: PaperType.meta(context).copyWith(
                                    fontSize: 11.5, color: c.accent)))
                    ]),
                    const SizedBox(height: 6),
                    if (tomorrowShown.isEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child:
                              Text('明天没有安排', style: PaperType.meta(context)))
                    else
                      for (final p in tomorrowShown) _compactRow(context, p),
                  ]))
        ]));
  }

  Widget _compactRow(BuildContext context, Period p) => Builder(
      builder: (context) => PaperAction(
          borderRadius: Paper.smallRadius,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          onTap: () {
            if (p.type == PeriodType.virtual) {
              openHomework(
                  store.todos.firstWhere((t) => 'homework-${t.id}' == p.uid));
            } else {
              showPeriodPopover(context, p);
            }
          },
          child: SizedBox(
              height: MediaQuery.textScalerOf(context).scale(28),
              child: Row(children: [
                SizedBox(
                    width: 44,
                    child: Text(fmtTime(p.startTime),
                        style: PaperType.meta(context)
                            .copyWith(color: PaperColors.of(context).text3))),
                Expanded(
                    child: Text(
                        '${p.summary}${p.location.isEmpty ? '' : ' · ${p.location}'}',
                        style: PaperType.meta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis))
              ]))));
}

/// Fill the summary viewport with complete rows and keep the hidden count visible.
class _TodayHomework extends StatelessWidget {
  const _TodayHomework(
      {required this.todos, required this.now, required this.onOpenAll});
  final List<Todo> todos;
  final DateTime now;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
        final row = homeworkRowHeightOf(context);
        final header = MediaQuery.textScalerOf(context).scale(28);
        final footer = MediaQuery.textScalerOf(context).scale(28);
        final groups = homeworkGroups(todos, now);
        final ends = <double>[];
        var extent = 0.0;
        for (final group in groups.values) {
          extent += header;
          for (final _ in group) {
            extent += row;
            ends.add(extent);
          }
        }
        final hidden = extent > bounds.maxHeight;
        final available = (bounds.maxHeight - (hidden ? footer : 0))
            .clamp(0.0, double.infinity);
        final complete = ends.where((end) => end <= available).length;
        final extra = complete > 0
            ? (available - ends[complete - 1]) / complete
            : 0.0;
        final children = <Widget>[];
        for (final group in groups.entries) {
          children.add(SizedBox(
              height: header,
              child: SectionLabel(
                  group.key == '已逾期'
                      ? '已逾期 ${group.value.length}'
                      : group.key,
                  danger: group.key == '已逾期')));
          for (final todo in group.value) {
            children.add(SizedBox(
                height: row + extra,
                child: Center(child: HomeworkRow(todo: todo, now: now))));
          }
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: ScrollArea(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children))),
          if (hidden)
            PaperAction(
                onTap: onOpenAll,
                child: SizedBox(
                    height: footer,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('还有 ${todos.length - complete} 项 →',
                            style: PaperType.meta(context)))))
        ]);
      });
}

/// Strictly time-proportional vertical timeline for today's scheduled items.
class _TodayTimeline extends StatefulWidget {
  const _TodayTimeline(
      {required this.day, required this.now, required this.periods});
  final DateTime day;
  final DateTime now;
  final List<Period> periods;
  @override
  State<_TodayTimeline> createState() => _TodayTimelineState();
}

class _TodayTimelineState extends State<_TodayTimeline> {
  final _scroll = ScrollController();
  String? _positionedRange;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final dayStart = widget.day;
    final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day + 1);
    final nowMinute = widget.now.hour * 60.0 +
        widget.now.minute +
        widget.now.second / 60.0;

    final entries = <_PlacedTodayPeriod>[];
    var earliestMin = nowMinute;
    var latestMin = nowMinute;
    for (final p in widget.periods) {
      final start = p.startTime.isBefore(dayStart) ? dayStart : p.startTime;
      final end = p.endTime.isAfter(dayEnd) ? dayEnd : p.endTime;
      if (!end.isAfter(start)) continue;
      final a = start.difference(dayStart).inMinutes.toDouble();
      final b = end.difference(dayStart).inMinutes.toDouble();
      earliestMin = math.min(earliestMin, a);
      latestMin = math.max(latestMin, b);
      entries.add(_PlacedTodayPeriod(p, a, b));
    }
    _placeTodayOverlaps(entries);

    var startHour = (earliestMin / 60).floor().clamp(0, 23);
    var endHour = (latestMin / 60).ceil().clamp(1, 24);
    if (endHour <= startHour) endHour = (startHour + 1).clamp(1, 24);
    while (endHour - startHour < 6 && (startHour > 0 || endHour < 24)) {
      if (endHour < 24) {
        endHour++;
      } else if (startHour > 0) {
        startHour--;
      }
    }

    const topPad = 14.0;
    const bottomPad = 14.0;
    final totalHours = endHour - startHour;

    return LayoutBuilder(builder: (context, bounds) {
      final usable =
          (bounds.maxHeight - topPad - bottomPad).clamp(0.0, double.infinity);
      final hourHeight =
          (usable / totalHours).clamp(44.0 * scale, 82.0 * scale);
      final gridHeight = totalHours * hourHeight + topPad + bottomPad;
      double yOf(double minute) =>
          topPad + (minute / 60 - startHour) * hourHeight;
      final nowY = yOf(nowMinute);

      final range =
          '${dayStart.toIso8601String()}|$startHour|$endHour|${bounds.maxHeight.round()}|$scale';
      if (_positionedRange != range) {
        _positionedRange = range;
        final ongoing = entries
            .where((e) => e.start <= nowMinute && e.end > nowMinute)
            .toList();
        double target;
        if (gridHeight <= bounds.maxHeight || nowY + 80 <= bounds.maxHeight) {
          target = 0;
        } else if (ongoing.isNotEmpty) {
          target = math.min(
              yOf(ongoing.first.start) - 20, nowY - bounds.maxHeight * 0.35);
        } else {
          target = nowY - bounds.maxHeight * 0.3;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scroll.hasClients) return;
          _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
        });
      }

      final gutter = _timelineGutter * scale;
      final gridWidth =
          (bounds.maxWidth - gutter - 8).clamp(1.0, double.infinity);

      return Scrollbar(
          controller: _scroll,
          child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(right: 8),
              children: [
                SizedBox(
                    height: gridHeight,
                    child: Stack(clipBehavior: Clip.none, children: [
                      for (var half = startHour * 2;
                          half <= endHour * 2;
                          half++)
                        Positioned(
                            top: topPad + (half / 2 - startHour) * hourHeight,
                            left: gutter,
                            right: 0,
                            child: Container(
                                height: 1,
                                color: half.isEven ? c.gridHour : c.gridHalf)),
                      for (var hour = startHour; hour <= endHour; hour++)
                        if ((topPad + (hour - startHour) * hourHeight - nowY)
                                .abs() >=
                            15 * scale)
                          Positioned(
                              top: topPad +
                                  (hour - startHour) * hourHeight -
                                  7.5 * scale,
                              left: 0,
                              width: gutter - 10,
                              child: Text('${two(hour)}:00',
                                  textAlign: TextAlign.right,
                                  style: PaperType.meta(context).copyWith(
                                      fontSize: 11.5, color: c.text3))),
                      for (final entry in entries)
                        () {
                          final rawTop = yOf(entry.start) + 1;
                          final rawHeight = math.max(22.0 * scale,
                              (entry.end - entry.start) / 60 * hourHeight - 2);
                          final colW = gridWidth / entry.columns;
                          final elapsedPx = (entry.start <= nowMinute &&
                                  entry.end > nowMinute)
                              ? (nowY - rawTop).clamp(0.0, rawHeight)
                              : null;
                          return Positioned(
                              top: rawTop,
                              left: gutter + colW * entry.column + 2,
                              width: math.max(1.0, colW - 4),
                              height: rawHeight,
                              child: _TimelineBlock(
                                  period: entry.period,
                                  now: widget.now,
                                  elapsedHeight: elapsedPx));
                        }(),
                      Positioned(
                          top: nowY - 9.5 * scale,
                          left: 0,
                          width: gutter - 8,
                          child: IgnorePointer(
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                          color: c.danger,
                                          borderRadius: BorderRadius.circular(
                                              Paper.chipRadius)),
                                      child: Text(fmtTime(widget.now),
                                          style: PaperType.base(
                                              context,
                                              11,
                                              FontWeight.w600,
                                              1.2,
                                              c.onAccent)))))),
                      Positioned(
                          top: nowY - 3,
                          left: gutter - 6,
                          right: 0,
                          child: IgnorePointer(
                              child: Row(children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: c.danger, shape: BoxShape.circle)),
                            Expanded(
                                child: Container(height: 1.5, color: c.danger))
                          ])))
                    ]))
              ]));
    });
  }
}

class _PlacedTodayPeriod {
  _PlacedTodayPeriod(this.period, this.start, this.end);
  final Period period;
  final double start, end;
  int column = 0, columns = 1;
}

void _placeTodayOverlaps(List<_PlacedTodayPeriod> entries) {
  entries.sort((a, b) {
    final s = a.start.compareTo(b.start);
    return s == 0 ? b.end.compareTo(a.end) : s;
  });
  var group = <_PlacedTodayPeriod>[];
  var ends = <double>[];
  var groupEnd = -1.0;
  void finish() {
    for (final item in group) {
      item.columns = ends.length;
    }
    group = [];
    ends = [];
  }

  for (final entry in entries) {
    if (entry.start >= groupEnd) finish();
    var column = ends.indexWhere((end) => end <= entry.start);
    if (column < 0) {
      column = ends.length;
      ends.add(entry.end);
    } else {
      ends[column] = entry.end;
    }
    entry.column = column;
    group.add(entry);
    groupEnd = math.max(groupEnd, entry.end);
  }
  finish();
}

String _fmtRemaining(Duration d) {
  final mins = d.inMinutes.clamp(1, 24 * 60);
  if (mins >= 60) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '剩 $h 小时' : '剩 $h 小时 $m 分';
  }
  return '剩 $mins 分钟';
}

class _TimelineBlock extends StatefulWidget {
  const _TimelineBlock(
      {required this.period, required this.now, this.elapsedHeight});
  final Period period;
  final DateTime now;
  final double? elapsedHeight;
  @override
  State<_TimelineBlock> createState() => _TimelineBlockState();
}

class _TimelineBlockState extends State<_TimelineBlock> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final period = widget.period;
    final c = PaperColors.of(context);
    final course = CourseColors(context, period.summary);
    final exam = period.type == PeriodType.test;
    final past = !period.endTime.isAfter(widget.now);
    final ongoing = !period.startTime.isAfter(widget.now) &&
        period.endTime.isAfter(widget.now);

    final rawBar = exam ? c.danger : course.bar;
    final bar = past ? rawBar.withValues(alpha: .42) : rawBar;
    final baseTint = exam
        ? Color.alphaBlend(
            c.danger.withValues(alpha: c.dark ? .18 : .11), c.canvas)
        : course.tint;
    final tint = past
        ? Color.alphaBlend(
            c.canvas.withValues(alpha: c.dark ? .44 : .48), baseTint)
        : baseTint;
    final fill = _hover
        ? Color.alphaBlend(c.text.withValues(alpha: .04), tint)
        : tint;
    final elapsedFill = Color.alphaBlend(
        c.canvas.withValues(alpha: c.dark ? .38 : .42), fill);
    final titleColor = past ? c.text2 : (exam ? c.danger : course.ink);
    final teacher =
        RegExp(r'教师[:：]\s*([^\n]+)').firstMatch(period.description)?.group(1);
    final meta = [
      if (period.location.isNotEmpty) period.location,
      if (teacher != null) teacher
    ].join(' · ');
    final rangeText = fmtRange(period.startTime, period.endTime);
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return Tooltip(
        message:
            '${exam ? '考试 · ' : ''}${period.summary}\n$rangeText${meta.isEmpty ? '' : ' · $meta'}',
        child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(Paper.smallRadius),
                    border: ongoing
                        ? Border.all(
                            color: rawBar.withValues(alpha: .42), width: 1)
                        : exam
                            ? Border.all(
                                color: c.danger.withValues(alpha: .30),
                                width: 1)
                            : _hover
                                ? Border.all(color: course.border, width: 1)
                                : null),
                child: Stack(children: [
                  if (widget.elapsedHeight != null &&
                      widget.elapsedHeight! > 0)
                    Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: widget.elapsedHeight,
                        child: Container(color: elapsedFill)),
                  Positioned(
                      left: 4,
                      top: 6,
                      bottom: 6,
                      child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                              color: bar,
                              borderRadius: BorderRadius.circular(1.5)))),
                  Positioned.fill(
                      child: Builder(
                          builder: (context) => PaperAction(
                              borderRadius: Paper.smallRadius,
                              onTap: () => showPeriodPopover(context, period),
                              child: LayoutBuilder(builder: (context, bounds) {
                                final h = bounds.maxHeight / scale;
                                final w = bounds.maxWidth;
                                final wide = w >= 220;
                                final vPad = h >= 68
                                    ? 8.0
                                    : h >= 38
                                        ? 4.0
                                        : 1.0;
                                final remainingText = ongoing
                                    ? _fmtRemaining(
                                        period.endTime.difference(widget.now))
                                    : null;
                                return ClipRect(
                                    child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            13, vPad, 10, vPad),
                                        child: h < 38
                                            ? Align(
                                                alignment: Alignment.centerLeft,
                                                child: Row(children: [
                                                  Expanded(
                                                      child: Text(
                                                          '${exam ? '考试 · ' : ''}${period.summary}${meta.isEmpty ? '' : ' · $meta'}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: PaperType.base(
                                                              context,
                                                              12.5,
                                                              FontWeight.w600,
                                                              1.2,
                                                              titleColor))),
                                                  if (wide) ...[
                                                    const SizedBox(width: 8),
                                                    Text(rangeText,
                                                        style: PaperType.meta(
                                                                context)
                                                            .copyWith(
                                                                fontSize: 12))
                                                  ]
                                                ]))
                                            : SingleChildScrollView(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Row(children: [
                                                        Expanded(
                                                            child: Text(
                                                                period.summary,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: PaperType.base(
                                                                    context,
                                                                    h >= 68
                                                                        ? 14
                                                                        : 13,
                                                                    FontWeight
                                                                        .w600,
                                                                    1.3,
                                                                    titleColor))),
                                                        if (exam) ...[
                                                          const SizedBox(
                                                              width: 6),
                                                          Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          5,
                                                                      vertical:
                                                                          1),
                                                              decoration: BoxDecoration(
                                                                  color: c.danger
                                                                      .withValues(
                                                                          alpha:
                                                                              .16),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          Paper
                                                                              .chipRadius)),
                                                              child: Text('考试',
                                                                  style: PaperType.meta(
                                                                          context)
                                                                      .copyWith(
                                                                          fontSize:
                                                                              11,
                                                                          color:
                                                                              c.danger)))
                                                        ],
                                                        if (wide) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          if (remainingText !=
                                                              null) ...[
                                                            Text(remainingText,
                                                                style: PaperType.base(
                                                                    context,
                                                                    12,
                                                                    FontWeight
                                                                        .w500,
                                                                    1.2,
                                                                    titleColor)),
                                                            Text(' · ',
                                                                style: PaperType
                                                                        .meta(
                                                                            context)
                                                                    .copyWith(
                                                                        fontSize:
                                                                            12))
                                                          ],
                                                          Text(rangeText,
                                                              style: PaperType
                                                                      .meta(
                                                                          context)
                                                                  .copyWith(
                                                                      fontSize:
                                                                          12))
                                                        ]
                                                      ]),
                                                      if (!wide)
                                                        Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 2),
                                                            child: Text(
                                                                remainingText ==
                                                                        null
                                                                    ? rangeText
                                                                    : '$rangeText · $remainingText',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: PaperType
                                                                        .meta(
                                                                            context)
                                                                    .copyWith(
                                                                        fontSize:
                                                                            12))),
                                                      if (meta.isNotEmpty)
                                                        Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: h >= 68
                                                                        ? 3
                                                                        : 1),
                                                            child: Text(meta,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: PaperType
                                                                        .meta(
                                                                            context)
                                                                    .copyWith(
                                                                        fontSize:
                                                                            12)))
                                                    ]))));
                              }))))
                ]))));
  }
}
