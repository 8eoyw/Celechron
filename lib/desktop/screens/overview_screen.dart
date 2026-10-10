import 'dart:math';
import 'package:flutter/material.dart';

import 'package:celechron/desktop/side_panels.dart';
import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';

import 'package:celechron/model/period.dart';

/// 总览页：KPI 行 + 今天时间轴 + 作业/明天。规格见 lib/desktop/DESIGN.md（作业与即将考试已对调）
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.store});

  final DesktopStore store;

  String _f2(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Column(
          children: [
            // KPI 行（高度 76，5 个指标均分）
            SizedBox(
              height: 76,
              child: Row(
                children: [
                  Expanded(flex: 2, child: _nextClassTile(context)),
                  SizedBox(width: DS.s3),
                  Expanded(
                      child: KpiTile(
                          label: '五分制',
                          value: store.maskGpa(_f2(store.gpa[0])),
                          action: EyeToggle(
                              hidden: store.gpaHidden,
                              onTap: store.toggleGpaHidden))),
                  SizedBox(width: DS.s3),
                  Expanded(
                      child: KpiTile(
                          label: '四分制',
                          value: store.maskGpa(_f2(store.gpa[1])),
                          sub: '4.0 制 ${store.maskGpa(_f2(store.gpa[2]))}')),
                  SizedBox(width: DS.s3),
                  Expanded(
                      child: KpiTile(
                          label: '已获学分', value: _f2(store.earnedCredit))),
                  SizedBox(width: DS.s3),
                  Expanded(child: _homeworkCountTile(context)),
                ],
              ),
            ),
            SizedBox(height: DS.s3),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 今天：纵向时间轴（flex 3）
                  Expanded(flex: 3, child: _todayCard(context)),
                  SizedBox(width: DS.s3),
                  // 右栏（flex 2）：作业 + 明天；即将考试在右侧栏
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(child: _homeworkCard(context)),
                        SizedBox(height: DS.s3),
                        _tomorrowCard(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────── KPI 行 ─────────────────────────

  /// 下一节：课程名 + 「进行中 / N 后」+ 地点
  Widget _nextClassTile(BuildContext context) {
    final ongoing = store.ongoing;
    if (ongoing.isNotEmpty) {
      final p = ongoing.first;
      return KpiTile(
          label: '下一节',
          textValue: true,
          value: p.summary,
          sub: '进行中 · ${p.location}',
          color: periodColor(p));
    }
    final next = store.nextPeriod;
    if (next == null) {
      return KpiTile(
          label: '下一节',
          textValue: true,
          value: '—',
          sub: store.isLoggedIn ? '暂无安排' : '未登录');
    }
    return KpiTile(
        label: '下一节',
        textValue: true,
        value: next.summary,
        sub: '${fmtRelative(next.startTime, store.now)} · ${next.location}',
        color: periodColor(next));
  }

  /// 近期作业：7 天内截止、尚未逾期的作业数 + 最近一项的剩余时间；24 小时内转橙色
  Widget _homeworkCountTile(BuildContext context) {
    final soon = store.todos
        .where((t) =>
            store.groupOf(t) == TodoGroup.within24h ||
            store.groupOf(t) == TodoGroup.thisWeek)
        .toList();
    final urgent =
        soon.isNotEmpty && store.groupOf(soon.first) == TodoGroup.within24h;
    return KpiTile(
        label: '近期作业',
        value: '${soon.length}',
        sub: soon.isEmpty
            ? '7 天内无截止'
            : fmtRelative(soon.first.endTime!, store.now),
        color: urgent ? DS.warning : const Color(0xFF4F7CFF));
  }

  // ───────────────────────── 今天（时间轴） ─────────────────────────

  Widget _todayCard(BuildContext context) {
    final periods = store.todayPeriods;
    if (periods.isEmpty) {
      return DCard(title: '今天', child: EmptyHint('今天没有安排'));
    }
    return DCard(
      title: '今天',
      trailing: Text('${periods.length} 项'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HourAxis(),
          Expanded(
            child:
                DayTimeline(day: store.now, periods: periods, now: store.now),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── 作业（右栏上） ─────────────────────────

  Widget _homeworkCard(BuildContext context) => DCard(
        title: '作业',
        trailing: store.isLoggedIn
            ? Text('更新于 ${fmtAgo(store.homeworkUpdatedAt, store.now)}')
            : null,
        padding: const EdgeInsets.fromLTRB(DS.s2, 0, DS.s2, DS.s1),
        child: HomeworkList(store: store),
      );

  // ───────────────────────── 明天（右栏下） ─────────────────────────

  Widget _tomorrowCard(BuildContext context) {
    final tomorrow = DateTime(store.now.year, store.now.month, store.now.day)
        .add(const Duration(days: 1));
    final periods = store.periodsOfDay(tomorrow);
    return SizedBox(
      height: 180,
      child: DCard(
        title: '明天',
        child: periods.isEmpty
            ? EmptyHint('明天没有安排')
            : LayoutBuilder(
                builder: (context, c) {
                  // 计算放得下几行，多余的显示「还有 N 项」
                  final maxRows = (c.maxHeight / DS.rowHeight).floor();
                  final visible = min(periods.length, maxRows);
                  final hidden = periods.length - visible;
                  final rows = <Widget>[
                    for (final p in periods.take(visible))
                      _TomorrowRow(period: p),
                    if (hidden > 0)
                      DRow(
                          height: DS.rowHeight,
                          child: Row(children: [
                            Text('还有 $hidden 项', style: DText.muted(context)),
                          ])),
                  ];
                  return Column(children: rows);
                },
              ),
      ),
    );
  }
}

/// 明天的时段行：时间 · 名称 · 地点（单行）
class _TomorrowRow extends StatelessWidget {
  const _TomorrowRow({required this.period});

  final Period period;

  @override
  Widget build(BuildContext context) {
    return DRow(
      height: DS.rowHeight,
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(
                  '${fmtTime(period.startTime)}–${fmtTime(period.endTime)}',
                  style: DText.muted(context))),
          SizedBox(width: DS.s2),
          Expanded(
              child: Text(period.summary,
                  style: DText.strong(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          SizedBox(width: DS.s2),
          Text(period.location,
              style: DText.muted(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
