import 'package:flutter/material.dart';
import '../store.dart';
import '../screens/grades_screen.dart';
import '../widgets/page_header.dart';
import '../widgets/semester_dropdown.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key, required this.store});
  final DesktopStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => PaperPage(
          store: store,
          header: PageHeader(
              title: '成绩',
              subtitle: '已获 ${store.earnedCredit} 学分',
              actions: [SemesterDropdown(store: store)]),
          // PHASE2: Replace the legacy grades body (including its eye toggle).
          child: GradesScreen(store: store)));
}
