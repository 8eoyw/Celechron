import 'package:flutter/material.dart';

import 'package:celechron/desktop/screens/class_hours_view.dart';
import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';
import 'package:celechron/model/period.dart';

enum _ViewMode { week, month, stats }

/// 课表：周视图（七列时间轴，纵轴 08:00–22:00 撑满可用高度）、月视图（月历网格）
/// 与统计视图（学期课时），都不滚动。顶栏的学期选择会把视图跳到该学期；翻页翻进别的学期时也会同步顶栏。
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, required this.store});

  final DesktopStore store;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  _ViewMode _mode = _ViewMode.week;

  /// 视图锚定的日期：周视图显示它所在的周，月视图显示它所在的月
  late DateTime _anchor = _today;

  /// 上次看到的顶栏学期，用来判断用户是否在顶栏切换了学期
  String? _seenSemester;

  DesktopStore get store => widget.store;

  DateTime get _today =>
      DateTime(store.now.year, store.now.month, store.now.day);

  /// 顶栏切了学期：本学期回到今天，其它学期跳到开学那周/那月
  void _followSemesterPicker() {
    final sem = store.selectedSemester;
    final name = sem?.name;
    if (name == _seenSemester) return;
    final first = _seenSemester == null;
    _seenSemester = name;
    if (first || sem == null) return;
    final idx = store.semesterIndexOn(_today);
    _anchor = idx == store.selectedSemesterIndex
        ? _today
        : DateTime(sem.firstDay.year, sem.firstDay.month, sem.firstDay.day);
  }

  /// 翻页/回到今天/点日期；落到别的学期时同步顶栏
  void _goTo(DateTime day, {_ViewMode? mode}) {
    setState(() {
      _anchor = DateTime(day.year, day.month, day.day);
      if (mode != null) _mode = mode;
    });
    final probe = _mode == _ViewMode.month
        ? DateTime(_anchor.year, _anchor.month, 15)
        : _anchor;
    final idx = store.semesterIndexOn(probe);
    if (idx != null && idx != store.selectedSemesterIndex) {
      _seenSemester = store.semesters[idx].name;
      store.selectSemester(idx);
    }
  }

  /// 月视图切回周视图（非本月）时的落点：当月第一个有安排的日子，
  /// 避免落在开学前的空周；整月没安排就回到 1 号
  DateTime _firstBusyDayOfMonth() {
    final first = DateTime(_anchor.year, _anchor.month, 1);
    final periods = store.periodsBetween(
        first, DateTime(_anchor.year, _anchor.month + 1, 1));
    return periods.isEmpty ? first : periods.first.startTime;
  }

  /// 统计视图里翻的是学期：列表新 → 旧，所以「上一个」是序号 +1
  void _stepSemester(int delta) =>
      store.selectSemester(store.selectedSemesterIndex - delta);

  void _step(int delta) {
    if (_mode == _ViewMode.stats) {
      _stepSemester(delta);
    } else if (_mode == _ViewMode.week) {
      _goTo(_anchor.add(Duration(days: 7 * delta)));
    } else {
      _goTo(DateTime(_anchor.year, _anchor.month + delta, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        _followSemesterPicker();
        final isWeek = _mode == _ViewMode.week;
        final isStats = _mode == _ViewMode.stats;
        final monday = DesktopStore.mondayOf(_anchor);
        final todaySemester = store.semesterIndexOn(_today);
        final showsToday = switch (_mode) {
          _ViewMode.week => monday == DesktopStore.mondayOf(_today),
          _ViewMode.month =>
            _anchor.year == _today.year && _anchor.month == _today.month,
          _ViewMode.stats => todaySemester == store.selectedSemesterIndex,
        };
        final semester = store.selectedSemester;

        final String title;
        if (isStats) {
          title = '${semester?.name ?? ''} 课时统计';
        } else if (isWeek) {
          final sunday = monday.add(const Duration(days: 6));
          final week = store.teachingWeekOn(monday);
          title = '${week != null ? '第 $week 周 · ' : ''}'
              '${monday.month}/${monday.day} – ${sunday.month}/${sunday.day}'
              '${showsToday ? '（本周）' : ''}';
        } else {
          title = '${_anchor.year} 年 ${_anchor.month} 月';
        }

        return DCard(
          title: title,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            _ModeSwitch(
                mode: _mode,
                onChanged: (m) {
                  // 统计视图进出不动日期：日期已随顶栏学期跳过
                  if (isStats || m == _ViewMode.stats) {
                    setState(() => _mode = m);
                  } else {
                    _goTo(
                        m == _ViewMode.week && !showsToday
                            ? _firstBusyDayOfMonth()
                            : (showsToday ? _today : _anchor),
                        mode: m);
                  }
                }),
            const SizedBox(width: DS.s3),
            IconButton(
                tooltip: isStats ? '上一学期' : (isWeek ? '上一周' : '上个月'),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: isStats &&
                        store.selectedSemesterIndex >=
                            store.semesters.length - 1
                    ? null
                    : () => _step(-1),
                icon: const Icon(Icons.chevron_left)),
            TextButton(
                onPressed: showsToday || (isStats && todaySemester == null)
                    ? null
                    : () => isStats
                        ? store.selectSemester(todaySemester!)
                        : _goTo(_today),
                child: Text(isStats ? '本学期' : (isWeek ? '本周' : '本月'))),
            IconButton(
                tooltip: isStats ? '下一学期' : (isWeek ? '下一周' : '下个月'),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: isStats && store.selectedSemesterIndex <= 0
                    ? null
                    : () => _step(1),
                icon: const Icon(Icons.chevron_right)),
          ]),
          padding: const EdgeInsets.fromLTRB(DS.s2, 0, DS.s3, DS.s3),
          child: switch (_mode) {
            _ViewMode.week => _WeekView(monday: monday, store: store),
            _ViewMode.month => _MonthView(
                month: DateTime(_anchor.year, _anchor.month, 1),
                store: store,
                onOpenDay: (d) => _goTo(d, mode: _ViewMode.week),
              ),
            _ViewMode.stats => semester == null
                ? const EmptyHint('还没有课程数据')
                : ClassHoursView(hours: store.hoursOf(semester)),
          },
        );
      },
    );
  }
}

