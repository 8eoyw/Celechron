import 'package:flutter/material.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/list_row.dart';
import '../../widgets/page_header.dart';
import '../../widgets/segmented_control.dart';
import '../../widgets/semester_dropdown.dart';
import 'hours_view.dart';
import 'month_view.dart';
import 'week_view.dart';

enum _CalendarView { week, month, hours }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final DesktopStore store;
  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  // Remember the preference with this store, including page remounts.
  static final _views = Expando<_CalendarView>();
  late _CalendarView _view = _views[widget.store] ?? _CalendarView.week;
  late DateTime _anchor = _today;
  String? _seenSemester;
  bool _sawSemester = false;
  DesktopStore get store => widget.store;
  DateTime get _today =>
      DateTime(store.now.year, store.now.month, store.now.day);

  // Navigation contract used by the shell and sidebar mini calendar.
  void openDay(DateTime day) => _goTo(day, view: _CalendarView.week);
  void handleKey(String key) {
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus?.widget is EditableText ||
        focus?.findAncestorWidgetOfExactType<EditableText>() != null) {
      return;
    }
    switch (key.toLowerCase()) {
      case 'left':
        _step(-1);
      case 'right':
        _step(1);
      case 't':
        _goToday();
      case 'w':
        _setView(_CalendarView.week);
      case 'm':
        _setView(_CalendarView.month);
    }
  }

  void _followSemester() {
    final semester = store.selectedSemester;
    if (_sawSemester && semester?.name != _seenSemester && semester != null) {
      _anchor = store.semesterIndexOn(_today) == store.selectedSemesterIndex
          ? _today
          : DateTime(semester.firstDay.year, semester.firstDay.month,
              semester.firstDay.day);
    }
    _sawSemester = true;
    _seenSemester = semester?.name;
  }

  void _goTo(DateTime day, {_CalendarView? view}) {
    setState(() {
      _anchor = DateTime(day.year, day.month, day.day);
      if (view != null) _view = view;
      _views[store] = _view;
    });
    final index = store.semesterIndexOn(_anchor);
    if (index != null && index != store.selectedSemesterIndex) {
      _seenSemester = store.semesters[index].name;
      store.selectSemester(index);
    }
  }

  void _setView(_CalendarView view) {
    var day = _anchor;
    if (view == _CalendarView.week &&
        _view == _CalendarView.month &&
        day.year == _today.year &&
        day.month == _today.month) {
      day = _today;
    }
    _goTo(day, view: view);
  }

  void _goToday() {
    if (_view == _CalendarView.hours) {
      final index = store.semesterIndexOn(_today);
      if (index != null) store.selectSemester(index);
    }
    _goTo(_today);
  }

  void _step(int delta) {
    switch (_view) {
      case _CalendarView.week:
        _goTo(DateTime(_anchor.year, _anchor.month, _anchor.day + delta * 7));
      case _CalendarView.month:
        _goTo(DateTime(_anchor.year, _anchor.month + delta, 1));
      case _CalendarView.hours:
        store.selectSemester(store.selectedSemesterIndex - delta);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        _followSemester();
        final monday = DesktopStore.mondayOf(_anchor);
        final sunday = DateTime(monday.year, monday.month, monday.day + 6);
        final week = store.teachingWeekOn(monday);
        final subtitle = switch (_view) {
          _CalendarView.week =>
            '${week == null ? '' : '第 $week 周 · '}${monday.month}/${monday.day} – ${sunday.month}/${sunday.day}',
          _CalendarView.month => '月日程',
          _CalendarView.hours => store.selectedSemester?.name ?? '暂无学期',
        };
        final hours = _view == _CalendarView.hours;
        return PaperPage(
            store: store,
            header: PageHeader(
                title: hours ? '课时' : '${_anchor.year}年${_anchor.month}月',
                subtitle: subtitle,
                actions: [
                  SemesterDropdown(store: store),
                  const SizedBox(width: 12),
                  PaperSegmented<_CalendarView>(values: const {
                    _CalendarView.week: '周',
                    _CalendarView.month: '月',
                    _CalendarView.hours: '课时'
                  }, value: _view, onChanged: _setView),
                  const SizedBox(width: 12),
                  PaperIconButton(
                      icon: Icons.chevron_left,
                      tooltip: hours ? '上一学期' : '上一页（←）',
                      onPressed: hours &&
                              store.selectedSemesterIndex >=
                                  store.semesters.length - 1
                          ? null
                          : () => _step(-1)),
                  PaperAction(
                      onTap: _goToday,
                      tooltip: '回到今天（T）',
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Text('今天', style: PaperType.meta(context))),
                  PaperIconButton(
                      icon: Icons.chevron_right,
                      tooltip: hours ? '下一学期' : '下一页（→）',
                      onPressed: hours && store.selectedSemesterIndex <= 0
                          ? null
                          : () => _step(1))
                ]),
            child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: PaperColors.of(context).surface,
                    borderRadius: BorderRadius.circular(Paper.blockRadius),
                    border:
                        Border.all(color: PaperColors.of(context).hairline)),
                child: switch (_view) {
                  _CalendarView.week => CalendarWeekView(
                      key: ValueKey(monday), monday: monday, store: store),
                  _CalendarView.month => CalendarMonthView(
                      month: DateTime(_anchor.year, _anchor.month),
                      store: store,
                      onOpenDay: openDay),
                  _CalendarView.hours => CalendarHoursView(store: store),
                }));
      });
}
