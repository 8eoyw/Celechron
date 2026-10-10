import 'package:flutter/material.dart';

import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';

import 'package:celechron/model/exam.dart';
import 'package:celechron/model/semester.dart';

/// 考试页：左栏考试表（flex 3）+ 右栏倒计时大卡（flex 2）。规格见 lib/desktop/DESIGN.md
class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key, required this.store});

  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.isLoggedIn) {
          return EmptyHint('未登录');
        }
        final semester = store.selectedSemester;
        if (semester == null) {
          return EmptyHint('暂无学期数据');
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 7, child: _examTableCard(context, semester)),
            SizedBox(width: DS.s3),
            Expanded(flex: 3, child: _countdownCard(context)),
          ],
        );
      },
    );
  }

  // ─────────────────────── 考试表（左栏） ───────────────────────

  Widget _examTableCard(BuildContext context, Semester semester) {
    final entries = store.examsOf(semester);
    if (entries.isEmpty) {
      return DCard(title: semester.name + ' 考试', child: EmptyHint('暂无考试安排'));
    }
    // 地点/座位多数时候尚未公布，整列为空时不占宽度，把空间留给课程名
    final showPlace = entries.any((e) => (e.exam.location ?? '').isNotEmpty);
    final showSeat = entries.any((e) => (e.exam.seat ?? '').isNotEmpty);
    return DCard(
      title: semester.name + ' 考试',
      child: Column(
        children: [
          _examHeader(context, showPlace, showSeat),
          Expanded(
            child: DScrollArea(
              child: Column(
                children: [
                  for (final e in entries)
                    _ExamRow(
                        entry: e,
                        now: store.now,
                        showPlace: showPlace,
                        showSeat: showSeat),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examHeader(BuildContext context, bool showPlace, bool showSeat) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          _headerCell(context, 70, '日期'),
          SizedBox(width: DS.s2),
          _headerCell(context, 80, '时间'),
          SizedBox(width: DS.s2),
          Expanded(child: Text('课程', style: DText.muted(context))),
          SizedBox(width: DS.s2),
          _headerCell(context, 44, '类型'),
          SizedBox(width: DS.s2),
          if (showPlace) ...[
            _headerCell(context, 64, '地点'),
            SizedBox(width: DS.s2),
          ],
          if (showSeat) ...[
            _headerCell(context, 36, '座位'),
            SizedBox(width: DS.s2),
          ],
          _headerCell(context, 56, '倒计时'),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, double w, String text) {
    return SizedBox(width: w, child: Text(text, style: DText.muted(context)));
  }

  // ─────────────────────── 倒计时（右栏） ───────────────────────

  Widget _countdownCard(BuildContext context) {
    final upcoming = store.upcomingExams;
    if (upcoming.isEmpty) {
      return DCard(title: '倒计时', child: EmptyHint('近期没有考试'));
    }
    final items = upcoming.length > 6 ? upcoming.take(6).toList() : upcoming;
    return DCard(
      title: '倒计时',
      child: DScrollArea(
        child: Column(
          children: [
            for (final e in items)
              Padding(
                padding: const EdgeInsets.only(bottom: DS.s3),
                child: _CountdownCard(entry: e, now: store.now),
              ),
          ],
        ),
      ),
    );
  }
}

/// 考试行：日期 / 时间 / 课程 / 类型 / 地点 / 座位 / 倒计时；已结束的考试整体次级色
class _ExamRow extends StatelessWidget {
  const _ExamRow(
      {required this.entry,
      required this.now,
      required this.showPlace,
      required this.showSeat});

  final bool showPlace;
  final bool showSeat;

  final ExamEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final exam = entry.exam;
    final finished = !entry.end.isAfter(now);
    final metaStyle = DText.muted(context);
    final nameStyle = finished ? DText.muted(context) : DText.strong(context);
    final countdown = finished ? '已结束' : fmtRelative(entry.start, now);
    final isMidterm = exam.type == ExamType.midterm;
    final typeLabel = isMidterm ? '期中' : '期末';
    final typeColor = isMidterm ? DS.warning : DS.danger;
    return DRow(
      height: DS.rowHeight,
      child: Row(
        children: [
          _cell(70, fmtDate(entry.start), metaStyle),
          _gap(),
          _cell(80, fmtRange(entry.start, entry.end), metaStyle),
          _gap(),
          Expanded(
              child: Text(exam.name,
                  style: nameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          _gap(),
          SizedBox(width: 44, child: Pill(typeLabel, color: typeColor)),
          _gap(),
          if (showPlace) ...[
            _cell(64, exam.location ?? '', metaStyle),
            _gap(),
          ],
          if (showSeat) ...[
            _cell(36, exam.seat ?? '', metaStyle),
            _gap(),
          ],
          _cell(56, countdown,
              finished ? metaStyle : metaStyle.copyWith(color: DS.danger)),
        ],
      ),
    );
  }

  Widget _cell(double w, String text, TextStyle style) {
    return SizedBox(
        width: w,
        child: Text(text,
            style: style, maxLines: 1, overflow: TextOverflow.ellipsis));
  }

  Widget _gap() => const SizedBox(width: DS.s2);
}

/// 倒计时大卡：剩余天数（大数字）+ 课程 + 日期时间 + 地点
class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.entry, required this.now});

  final ExamEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final d = entry.start.difference(now);
    final days = d.inDays;
    final color = days <= 1 ? DS.danger : (days <= 3 ? DS.warning : DS.success);
    final exam = entry.exam;
    return Container(
      padding: const EdgeInsets.all(DS.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DS.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(days.toString(), style: DText.kpi(context)),
                Text('天后', style: DText.muted(context)),
              ],
            ),
          ),
          SizedBox(width: DS.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.name,
                    style: DText.strong(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    fmtDate(entry.start) +
                        ' ' +
                        fmtRange(entry.start, entry.end),
                    style: DText.muted(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (exam.location != null)
                  Text(exam.location!,
                      style: DText.muted(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