/// 周 / 月 / 统计 分段切换
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    Widget seg(_ViewMode m, String label) {
      final on = m == mode;
      return MouseRegion(
        cursor: on ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: on ? null : () => onChanged(m),
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: DS.s3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? colors.card : null,
              borderRadius: BorderRadius.circular(DS.radiusSm - 2),
              border: on ? Border.all(color: colors.border) : null,
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: DS.fsSmall,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    color: on ? primary : colors.muted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.subtle,
        borderRadius: BorderRadius.circular(DS.radiusSm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg(_ViewMode.week, '周'),
        seg(_ViewMode.month, '月'),
        seg(_ViewMode.stats, '统计'),
      ]),
    );
  }
}

// ───────────────────────── 周视图 ─────────────────────────

const double _headerHeight = 38;

class _WeekView extends StatelessWidget {
  const _WeekView({required this.monday, required this.store});
  final DateTime monday;
  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    final week = store.periodsOfWeek(monday);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Column(children: [
          SizedBox(height: _headerHeight),
          Expanded(child: HourAxis()),
        ]),
        for (var i = 0; i < 7; i++)
          Expanded(
            // 周末没课时只占一半宽度，把空间让给工作日
            flex: i >= 5 && week[i].isEmpty ? 1 : 2,
            child: _DayColumn(
              day: monday.add(Duration(days: i)),
              periods: week[i],
              store: store,
            ),
          ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn(
      {required this.day, required this.periods, required this.store});

  final DateTime day;
  final List<Period> periods;
  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final now = store.now;
    final isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;
    final holiday = store.specialDateOf(day);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: isToday ? primary.withValues(alpha: 0.05) : null,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${weekdayName(day.weekday)} ${day.month}/${day.day}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DText.strong(context)
                        .copyWith(color: isToday ? primary : null)),
                if (holiday != null)
                  Text(holiday,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DText.muted(context)
                          .copyWith(color: DS.warning, fontSize: 10.5)),
              ],
            ),
          ),
          Expanded(
            child: DayTimeline(day: day, periods: periods, now: now),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 月视图 ─────────────────────────

/// 月历：每行一周，左侧标教学周；格子里按时间列出当天的时段，放不下的折成「+N 项」。
/// 点格子空白处进入那一周的周视图，点时段看详情。
class _MonthView extends StatelessWidget {
  const _MonthView(
      {required this.month, required this.store, required this.onOpenDay});

  /// 当月 1 号
  final DateTime month;
  final DesktopStore store;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final start = DesktopStore.mondayOf(month);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final weeks = lastOfMonth.difference(start).inDays ~/ 7 + 1;
    final end = start.add(Duration(days: weeks * 7));

    // 一次取整月，再按开始日期分到各格
    final byDay = <DateTime, List<Period>>{};
    for (final p in store.periodsBetween(start, end)) {
      final d = DateTime(p.startTime.year, p.startTime.month, p.startTime.day);
      (byDay[d] ??= []).add(p);
    }
    List<Period> on(DateTime d) => byDay[d] ?? const [];

    // 整月周末都没课时，周末两列只占一半宽度
    final weekendEmpty = [
      for (var w = 0; w < weeks; w++)
        for (final i in [5, 6]) start.add(Duration(days: w * 7 + i)),
    ].every((d) => on(d).isEmpty);
    int flexOf(int i) => i >= 5 && weekendEmpty ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 26,
          child: Row(children: [
            const SizedBox(width: _weekLabelWidth),
            for (var i = 0; i < 7; i++)
              Expanded(
                flex: flexOf(i),
                child: Center(
                    child: Text(weekdayName(i + 1),
                        style: DText.muted(context)
                            .copyWith(fontWeight: FontWeight.w600))),
              ),
          ]),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: colors.border),
                    right: BorderSide(color: colors.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var w = 0; w < weeks; w++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WeekLabel(
                            week: store.teachingWeekOn(
                                start.add(Duration(days: w * 7)))),
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            flex: flexOf(i),
                            child: Builder(builder: (context) {
                              final d = start.add(Duration(days: w * 7 + i));
                              return _MonthCell(
                                day: d,
                                inMonth: d.month == month.month,
                                periods: on(d),
                                store: store,
                                onOpen: () => onOpenDay(d),
                              );
                            }),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const double _weekLabelWidth = 40;

/// 月历左侧的教学周号
class _WeekLabel extends StatelessWidget {
  const _WeekLabel({required this.week});
  final int? week;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _weekLabelWidth,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, right: DS.s1),
          child: Text(week == null ? '' : '第$week周',
              textAlign: TextAlign.right,
              style: DText.muted(context).copyWith(fontSize: 10.5)),
        ),
      );
}

