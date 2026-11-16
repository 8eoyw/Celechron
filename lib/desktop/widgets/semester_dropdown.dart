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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(store.selectedSemester?.name ?? '暂无学期',
                style: PaperType.meta(context)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16)
          ])));
}
