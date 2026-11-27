import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:celechron/model/exam.dart';
import 'package:celechron/model/grade.dart';
import 'package:celechron/model/semester.dart';
import '../../format.dart';
import '../../state/desktop_controller.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common_ui.dart';
import '../../widgets/course_palette.dart';

/// Unified semester-scoped Academics workspace:
/// Shared Semester picker + segmented switch between Exams, Grades & GPA, and Class Hours.
class AcademicsPage extends StatelessWidget {
  const AcademicsPage({
    super.key,
    required this.store,
    required this.controller,
  });

  final DesktopStore store;
  final DesktopController controller;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final tab = controller.academicsTab;
    final semester = store.selectedSemester;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Contextual bar: Title + Semester Picker + Segmented Tab
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Row(
            children: [
              Text('学业', style: DesktopType.title(context).copyWith(fontSize: 17)),
              const SizedBox(width: 12),
              if (store.semesters.isNotEmpty) _SemesterPicker(store: store),
              const Spacer(),
              if (tab == AcademicsTab.grades) ...[
                DesktopAction(
                  onTap: store.toggleGpaHidden,
                  tooltip: store.gpaHidden ? '显示绩点与分数' : '隐私模式：隐藏绩点与分数',
                  borderColor: c.hairline,
                  borderRadius: DesktopRadius.chip,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        store.gpaHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 15,
                        color: store.gpaHidden ? c.primary : c.text2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.gpaHidden ? '已隐藏' : '隐藏绩点',
                        style: DesktopType.meta(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              DesktopSegmented<AcademicsTab>(
                compact: true,
                items: const {
                  AcademicsTab.exams: '考试',
                  AcademicsTab.grades: '成绩',
                  AcademicsTab.hours: '课时',
                },
                value: tab,
                onChanged: controller.setAcademicsTab,
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: store.initialLoading
              ? const LoadingSkeleton()
              : switch (tab) {
                  AcademicsTab.exams => _ExamsView(
                      store: store,
                      controller: controller,
                      semester: semester,
                    ),
                  AcademicsTab.grades => _GradesView(
                      store: store,
                      controller: controller,
                      semester: semester,
                    ),
                  AcademicsTab.hours => _HoursView(
                      store: store,
                      controller: controller,
                      semester: semester,
                    ),
                },
        ),
      ],
    );
  }
}

class _SemesterPicker extends StatelessWidget {
  const _SemesterPicker({required this.store});
  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final semesters = store.semesters;
    final current = store.selectedSemester;
    return PopupMenuButton<int>(
      tooltip: '切换学期',
      color: c.sheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopRadius.popover),
        side: BorderSide(color: c.hairline),
      ),
      onSelected: store.selectSemester,
      itemBuilder: (context) => [
        for (var i = 0; i < semesters.length; i++)
          PopupMenuItem<int>(
            value: i,
            height: 36,
            child: Row(
              children: [
                if (i == store.selectedSemesterIndex)
                  Icon(Icons.check_rounded, size: 15, color: c.primary)
                else
                  const SizedBox(width: 15),
                const SizedBox(width: 6),
                Text(semesters[i].name,
                    style: DesktopType.body(context, numeric: true)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.surfaceLow,
          borderRadius: BorderRadius.circular(DesktopRadius.chip),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current?.name ?? '选择学期',
              style: DesktopType.meta(context, numeric: true)
                  .copyWith(color: c.text1, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: c.text2),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Exams Tab ─────────────────────────

class _ExamsView extends StatelessWidget {
  const _ExamsView({
    required this.store,
    required this.controller,
    required this.semester,
  });

  final DesktopStore store;
  final DesktopController controller;
  final Semester? semester;

  @override
  Widget build(BuildContext context) {
    final entries = semester == null ? <ExamEntry>[] : store.examsOf(semester!);
    final upcoming = entries.where((e) => e.end.isAfter(store.now)).toList();
    final past = entries.where((e) => !e.end.isAfter(store.now)).toList();

    if (entries.isEmpty) {
      return const EmptyStateView(
        title: '本学期暂无考试安排',
        subtitle: '教务网公布考场与座位信息后会自动同步',
        icon: Icons.event_note_outlined,
      );
    }

    return DesktopScrollArea(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (upcoming.isNotEmpty) ...[
            SectionHeading(
              '即将开考',
              trailing: Text(
                '${upcoming.length} 场',
                style: DesktopType.caption(context, numeric: true),
              ),
            ),
            for (final entry in upcoming) ...[
              _ExamRow(
                entry: entry,
                now: store.now,
                upcoming: true,
                onTap: () => controller.inspect(ExamInspectorTarget(entry)),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],
          if (past.isNotEmpty) ...[
            SectionHeading(
              '已结束',
              trailing: Text(
                '${past.length} 场',
                style: DesktopType.caption(context, numeric: true),
              ),
            ),
            for (final entry in past) ...[
              _ExamRow(
                entry: entry,
                now: store.now,
                upcoming: false,
                onTap: () => controller.inspect(ExamInspectorTarget(entry)),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({
    required this.entry,
    required this.now,
    required this.upcoming,
    required this.onTap,
  });

  final ExamEntry entry;
  final DateTime now;
  final bool upcoming;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final exam = entry.exam;
    final swatch = CoursePalette.of(context, exam.name);
    final isMidterm = exam.type == ExamType.midterm;
    final days = calendarDaysBetween(now, entry.start);
    final urgent = upcoming && days <= 7;

    return DesktopAction(
      onTap: onTap,
      backgroundColor: c.surfaceLow,
      borderColor: urgent ? c.warning.withValues(alpha: 0.45) : c.hairline,
      borderRadius: DesktopRadius.card,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Opacity(
        opacity: upcoming ? 1.0 : 0.65,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: upcoming ? swatch.bar : c.text3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          exam.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesktopType.strong(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConcentricTag(
                        label: isMidterm ? '期中' : '期末',
                        foreground: isMidterm ? c.warning : c.text2,
                        background: isMidterm ? c.warningFill : c.surfaceHigh,
                        radius: DesktopRadius.tag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '${fmtDate(entry.start)} ${fmtRange(entry.start, entry.end)}',
                      if ((exam.location ?? '').isNotEmpty) exam.location!,
                      if ((exam.seat ?? '').isNotEmpty) '座位 ${exam.seat}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesktopType.meta(context, numeric: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (upcoming)
              ConcentricTag(
                label: examCountdown(entry.start, now),
                foreground: urgent ? c.warning : c.primary,
                background: urgent ? c.warningFill : c.selectedFill,
                radius: DesktopRadius.badge,
                numeric: true,
              )
            else
              const ConcentricTag(
                label: '已结束',
                radius: DesktopRadius.badge,
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Grades & GPA Tab ─────────────────────────

class _GradesView extends StatelessWidget {
  const _GradesView({
    required this.store,
    required this.controller,
    required this.semester,
  });

  final DesktopStore store;
  final DesktopController controller;
  final Semester? semester;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final gpa = store.gpa;
    final grades = semester == null ? <Grade>[] : store.gradesOf(semester!);

    return DesktopScrollArea(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall GPA KPI Strip
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiCard(
                label: '总均绩（五分制）',
                value: store.maskGpa(gpa[0].toStringAsFixed(2)),
                highlight: true,
              ),
              _KpiCard(
                label: '四分制（4.3）',
                value: store.maskGpa(gpa[1].toStringAsFixed(2)),
              ),
              _KpiCard(
                label: '主修均绩',
                value: store.maskGpa(store.majorGpa.toStringAsFixed(2)),
                sub: '${store.majorCredit.toStringAsFixed(1)} 学分',
              ),
              _KpiCard(
                label: '已获学分',
                value: store.earnedCredit.toStringAsFixed(1),
                sub: '百分制 ${store.maskGpa(gpa[3].toStringAsFixed(1))}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Selected Semester section
          if (semester != null) ...[
            SectionHeading(
              '${semester!.name} 成绩明细',
              trailing: grades.isEmpty
                  ? null
                  : Text(
                      '学期均绩 ${store.maskGpa(semester!.gpa[0].toStringAsFixed(2))} · ${semester!.credits.toStringAsFixed(1)} 学分',
                      style: DesktopType.meta(context, numeric: true),
                    ),
            ),
          ],
          if (grades.isEmpty)
            const EmptyStateView(
              title: '本学期暂无已出成绩',
              subtitle: '切换上方学期可查看历史成绩单',
              icon: Icons.school_outlined,
              compact: true,
            )
          else
            Container(
              decoration: BoxDecoration(
                color: c.surfaceLow,
                borderRadius: BorderRadius.circular(DesktopRadius.card),
                border: Border.all(color: c.hairline),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: c.surfaceHigh.withValues(alpha: 0.6),
                      border: Border(bottom: BorderSide(color: c.hairline)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text('课程', style: DesktopType.caption(context)),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text('学分',
                              textAlign: TextAlign.right,
                              style: DesktopType.caption(context)),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text('成绩',
                              textAlign: TextAlign.right,
                              style: DesktopType.caption(context)),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text('绩点',
                              textAlign: TextAlign.right,
                              style: DesktopType.caption(context)),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < grades.length; i++)
                    _GradeTableRow(
                      grade: grades[i],
                      store: store,
                      showDivider: i > 0,
                      onTap: () => controller
                          .inspect(CourseInspectorTarget(grades[i].name)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    this.sub,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? sub;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Container(
      width: 158,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? c.selectedFill : c.surfaceLow,
        borderRadius: BorderRadius.circular(DesktopRadius.card),
        border: Border.all(color: highlight ? c.selectedBorder : c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DesktopType.caption(context)),
          const SizedBox(height: 4),
          Text(
            value,
            style: DesktopType.display(context).copyWith(
              fontSize: 23,
              color: highlight ? c.primary : c.text1,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!, style: DesktopType.caption(context, numeric: true)),
          ],
        ],
      ),
    );
  }
}

class _GradeTableRow extends StatelessWidget {
  const _GradeTableRow({
    required this.grade,
    required this.store,
    required this.showDivider,
    required this.onTap,
  });

  final Grade grade;
  final DesktopStore store;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final high = grade.fivePoint >= 4.5;
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: c.hairline))
            : null,
      ),
      child: DesktopAction(
        onTap: onTap,
        borderRadius: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      grade.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesktopType.body(context),
                    ),
                  ),
                  if (!grade.gpaIncluded) ...[
                    const SizedBox(width: 6),
                    const ConcentricTag(
                      label: '不计绩点',
                      radius: DesktopRadius.tag,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                grade.credit.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: DesktopType.meta(context, numeric: true),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                store.maskGpa(grade.original),
                textAlign: TextAlign.right,
                style: DesktopType.strong(context, numeric: true).copyWith(
                  color: !store.gpaHidden && high ? c.success : c.text1,
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                store.maskGpa(grade.fivePoint.toStringAsFixed(1)),
                textAlign: TextAlign.right,
                style: DesktopType.mono(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Class Hours & 16-Week Chart Tab ─────────────────────────

class _HoursView extends StatelessWidget {
  const _HoursView({
    required this.store,
    required this.controller,
    required this.semester,
  });

  final DesktopStore store;
  final DesktopController controller;
  final Semester? semester;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    if (semester == null) {
      return const EmptyStateView(
        title: '暂无学期课时数据',
        icon: Icons.bar_chart_rounded,
      );
    }
    final hours = store.hoursOf(semester!);
    if (hours.courses.isEmpty) {
      return const EmptyStateView(
        title: '本学期暂无排课记录',
        icon: Icons.bar_chart_rounded,
      );
    }

    final pct = hours.total == 0 ? 0 : (hours.done / hours.total * 100).round();
    final curWeekCount = hours.currentWeek != null &&
            hours.currentWeek! >= 0 &&
            hours.currentWeek! < hours.weekly.length
        ? hours.weekly[hours.currentWeek!]
        : null;

    return DesktopScrollArea(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiCard(
                label: '已完成课时',
                value: '${hours.done} / ${hours.total}',
                sub: '完成度 $pct%',
                highlight: true,
              ),
              _KpiCard(
                label: '在修课程',
                value: '${hours.courses.length} 门',
                sub: '共 ${hours.weekly.length} 个教学周',
              ),
              if (curWeekCount != null)
                _KpiCard(
                  label: '本周节数',
                  value: '$curWeekCount 节',
                  sub: '第 ${hours.currentWeek! + 1} 周',
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (hours.weekly.isNotEmpty) ...[
            SectionHeading(
              '教学周课量分布',
              trailing: Text(
                '单位：节 / 周',
                style: DesktopType.caption(context),
              ),
            ),
            Container(
              height: 156,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: BoxDecoration(
                color: c.surfaceLow,
                borderRadius: BorderRadius.circular(DesktopRadius.card),
                border: Border.all(color: c.hairline),
              ),
              child: _WeeklyLoadChart(
                weekly: hours.weekly,
                currentWeek: hours.currentWeek,
              ),
            ),
            const SizedBox(height: 18),
          ],
          SectionHeading(
            '各课程课时进度',
            trailing: Text(
              '点击查看课程详情',
              style: DesktopType.caption(context),
            ),
          ),
          for (final ch in hours.courses) ...[
            _CourseHoursRow(
              course: ch,
              onTap: () => controller.inspect(CourseInspectorTarget(ch.name)),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _WeeklyLoadChart extends StatelessWidget {
  const _WeeklyLoadChart({
    required this.weekly,
    required this.currentWeek,
  });

  final List<int> weekly;
  final int? currentWeek;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final maxVal = weekly.fold<int>(1, math.max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < weekly.length; i++)
          Expanded(
            child: Tooltip(
              message: '第 ${i + 1} 周：${weekly[i]} 节',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      weekly[i] > 0 ? '${weekly[i]}' : '',
                      style: DesktopType.caption(context, numeric: true)
                          .copyWith(
                        fontSize: 10,
                        color: i == currentWeek ? c.primary : c.text3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (weekly[i] / maxVal).clamp(0.04, 1.0),
                          widthFactor: 0.72,
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == currentWeek
                                  ? c.primary
                                  : (currentWeek != null && i < currentWeek!)
                                      ? c.text3.withValues(alpha: 0.35)
                                      : c.primary.withValues(alpha: 0.42),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(DesktopRadius.tag),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${i + 1}',
                      style: DesktopType.caption(context, numeric: true)
                          .copyWith(
                        fontSize: 10.5,
                        color: i == currentWeek ? c.primary : c.text3,
                        fontWeight: i == currentWeek
                            ? FontWeight.w700
                            : FontWeight.w500,
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

class _CourseHoursRow extends StatelessWidget {
  const _CourseHoursRow({required this.course, required this.onTap});
  final CourseHours course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final swatch = CoursePalette.of(context, course.name);
    final frac = course.total == 0 ? 0.0 : (course.done / course.total).clamp(0.0, 1.0);

    return DesktopAction(
      onTap: onTap,
      backgroundColor: c.surfaceLow,
      borderColor: c.hairline,
      borderRadius: DesktopRadius.block,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: swatch.bar,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopType.strong(context),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.done} / ${course.total} 节',
                style: DesktopType.mono(context),
              ),
              const SizedBox(width: 10),
              Text(
                '均 ${course.perWeek.toStringAsFixed(1)} 节/周',
                style: DesktopType.caption(context, numeric: true),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(2.5),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 4.5,
              backgroundColor: c.hairline,
              color: swatch.bar,
            ),
          ),
        ],
      ),
    );
  }
}
