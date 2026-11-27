import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../model/period.dart';
import '../../format.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/course_colors.dart';
import '../../widgets/list_row.dart';

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView(
      {super.key,
      required this.month,
      required this.store,
      required this.onOpenDay});
  final DateTime month;
  final DesktopStore store;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final first = DesktopStore.mondayOf(DateTime(month.year, month.month));
    final colors = PaperColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(children: [
      SizedBox(
          height: 32 * scale,
          child: Row(children: [
            for (var i = 1; i <= 7; i++)
              Expanded(
                  child: Center(
                      child:
                          Text(weekdayName(i), style: PaperType.meta(context))))
          ])),
      Expanded(
          child: Column(children: [
        for (var week = 0; week < 6; week++)
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(child: Builder(builder: (context) {
                    final day = DateTime(first.year, first.month,
                        first.day + week * 7 + weekday);
                    return Container(
                        decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: colors.hairline),
                                left: weekday == 0
                                    ? BorderSide.none
                                    : BorderSide(color: colors.hairline))),
                        child: _MonthCell(
                            day: day,
                            inMonth: day.month == month.month,
                            store: store,
                            onOpen: () => onOpenDay(day)));
                  }))
              ]))
      ]))
    ]);
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell(
      {required this.day,
      required this.inMonth,
      required this.store,
      required this.onOpen});
  final DateTime day;
  final bool inMonth;
  final DesktopStore store;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = PaperColors.of(context);
    final today = calendarDaysBetween(day, store.now) == 0;
    final special = store.specialDateOf(day);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final items = <_MonthItem>[
      for (final p in store
          .agendaPeriodsOn(day)
          .where((p) => p.type != PeriodType.virtual))
        _MonthItem(
            p.startTime,
            '${fmtTime(p.startTime)} ${p.summary}',
            p.type == PeriodType.test
                ? colors.danger
                : CourseColors(context, p.summary).bar,
            exam: p.type == PeriodType.test),
      for (final todo in store.todosOn(day))
        _MonthItem(todo.endTime!, todo.name, colors.accent,
            deadline: true,
            detail: '${todo.course} · ${fmtDeadline(todo.endTime!, store.now)}')
    ]..sort((a, b) => a.time.compareTo(b.time));
    return PaperAction(
        onTap: onOpen,
        tooltip: '${fmtDate(day)} · 打开周日程',
        padding: const EdgeInsets.all(6),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              height: 26 * scale,
              child: Row(children: [
                Container(
                    width: 26 * scale,
                    height: 26 * scale,
                    alignment: Alignment.center,
                    decoration: today
                        ? BoxDecoration(
                            color: colors.accent, shape: BoxShape.circle)
                        : null,
                    child: Text('${day.day}',
                        style: PaperType.meta(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: today
                                ? colors.onAccent
                                : inMonth
                                    ? colors.text
                                    : colors.text3))),
                if (special != null)
                  Expanded(
                      child: Text(special,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              PaperType.meta(context).copyWith(fontSize: 10.5)))
              ])),
          Expanded(child: LayoutBuilder(builder: (context, bounds) {
            final lineHeight = 19.0 * scale;
            final capacity =
                math.max(0, (bounds.maxHeight / lineHeight).floor());
            final shown = math.min(
                3,
                math.min(
                    items.length,
                    items.length > math.min(3, capacity)
                        ? math.max(0, capacity - 1)
                        : capacity));
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items.take(shown))
                    SizedBox(
                        height: lineHeight,
                        child: Tooltip(
                            message:
                                '${item.exam ? '考试 · ' : ''}${item.label}${item.detail.isEmpty ? '' : '\n${item.detail}'}',
                            child: Row(children: [
                              if (item.deadline) ...[
                                Icon(Icons.edit_outlined,
                                    size: 12, color: colors.accent),
                                const SizedBox(width: 3)
                              ] else ...[
                                Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: item.color,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 4)
                              ],
                              Expanded(
                                  child: Text(
                                      '${item.exam ? '考试 ' : ''}${item.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PaperType.meta(context).copyWith(
                                          fontSize: 11.5,
                                          color: item.deadline || item.exam
                                              ? item.color
                                              : colors.text2)))
                            ]))),
                  if (items.length > shown && capacity > shown)
                    SizedBox(
                        height: lineHeight,
                        child: Text('+${items.length - shown}',
                            style: PaperType.meta(context)
                                .copyWith(fontSize: 11.5)))
                ]);
          }))
        ]));
  }
}

class _MonthItem {
  const _MonthItem(this.time, this.label, this.color,
      {this.deadline = false, this.exam = false, this.detail = ''});
  final DateTime time;
  final String label, detail;
  final Color color;
  final bool deadline, exam;
}
