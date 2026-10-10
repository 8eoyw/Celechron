import 'dart:math';

import 'package:flutter/material.dart';

import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';

import 'package:celechron/model/grade.dart';
import 'package:celechron/model/semester.dart';

/// 成绩页：KPI 行（6 个指标）+ 学期列表（含 GPA 趋势）+ 成绩表。规格见 lib/desktop/DESIGN.md
class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key, required this.store});

  final DesktopStore store;

  String _f2(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.isLoggedIn) {
          return EmptyHint('未登录');
        }
        return Column(
          children: [
            _kpiRow(context),
            SizedBox(height: DS.s3),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 240, child: _semesterCard(context)),
                  SizedBox(width: DS.s3),
                  Expanded(child: _gradeTableCard(context)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────── KPI 行 ─────────────────────────

  /// KPI 行（高 76，6 个指标均分，两位小数）
  Widget _kpiRow(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Expanded(
              child: KpiTile(
                  label: '五分制',
                  value: store.maskGpa(_f2(store.gpa[0])),
                  action: EyeToggle(
                      hidden: store.gpaHidden, onTap: store.toggleGpaHidden))),
          SizedBox(width: DS.s3),
          Expanded(
              child: KpiTile(
                  label: '四分制',
                  value: store.maskGpa(_f2(store.gpa[1])),
                  sub: '4.0 制 ${store.maskGpa(_f2(store.gpa[2]))}')),
          SizedBox(width: DS.s3),
          Expanded(
              child: KpiTile(
                  label: '百分制', value: store.maskGpa(_f2(store.gpa[3])))),
          SizedBox(width: DS.s3),
          Expanded(
              child: KpiTile(
                  label: '主修均绩', value: store.maskGpa(_f2(store.majorGpa)))),
          SizedBox(width: DS.s3),
          Expanded(
              child: KpiTile(label: '主修学分', value: _f2(store.majorCredit))),
          SizedBox(width: DS.s3),
          Expanded(
              child: KpiTile(label: '已获学分', value: _f2(store.earnedCredit))),
        ],
      ),
    );
  }

  // ─────────────────────── 学期（左，宽 240） ───────────────────────

  Widget _semesterCard(BuildContext context) {
    final semesters = store.semesters;
    if (semesters.isEmpty) {
      return DCard(title: '学期', child: EmptyHint('暂无学期数据'));
    }
    final selected = store.selectedSemesterIndex;
    // 趋势图数据：从最早到最新学期，取 gpa[0]
    final trend = <double>[
      for (final s in List<Semester>.of(semesters).reversed)
        if (s.grades.isNotEmpty) s.gpa[0],
    ];
    return DCard(
      title: '学期',
      child: Column(
        children: [
          Expanded(
            child: DScrollArea(
              child: Column(
                children: [
                  for (int i = 0; i < semesters.length; i++)
                    DRow(
                      selected: i == selected,
                      onTap: () => store.selectSemester(i),
                      child: _SemesterRow(
                          index: i,
                          semester: semesters[i],
                          selected: i == selected),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: DS.s3),
          SizedBox(height: 90, child: _GpaTrendChart(values: trend)),
        ],
      ),
    );
  }

  // ─────────────────────── 成绩表（右，Expanded） ───────────────────────

  Widget _gradeTableCard(BuildContext context) {
    final semester = store.selectedSemester;
    if (semester == null) {
      return const DCard(title: '成绩', child: EmptyHint('暂无学期数据'));
    }
    final grades = List<Grade>.of(store.gradesOf(semester))
      ..sort((a, b) {
        final c = b.fivePoint.compareTo(a.fivePoint);
        return c != 0 ? c : b.hundredPoint.compareTo(a.hundredPoint);
      });
    final credits = grades.fold(0.0, (s, g) => s + g.credit);
    return DCard(
      title: '${semester.name} 成绩',
      trailing: grades.isEmpty
          ? null
          : Text('${grades.length} 门 · ${credits.toStringAsFixed(1)} 学分 · '
              '五分制 ${semester.gpa[0].toStringAsFixed(2)}'),
      padding: const EdgeInsets.fromLTRB(DS.s3, 0, DS.s3, DS.s3),
      child: grades.isEmpty
          ? const EmptyHint('本学期成绩尚未公布')
          : Column(
              children: [
                const _GradeHeader(),
                Expanded(
                  child: DScrollArea(
                    child: Column(
                      children: [for (final g in grades) _GradeRow(grade: g)],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// 学期行：短名 + 五分制 GPA + 学分，点击切换当前学期
class _SemesterRow extends StatelessWidget {
  const _SemesterRow({
    required this.index,
    required this.semester,
    this.selected = false,
  });

  final int index;
  final Semester semester;
  final bool selected;

  String _f2(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final shortName =
        // "2025-2026秋冬" → "25-26 秋冬"
        semester.name.length > 9
            ? '${semester.name.substring(2, 4)}-${semester.name.substring(7, 9)} ${semester.name.substring(9)}'
            : semester.name;
    return Row(
      children: [
        Expanded(
            child: Text(shortName,
                style: DText.strong(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        SizedBox(width: DS.s2),
        Text(_f2(semester.gpa[0]),
            style: DText.muted(context), textAlign: TextAlign.right),
        SizedBox(width: DS.s2),
        Text(_f2(semester.courseCredit),
            style: DText.muted(context), textAlign: TextAlign.right),
      ],
    );
  }
}

/// 学期 GPA 趋势：高 90 的折线图（CustomPainter），数据为各学期 gpa[0]（最早 → 最新）
class _GpaTrendChart extends StatelessWidget {
  const _GpaTrendChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      painter: _GpaTrendPainter(
        values: values,
        lineColor: primary,
        fillColor: primary.withValues(alpha: 0.12),
        axisColor: colors.muted,
      ),
      size: Size.infinite,
    );
  }
}

class _GpaTrendPainter extends CustomPainter {
  _GpaTrendPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.axisColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 10.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    if (w <= 0 || h <= 0) return;

    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(size.width - pad, size.height - pad),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );
    if (values.isEmpty) return;

    // 纵轴从略低于最低值开始，避免最低点贴着底线看起来像 0
    double minV = (values.reduce(min) - 0.6).clamp(0.0, 5.0);
    double maxV = (values.reduce(max) + 0.3).clamp(0.0, 5.0);
    if (maxV - minV < 0.5) maxV = minV + 0.5;

    List<Offset> pts;
    if (values.length == 1) {
      pts = [
        Offset(
          size.width / 2,
          pad + h - (values[0] - minV) / (maxV - minV) * h,
        )
      ];
    } else {
      final stepX = w / (values.length - 1);
      pts = List<Offset>.generate(
          values.length,
          (i) => Offset(pad + i * stepX,
              pad + h - (values[i] - minV) / (maxV - minV) * h));
    }

    final area = Path()..moveTo(pts[0].dx, size.height - pad);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(pts[pts.length - 1].dx, size.height - pad)
      ..close();
    canvas.drawPath(area, Paint()..color = fillColor);

    final line = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final dot = Paint()..color = lineColor;
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], 3, dot);
      // 每个点上方标出学期均绩
      final tp = TextPainter(
        text: TextSpan(
            text: values[i].toStringAsFixed(2),
            style:
                TextStyle(fontSize: 10, color: lineColor, fontFamily: DS.font)),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (pts[i].dx - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(x, pts[i].dy - tp.height - 3));
    }
  }

  bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool shouldRepaint(_GpaTrendPainter old) =>
      !_sameValues(old.values, values) ||
      old.lineColor != lineColor ||
      old.fillColor != fillColor ||
      old.axisColor != axisColor;
}

/// 成绩行：课程 / 学分 / 成绩（原始）/ 百分制 / 四分制；gpaIncluded == false 的行用次级色
/// 成绩表列宽（表头与行共用）
const double _wCredit = 52,
    _wScore = 64,
    _wFive = 64,
    _wFour = 64,
    _wHundred = 64;

/// 按五分制给成绩上色
Color _scoreColor(double five) => five >= 4.5
    ? DS.success
    : five >= 3.5
        ? const Color(0xFF4F7CFF)
        : five >= 2.5
            ? DS.warning
            : DS.danger;

class _GradeHeader extends StatelessWidget {
  const _GradeHeader();

  @override
  Widget build(BuildContext context) {
    final style = DText.muted(context)
        .copyWith(fontSize: 12, fontWeight: FontWeight.w600);
    Widget cell(double w, String t) => SizedBox(
        width: w, child: Text(t, style: style, textAlign: TextAlign.center));
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: DS.s3),
      decoration: BoxDecoration(
        color: DSColors.of(context).subtle,
        borderRadius: BorderRadius.circular(DS.radiusSm),
      ),
      child: Row(children: [
        Expanded(child: Text('课程', style: style)),
        cell(_wCredit, '学分'),
        cell(_wScore, '成绩'),
        cell(_wFive, '五分制'),
        cell(_wFour, '4.3 制'),
        cell(_wHundred, '百分制'),
      ]),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});

  final Grade grade;

  @override
  Widget build(BuildContext context) {
    final excluded = !grade.gpaIncluded;
    final color = _scoreColor(grade.fivePoint);
    final body = DText.body(context).copyWith(
      fontSize: 14,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: excluded ? DSColors.of(context).muted : null,
    );
    Widget num(double w, String t, {bool strong = false}) => SizedBox(
        width: w,
        child: Text(t,
            textAlign: TextAlign.center,
            style: strong ? body.copyWith(fontWeight: FontWeight.w700) : body));
    return Tooltip(
      message: excluded ? '不计入均绩' : '',
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: DS.s3),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: DSColors.of(context).border)),
        ),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: DS.colorFor(grade.name), shape: BoxShape.circle)),
          const SizedBox(width: DS.s2),
          Expanded(
            child: Text(grade.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body.copyWith(fontWeight: FontWeight.w500)),
          ),
          num(_wCredit, grade.credit.toStringAsFixed(1)),
          SizedBox(
            width: _wScore,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: excluded ? 0.06 : 0.14),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(grade.original,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body.copyWith(
                        color: excluded ? null : color,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          num(_wFive, grade.fivePoint.toStringAsFixed(1), strong: !excluded),
          num(_wFour, grade.fourPoint.toStringAsFixed(1)),
          // 等级制成绩（优/中/合格…）没有百分制分数
          num(_wHundred,
              grade.hundredPoint > 0 ? '${grade.hundredPoint}' : '—'),
        ]),
      ),
    );
  }
}
