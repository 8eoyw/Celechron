import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Secondary sub-group label inside a list (e.g., "已逾期 1", "今天", "周四 11/19").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text,
      {super.key, this.trailing, this.danger = false});
  final String text;
  final Widget? trailing;
  final bool danger;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: PaperType.label(context).copyWith(
                    color: danger ? PaperColors.of(context).danger : null),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        if (trailing != null) trailing!
      ]));
}

/// Primary M3 card/module header (Title Small 14px w600) — clearly stronger than
/// list items and sub-group labels for instant Google-style scannability.
class CardHeader extends StatelessWidget {
  const CardHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: PaperType.cardTitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        if (trailing != null) trailing!
      ]));
}
