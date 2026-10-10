import 'package:flutter/material.dart';

import 'package:celechron/desktop/theme.dart';
import 'package:celechron/model/period.dart';

// ───────────────────────── 格式化 ─────────────────────────

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

String two(int v) => v.toString().padLeft(2, '0');

/// 14:05
String fmtTime(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

/// 14:05–15:40
String fmtRange(DateTime a, DateTime b) => '${fmtTime(a)}–${fmtTime(b)}';

/// 10/12 周日
String fmtDate(DateTime t) =>
    '${t.month}/${t.day} 周${_weekdays[t.weekday - 1]}';

/// 周一 … 周日
String weekdayName(int weekday) => '周${_weekdays[weekday - 1]}';

/// 相对时间：「3 小时后」「2 天后」「已过 5 小时」，用于截止时间与倒计时
String fmtRelative(DateTime target, DateTime now) {
  final diff = target.difference(now);
  final past = diff.isNegative;
  final d = diff.abs();
  String text;
  if (d.inMinutes < 60) {
    text = '${d.inMinutes} 分钟';
  } else if (d.inHours < 24) {
    text = '${d.inHours} 小时';
  } else {
    text = '${d.inDays} 天';
  }
  return past ? '已过 $text' : '$text后';
}

/// 「更新于 3 分钟前」
String fmtAgo(DateTime t, DateTime now) {
  final d = now.difference(t);
  if (d.inMinutes < 1) return '刚刚';
  if (d.inMinutes < 60) return '${d.inMinutes} 分钟前';
  if (d.inHours < 24) return '${d.inHours} 小时前';
  return '${d.inDays} 天前';
}

/// 时段类型的颜色：课程按课名取色，其它类型固定色
Color periodColor(Period p) => switch (p.type) {
      PeriodType.classes => DS.colorFor(p.summary),
      PeriodType.test => DS.danger,
      PeriodType.flow => DS.success,
      PeriodType.user => const Color(0xFF8B5CF6),
      PeriodType.virtual => Colors.grey,
    };

String periodTypeName(PeriodType t) => switch (t) {
      PeriodType.classes => '课程',
      PeriodType.test => '考试',
      PeriodType.flow => '规划',
      PeriodType.user => '日程',
      PeriodType.virtual => '占位',
    };

// ───────────────────────── 文本样式 ─────────────────────────

class DText {
  DText._();

  static TextStyle body(BuildContext c) => TextStyle(
      fontSize: DS.fsBody,
      color: Theme.of(c).colorScheme.onSurface,
      height: 1.3);

  static TextStyle muted(BuildContext c) =>
      TextStyle(fontSize: DS.fsSmall, color: DSColors.of(c).muted, height: 1.3);

  static TextStyle strong(BuildContext c) =>
      body(c).copyWith(fontWeight: FontWeight.w600);

  static TextStyle kpi(BuildContext c) => TextStyle(
        fontSize: DS.fsKpi,
        fontWeight: FontWeight.w700,
        color: Theme.of(c).colorScheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.1,
      );
}

// ───────────────────────── 卡片 ─────────────────────────

/// 所有内容块的容器：标题栏（标题 + 右侧操作）+ 内容。
/// 卡片自身不滚动；内容可能超长时，内容区自行用 [DScrollArea]。
class DCard extends StatelessWidget {
  const DCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(DS.s4, DS.s2, DS.s4, DS.s3),
  });

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) =>
            _build(context, constraints.hasBoundedHeight));
  }

  Widget _build(BuildContext context, bool bounded) {
    final colors = DSColors.of(context);
    final body = Padding(
      padding: title == null ? padding : padding.copyWith(top: 0),
      child: child,
    );
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(DS.radius),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            SizedBox(
              height: 38,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DS.s4),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: colors.muted),
                      const SizedBox(width: DS.s2),
                    ],
                    Text(title!,
                        style: TextStyle(
                            fontSize: DS.fsCardTitle,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const Spacer(),
                    if (trailing != null)
                      DefaultTextStyle.merge(
                          style: DText.muted(context), child: trailing!),
                  ],
                ),
              ),
            ),
          // 高度有上限时内容填满卡片；放在不限高的父级里时按内容收缩
          if (bounded) Expanded(child: body) else body,
        ],
      ),
    );
  }
}

