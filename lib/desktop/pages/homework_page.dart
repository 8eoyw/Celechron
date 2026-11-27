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
                          outlined: true,
                          borderRadius: Paper.pillRadius,
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
                              horizontal: 12, vertical: 5),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 160),
                                child: Text(selected ?? '全部课程',
                                    style: PaperType.meta(context).copyWith(
                                        color: PaperColors.of(context).text),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16, color: PaperColors.of(context).text2)
                          ]))),
                  const SizedBox(width: 8),
                  PaperIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: '刷新作业',
                      onPressed: store.refresh)
                ]),
            padding: const EdgeInsets.fromLTRB(28, 12, 20, 16),
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: todos.isEmpty
                        ? const EmptyState('没有待交作业',
                            icon: Icons.check_circle_outline_rounded,
                            subtitle: '目前没有待提交的课程作业')
                        : HomeworkList(todos: todos, now: store.now))));
      });
}
