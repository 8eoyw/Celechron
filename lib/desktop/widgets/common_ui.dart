import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:celechron/model/todo.dart';
import '../format.dart';
import '../theme/tokens.dart';

Uri homeworkUri(Todo todo) => Uri.parse(todo.courseId == null
    ? 'https://courses.zju.edu.cn/user/index'
    : 'https://courses.zju.edu.cn/course/${todo.courseId}/learning-activity#/${Uri.encodeComponent(todo.id)}');

Future<void> openHomework(Todo todo) async {
  try {
    await launchUrl(homeworkUri(todo), mode: LaunchMode.externalApplication);
  } catch (_) {
    // No browser available in headless / restricted environments.
  }
}

/// Interactive M3/Antigravity button/surface primitive with crisp hover & focus.
class DesktopAction extends StatefulWidget {
  const DesktopAction({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTapDown,
    this.onHoverChanged,
    this.tooltip,
    this.padding = EdgeInsets.zero,
    this.borderRadius = DesktopRadius.chip,
    this.backgroundColor,
    this.hoverColor,
    this.borderColor,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final ValueChanged<bool>? onHoverChanged;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? hoverColor;
  final Color? borderColor;
  final bool selected;

  @override
  State<DesktopAction> createState() => _DesktopActionState();
}

class _DesktopActionState extends State<DesktopAction> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final enabled = widget.onTap != null || widget.onDoubleTap != null;
    final bg = widget.selected
        ? c.selectedFill
        : (_hovered && enabled)
            ? (widget.hoverColor ?? c.hover)
            : (widget.backgroundColor ?? Colors.transparent);
    final border = _focused
        ? Border.all(color: c.primary, width: 1.5)
        : widget.selected
            ? Border.all(color: c.selectedBorder)
            : widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null;

    Widget content = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHoverChanged?.call(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHoverChanged?.call(false);
      },
      child: Focus(
        canRequestFocus: enabled,
        onFocusChange: (f) => setState(() => _focused = f),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onSecondaryTapDown: widget.onSecondaryTapDown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: border,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }
    return content;
  }
}

class DesktopIconButton extends StatelessWidget {
  const DesktopIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 18,
    this.boxSize = 32,
    this.color,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double boxSize;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return DesktopAction(
      onTap: onPressed,
      tooltip: tooltip,
      selected: selected,
      borderRadius: DesktopRadius.chip,
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: Center(
          child: Icon(
            icon,
            size: size,
            color: onPressed == null
                ? c.text3.withValues(alpha: 0.45)
                : (selected ? c.primary : (color ?? c.text2)),
          ),
        ),
      ),
    );
  }
}

/// Small concentric tag/badge (4–6px radius, never an oval).
class ConcentricTag extends StatelessWidget {
  const ConcentricTag({
    super.key,
    required this.label,
    this.foreground,
    this.background,
    this.borderColor,
    this.radius = DesktopRadius.badge,
    this.numeric = false,
  });

  final String label;
  final Color? foreground;
  final Color? background;
  final Color? borderColor;
  final double radius;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: background ?? c.surfaceHigh,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DesktopType.caption(context, numeric: numeric).copyWith(
          color: foreground ?? c.text2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Clean M3 segmented control using concentric 8px outer / 6px inner radii.
class DesktopSegmented<T> extends StatelessWidget {
  const DesktopSegmented({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final Map<T, String> items;
  final T value;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(DesktopRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in items.entries)
            _SegmentItem(
              label: entry.value,
              selected: entry.key == value,
              compact: compact,
              onTap: () => onChanged(entry.key),
            ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return DesktopAction(
      onTap: onTap,
      borderRadius: DesktopRadius.badge,
      backgroundColor: selected ? c.sheet : Colors.transparent,
      hoverColor: selected ? c.sheet : c.hover,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 5,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: DesktopType.meta(context).copyWith(
          color: selected ? c.text1 : c.text2,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class DesktopScrollArea extends StatefulWidget {
  const DesktopScrollArea({
    super.key,
    required this.child,
    this.controller,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;

  @override
  State<DesktopScrollArea> createState() => _DesktopScrollAreaState();
}

class _DesktopScrollAreaState extends State<DesktopScrollArea> {
  ScrollController? _owned;
  ScrollController get _effective =>
      widget.controller ?? (_owned ??= ScrollController());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: _effective,
        child: SingleChildScrollView(
          controller: _effective,
          padding: widget.padding,
          child: widget.child,
        ),
      );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing, this.color});
  final String title;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: DesktopType.label(context).copyWith(color: color ?? c.text2),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: compact ? 16 : 36,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(DesktopRadius.card),
                ),
                child: Icon(icon, size: compact ? 18 : 22, color: c.text3),
              ),
              SizedBox(height: compact ? 8 : 12),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: compact
                  ? DesktopType.meta(context)
                  : DesktopType.section(context),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: DesktopType.meta(context),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.rows = 6});
  final int rows;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows; i++) ...[
            Row(
              children: [
                Container(
                  width: 44,
                  height: 14,
                  decoration: BoxDecoration(
                    color: c.surfaceHigh,
                    borderRadius: BorderRadius.circular(DesktopRadius.tag),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: i.isEven ? 48 : 34,
                    decoration: BoxDecoration(
                      color: c.surfaceHigh.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(DesktopRadius.block),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class DeadlineCountdown extends StatelessWidget {
  const DeadlineCountdown({super.key, required this.target, required this.now});
  final DateTime target;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    final diff = target.difference(now);
    final overdue = diff.isNegative;
    final urgent = !overdue && diff <= const Duration(hours: 24);
    final soon = !overdue && !urgent && diff <= const Duration(days: 7);
    final text = fmtDeadlineCountdown(target, now);

    final Color fg;
    final Color? bg;
    if (overdue) {
      fg = c.danger;
      bg = c.dangerFill;
    } else if (urgent) {
      fg = c.warning;
      bg = c.warningFill;
    } else if (soon) {
      fg = c.primary;
      bg = c.selectedFill;
    } else {
      fg = c.text2;
      bg = null;
    }

    if (bg != null) {
      return ConcentricTag(
        label: text,
        foreground: fg,
        background: bg,
        radius: DesktopRadius.tag,
        numeric: true,
      );
    }
    return Text(
      text,
      style: DesktopType.caption(context, numeric: true).copyWith(color: fg),
    );
  }
}

Future<T?> showDesktopContextMenu<T>(
  BuildContext context,
  Offset globalPosition,
  Map<T, String> items,
) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final c = DesktopColors.of(context);
  return showMenu<T>(
    context: context,
    color: c.sheet,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesktopRadius.popover),
      side: BorderSide(color: c.hairline),
    ),
    position: RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      for (final entry in items.entries)
        PopupMenuItem<T>(
          value: entry.key,
          height: 36,
          child: Text(entry.value, style: DesktopType.body(context)),
        ),
    ],
  );
}