/// 卡片内允许纵向滚动的区域（唯一允许出现滚动的地方：作业栏、长表格）。
/// 带细滚动条，鼠标滚轮可用，不支持拖动。
class DScrollArea extends StatefulWidget {
  const DScrollArea({super.key, required this.child});
  final Widget child;

  @override
  State<DScrollArea> createState() => _DScrollAreaState();
}

class _DScrollAreaState extends State<DScrollArea> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: _controller,
        thumbVisibility: false,
        child:
            SingleChildScrollView(controller: _controller, child: widget.child),
      );
}

/// 大号指标：数字 + 标签（+ 可选副文字）
class KpiTile extends StatelessWidget {
  const KpiTile(
      {super.key,
      required this.label,
      required this.value,
      this.sub,
      this.color,
      this.textValue = false,
      this.action});

  final String label;
  final String value;
  final String? sub;
  final Color? color;

  /// 取值是文字（课程名等）而非数字时用较小字号
  final bool textValue;

  /// 标签右侧的小按钮（如隐藏绩点的眼睛）
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.s3, vertical: DS.s2),
      decoration: BoxDecoration(
        color: (color ?? colors.subtle)
            .withValues(alpha: color == null ? 1 : 0.10),
        borderRadius: BorderRadius.circular(DS.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Flexible(
              child: Text(label,
                  style: DText.muted(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (action != null) ...[const SizedBox(width: DS.s1), action!],
          ]),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // 文字型取值（课程名）可截断；数字取值必须完整显示，空间不够时先截副文字
              if (textValue)
                Flexible(
                  child: Text(value,
                      style: DText.strong(context).copyWith(fontSize: 15.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                )
              else
                Text(value,
                    style: DText.kpi(context), maxLines: 1, softWrap: false),
              if (sub != null) ...[
                const SizedBox(width: DS.s1),
                Flexible(
                  child: Text(sub!,
                      style: DText.muted(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 小色块标签：「考试」「已逾期」「单周」
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4)),
      );
}

/// 可点击的列表行：固定高度、悬停变色、手形光标、右键回调
class DRow extends StatefulWidget {
  const DRow({
    super.key,
    required this.child,
    this.onTap,
    this.onSecondaryTapUp,
    this.height = DS.rowHeight,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final double height;
  final bool selected;

  @override
  State<DRow> createState() => _DRowState();
}

class _DRowState extends State<DRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final clickable = widget.onTap != null || widget.onSecondaryTapUp != null;
    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTapUp: widget.onSecondaryTapUp,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: DS.s2),
          decoration: BoxDecoration(
            color: widget.selected
                ? primary.withValues(alpha: 0.10)
                : (_hover && clickable ? colors.subtle : null),
            borderRadius: BorderRadius.circular(DS.radiusSm),
          ),
          alignment: Alignment.centerLeft,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 空状态
class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.icon = Icons.inbox_outlined});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: DSColors.of(context).muted),
            const SizedBox(height: DS.s2),
            Text(text, style: DText.muted(context)),
          ],
        ),
      );
}

/// 竖向色条 + 内容，用于课程/时段条目
class ColorBarTile extends StatelessWidget {
  const ColorBarTile({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 3,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: DS.s2),
          Expanded(child: child),
        ],
      );
}

