import 'package:flutter/material.dart';
import '../store.dart';
import '../theme/tokens.dart';
import 'list_row.dart';
import 'context_menu.dart';

class SemesterDropdown extends StatelessWidget {
  const SemesterDropdown({super.key, required this.store});
  final DesktopStore store;
  @override
  Widget build(BuildContext context) => Builder(
      builder: (context) => PaperAction(
          outlined: true,
          borderRadius: Paper.pillRadius,
          onTap: store.semesters.isEmpty
              ? null
              : () async {
                  final box = context.findRenderObject()! as RenderBox;
                  final value = await paperContextMenu(
                      context, box.localToGlobal(Offset(0, box.size.height)), {
                    for (var i = 0; i < store.semesters.length; i++)
                      i: store.semesters[i].name
                  });
                  if (value != null) store.selectSemester(value);
                },
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(store.selectedSemester?.name ?? '暂无学期',
                style: PaperType.meta(context)
                    .copyWith(color: PaperColors.of(context).text)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: PaperColors.of(context).text2)
          ])));
}
