import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Calm Google M3 empty state with optional centered icon + guidance.
class EmptyState extends StatelessWidget {
  const EmptyState(this.text,
      {super.key, this.icon, this.subtitle, this.compact = false});
  final String text;
  final IconData? icon;
  final String? subtitle;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    if (compact || icon == null) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(text, style: PaperType.meta(context)));
    }
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: c.glassControl, shape: BoxShape.circle),
                      child: Icon(icon, size: 20, color: c.text3)),
                  const SizedBox(height: 12),
                  Text(text,
                      style: PaperType.strong(context)
                          .copyWith(color: c.text2)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: PaperType.meta(context)
                            .copyWith(color: c.text3),
                        textAlign: TextAlign.center)
                  ]
                ])));
  }
}