/// 在鼠标位置弹出右键菜单。[items] 为 (文字, 图标, 回调, 是否危险操作)
Future<void> showContextMenu(BuildContext context, Offset globalPosition,
    List<(String, IconData, VoidCallback, bool)> items) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final p = overlay.globalToLocal(globalPosition);
  final picked = await showMenu<int>(
    context: context,
    position: RelativeRect.fromLTRB(
        p.dx, p.dy, overlay.size.width - p.dx, overlay.size.height - p.dy),
    items: [
      for (var i = 0; i < items.length; i++)
        PopupMenuItem<int>(
          value: i,
          height: 36,
          child: Row(children: [
            Icon(items[i].$2, size: 16, color: items[i].$4 ? DS.danger : null),
            const SizedBox(width: DS.s2),
            Text(items[i].$1,
                style: TextStyle(
                    fontSize: DS.fsBody,
                    color: items[i].$4 ? DS.danger : null)),
          ]),
        ),
    ],
  );
  if (picked != null) items[picked].$3();
}

// ───────────────────────── 时间轴 ─────────────────────────

/// 时段详情对话框（总览、课表共用）
Future<void> showPeriodDetail(BuildContext context, Period p) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: periodColor(p), shape: BoxShape.circle)),
          const SizedBox(width: DS.s2),
          Expanded(
              child: Text(p.summary, style: const TextStyle(fontSize: 16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine(context, Icons.schedule,
                '${fmtDate(p.startTime)} ${fmtRange(p.startTime, p.endTime)}'),
            if (p.location.isNotEmpty)
              _detailLine(context, Icons.place_outlined, p.location),
            _detailLine(context, Icons.label_outline, periodTypeName(p.type)),
            if (p.description.isNotEmpty)
              _detailLine(context, Icons.notes, p.description),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭')),
        ],
      ),
    );

Widget _detailLine(BuildContext context, IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: DSColors.of(context).muted),
        const SizedBox(width: DS.s2),
        Expanded(child: Text(text, style: DText.body(context))),
      ]),
    );

/// 左侧整点刻度（与 [DayTimeline] 的纵轴对齐）
class HourAxis extends StatelessWidget {
  const HourAxis(
      {super.key, this.startHour = 8, this.endHour = 22, this.width = 40});
  final int startHour, endHour;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: LayoutBuilder(builder: (context, c) {
          final pxPerHour = c.maxHeight / (endHour - startHour);
          return Stack(children: [
            // 首尾刻度会被裁掉一半，只画中间的
            for (var h = startHour + 1; h < endHour; h++)
              Positioned(
                top: (h - startHour) * pxPerHour - 7,
                left: 0,
                right: DS.s1,
                child: Text('${two(h)}:00',
                    textAlign: TextAlign.right,
                    style: DText.muted(context).copyWith(fontSize: 10.5)),
              ),
          ]);
        }),
      );
}

/// 一天的纵向时间轴：整点网格线、当前时间线、按时间定位的时段块。
/// 只有真正重叠的时段才并排分栏，其余时段占满整列宽度。
class DayTimeline extends StatelessWidget {
  const DayTimeline({
    super.key,
    required this.day,
    required this.periods,
    required this.now,
    this.startHour = 8,
    this.endHour = 22,
  });

  final DateTime day;
  final List<Period> periods;
  final DateTime now;
  final int startHour, endHour;