class _MonthCell extends StatefulWidget {
  const _MonthCell({
    required this.day,
    required this.inMonth,
    required this.periods,
    required this.store,
    required this.onOpen,
  });

  final DateTime day;
  final bool inMonth;
  final List<Period> periods;
  final DesktopStore store;
  final VoidCallback onOpen;

  @override
  State<_MonthCell> createState() => _MonthCellState();
}

class _MonthCellState extends State<_MonthCell> {
  bool _hover = false;

  static const double _chipHeight = 17;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final day = widget.day;
    final now = widget.store.now;
    final isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;
    final holiday = widget.store.specialDateOf(day);
    final periods = widget.periods;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: Container(
          decoration: BoxDecoration(
            color: isToday
                ? scheme.primary.withValues(alpha: 0.05)
                : (_hover ? colors.subtle.withValues(alpha: 0.6) : null),
            border: Border(
                left: BorderSide(color: colors.border),
                top: BorderSide(color: colors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
          child: Opacity(
            opacity: widget.inMonth ? 1 : 0.45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 20,
                  child: Row(children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: isToday
                          ? BoxDecoration(
                              color: scheme.primary, shape: BoxShape.circle)
                          : null,
                      child: Text('${day.day}',
                          style: TextStyle(
                              fontSize: DS.fsSmall,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? scheme.onPrimary
                                  : scheme.onSurface)),
                    ),
                    if (holiday != null) ...[
                      const SizedBox(width: DS.s1),
                      Expanded(
                        child: Text(holiday,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DText.muted(context)
                                .copyWith(color: DS.warning, fontSize: 10.5)),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    final fit = (c.maxHeight / _chipHeight).floor();
                    if (fit <= 0 || periods.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final overflow = periods.length > fit;
                    final shown =
                        overflow ? periods.take(fit - 1).toList() : periods;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final p in shown)
                          SizedBox(
                              height: _chipHeight,
                              child: _MonthChip(period: p)),
                        if (overflow)
                          SizedBox(
                            height: _chipHeight,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text('+${periods.length - shown.length} 项',
                                  style: DText.muted(context)
                                      .copyWith(fontSize: 10.5)),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 月历格子里的一行时段：色条 + 开始时间 + 名称
class _MonthChip extends StatefulWidget {
  const _MonthChip({required this.period});
  final Period period;

  @override
  State<_MonthChip> createState() => _MonthChipState();
}

class _MonthChipState extends State<_MonthChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.period;
    final base = periodColor(p);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final nameColor = Color.lerp(base, onSurface, dark ? 0.15 : 0.45)!;
    return Tooltip(
      message: [
        p.summary,
        fmtRange(p.startTime, p.endTime),
        if (p.location.isNotEmpty) p.location,
      ].join('\n'),
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => showPeriodDetail(context, p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: base.withValues(
                  alpha: (dark ? 0.22 : 0.12) + (_hover ? 0.1 : 0)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(children: [
              Container(
                  width: 3,
                  height: 10,
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(1.5))),
              const SizedBox(width: 3),
              Text(fmtTime(p.startTime),
                  style:
                      DText.muted(context).copyWith(fontSize: 10, height: 1.2)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                    p.type == PeriodType.test ? '【考试】${p.summary}' : p.summary,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: nameColor)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
