import 'package:flutter/material.dart';
import '../../store.dart';
import '../../screens/timetable_screen.dart';
import '../../widgets/page_header.dart';
import '../../widgets/semester_dropdown.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final DesktopStore store;
  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  final timetable = GlobalKey<TimetableScreenState>();
  void openDay(DateTime day) => timetable.currentState?.openDay(day);
  void handleKey(String key) => timetable.currentState?.handleKey(key);
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => PaperPage(
          store: widget.store,
          header: PageHeader(
              title: '日程',
              subtitle: '${widget.store.now.year}年${widget.store.now.month}月',
              actions: [SemesterDropdown(store: widget.store)]),
          // PHASE2: Replace the legacy body with week/month/hours views; retain these navigation hooks.
          child: TimetableScreen(key: timetable, store: widget.store)));
}