  /// 每个时段的（所在栏, 所属重叠簇的栏数）。簇 = 时间上连成一片的时段
  static Map<Period, (int, int)> lanes(List<Period> sorted) {
    final result = <Period, (int, int)>{};
    var cluster = <Period>[];
    var laneEnds = <DateTime>[];
    DateTime? clusterEnd;
    void flush() {
      for (final p in cluster) {
        result[p] = (result[p]!.$1, laneEnds.length);
      }
      cluster = [];
      laneEnds = [];
      clusterEnd = null;
    }

    for (final p in sorted) {
      final end = clusterEnd;
      if (end != null && !p.startTime.isBefore(end)) flush();
      var lane = laneEnds.indexWhere((e) => !p.startTime.isBefore(e));
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(p.endTime);
      } else {
        laneEnds[lane] = p.endTime;
      }
      result[p] = (lane, 0);
      cluster.add(p);
      final ce = clusterEnd;
      if (ce == null || p.endTime.isAfter(ce)) clusterEnd = p.endTime;
    }
    flush();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors.of(context);
    return LayoutBuilder(builder: (context, c) {
      final minutes = (endHour - startHour) * 60;
      final pxPerMin = c.maxHeight / minutes;
      final origin = DateTime(day.year, day.month, day.day, startHour);
      final sorted = List<Period>.of(periods)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      final laneOf = lanes(sorted);
      final isToday =
          now.year == day.year && now.month == day.month && now.day == day.day;
      final nowMin = now.difference(origin).inMinutes;

      final children = <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: _HourGridPainter(
                hours: endHour - startHour, color: colors.border),
          ),
        ),
      ];
      for (final p in sorted) {
        final top = (p.startTime.difference(origin).inMinutes * pxPerMin)
            .clamp(0.0, c.maxHeight);
        final bottom = (p.endTime.difference(origin).inMinutes * pxPerMin)
            .clamp(0.0, c.maxHeight);
        if (bottom - top < 2) continue;
        final (lane, count) = laneOf[p]!;
        final laneW = c.maxWidth / count;
        children.add(Positioned(
          left: lane * laneW,
          width: laneW,
          top: top,
          height: bottom - top,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 1, 2, 1),
            child: TimelineBlock(period: p),
          ),
        ));
      }
      if (isToday && nowMin >= 0 && nowMin <= minutes) {
        children.add(Positioned(
          left: 0,
          right: 0,
          top: nowMin * pxPerMin - 3,
          child: IgnorePointer(
            child: Row(children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: DS.danger, shape: BoxShape.circle)),
              Expanded(child: Container(height: 1.5, color: DS.danger)),
            ]),
          ),
        ));
      }
      return Stack(clipBehavior: Clip.hardEdge, children: children);
    });
  }
}

class _HourGridPainter extends CustomPainter {
  _HourGridPainter({required this.hours, required this.color});
  final int hours;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i <= hours; i++) {
      final y = (size.height / hours * i).roundToDouble() + 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HourGridPainter old) =>
      old.hours != hours || old.color != color;
}

/// 时间轴上的一个时段块：浅色底 + 左侧色条，文字行数随块的实际大小增减
class TimelineBlock extends StatefulWidget {
  const TimelineBlock({super.key, required this.period});
  final Period period;

  @override
  State<TimelineBlock> createState() => _TimelineBlockState();
}

class _TimelineBlockState extends State<TimelineBlock> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.period;
    final base = periodColor(p);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final titleColor = Color.lerp(base, onSurface, dark ? 0.15 : 0.45)!;
    final fill =
        base.withValues(alpha: (dark ? 0.24 : 0.13) + (_hover ? 0.08 : 0));
    final isTest = p.type == PeriodType.test;

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
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(DS.radiusSm),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: base),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 3, 3, 2),
                    child: LayoutBuilder(builder: (context, c) {
                      // 每行约 15px：先给课名（空间够时两行），剩下的依次给地点、时间
                      var budget = (c.maxHeight / 15).floor();
                      if (budget < 1) return const SizedBox.shrink();
                      final nameLines = budget >= 4 ? 2 : 1;
                      budget -= nameLines;
                      final showPlace = budget >= 1 && p.location.isNotEmpty;
                      if (showPlace) budget -= 1;
                      final showTime = budget >= 1;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isTest ? '【考试】${p.summary}' : p.summary,
                              maxLines: nameLines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor)),
                          if (showPlace)
                            Text(p.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DText.muted(context)
                                    .copyWith(fontSize: 11, height: 1.25)),
                          if (showTime)
                            Text(fmtRange(p.startTime, p.endTime),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                                style: DText.muted(context)
                                    .copyWith(fontSize: 11, height: 1.25)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 隐藏/显示绩点的小眼睛按钮
class EyeToggle extends StatelessWidget {
  const EyeToggle({super.key, required this.hidden, required this.onTap});
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: hidden ? '显示绩点' : '隐藏绩点',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Icon(
                hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 15,
                color: DSColors.of(context).muted),
          ),
        ),
      );
}
