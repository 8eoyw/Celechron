import 'package:flutter/material.dart';
import '../store.dart';
import '../screens/exams_screen.dart';
import '../widgets/page_header.dart';
import '../widgets/semester_dropdown.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key, required this.store});
  final DesktopStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => PaperPage(
          store: store,
          header: PageHeader(
              title: '考试',
              subtitle:
                  '${store.selectedSemester?.name ?? ''} · ${store.selectedSemester == null ? 0 : store.examsOf(store.selectedSemester!).length} 场',
              actions: [SemesterDropdown(store: store)]),
          // PHASE2: Replace the legacy exams body.
          child: ExamsScreen(store: store)));
}
