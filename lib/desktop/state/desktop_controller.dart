import 'package:flutter/material.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/model/todo.dart';
import 'package:celechron/page/task/task_edit_page.dart';
import '../store.dart';
import '../theme/tokens.dart';

/// Top-level Google-native 3-workspace Information Architecture.
enum DesktopDestination { schedule, tasks, academics }

/// Sub-modes inside the primary Schedule workspace.
enum ScheduleMode { day, week, month }

/// Sub-tabs inside the unified semester-scoped Academics workspace.
enum AcademicsTab { exams, grades, hours }

/// What is currently inspected in the Right Companion Panel.
sealed class InspectorTarget {
  const InspectorTarget();
}

class PeriodInspectorTarget extends InspectorTarget {
  const PeriodInspectorTarget(this.period);
  final Period period;
}

class TodoInspectorTarget extends InspectorTarget {
  const TodoInspectorTarget(this.todo);
  final Todo todo;
}

class TaskInspectorTarget extends InspectorTarget {
  const TaskInspectorTarget(this.task);
  final Task task;
}

class ExamInspectorTarget extends InspectorTarget {
  const ExamInspectorTarget(this.entry);
  final ExamEntry entry;
}

/// Unified Course Inspector joining schedule, class hours, homework, exams, and grade.
class CourseInspectorTarget extends InspectorTarget {
  const CourseInspectorTarget(this.courseName);
  final String courseName;
}

class DesktopController extends ChangeNotifier {
  DesktopController({
    DesktopDestination initialDestination = DesktopDestination.schedule,
    ScheduleMode initialScheduleMode = ScheduleMode.day,
    AcademicsTab initialAcademicsTab = AcademicsTab.exams,
    required DateTime initialDate,
  })  : _destination = initialDestination,
        _scheduleMode = initialScheduleMode,
        _academicsTab = initialAcademicsTab,
        _focusedDay =
            DateTime(initialDate.year, initialDate.month, initialDate.day);

  DesktopDestination _destination;
  ScheduleMode _scheduleMode;
  AcademicsTab _academicsTab;
  DateTime _focusedDay;
  InspectorTarget? _inspector;
  bool _companionOpen = true;
  bool _companionUserToggled = false;
  String? _hoveredTodoId;
  String? _hoveredCourseName;
  String? _taskCourseFilter;
  bool _showPeriodAxis = true;

  DesktopDestination get destination => _destination;
  ScheduleMode get scheduleMode => _scheduleMode;
  AcademicsTab get academicsTab => _academicsTab;
  DateTime get focusedDay => _focusedDay;
  InspectorTarget? get inspector => _inspector;
  bool get companionOpen => _companionOpen;
  bool get companionUserToggled => _companionUserToggled;
  String? get hoveredTodoId => _hoveredTodoId;
  String? get hoveredCourseName => _hoveredCourseName;
  String? get taskCourseFilter => _taskCourseFilter;
  bool get showPeriodAxis => _showPeriodAxis;

  void setDestination(DesktopDestination dest) {
    if (_destination == dest) return;
    _destination = dest;
    notifyListeners();
  }

  void setScheduleMode(ScheduleMode mode) {
    if (_scheduleMode == mode && _destination == DesktopDestination.schedule) {
      return;
    }
    _destination = DesktopDestination.schedule;
    _scheduleMode = mode;
    notifyListeners();
  }

  void setAcademicsTab(AcademicsTab tab) {
    if (_academicsTab == tab && _destination == DesktopDestination.academics) {
      return;
    }
    _destination = DesktopDestination.academics;
    _academicsTab = tab;
    notifyListeners();
  }

  void focusDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    if (_focusedDay == normalized) return;
    _focusedDay = normalized;
    notifyListeners();
  }

  void goToday(DateTime now) {
    focusDay(now);
  }

  void stepDate(int delta) {
    switch (_scheduleMode) {
      case ScheduleMode.day:
        focusDay(_focusedDay.add(Duration(days: delta)));
      case ScheduleMode.week:
        focusDay(_focusedDay.add(Duration(days: delta * 7)));
      case ScheduleMode.month:
        focusDay(DateTime(_focusedDay.year, _focusedDay.month + delta, 1));
    }
  }

  void inspect(InspectorTarget? target, {bool openPanel = true}) {
    _inspector = target;
    if (target != null && openPanel) {
      _companionOpen = true;
    }
    notifyListeners();
  }

  void clearInspector() {
    if (_inspector == null) return;
    _inspector = null;
    notifyListeners();
  }

  void toggleCompanion({bool? currentlyVisible}) {
    _companionUserToggled = true;
    _companionOpen =
        currentlyVisible != null ? !currentlyVisible : !_companionOpen;
    notifyListeners();
  }

  void setCompanionOpen(bool open, {bool userAction = false}) {
    if (userAction) _companionUserToggled = true;
    if (_companionOpen == open) return;
    _companionOpen = open;
    notifyListeners();
  }

  void setHoveredTodo(String? id) {
    if (_hoveredTodoId == id) return;
    _hoveredTodoId = id;
    notifyListeners();
  }

  void setHoveredCourse(String? courseName) {
    if (_hoveredCourseName == courseName) return;
    _hoveredCourseName = courseName;
    notifyListeners();
  }

  void setTaskCourseFilter(String? courseName) {
    if (_taskCourseFilter == courseName) return;
    _taskCourseFilter = courseName;
    notifyListeners();
  }

  void togglePeriodAxis() {
    _showPeriodAxis = !_showPeriodAxis;
    notifyListeners();
  }

  /// Open the shared TaskEditPage in a clean M3 desktop dialog.
  Future<void> openTaskEditor(
    BuildContext context,
    DesktopStore store,
    Task task,
  ) async {
    final result = await showDialog<Task?>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesktopRadius.dialog),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 560,
          height: 640,
          child: TaskEditPage(task),
        ),
      ),
    );
    if (result != null) {
      store.saveTask(task, result);
    }
  }

  /// Create a new deadline task or pre-filled fixed event slot.
  Future<void> createTask(
    BuildContext context,
    DesktopStore store, {
    TaskType type = TaskType.deadline,
    DateTime? start,
    DateTime? end,
  }) async {
    final base = start ?? store.now;
    final cleanStart =
        DateTime(base.year, base.month, base.day, base.hour, base.minute);
    final cleanEnd = end != null
        ? DateTime(end.year, end.month, end.day, end.hour, end.minute)
        : type == TaskType.fixed
            ? cleanStart.add(const Duration(hours: 1))
            : cleanStart.add(const Duration(days: 1));
    final task = Task(
      startTime: cleanStart,
      endTime: cleanEnd,
      repeatEndsTime:
          DateTime(cleanStart.year, cleanStart.month, cleanStart.day),
    )..reset();
    task.type = type;
    task.startTime = cleanStart;
    task.endTime = cleanEnd;
    task.repeatEndsTime =
        DateTime(cleanStart.year, cleanStart.month, cleanStart.day);
    await openTaskEditor(context, store, task);
  }
}
