import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text,
      {super.key, this.trailing, this.danger = false});
  final String text;
  final Widget? trailing;
  final bool danger;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
