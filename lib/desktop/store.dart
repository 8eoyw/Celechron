import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:celechron/model/exam.dart';
import 'package:celechron/model/grade.dart';
import 'package:celechron/model/option.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/model/scholar.dart';
import 'package:celechron/model/semester.dart';
import 'package:celechron/model/task.dart';
import 'package:celechron/model/todo.dart';
import 'package:celechron/page/flow/flow_controller.dart';
import 'package:celechron/page/task/task_controller.dart';
import 'package:celechron/utils/global.dart';
import 'package:celechron/database/database_helper.dart';
import 'package:celechron/worker/fuse.dart';

/// 一门考试连同其所属学期，供考试页/总览使用
class ExamEntry {
  ExamEntry(this.exam, this.semester);
  final Exam exam;
  final Semester semester;
  DateTime get start => exam.time.first;
  DateTime get end => exam.time.length > 1 ? exam.time[1] : exam.time.first;
}

/// 一门课在一个学期里的课时（单位：节）
class CourseHours {
  CourseHours(this.name, this.credit);
  final String name;
  final double credit;
  int total = 0;
  int done = 0;

  /// 有课的教学周（从 0 开始）
  final Set<int> weeks = {};

  /// 有课的周里平均每周几节
  double get perWeek => weeks.isEmpty ? 0 : total / weeks.length;
}

/// 一个学期的课时统计
class SemesterHours {
  SemesterHours(
      {required this.courses, required this.weekly, this.currentWeek});

  /// 按总课时从多到少
  final List<CourseHours> courses;

  /// 每个教学周的节数，index 0 = 第 1 周
  final List<int> weekly;

  /// 今天所在教学周（从 0 开始）；不在本学期内为 null
  final int? currentWeek;

  int get total => courses.fold(0, (s, c) => s + c.total);
  int get done => courses.fold(0, (s, c) => s + c.done);
}

/// 作业按截止时间分组
enum TodoGroup { overdue, within24h, thisWeek, later, noDeadline }

const Map<TodoGroup, String> todoGroupName = {
  TodoGroup.overdue: '已逾期',
  TodoGroup.within24h: '24 小时内',
  TodoGroup.thisWeek: '7 天内',
  TodoGroup.later: '之后',
  TodoGroup.noDeadline: '无截止时间',
};

/// 桌面版唯一的数据入口。页面只读这里的 getter、只调这里的方法，
/// 不直接 Get.find，也不碰 lib/page 下的移动端控制器。
///
/// 数据源是 main_desktop.dart 注册的共享 Rx 对象（与移动端同一份），
/// 任何一个变化都会 notifyListeners()，页面用 ListenableBuilder 订阅。
class DesktopStore extends ChangeNotifier {
  final Rx<Scholar> _scholar = Get.find<Rx<Scholar>>(tag: 'scholar');
  final RxList<Task> _taskList = Get.find<RxList<Task>>(tag: 'taskList');
  final RxList<Period> _flowList = Get.find<RxList<Period>>(tag: 'flowList');
  final Option _option = Get.find<Option>(tag: 'option');

  // 任务状态推进、写库、自动规划这些业务逻辑在这两个控制器里（不含界面），
  // 桌面版直接复用，避免分叉出第二套逻辑
  final TaskController _tasks = Get.put(TaskController());
  final FlowController _flow = Get.put(FlowController());
  final List<Worker> _workers = [];
  Timer? _clock;

  /// 当前时间；每 30 秒更新一次并通知，用于倒计时、"现在"指示线
  DateTime now = DateTime.now();

