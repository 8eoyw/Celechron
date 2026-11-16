import 'package:flutter/material.dart';
import '../../model/period.dart';
import '../format.dart';
import '../store.dart';
import '../shell/navigation.dart';
import '../theme/tokens.dart';
import '../widgets/countdown.dart';
import '../widgets/course_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/homework_row.dart';
import '../widgets/homework_list.dart';
import '../widgets/list_row.dart';
import '../widgets/page_header.dart';
import '../widgets/popover.dart';
import '../widgets/scroll_area.dart';
import '../widgets/section_label.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.store, required this.onNavigate});
  final DesktopStore store;
  final ValueChanged<DesktopPage> onNavigate;
  List<Period> _agenda(DateTime day) => [
        ...store.agendaPeriodsOn(day).where(
            (p) => p.type != PeriodType.flow && p.type != PeriodType.virtual),
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
                ].join(' · ')),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 3, child: _left(context)),
              const SizedBox(width: 32),
              VerticalDivider(
                  width: 1, color: PaperColors.of(context).hairline),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: _right(context))
            ]));
      });
  Widget _left(BuildContext context) {
    final today = _agenda(store.now);
    final remaining = today.where((p) => !p.endTime.isBefore(store.now)).length;
    final tomorrow =
        _agenda(DateTime(store.now.year, store.now.month, store.now.day + 1));
    final children = <Widget>[];
    var inserted = false;
    for (final p in today) {
      if (!inserted && p.startTime.isAfter(store.now)) {
        children.add(_now(context));
        inserted = true;
      }
      children.add(_agendaRow(context, p));
    }
    if (!inserted) children.add(_now(context));
    return LayoutBuilder(builder: (context, bounds) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final tomorrowCount = remaining <= 3
          ? ((bounds.maxHeight - 160 * scale) / (32 * scale))
              .floor()
              .clamp(0, 4)
              .clamp(0, tomorrow.length)
          : 0;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionLabel('日程'),
        if (remaining == 0) ...[
          EmptyState(today.isEmpty ? '今天没有课' : '今天的课已结束'),
          _now(context),
        ] else
          Expanded(
              child: ScrollArea(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [...children]))),
        if (tomorrowCount > 0) ...[
          const SizedBox(height: 16),
          const SectionLabel('明天'),
          for (final p in tomorrow.take(tomorrowCount)) _compactRow(context, p),
          if (tomorrow.length > tomorrowCount)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                    onPressed: () => onNavigate(DesktopPage.calendar),
                    child: Text('还有 ${tomorrow.length - tomorrowCount} 项')))
        ]
      ]);
    });
  }

  Widget _now(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Text(fmtTime(store.now),
            style: PaperType.meta(context)
                .copyWith(color: PaperColors.of(context).danger)),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: PaperColors.of(context).danger))
      ]));
  Widget _agendaRow(BuildContext context, Period period) {
    final c = PaperColors.of(context);
    final colors = CourseColors(context, period.summary);
    final past = period.endTime.isBefore(store.now);
    final ongoing = !period.startTime.isAfter(store.now) &&
        period.endTime.isAfter(store.now);
    final homework = period.type == PeriodType.virtual;
    final teacher =
        RegExp(r'教师[:：]\s*([^\n]+)').firstMatch(period.description)?.group(1);
    final meta = [
      if (period.location.isNotEmpty) period.location,
      if (teacher != null) teacher
    ].join(' · ');
    return Builder(
        builder: (context) => PaperAction(
            onTap: () {
              if (homework) {
                final t = store.todos
                    .firstWhere((t) => 'homework-${t.id}' == period.uid);
                openHomework(t);
              } else {
                showPeriodPopover(context, period);
              }
            },
            child: Container(
                height: MediaQuery.textScalerOf(context).scale(64),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                    color: ongoing ? colors.tint : null,
                    borderRadius: BorderRadius.circular(6)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                          width: 56,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(fmtTime(period.startTime),
                                    style: PaperType.strong(context).copyWith(
                                        color: past ? c.text2 : null)),
                                if (!homework)
                                  Text(fmtTime(period.endTime),
                                      style: PaperType.meta(context))
                              ])),
                      if (homework)
                        const Center(
                            child: Icon(Icons.circle_outlined, size: 13))
                      else
                        Container(
                            width: 3,
                            decoration: BoxDecoration(
                                color: period.type == PeriodType.test
                                    ? c.danger
                                    : colors.bar
                                        .withValues(alpha: past ? .4 : 1),
                                borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(
                                  child: Text(period.summary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PaperType.strong(context).copyWith(
                                          color: past ? c.text2 : null))),
                              if (period.type == PeriodType.test)
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    color: c.accentSoft,
                                    child: Text('考试',
                                        style: PaperType.meta(context)
                                            .copyWith(color: c.danger)))
                            ]),
                            if (meta.isNotEmpty)
                              Text(meta,
                                  style: PaperType.meta(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                          ]))
                    ]))));
  }

  Widget _compactRow(BuildContext context, Period p) => Builder(
      builder: (context) => PaperAction(
          onTap: () {
            if (p.type == PeriodType.virtual) {
              openHomework(
                  store.todos.firstWhere((t) => 'homework-${t.id}' == p.uid));
            } else {
              showPeriodPopover(context, p);
            }
          },
          child: SizedBox(
              height: MediaQuery.textScalerOf(context).scale(32),
              child: Row(children: [
                SizedBox(
                    width: 56,
                    child: Text(fmtTime(p.startTime),
                        style: PaperType.meta(context))),
                Expanded(
                    child: Text(
                        '${p.summary}${p.location.isEmpty ? '' : ' · ${p.location}'}',
                        style: PaperType.meta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis))
              ]))));
  Widget _right(BuildContext context) {
    final todos = store.todos
        .where((t) =>
            t.endTime != null &&
            calendarDaysBetween(store.now, t.endTime!) <= 7)
        .toList();
    final exams = store.upcomingExams.take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('作业 · 7 天内',
          trailing: PaperAction(
              onTap: () => onNavigate(DesktopPage.homework),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text('查看全部 →', style: PaperType.meta(context)))),
      Expanded(
          child: todos.isEmpty
              ? const Align(
                  alignment: Alignment.topLeft, child: EmptyState('没有待交作业'))
              : HomeworkList(
                  todos: todos, now: store.now, showOverdueCount: true)),
      if (exams.isNotEmpty) ...[
        const SizedBox(height: 16),
        const SectionLabel('考试'),
        for (final e in exams)
          PaperAction(
              onTap: () => onNavigate(DesktopPage.exams),
              child: SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(68),
                  child: Row(children: [
                    SizedBox(
                        width: 76,
                        child: CountdownText(
                            target: e.start, now: store.now, exam: true)),
                    Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(e.exam.name,
                              style: PaperType.strong(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                              '${fmtDate(e.start)} ${fmtRange(e.start, e.end)}${e.exam.location == null ? '' : ' · ${e.exam.location}'}',
                              style: PaperType.meta(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                        ]))
                  ])))
      ],
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: Text(
                '学业   五分制 ${store.maskGpa(store.gpa[0].toStringAsFixed(2))} · 四分制 ${store.maskGpa(store.gpa[1].toStringAsFixed(2))} · 学分 ${store.earnedCredit.toStringAsFixed(0)}',
                style: PaperType.meta(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        PaperIconButton(
            icon: store.gpaHidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            tooltip: '显示或隐藏 GPA',
            onPressed: store.toggleGpaHidden)
      ])
    ]);
  }
}
