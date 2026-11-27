import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../model/grade.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_row.dart';
import '../widgets/page_header.dart';
import '../widgets/scroll_area.dart';
import '../widgets/section_label.dart';
import '../widgets/semester_dropdown.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key, required this.store});
  final DesktopStore store;

  String _gpa(double value) => store.maskGpa(value.toStringAsFixed(2));
  String _credit(double value) =>
      value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => PaperPage(
          store: store,
          header: PageHeader(
              title: '成绩',
              subtitle: '已获 ${_credit(store.earnedCredit)} 学分',
              actions: [
                SemesterDropdown(store: store),
                const SizedBox(width: 8),
                PaperIconButton(
                    icon: store.gpaHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    tooltip: store.gpaHidden ? '显示 GPA' : '隐藏 GPA',
                    onPressed: store.toggleGpaHidden)
              ]),
          child: Column(children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: PaperColors.of(context).hairline))),
                child: _summary(context)),
            Expanded(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Container(
                      width: 244,
                      color: PaperColors.of(context).rail,
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
                      child: _semesters(context)),
                  Container(
                      width: 1, color: PaperColors.of(context).hairline),
                  Expanded(child: _table(context))
                ]))
          ])));

  Widget _summary(BuildContext context) {
    final values = store.gpa;
    final items = <(String, String, String?)>[
      ('五分制', _gpa(values[0]), null),
      ('四分制（4.3）', _gpa(values[1]), '4.0 制 ${_gpa(values[2])}'),
      ('百分制', _gpa(values[3]), null),
      ('主修均绩', _gpa(store.majorGpa), '${_credit(store.majorCredit)} 学分'),
      ('已获学分', _credit(store.earnedCredit), null)
    ];
    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0)
          VerticalDivider(
              width: 32, thickness: 1, color: PaperColors.of(context).hairline),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(items[i].$1,
              style: PaperType.label(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(items[i].$2,
              style: PaperType.number(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (items[i].$3 != null)
            Text(items[i].$3!,
                style: PaperType.meta(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
        ]))
      ]
    ]));
  }

  Widget _semesters(BuildContext context) {
    final semesters = store.semesters;
    final trend = semesters.reversed.where((s) => s.grades.isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const CardHeader('学期'),
      Expanded(
          child: semesters.isEmpty
              ? const EmptyState('暂无学期数据', compact: true)
              : ScrollArea(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      for (var i = 0; i < semesters.length; i++)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: PaperAction(
                                onTap: () => store.selectSemester(i),
                                selected: i == store.selectedSemesterIndex,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(semesters[i].name,
                                          style: PaperType.strong(context),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(
                                          'GPA ${_gpa(semesters[i].gpa[0])} · ${_credit(semesters[i].courseCredit)} 学分',
                                          style: PaperType.meta(context),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)
                                    ])))
                    ]))),
      if (MediaQuery.sizeOf(context).height >= 760) ...[
        const SizedBox(height: 16),
        SizedBox(
            height: 140,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('GPA 趋势 · 五分制'),
                  Expanded(
                      child: store.gpaHidden
                          ? const EmptyState('GPA 已隐藏')
                          : trend.isEmpty
                              ? const EmptyState('暂无成绩数据')
                              : Semantics(
                                  label:
                                      'GPA 趋势：${trend.map((s) => '${s.name} ${_gpa(s.gpa[0])}').join('，')}',
                                  child: CustomPaint(
                                      painter: _TrendPainter(
                                          values: [
                                        for (final s in trend) s.gpa[0]
                                      ],
                                          labels: [
                                        for (final s in trend) s.name
                                      ],
                                          line: PaperColors.of(context).accent,
                                          hairline:
                                              PaperColors.of(context).hairline,
                                          textStyle: PaperType.meta(context),
                                          textScaler: MediaQuery.textScalerOf(
                                              context)))))
                ]))
      ]
    ]);
  }

  Widget _table(BuildContext context) {
    final semester = store.selectedSemester;
    final grades = semester == null
        ? <Grade>[]
        : List<Grade>.of(store.gradesOf(semester))
      ..sort((a, b) {
        final result = b.fivePoint.compareTo(a.fivePoint);
        return result == 0 ? b.hundredPoint.compareTo(a.hundredPoint) : result;
      });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
          child: CardHeader(semester == null ? '成绩' : semester.name,
              trailing:
                  Text('${grades.length} 门', style: PaperType.meta(context)))),
      Expanded(
          child: grades.isEmpty
              ? const EmptyState('暂无成绩数据',
                  icon: Icons.school_outlined, subtitle: '该学期尚未录入成绩')
              : LayoutBuilder(builder: (context, bounds) {
                  final width = math.max(560.0, bounds.maxWidth);
                  return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                          width: width,
                          height: bounds.maxHeight,
                          child: Column(children: [
                            _GradeHeader(),
                            Expanded(
                                child: ScrollArea(
                                    child: Column(children: [
                              for (final grade in grades)
                                _GradeRow(grade: grade, store: store)
                            ])))
                          ])));
                }))
    ]);
  }
}

const _numericWidths = [44.0, 64.0, 56.0, 56.0, 62.0];

