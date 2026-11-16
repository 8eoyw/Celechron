import 'package:flutter/material.dart';
import '../store.dart';
import '../screens/tasks_screen.dart';
import '../widgets/page_header.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.store});
  final DesktopStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => PaperPage(
          store: store,
          header: PageHeader(
              title: '任务', subtitle: '${store.pendingDeadlines.length} 项进行中'),
          // PHASE2: Retains the task edit dialog and context menus until replaced.
          child: TasksScreen(store: store)));
}
