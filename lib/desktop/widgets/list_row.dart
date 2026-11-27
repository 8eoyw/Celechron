import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Interactive target modeled after Antigravity's flat, borderless translucent
/// selection fills. Keyboard focus always displays a crisp accent ring.
class PaperAction extends StatefulWidget {
  const PaperAction(
      {super.key,
      required this.child,
      required this.onTap,
      this.onSecondaryTapDown,
      this.selected = false,
      this.outlined = false,
      this.borderRadius,
      this.tooltip,
      this.padding = EdgeInsets.zero});
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final bool selected;
  final bool outlined;
  final double? borderRadius;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  @override
  State<PaperAction> createState() => _PaperActionState();
}

class _PaperActionState extends State<PaperAction> {
  bool hover = false, focus = false;
  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    final radius = widget.borderRadius ?? Paper.smallRadius;
    final Color? fill = widget.selected
        ? c.selectionFill
        : hover
            ? c.hover
            : (widget.outlined ? c.glassControl : null);
    final Color borderColor = focus
        ? c.accent
        : widget.outlined
            ? (hover ? c.text3.withValues(alpha: .5) : c.hairlineStrong)
            : const Color(0x00000000);

    Widget result = FocusableActionDetector(
      enabled: widget.onTap != null,
      mouseCursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onShowFocusHighlight: (v) => setState(() => focus = v),
      onShowHoverHighlight: (v) => setState(() => hover = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onTap?.call();
          return null;
        })
      },
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onSecondaryTapDown: widget.onSecondaryTapDown,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              padding: widget.padding,
              decoration: BoxDecoration(
                  color: fill, borderRadius: BorderRadius.circular(radius)),
              foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                      color: borderColor, width: focus ? 1.5 : 1)),
              child: widget.child)),
    );
    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}

class PaperIconButton extends StatelessWidget {
  const PaperIconButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => PaperAction(
      tooltip: tooltip,
      borderRadius: Paper.smallRadius,
      onTap: onPressed,
      child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 17, color: PaperColors.of(context).text2)));
}
