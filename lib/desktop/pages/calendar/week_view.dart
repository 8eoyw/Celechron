import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../model/period.dart';
import '../../../model/todo.dart';
import '../../format.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/course_colors.dart';
import '../../widgets/homework_row.dart';
import '../../widgets/list_row.dart';
import '../../widgets/popover.dart';

const _gutterBase = 56.0;
const _topPad = 10.0;

class CalendarWeekView extends StatefulWidget {
  const CalendarWeekView(
      {super.key, required this.monday, required this.store});
  final DateTime monday;
  final DesktopStore store;
  @override
  State<CalendarWeekView> createState() => _CalendarWeekViewState();
}

class _CalendarWeekViewState extends State<CalendarWeekView> {
  final _scroll = ScrollController();
  String? _positionedRange;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final colors = PaperColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(widget.monday.year, widget.monday.month, widget.monday.day + i)
    ];
    final periods = [
      for (final day in days)
        store
            .agendaPeriodsOn(day)
            .where((p) => p.type != PeriodType.virtual)
            .toList()
    ];
    final deadlines = [for (final day in days) store.todosOn(day)];
    final deadlineRows = deadlines.fold<int>(
        0, (n, items) => math.max(n, math.min(items.length, 2)));
    var firstMinute = 8 * 60;
    var lastMinute = 18 * 60;
    final entries = <List<_PlacedPeriod>>[];
    for (var i = 0; i < 7; i++) {
      final day = days[i];
      final next = DateTime(day.year, day.month, day.day + 1);
      final dayEntries = <_PlacedPeriod>[];
      for (final p in periods[i]) {
        final start = p.startTime.isBefore(day) ? day : p.startTime;
        final end = p.endTime.isAfter(next) ? next : p.endTime;
        if (!end.isAfter(start)) continue;
        final a = start.difference(day).inMinutes.toDouble();
        final b = end.difference(day).inMinutes.toDouble();
        firstMinute = math.min(firstMinute, a.floor());
        lastMinute = math.max(lastMinute, b.ceil() + 30);
        dayEntries.add(_PlacedPeriod(p, a, b));
      }
      _placeOverlaps(dayEntries);
      entries.add(dayEntries);
    }
    final startHour = (firstMinute / 60).floor().clamp(0, 8);
    final endHour = (lastMinute / 60).ceil().clamp(18, 24);
    final gutter = _gutterBase * scale;
    final headerHeight = 60.0 * scale;
    final laneHeight =
        deadlineRows == 0 ? 0.0 : deadlineRows * 26.0 * scale + 8;
    return Column(children: [
      SizedBox(
          height: headerHeight,
          child: Row(children: [
            SizedBox(width: gutter),
            for (final day in days) Expanded(child: _dayHeader(context, day))
          ])),
      if (deadlineRows > 0)
        SizedBox(
            height: laneHeight,
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                  width: gutter,
                  child: Center(
                      child: Text('截止', style: PaperType.meta(context)))),
              for (var i = 0; i < 7; i++)
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: _todayFill(context, days[i]),
                            border: Border(
                                left: BorderSide(color: colors.hairline))),
                        child: Column(children: [
                          for (var j = 0;
                              j < math.min(2, deadlines[i].length);
                              j++)
                            SizedBox(
                                height: 26 * scale,
                                child: Row(children: [
                                  Expanded(
                                      child: _deadlineChip(
                                          context, deadlines[i][j])),
                                  if (j == 1 && deadlines[i].length > 2)
                                    _moreDeadlines(context, deadlines[i])
                                ]))
                        ])))
            ])),
      Expanded(child: LayoutBuilder(builder: (context, bounds) {
        final hourHeight = math.max(
            44.0 * scale, (bounds.maxHeight - _topPad * 2) / (endHour - startHour));
        final gridHeight = (endHour - startHour) * hourHeight + _topPad * 2;
        final range =
            '${widget.monday}|$startHour|$endHour|${bounds.maxHeight}|$scale';
        if (_positionedRange != range) {
          _positionedRange = range;
          final today = days
              .indexWhere((day) => calendarDaysBetween(day, store.now) == 0);
          // 先从本周最早的一节课开始显示；只有「现在」会因此落在可视区外时才改为对准现在
          final starts = entries.expand((day) => day).map((e) => e.start);
          final earliest = starts.isEmpty
              ? startHour * 60.0
              : starts.reduce((a, b) => a < b ? a : b);
          final nowMinute = store.now.hour * 60.0 + store.now.minute;
          final nowVisible = today >= 0 &&
              nowMinute >= startHour * 60 &&
              nowMinute <= endHour * 60;
          double top(double m) => _topPad + (m / 60 - startHour) * hourHeight;
          final fromEarliest = top(earliest) - 8;
          final minute = !nowVisible ||
                  top(nowMinute) - fromEarliest < bounds.maxHeight - 60
              ? null
              : nowMinute;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scroll.hasClients) return;
            final target =
                minute == null ? fromEarliest : top(minute) - 60;
            _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
          });
        }
        return Scrollbar(
            controller: _scroll,
            child: ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                      height: gridHeight,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                                width: gutter,
                                child: Stack(children: [
                                  for (var hour = startHour;
                                      hour <= endHour;
                                      hour++)
                                    Positioned(
                                        top: _topPad +
                                            (hour - startHour) * hourHeight -
                                            7.5 * scale,
                                        left: 0,
                                        width: gutter - 8,
                                        child: Text('${two(hour)}:00',
                                            textAlign: TextAlign.right,
                                            style: PaperType.meta(context)
                                                .copyWith(fontSize: 11.5)))
                                ])),
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                  child: _dayGrid(context, days[i], entries[i],
                                      startHour, endHour, hourHeight))
                          ]))
                ]));
      }))
    ]);
  }

  Color? _todayFill(BuildContext context, DateTime day) =>
      calendarDaysBetween(day, widget.store.now) == 0
          ? Color.alphaBlend(
              PaperColors.of(context).accent.withValues(alpha: .04),
              PaperColors.of(context).canvas)
          : null;

  Widget _dayHeader(BuildContext context, DateTime day) {
    final colors = PaperColors.of(context);
    final today = calendarDaysBetween(day, widget.store.now) == 0;
    final special = widget.store.specialDateOf(day);
    return Container(
        decoration: BoxDecoration(
            color: _todayFill(context, day),
            border: Border(left: BorderSide(color: colors.hairline))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(weekdayName(day.weekday), style: PaperType.meta(context)),
            const SizedBox(width: 4),
            Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: today
                    ? BoxDecoration(
                        color: colors.accent, shape: BoxShape.circle)
                    : null,
                child: Text('${day.day}',
                    style: PaperType.h2(context)
                        .copyWith(color: today ? colors.onAccent : null)))
          ]),
          if (special != null)
            Text(special,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PaperType.meta(context).copyWith(fontSize: 10.5))
        ]));
  }

  Widget _deadlineChip(BuildContext context, Todo todo) => Tooltip(
      message:
          '${todo.name}\n${todo.course} · ${fmtDeadline(todo.endTime!, widget.store.now)}',
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
              color: PaperColors.of(context).accentSoft,
              borderRadius: BorderRadius.circular(Paper.chipRadius)),
          child: PaperAction(
              borderRadius: Paper.chipRadius,
              onTap: () => openHomework(todo),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(children: [
                Icon(Icons.edit_outlined,
                    size: 12, color: PaperColors.of(context).accent),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(todo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PaperType.meta(context).copyWith(
                            fontSize: 11.5,
                            color: PaperColors.of(context).accent)))
              ]))));

  Widget _moreDeadlines(BuildContext context, List<Todo> todos) => Builder(
      builder: (context) => PaperAction(
          tooltip: todos.skip(2).map((t) => t.name).join('\n'),
          onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                      title: const Text('截止作业'),
                      content: SizedBox(
                          width: 360,
                          child: ListView(shrinkWrap: true, children: [
                            for (final todo in todos)
                              ListTile(
                                  title: Text(todo.name),
                                  subtitle: Text(
                                      '${todo.course} · ${fmtDeadline(todo.endTime!, widget.store.now)}'),
                                  onTap: () => openHomework(todo))
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'))
                      ])),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('+${todos.length - 2}', style: PaperType.meta(context))));

  Widget _dayGrid(
      BuildContext context,
      DateTime day,
      List<_PlacedPeriod> entries,
      int startHour,
      int endHour,
      double hourHeight) {
    final colors = PaperColors.of(context);
    final now = widget.store.now;
    final nowMinute = now.hour * 60 + now.minute;
    final showNow = calendarDaysBetween(day, now) == 0 &&
        nowMinute >= startHour * 60 &&
        nowMinute <= endHour * 60;
    return Container(
        decoration: BoxDecoration(
            color: _todayFill(context, day),
            border: Border(left: BorderSide(color: colors.hairline))),
        child: LayoutBuilder(
            builder: (context, bounds) => Stack(children: [
                  for (var half = startHour * 2; half <= endHour * 2; half++)
                    Positioned(
                        top: _topPad + (half / 2 - startHour) * hourHeight,
                        left: 0,
                        right: 0,
                        child: Container(
                            height: 1,
                            color: half.isEven
                                ? colors.gridHour
                                : colors.gridHalf)),
                  for (final entry in entries)
                    Positioned(
                        top: _topPad +
                            (entry.start / 60 - startHour) * hourHeight +
                            1,
                        left:
                            bounds.maxWidth * entry.column / entry.columns + 2,
                        width: math.max(1, bounds.maxWidth / entry.columns - 4),
                        height: math.max(
                            1, (entry.end - entry.start) / 60 * hourHeight - 2),
                        child: _EventBlock(period: entry.period)),
                  if (showNow)
                    Positioned(
                        top: _topPad + (nowMinute / 60 - startHour) * hourHeight - 3,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                            child: Row(children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: colors.danger,
                                  shape: BoxShape.circle)),
                          Expanded(
                              child:
                                  Container(height: 1.5, color: colors.danger))
                        ])))
                ])));
  }
}

