import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Common mouse/keyboard target. Keyboard focus always has a 2px accent ring.
class PaperAction extends StatefulWidget {
  const PaperAction(
      {super.key,
      required this.child,
      required this.onTap,
      this.onSecondaryTapDown,
      this.selected = false,
      this.tooltip,
      this.padding = EdgeInsets.zero});
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final bool selected;
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
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: widget.padding,
              decoration: BoxDecoration(
                  color: widget.selected
                      ? c.surface
                      : hover
                          ? c.hover
                          : null,
                  borderRadius: BorderRadius.circular(6)),
              foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: focus
                          ? c.accent
                          : widget.selected
                              ? c.hairline
                              : const Color(0x00000000),
                      width: focus ? 2 : 1)),
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
      onTap: onPressed,
      child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: PaperColors.of(context).text2)));
}
