import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'list_row.dart';

class PaperSegmented<T> extends StatelessWidget {
  const PaperSegmented(
      {super.key,
      required this.values,
      required this.value,
      required this.onChanged});
  final Map<T, String> values;
  final T value;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: c.glassControl,
            border: Border.all(color: c.hairline),
            // Exact M3 concentric radii: outer 12px = inner 8px + 4px padding.
            borderRadius: BorderRadius.circular(Paper.blockRadius)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final entry in values.entries)
            PaperAction(
                selected: entry.key == value,
                borderRadius: Paper.smallRadius,
                onTap: () => onChanged(entry.key),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(entry.value,
                    style: PaperType.meta(context).copyWith(
                        fontWeight: entry.key == value
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: entry.key == value ? c.selectionInk : c.text2)))
        ]));
  }
}