  /// [autoRefresh] 为 false 时不在启动时联网（离屏版面检查用）
  void start({bool autoRefresh = true}) {
    _workers
      ..add(ever(_scholar, (_) => notifyListeners()))
      ..add(ever(_taskList, (_) => notifyListeners()))
      ..add(ever(_flowList, (_) => notifyListeners()));
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      now = DateTime.now();
      notifyListeners();
    });
    _selectedSemester = _defaultSemesterIndex();
    if (autoRefresh && isLoggedIn) unawaited(refresh(startup: true));
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    _clock?.cancel();
    super.dispose();
  }

  // ───────────────────────── 账号与刷新 ─────────────────────────

  Scholar get scholar => _scholar.value;
  bool get isLoggedIn => scholar.isLogan;
  String get username => scholar.username ?? '';

  bool refreshing = false;
  DateTime? lastRefreshAt;

  /// 最近一次刷新失败/降级的模块说明（为空表示全部成功）
  List<String> lastErrors = const [];

  /// 刷新全部数据；并发调用会复用数据层的同一次刷新
  Future<void> refresh({bool startup = false}) async {
    if (!isLoggedIn || refreshing) return;
    refreshing = true;
    notifyListeners();
    if (startup) GlobalStatus.isFirstScreenReq = true;
    try {
      final results = await scholar.refresh(onPartialUpdate: _scholar.refresh);
      lastErrors = results.whereType<String>().toList();
    } on Object catch (e) {
      lastErrors = ['$e'];
    } finally {
      if (startup) GlobalStatus.isFirstScreenReq = false;
      refreshing = false;
      lastRefreshAt = DateTime.now();
      _selectedSemester = _selectedSemester.clamp(0, _maxSemesterIndex);
      _scholar.refresh();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await scholar.logout();
    _scholar.refresh();
    notifyListeners();
  }

  /// 登录：写入学号/密码到数据层后调用 scholar.login()，全 null 即成功；成功后 onLoggedIn() 并刷新
  Future<String?> login(String user, String pass) async {
    scholar.username = user;
    scholar.password = pass;
    final errors = await scholar.login();
    if (errors.every((e) => e == null)) {
      onLoggedIn();
      unawaited(refresh());
      return null;
    }
    return errors.whereType<String>().join('\n');
  }

  /// 登录成功后由设置页调用（登录表单本身复用数据层）
  void onLoggedIn() {
    _selectedSemester = _defaultSemesterIndex();
    _scholar.refresh();
    notifyListeners();
  }

  // ───────────────────────── 学期 ─────────────────────────

  /// 有课或有成绩的学期，新 → 旧
  List<Semester> get semesters => scholar.semesters
      .where((s) => s.courseCount > 0 || s.grades.isNotEmpty)
      .toList();

  int _selectedSemester = 0;
  int get selectedSemesterIndex => _selectedSemester;
  Semester? get selectedSemester =>
      semesters.isEmpty ? null : semesters[_selectedSemester];

  void selectSemester(int index) {
    _selectedSemester = index.clamp(0, _maxSemesterIndex);
    notifyListeners();
  }

  int get _maxSemesterIndex => semesters.isEmpty ? 0 : semesters.length - 1;

  int _defaultSemesterIndex() {
    final list = semesters;
    if (list.isEmpty) return 0;
    final i = list.indexWhere((s) => s.name == scholar.thisSemester.name);
    return i < 0 ? 0 : i;
  }

  /// 当前学期的教学周序号（从 1 开始）；不在学期内返回 null
  int? get teachingWeek {
    final sem = scholar.thisSemester;
    final first = _mondayOf(sem.firstDay);
    if (now.isBefore(first) || now.isAfter(sem.lastDay)) return null;
    return now.difference(first).inDays ~/ 7 + 1;
  }

  /// 包含 [day] 的学期在 [semesters] 中的序号；不在任何学期内返回 null
  int? semesterIndexOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final list = semesters;
    for (var i = 0; i < list.length; i++) {
      final first = _mondayOf(list[i].firstDay);
      final last = list[i].lastDay;
      // 没有校历时 firstDay/lastDay 都退化成"现在"，不算有效区间
      if (last.difference(first).inDays < 7) continue;
      if (!d.isBefore(first) && !d.isAfter(last)) return i;
    }
    return null;
  }

  /// [day] 在其所属学期中的教学周（从 1 开始）；不在任何学期内返回 null
  int? teachingWeekOn(DateTime day) {
    final i = semesterIndexOn(day);
    if (i == null) return null;
    final first = _mondayOf(semesters[i].firstDay);
    return _mondayOf(day).difference(first).inDays ~/ 7 + 1;
  }

  // ───────────────────────── 课时统计 ─────────────────────────

  /// 一个时段包含几节课：按学期的节次时间表数落在时段内的节，
  /// 跨午休/晚饭的长时段也不会多算；时间表缺失时按每节 45 分钟 + 课间 5 分钟估算
  static int sessionsOf(Period p, List<List<Duration>> table) {
    final day = DateTime(p.startTime.year, p.startTime.month, p.startTime.day);
    var n = 0;
    for (final t in table.skip(1)) {
      if (t.length < 2) continue;
      if (!day.add(t.first).isBefore(p.startTime) &&
          !day.add(t.last).isAfter(p.endTime)) {
        n++;
      }
    }
    if (n > 0) return n;
    final minutes = p.endTime.difference(p.startTime).inMinutes;
    return ((minutes + 5) / 50).round().clamp(1, 99);
  }

  /// [semester] 的课时统计：按课程、按教学周汇总，已上 = 结束时间早于现在
  SemesterHours hoursOf(Semester semester) {
    final seen = <String>{};
    final classes = semester.periods
        .where((p) => p.type == PeriodType.classes)
        .where((p) => seen.add('${p.summary}|${p.startTime}|${p.endTime}'))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // 第 1 周从校历首日所在周算起；没有校历时退回到第一节课所在周
    var first = _mondayOf(semester.firstDay);
    if (semester.lastDay.difference(first).inDays < 7 && classes.isNotEmpty) {
      first = _mondayOf(classes.first.startTime);
    }

    final byCourse = <String, CourseHours>{};
    final weekly = <int>[];
    for (final p in classes) {
      final n = sessionsOf(p, semester.sessionToTime);
      final done = !p.endTime.isAfter(now);
      final course = byCourse.putIfAbsent(p.summary, () {
        final c =
            semester.courses.values.where((c) => c.name == p.summary).toList();
        return CourseHours(p.summary, c.isEmpty ? 0 : c.first.credit);
      });
      final week = _mondayOf(p.startTime).difference(first).inDays ~/ 7;
      course.total += n;
      if (done) course.done += n;
      course.weeks.add(week);
      if (week < 0) continue;
      while (weekly.length <= week) {
        weekly.add(0);
      }
      weekly[week] += n;
    }

    final courses = byCourse.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final nowWeek = _mondayOf(now).difference(first).inDays ~/ 7;
    return SemesterHours(
      courses: courses,
      weekly: weekly,
      currentWeek:
          !now.isBefore(first) && nowWeek < weekly.length ? nowWeek : null,
    );
  }

  // ───────────────────────── 日程 / 课表 ─────────────────────────

  static DateTime mondayOf(DateTime d) => _mondayOf(d);

  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  DateTime get thisMonday => _mondayOf(now);

  /// [start, end) 之间的所有时段（课程、考试、自建日程、规划块），按开始时间排序
  List<Period> periodsBetween(DateTime start, DateTime end) {
    final out = <Period>[
      ...scholar.periods,
      ..._flowList,
    ].where((p) => p.endTime.isAfter(start) && p.startTime.isBefore(end));
    // 同一门课在秋、冬两个查询季各返回一次，会生成完全相同的时段，按内容去重
    final seen = <String>{};
    final list = out
        .where((p) => seen.add(
            '${p.type.index}|${p.summary}|${p.startTime}|${p.endTime}|${p.location}'))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  List<Period> periodsOfDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return periodsBetween(d, d.add(const Duration(days: 1)));
  }

  /// 一周七天的时段，index 0 = 周一
  List<List<Period>> periodsOfWeek(DateTime monday) => [
        for (var i = 0; i < 7; i++) periodsOfDay(monday.add(Duration(days: i))),
      ];

  List<Period> get todayPeriods => periodsOfDay(now);

  /// 正在进行的时段
  List<Period> get ongoing => todayPeriods
      .where((p) => !p.startTime.isAfter(now) && p.endTime.isAfter(now))
      .toList();

  /// 下一个尚未开始的时段（7 天内）
  Period? get nextPeriod {
    final upcoming = periodsBetween(now, now.add(const Duration(days: 7)))
        .where((p) => p.startTime.isAfter(now));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// 节假日/调休标注
  String? specialDateOf(DateTime day) =>
      scholar.specialDates[DateTime(day.year, day.month, day.day)];

  // ───────────────────────── 考试 ─────────────────────────

  List<ExamEntry> examsOf(Semester semester) => semester.exams
      .where((e) => e.time.isNotEmpty)
      .map((e) => ExamEntry(e, semester))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  /// 所有学期中尚未结束的考试，按时间排序
  List<ExamEntry> get upcomingExams {
    final list = <ExamEntry>[
      for (final s in scholar.semesters) ...examsOf(s),
    ].where((e) => e.end.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  // ───────────────────────── 成绩 ─────────────────────────

  /// [五分制, 四分制(4.3), 四分制(旧 4.0), 百分制]，按设置中的 GPA 口径
  List<double> get gpa => _option.gpaStrategy.value == GpaStrategy.first
      ? scholar.gpa
      : scholar.aboardGpa;

  /// 是否隐藏绩点（与移动端首页的「隐藏绩点」是同一个设置）
  bool get gpaHidden => _option.hideHomeGpa.value;

  void toggleGpaHidden() {
    final v = !gpaHidden;
    _option.hideHomeGpa.value = v;
    unawaited(Get.find<DatabaseHelper>(tag: 'db').setHideHomeGpa(v));
    notifyListeners();
  }

  /// 隐藏时把数字换成 *，与移动端一致
  String maskGpa(String s) =>
      gpaHidden ? s.replaceAll('.', '').replaceAll(RegExp(r'\d'), '*') : s;

  double get majorGpa => scholar.majorGpaAndCredit[0];
  double get majorCredit => scholar.majorGpaAndCredit[1];

  /// 已获得学分（与移动端同一口径：数据层按课程去重、排除重修与不计学分课程）
  double get earnedCredit => scholar.credit;

  List<Grade> gradesOf(Semester semester) => semester.grades;

  // 外观：明暗模式（与移动端 Option 共享，写库持久化）
  BrightnessMode get brightnessMode => _option.brightnessMode.value;

  /// 切换明暗模式并写入数据库（同移动端 option_controller）
  void setBrightnessMode(BrightnessMode mode) {
    _option.brightnessMode.value = mode;
    unawaited(Get.find<DatabaseHelper>(tag: 'db').setBrightnessMode(mode));
    notifyListeners();
  }

  /// 当前版本号（与移动端 Fuse 共享）
  String get fuseVersion =>
      Get.find<Rx<Fuse>>(tag: 'fuse').value.displayVersion;
  // ───────────────────────── 作业（学在浙大） ─────────────────────────

  List<Todo> get todos {
    final list = List<Todo>.of(scholar.todos)
      ..sort((a, b) {
        if (a.endTime == null) return 1;
        if (b.endTime == null) return -1;
        return a.endTime!.compareTo(b.endTime!);
      });
    return list;
  }

  TodoGroup groupOf(Todo t) {
    final end = t.endTime;
    if (end == null) return TodoGroup.noDeadline;
    if (end.isBefore(now)) return TodoGroup.overdue;
    final left = end.difference(now);
    if (left <= const Duration(hours: 24)) return TodoGroup.within24h;
    if (left <= const Duration(days: 7)) return TodoGroup.thisWeek;
    return TodoGroup.later;
  }

  Map<TodoGroup, List<Todo>> get todosGrouped {
    final map = {for (final g in TodoGroup.values) g: <Todo>[]};
    for (final t in todos) {
      map[groupOf(t)]!.add(t);
    }
    map.removeWhere((_, v) => v.isEmpty);
    return map;
  }

  DateTime get homeworkUpdatedAt => scholar.lastUpdateTimeHomework;
  DateTime get gradeUpdatedAt => scholar.lastUpdateTimeGrade;
  DateTime get courseUpdatedAt => scholar.lastUpdateTimeCourse;

  // ───────────────────────── 任务（本地） ─────────────────────────

  List<Task> get _aliveTasks =>
      _taskList.where((t) => t.status != TaskStatus.deleted).toList();

  /// 未完成的 DDL，按截止时间
  List<Task> get pendingDeadlines => _aliveTasks
      .where((t) =>
          t.type == TaskType.deadline &&
          (t.status == TaskStatus.running || t.status == TaskStatus.suspended))
      .toList()
    ..sort((a, b) => a.endTime.compareTo(b.endTime));

  List<Task> get finishedDeadlines => _aliveTasks
      .where((t) =>
          t.type == TaskType.deadline &&
          (t.status == TaskStatus.completed || t.status == TaskStatus.failed))
      .toList()
    ..sort((a, b) => b.endTime.compareTo(a.endTime));

  /// 自建日程
  List<Task> get fixedTasks => _aliveTasks
      .where((t) => t.type == TaskType.fixed || t.type == TaskType.fixedlegacy)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  void toggleTaskCompleted(Task t) {
    if (t.status == TaskStatus.completed) {
      t.timeSpent = Duration.zero;
      t.forceRefreshStatus();
    } else {
      t.timeSpent = t.timeNeeded;
      t.status = TaskStatus.completed;
    }
    _afterTaskChange();
  }

  void deleteTask(Task t) {
    t.status = TaskStatus.deleted;
    _afterTaskChange();
  }

  /// 与移动端任务页相同的收尾：刷新状态、写库、重新规划
  void _afterTaskChange() {
    _tasks.updateDeadlineList();
    _tasks.updateDeadlineListTime();
    _flow.removeFlowInFlowList();
    final n = DateTime.now();
    _flow.generateNewFlowList(
        DateTime(n.year, n.month, n.day, n.hour, n.minute));
    _taskList.refresh();
  }

  /// 重新生成学习规划（"接下来"里的学习块）
  Future<void> replan() async {
    _afterTaskChange();
  }

  /// 新建或保存任务（编辑页返回的结果）
  void saveTask(Task original, Task edited) {
    if (edited.status == TaskStatus.deleted) {
      deleteTask(original);
      return;
    }
    if (_taskList.contains(original)) {
      original.copy(edited);
    } else {
      _taskList.add(edited);
    }
    _afterTaskChange();
  }
}