class _GradeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height:
          MediaQuery.textScalerOf(context).scale(40).clamp(40, double.infinity),
      // Match ScrollArea's 8px trailing inset so all table columns align.
      padding: const EdgeInsets.only(left: 12, right: 20),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: PaperColors.of(context).hairline))),
      child: Row(children: [
        Expanded(child: Text('课程', style: PaperType.label(context))),
        for (var i = 0; i < _numericWidths.length; i++)
          SizedBox(
              width: _numericWidths[i],
              child: Text(['学分', '成绩', '五分制', '4.3 制', '百分制'][i],
                  style: PaperType.label(context), textAlign: TextAlign.center))
      ]));
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade, required this.store});
  final Grade grade;
  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    final excluded = !grade.gpaIncluded;
    final neutralBand =
        !store.gpaHidden && !excluded && grade.hundredPoint >= 80 && grade.hundredPoint < 90;
    final color = store.gpaHidden || excluded || neutralBand
        ? c.text2
        : grade.hundredPoint >= 90
            ? c.success
            : grade.hundredPoint >= 70
                ? c.warning
                : c.danger;
    final style =
        PaperType.body(context).copyWith(color: excluded ? c.text2 : c.text);
    final numbers = [
      grade.credit.toStringAsFixed(1),
      store.gpaHidden ? '***' : grade.original,
      store.maskGpa(grade.fivePoint.toStringAsFixed(1)),
      store.maskGpa(grade.fourPoint.toStringAsFixed(1)),
      store.maskGpa(grade.hundredPoint > 0 ? '${grade.hundredPoint}' : '—')
    ];
    return MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: _GradeHover(
            child: Tooltip(
                message: '${grade.name}${excluded ? ' · 不计入均绩' : ''}',
                child: Container(
                    constraints: BoxConstraints(
                        minHeight: MediaQuery.textScalerOf(context)
                            .scale(40)
                            .clamp(40, double.infinity)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.hairline))),
                    child: Row(children: [
                      Expanded(
                          child: Text(grade.name,
                              style: style,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      for (var i = 0; i < numbers.length; i++)
                        SizedBox(
                            width: _numericWidths[i],
                            child: i == 1
                                ? Center(
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: store.gpaHidden ||
                                                    excluded ||
                                                    neutralBand
                                                ? c.glassControl
                                                : Color.alphaBlend(
                                                    color.withValues(
                                                        alpha:
                                                            c.dark ? .18 : .12),
                                                    c.surface),
                                            borderRadius: BorderRadius.circular(
                                                Paper.chipRadius)),
                                        child: Text(numbers[i],
                                            style: PaperType.meta(context)
                                                .copyWith(color: color),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)))
                                : Text(numbers[i],
                                    style: style, textAlign: TextAlign.center))
                    ])))));
  }
}

class _GradeHover extends StatefulWidget {
  const _GradeHover({required this.child});
  final Widget child;
  @override
  State<_GradeHover> createState() => _GradeHoverState();
}

class _GradeHoverState extends State<_GradeHover> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color:
              hover ? PaperColors.of(context).hover : const Color(0x00000000),
          child: widget.child));
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(
      {required this.values,
      required this.labels,
      required this.line,
      required this.hairline,
      required this.textStyle,
      required this.textScaler});
  final List<double> values;
  final List<String> labels;
  final Color line, hairline;
  final TextStyle textStyle;
  final TextScaler textScaler;

  void _label(Canvas canvas, String text, Offset center, Size size) {
    final painter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
        ellipsis: '…')
      ..layout(maxWidth: size.width);
    painter.paint(
        canvas,
        Offset(
            (center.dx - painter.width / 2)
                .clamp(0.0, math.max(0, size.width - painter.width)),
            center.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width < 40 || size.height < 50) return;
    final top = textScaler.scale(18);
    final bottom = size.height - textScaler.scale(24);
    if (bottom <= top) return;
    final low = math.max(0.0, values.reduce(math.min) - .4);
    final high = math.max(low + .5, values.reduce(math.max) + .2);
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
            values.length == 1
                ? size.width / 2
                : 16 + (size.width - 32) * i / (values.length - 1),
            bottom - (values[i] - low) / (high - low) * (bottom - top))
    ];
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom),
        Paint()..color = hairline);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = line);
    }
    // Thin labels for long histories rather than painting overlapping numbers.
    final stride = math.max(
        1, (values.length / math.max(1, (size.width / 64).floor())).ceil());
    for (var i = 0; i < points.length; i++) {
      if (i % stride == 0 || i == points.length - 1) {
        _label(canvas, values[i].toStringAsFixed(2),
            Offset(points[i].dx, points[i].dy - textScaler.scale(19)), size);
      }
    }
    String semesterLabel(String name) {
      final match = RegExp(r'^(\d{4})-(\d{4})(.*)$').firstMatch(name);
      return match == null
          ? name
          : '${match[1]!.substring(2)}-${match[2]!.substring(2)} ${match[3]}';
    }

    _label(canvas, semesterLabel(labels.first), Offset(20, bottom + 5), size);
    if (values.length > 1) {
      _label(canvas, semesterLabel(labels.last),
          Offset(size.width - 20, bottom + 5), size);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      !listEquals(old.values, values) ||
      !listEquals(old.labels, labels) ||
      old.line != line ||
      old.hairline != hairline ||
      old.textStyle != textStyle ||
      old.textScaler != textScaler;
}