class _PlacedPeriod {
  _PlacedPeriod(this.period, this.start, this.end);
  final Period period;
  final double start, end;
  int column = 0, columns = 1;
}

// Interval partitioning: every connected overlap group shares a column count.
void _placeOverlaps(List<_PlacedPeriod> entries) {
  entries.sort((a, b) {
    final start = a.start.compareTo(b.start);
    return start == 0 ? b.end.compareTo(a.end) : start;
  });
  var group = <_PlacedPeriod>[];
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

class _EventBlock extends StatefulWidget {
  const _EventBlock({required this.period});
  final Period period;
  @override
  State<_EventBlock> createState() => _EventBlockState();
}

class _EventBlockState extends State<_EventBlock> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final period = widget.period;
    final colors = PaperColors.of(context);
    final course = CourseColors(context, period.summary);
    final exam = period.type == PeriodType.test;
    final bar = exam ? colors.danger : course.bar;
    final tint = exam
        ? Color.alphaBlend(
            colors.danger.withValues(alpha: colors.dark ? .20 : .11),
            colors.surface)
        : course.tint;
    final ink = exam ? colors.danger : course.ink;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Tooltip(
        message:
            '${exam ? '考试 · ' : ''}${period.summary}\n${fmtRange(period.startTime, period.endTime)} · ${period.location}',
        child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: _hover
                        ? Color.alphaBlend(
                            colors.text.withValues(alpha: .04), tint)
                        : tint,
                    borderRadius: BorderRadius.circular(Paper.smallRadius),
                    border: exam
                        ? Border.all(
                            color: colors.danger.withValues(alpha: .32),
                            width: 1)
                        : _hover
                            ? Border.all(color: course.border, width: 1)
                            : null),
                child: Stack(children: [
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
                              borderRadius: 8,
                              onTap: () => showPeriodPopover(context, period),
                              child: LayoutBuilder(builder: (context, bounds) {
                                final h = bounds.maxHeight / scale;
                                final padding = h >= 64
                                    ? 6.0
                                    : h >= 36
                                        ? 4.0
                                        : 0.0;
                                final tall = h >= 64;
                                final medium = h >= 40;
                                final titleLines = h >= 84 ? 2 : 1;
                                return ClipRect(
                                    child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            11, padding, 6, padding),
                                        child: SingleChildScrollView(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      '${exam ? '考试 · ' : ''}${period.summary}',
                                                      maxLines: titleLines,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: PaperType.base(
                                                          context,
                                                          13,
                                                          FontWeight.w600,
                                                          1.2,
                                                          ink)),
                                                  if (tall) ...[
                                                    Text(
                                                        fmtRange(
                                                            period.startTime,
                                                            period.endTime),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: PaperType.meta(
                                                                context)
                                                            .copyWith(
                                                                fontSize:
                                                                    11.5)),
                                                    if (period
                                                        .location.isNotEmpty)
                                                      Text(period.location,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: PaperType.meta(
                                                                  context)
                                                              .copyWith(
                                                                  fontSize:
                                                                      11.5))
                                                  ] else if (medium)
                                                    Text(
                                                        '${fmtRange(period.startTime, period.endTime)}${period.location.isEmpty ? '' : ' · ${period.location}'}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: PaperType.meta(
                                                                context)
                                                            .copyWith(
                                                                fontSize: 11.5))
                                                ]))));
                              }))))
                ]))));
  }
}
