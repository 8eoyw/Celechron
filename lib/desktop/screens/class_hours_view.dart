import 'package:flutter/material.dart';

import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';

/// 课表页的「统计」视图：一个学期的总课时、已上/剩余、按课程与按教学周的分布。
/// 1 节 = 45 分钟；数字用节，小字附折合小时。
class ClassHoursView extends StatelessWidget {
  const ClassHoursView({super.key, required this.hours});

  final SemesterHours hours;

  static String _h(int sessions) =>
      '约 ${(sessions * 45 / 60).toStringAsFixed(0)} 小时';

  @override
  Widget build(BuildContext context) {
    if (hours.courses.isEmpty) {
      return const EmptyHint('这个学期没有课程安排',
          icon: Icons.calendar_view_week_outlined);
    }
    final total = hours.total, done = hours.done;
    final weeks = hours.weekly.length;
    final cur = hours.currentWeek;
    final pct = total == 0 ? 0 : (done * 100 / total).round();

    return Padding(
      padding: const EdgeInsets.only(left: DS.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 68,
            child: Row(children: [
              Expanded(
                  child:
                      KpiTile(label: '总课时', value: '$total 节', sub: _h(total))),
              const SizedBox(width: DS.s3),
              Expanded(
                  child: KpiTile(
                      label: '已上',
                      value: '$done 节',
                      sub: '$pct%',
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: DS.s3),
              Expanded(
                  child: KpiTile(
                      label: '剩余',
                      value: '${total - done} 节',
                      sub: _h(total - done))),
              const SizedBox(width: DS.s3),
              Expanded(
                  child: cur != null
                      ? KpiTile(
                          label: '本周（第 ${cur + 1} 周）',
                          value: '${hours.weekly[cur]} 节',
                          sub: _h(hours.weekly[cur]))
                      : KpiTile(
                          label: '平均每周',
                          value:
                              '${(total / (weeks == 0 ? 1 : weeks)).toStringAsFixed(1)} 节',
                          sub: '共 $weeks 周')),
            ]),
          ),
          const SizedBox(height: DS.s3),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _CourseTable(hours: hours)),
                const SizedBox(width: DS.s4),
                Expanded(flex: 2, child: _WeeklyChart(hours: hours)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionTitle(BuildContext context, String text, [Widget? trailing]) =>
    SizedBox(
      height: 28,
      child: Row(children: [
        Text(text, style: DText.strong(context)),
        const Spacer(),
        if (trailing != null) trailing,
      ]),
    );

// ───────────────────────── 按课程 ─────────────────────────

class _CourseTable extends StatelessWidget {
  const _CourseTable({required this.hours});
  final SemesterHours hours;

  @override
  Widget build(BuildContext context) {
    final muted = DText.muted(context);
    Widget head(String t, double w, [TextAlign a = TextAlign.right]) =>
        SizedBox(width: w, child: Text(t, style: muted, textAlign: a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
            context, '按课程', Text('${hours.courses.length} 门', style: muted)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.s2),
          child: SizedBox(
            height: 24,
            child: Row(children: [
              Expanded(child: Text('课程', style: muted)),
              head('学分', 40),
              head('每周', 52),
              head('总课时', 56),
              const SizedBox(width: DS.s4),
              head('进度', 150, TextAlign.left),
            ]),
          ),
        ),
        Divider(height: 1, color: DSColors.of(context).border),
        Expanded(
          child: DScrollArea(
            child: Column(children: [
              for (final c in hours.courses) _CourseRow(course: c),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course});
  final CourseHours course;

  @override
  Widget build(BuildContext context) {
    final c = course;
    final color = DS.colorFor(c.name);
    final body = DText.body(context);
    final frac = c.total == 0 ? 0.0 : c.done / c.total;
    Widget cell(String t, double w) => SizedBox(
        width: w,
        child: Text(t,
            style: body
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            textAlign: TextAlign.right));
    return Tooltip(
      message: '${c.name}\n共 ${c.total} 节，已上 ${c.done} 节，'
          '分布在 ${c.weeks.length} 个教学周',
      waitDuration: const Duration(milliseconds: 500),
      child: DRow(
        child: Row(children: [
          Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(1.5))),
          const SizedBox(width: DS.s2),
          Expanded(
              child: Text(c.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: body)),
          cell(c.credit == 0 ? '—' : c.credit.toStringAsFixed(1), 40),
          cell(c.perWeek.toStringAsFixed(c.perWeek % 1 == 0 ? 0 : 1), 52),
          cell('${c.total}', 56),
          const SizedBox(width: DS.s4),
          SizedBox(
            width: 150,
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(children: [
                    Container(height: 6, color: color.withValues(alpha: 0.18)),
                    FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(height: 6, color: color)),
                  ]),
                ),
              ),
              const SizedBox(width: DS.s2),
              SizedBox(
                width: 52,
                child: Text('${c.done}/${c.total}',
                    style: DText.muted(context).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── 按教学周 ─────────────────────────

/// 每个教学周的节数柱状图：已上的周实色、未上的周浅色，当前周加粗标签；悬停看数值
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.hours});
  final SemesterHours hours;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = DSColors.of(context);
    final muted = DText.muted(context);
    final weekly = hours.weekly;
    final cur = hours.currentWeek;
    final maxV = weekly.fold(0, (m, v) => v > m ? v : m);
    // 刻度步长 5/10/20，3–5 条网格线
    final step = maxV <= 20 ? 5 : (maxV <= 50 ? 10 : 20);
    final top = maxV <= 0 ? step : ((maxV + step - 1) ~/ step) * step;
    final ticks = [for (var t = 0; t <= top; t += step) t];
    // 当前周之前（含）算已上；整个学期都在过去时全部算已上
    bool isDone(int i) => cur == null ? hours.done > 0 : i <= cur;

    Widget legendDot(Color c, String t) => Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: DS.s1),
          Text(t, style: muted),
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
            context,
            '每周节数',
            Row(mainAxisSize: MainAxisSize.min, children: [
              legendDot(primary, '已上'),
              const SizedBox(width: DS.s3),
              legendDot(primary.withValues(alpha: 0.3), '未上'),
            ])),
        const SizedBox(height: DS.s2),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            // padTop：最上面的刻度文字不被裁掉
            const axisW = 24.0, labelH = 18.0, padTop = 8.0;
            final plotH = c.maxHeight - labelH - padTop;
            final n = weekly.length;
            final slot = (c.maxWidth - axisW) / (n == 0 ? 1 : n);
            // 标签放不下时隔几周标一次
            final every = slot >= 22 ? 1 : (slot >= 11 ? 2 : 4);
            return Stack(children: [
              // 网格线与刻度
              for (final t in ticks)
                Positioned(
                  left: 0,
                  right: 0,
                  top: padTop + plotH - plotH * t / top - 7,
                  child: Row(children: [
                    SizedBox(
                        width: axisW - 4,
                        child: Text('$t',
                            textAlign: TextAlign.right,
                            style: muted.copyWith(fontSize: 10.5))),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Container(
                            height: 1,
                            margin: const EdgeInsets.only(top: 1),
                            color: colors.border)),
                  ]),
                ),
              Positioned(
                left: axisW,
                right: 0,
                top: padTop,
                bottom: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: Tooltip(
                          message: '第 ${i + 1} 周：${weekly[i]} 节'
                              '${i == cur ? '（本周）' : ''}',
                          waitDuration: const Duration(milliseconds: 150),
                          child: Column(children: [
                            SizedBox(
                              height: plotH,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  // 柱间 2px 留白
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  child: Container(
                                    height: plotH * weekly[i] / top,
                                    constraints:
                                        const BoxConstraints(maxWidth: 22),
                                    decoration: BoxDecoration(
                                      color: isDone(i)
                                          ? primary
                                          : primary.withValues(alpha: 0.3),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: labelH,
                              child: (i + 1) % every == 0 || i == 0 || i == cur
                                  ? Text('${i + 1}',
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      style: muted.copyWith(
                                          fontSize: 10.5,
                                          fontWeight:
                                              i == cur ? FontWeight.w700 : null,
                                          color: i == cur ? primary : null))
                                  : null,
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ]);
          }),
        ),
      ],
    );
  }
}
