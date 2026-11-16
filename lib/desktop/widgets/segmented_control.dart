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
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: PaperColors.of(context).hover,
          borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final entry in values.entries)
          PaperAction(
              selected: entry.key == value,
              onTap: () => onChanged(entry.key),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Text(entry.value,
                  style: PaperType.meta(context).copyWith(
                      color: entry.key == value
                          ? PaperColors.of(context).text
                          : null)))
      ]));
}
