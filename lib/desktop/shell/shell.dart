import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/today_page.dart';
import '../pages/homework_page.dart';
import '../pages/settings_page.dart';
import '../pages/calendar/calendar_page.dart';
import '../pages/exams_page.dart';
import '../pages/grades_page.dart';
import '../pages/tasks_page.dart';
import '../store.dart';
import 'command_palette.dart';
import 'navigation.dart';
import 'sidebar.dart';
export 'navigation.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell(
      {super.key, required this.store, this.initialPage = DesktopPage.today});
  final DesktopStore store;
  final DesktopPage initialPage;
  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell>
    with SingleTickerProviderStateMixin {
  late DesktopPage page = widget.initialPage;
  bool? manualCollapsed;
  bool? wasNarrow;
  bool paletteOpen = false;
  final calendar = GlobalKey<CalendarPageState>();
  late final fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120), value: 1);
  late final pages = <Widget>[
    TodayPage(store: widget.store, onNavigate: navigate),
    CalendarPage(key: calendar, store: widget.store),
    HomeworkPage(store: widget.store),
    ExamsPage(store: widget.store),
    GradesPage(store: widget.store),
    TasksPage(store: widget.store),
    SettingsPage(store: widget.store)
  ];
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(onKey);
    fade.dispose();
    super.dispose();
  }

  void navigate(DesktopPage destination) {
    if (!mounted || destination == page) return;
    setState(() => page = destination);
    fade.forward(from: 0);
  }

  void toggleSidebar() {
    setState(() => manualCollapsed = !(manualCollapsed ?? wasNarrow ?? false));
  }

  Future<void> search() async {
    if (paletteOpen) {
      Navigator.of(context).pop();
      return;
    }
    paletteOpen = true;
    final result = await showCommandPalette(context, widget.store);
    paletteOpen = false;
    if (mounted && result != null) navigate(result);
  }

  bool onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (key == LogicalKeyboardKey.f5 ||
        ctrl && key == LogicalKeyboardKey.keyR) {
      widget.store.refresh();
      return true;
    }
    if (ctrl && key == LogicalKeyboardKey.keyK) {
      search();
      return true;
    }
    if (paletteOpen ||
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<EditableText>() !=
            null) {
      return false;
    }
    if (ctrl) {
      const digits = [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6
      ];
      final index = digits.indexOf(key);
      if (index >= 0) {
        navigate(DesktopPage.values[index]);
        return true;
      }
      if (key == LogicalKeyboardKey.comma) {
        navigate(DesktopPage.settings);
        return true;
      }
      if (key == LogicalKeyboardKey.backslash) {
        toggleSidebar();
        return true;
      }
    }
    if (!ctrl && page == DesktopPage.calendar) {
      final command = {
        LogicalKeyboardKey.arrowLeft: 'left',
        LogicalKeyboardKey.arrowRight: 'right',
        LogicalKeyboardKey.keyT: 't',
        LogicalKeyboardKey.keyW: 'w',
        LogicalKeyboardKey.keyM: 'm'
      }[key];
      if (command != null) {
        calendar.currentState?.handleKey(command);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) =>
          Scaffold(body: LayoutBuilder(builder: (context, size) {
            final narrow = size.maxWidth < 1080;
            if (wasNarrow != null && wasNarrow != narrow) {
              manualCollapsed = null;
            }
            wasNarrow = narrow;
            return Row(children: [
              DesktopSidebar(
                  store: widget.store,
                  collapsed: manualCollapsed ?? narrow,
                  selected: page,
                  onNavigate: navigate,
                  onSearch: search,
                  onToggleCollapse: toggleSidebar,
                  onOpenDay: (date) {
                    final mounted = calendar.currentState;
                    navigate(DesktopPage.calendar);
                    if (mounted != null) {
                      mounted.openDay(date);
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => calendar.currentState?.openDay(date));
                      WidgetsBinding.instance.ensureVisualUpdate();
                    }
                  }),
              Expanded(
                  child: FadeTransition(
                      opacity: fade,
                      child: IndexedStack(index: page.index, children: [
                        for (final destination in DesktopPage.values)
                          if (destination == page ||
                              destination == DesktopPage.calendar)
                            pages[destination.index]
                          else
                            const SizedBox.expand()
                      ])))
            ]);
          })));
}
