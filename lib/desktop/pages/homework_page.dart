import 'package:flutter/material.dart';
import '../format.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/context_menu.dart';
import '../widgets/empty_state.dart';
import '../widgets/homework_list.dart';
import '../widgets/list_row.dart';
import '../widgets/page_header.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key, required this.store});
  final DesktopStore store;
  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  String? course;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final counts = <String, int>{};
        for (final t in store.todos) {
          counts.update(t.course, (v) => v + 1, ifAbsent: () => 1);
        }
        final selected = counts.containsKey(course) ? course : null;
        final todos = store.todos
            .where((t) => selected == null || t.course == selected)
            .toList();
        return PaperPage(
            store: store,
            header: PageHeader(
                title: '作业',
                subtitle:
                    '${store.todos.length} 项待交 · 更新于 ${updatedAgo(store.homeworkUpdatedAt, store.now)}',
                actions: [
                  Builder(
                      builder: (context) => PaperAction(
                          onTap: () async {
                            final box =
                                context.findRenderObject()! as RenderBox;
                            final result = await paperContextMenu(context,
                                box.localToGlobal(Offset(0, box.size.height)), {
                              '': '全部课程',
                              for (final e in counts.entries)
                                e.key: '${e.key}（${e.value}）'
                            });
                            if (result != null && mounted) {
                              setState(() =>
                                  course = result.isEmpty ? null : result);
                            }
                          },
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 160),
                                child: Text(selected ?? '全部课程',
                                    style: PaperType.meta(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.expand_more, size: 16)
                          ]))),
                  const SizedBox(width: 8),
                  PaperIconButton(
                      icon: Icons.refresh,
                      tooltip: '刷新作业',
                      onPressed: store.refresh)
                ]),
            child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: todos.isEmpty
                        ? const EmptyState('没有待交作业')
                        : HomeworkList(todos: todos, now: store.now))));
      });
}
