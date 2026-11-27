import 'package:flutter/material.dart';
import '../../model/exam.dart';
import '../format.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/course_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/scroll_area.dart';
import '../widgets/section_label.dart';
import '../widgets/semester_dropdown.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key, required this.store});
  final DesktopStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final semester = store.selectedSemester;
        final exams =
            semester == null ? <ExamEntry>[] : store.examsOf(semester);
        final upcoming = exams.where((e) => e.end.isAfter(store.now)).toList();
        final past = exams.where((e) => !e.end.isAfter(store.now)).toList()
          ..sort((a, b) => b.start.compareTo(a.start));
        return PaperPage(
            store: store,
            header: PageHeader(
                title: '考试',
                subtitle: '${semester?.name ?? '暂无学期'} · ${exams.length} 场',
                actions: [SemesterDropdown(store: store)]),
            padding: const EdgeInsets.fromLTRB(28, 12, 20, 16),
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: exams.isEmpty
                        ? const EmptyState('暂无考试安排',
                            icon: Icons.event_note_outlined,
                            subtitle: '本学期尚未公布考试时间表')
                        : ScrollArea(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                for (final exam in upcoming)
                                  _ExamRow(entry: exam, now: store.now),
                                if (past.isNotEmpty) ...[
                                  if (upcoming.isNotEmpty)
                                    const SizedBox(height: 24),
                                  const SectionLabel('已结束'),
                                  for (final exam in past)
                                    _ExamRow(
                                        entry: exam, now: store.now, past: true)
                                ]
                              ])))));
      });
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({required this.entry, required this.now, this.past = false});
  final ExamEntry entry;
  final DateTime now;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    final course = CourseColors(context, entry.exam.name);
    final days = calendarDaysBetween(now, entry.start);
    final countdownColor = past
        ? c.text2
        : days <= 1
            ? c.danger
            : days <= 3
                ? c.warning
                : c.text2;
    final detail = [
      '${fmtDate(entry.start)} ${fmtRange(entry.start, entry.end)}',
      if (entry.start.year != now.year) '${entry.start.year}年',
      if (entry.exam.location?.isNotEmpty ?? false) entry.exam.location!,
      if (entry.exam.seat?.isNotEmpty ?? false) '座位 ${entry.exam.seat}'
    ].join(' · ');
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return Tooltip(
        message: '${entry.exam.name}\n$detail',
        child: Container(
            constraints: BoxConstraints(minHeight: 72 * scale),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.hairline))),
            child: Row(children: [
              Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                      color: past ? c.surfaceElevated : course.tint,
                      border: Border.all(
                          color: past ? c.hairline : course.border),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${entry.start.day}',
                            style: PaperType.h2(context)
                                .copyWith(color: past ? c.text2 : course.ink)),
                        Text('${entry.start.month}月',
                            style: PaperType.meta(context))
                      ])),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Flexible(
                          child: Text(entry.exam.name,
                              style: PaperType.strong(context)
                                  .copyWith(color: past ? c.text2 : c.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: c.glassControl,
                              border: Border.all(color: c.hairlineStrong),
                              borderRadius:
                                  BorderRadius.circular(Paper.chipRadius)),
                          child: Text(
                              entry.exam.type == ExamType.midterm ? '期中' : '期末',
                              style: PaperType.meta(context)
                                  .copyWith(fontSize: 11)))
                    ]),
                    const SizedBox(height: 4),
                    Text(detail,
                        style: PaperType.meta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  ])),
              const SizedBox(width: 16),
              Text(
                  past
                      ? '已结束'
                      : days < 0
                          ? '进行中'
                          : examCountdown(entry.start, now),
                  style:
                      PaperType.strong(context).copyWith(color: countdownColor))
            ])));
  }
}
