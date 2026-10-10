// 宣传截图用的虚构学生数据：课程、教师、教室、成绩、考试、作业全部是编的。
// 只有校历（节次时间、每周对应的日期、节假日与调休）取自本机缓存——那是全校公共信息。
import 'package:celechron/model/scholar.dart';

/// 一门虚构课程；sessions 每项 = (星期几, 节次, 秋/春, 冬/夏, 单周, 双周)
class _Course {
  const _Course(this.name, this.teacher, this.credit, this.place, this.sessions,
      {this.score});
  final String name, teacher, place;
  final double credit;
  final List<(int, List<int>, bool, bool, bool, bool)> sessions;
  final int? score;
}

const _both = (true, true, true, true);

(int, List<int>, bool, bool, bool, bool) _s(int day, List<int> time,
        [(bool, bool, bool, bool) f = _both]) =>
    (day, time, f.$1, f.$2, f.$3, f.$4);

// 大二上（当前学期）：手排，含单双周、只上半学期/下半学期的课
final _current = <_Course>[
  _Course('数据结构基础', '王明远', 4.0, '紫金港东1A-201', [
    _s(1, [3, 4, 5]),
    _s(4, [1, 2], (true, true, true, false)),
  ]),
  _Course('离散数学及其应用', '李晓华', 4.0, '紫金港东2-302', [
    _s(2, [1, 2]),
    _s(5, [3, 4, 5]),
  ]),
  _Course('概率论与数理统计', '陈思颖', 2.5, '紫金港西1-405', [
    _s(3, [6, 7, 8])
  ]),
  _Course('面向对象程序设计', '刘建国', 2.5, '紫金港东4-511', [
    _s(4, [6, 7, 8]),
    _s(1, [9, 10], (true, true, false, true)),
  ]),
  _Course('马克思主义基本原理', '赵雅琴', 3.0, '紫金港东1B-104', [
    _s(2, [6, 7, 8])
  ]),
  _Course('学术英语写作', '周文博', 2.0, '紫金港东6-218', [
    _s(3, [1, 2])
  ]),
  _Course('羽毛球（初级）', '孙立新', 1.0, '紫金港风雨操场', [
    _s(2, [3, 4])
  ]),
  _Course('数字逻辑设计', '郑凯', 3.0, '紫金港东3-406', [
    _s(3, [3, 4, 5])
  ]),
  _Course('摄影基础', '吴佳怡', 1.5, '紫金港西2-108', [
    _s(1, [11, 12, 13], (true, false, true, true))
  ]),
  _Course('创新创业基础', '黄志强', 1.0, '紫金港东1A-104', [
    _s(4, [11, 12], (false, true, true, true))
  ]),
];

// 往年学期：自动排课
final _past = {
  '2025-2026秋冬': <_Course>[
    _Course('微积分（甲）Ⅰ', '冯德明', 5.0, '紫金港东2-201', [], score: 88),
    _Course('线性代数（甲）', '许静', 3.5, '紫金港东2-202', [], score: 91),
    _Course('程序设计基础', '何俊', 3.0, '紫金港东1A-401', [], score: 94),
    _Course('大学英语Ⅲ', '高雪', 3.0, '紫金港东6-223', [], score: 86),
    _Course('思想道德与法治', '罗文', 3.0, '紫金港东1B-302', [], score: 90),
    _Course('军事理论', '马强', 2.0, '紫金港西1-211', [], score: 85),
    _Course('篮球（初级）', '林涛', 1.0, '紫金港东田径场', [], score: 92),
  ],
  '2025-2026春夏': <_Course>[
    _Course('微积分（甲）Ⅱ', '冯德明', 5.0, '紫金港东2-201', [], score: 84),
    _Course('大学物理（甲）Ⅰ', '杨帆', 4.0, '紫金港东3-103', [], score: 80),
    _Course('中国近现代史纲要', '谢宁', 3.0, '紫金港东1B-302', [], score: 89),
    _Course('工程图学', '唐慧', 2.5, '紫金港东1B-214', [], score: 87),
    _Course('大学英语Ⅳ', '高雪', 3.0, '紫金港东6-223', [], score: 88),
    _Course('普通化学', '韩磊', 3.0, '紫金港西2-304', [], score: 78),
    _Course('游泳（初级）', '林涛', 1.0, '紫金港游泳馆', [], score: 95),
  ],
};

const _slots = [
  (1, [1, 2]),
  (2, [3, 4, 5]),
  (3, [6, 7, 8]),
  (4, [1, 2]),
  (5, [3, 4, 5]),
  (1, [6, 7, 8]),
  (2, [1, 2]),
  (3, [3, 4, 5]),
  (4, [6, 7, 8]),
  (5, [1, 2]),
  (2, [6, 7, 8]),
  (4, [3, 4, 5]),
  (3, [9, 10]),
  (5, [6, 7]),
];

double _five(int s) => s >= 95
    ? 5.0
    : s >= 92
        ? 4.8
        : s >= 89
            ? 4.5
            : s >= 86
                ? 4.2
                : s >= 83
                    ? 3.9
                    : s >= 80
                        ? 3.6
                        : s >= 77
                            ? 3.3
                            : s >= 74
                                ? 3.0
                                : 2.7;
double _four(int s) => s >= 95
    ? 4.3
    : s >= 92
        ? 4.2
        : s >= 89
            ? 4.1
            : s >= 86
                ? 3.9
                : s >= 83
                    ? 3.6
                    : s >= 80
                        ? 3.3
                        : 3.0;
double _legacy(int s) => s >= 85 ? 4.0 : (_five(s) > 4.0 ? 4.0 : _five(s));

/// [calendars]：学期名 → 该学期的校历字段（sessionToTime / dayOfWeekToDays / holidays / exchanges）
Scholar buildDemoScholar({
  required Map<String, Map<String, dynamic>> calendars,
  required Map<String, String> specialDates,
  required DateTime now,
}) {
  var allFive = 0.0, allFour = 0.0, allLegacy = 0.0, allHundred = 0.0;
  var allCredit = 0.0;

  Map<String, dynamic> semesterJson(
      String name, int termNo, List<_Course> courses) {
    final courseMap = <String, dynamic>{};
    final sessions = <Map<String, dynamic>>[];
    final grades = <Map<String, dynamic>>[];
    final exams = <Map<String, dynamic>>[];
    var slot = 0;
    var credit = 0.0, five = 0.0, four = 0.0, legacy = 0.0, hundred = 0.0;
    for (var i = 0; i < courses.length; i++) {
      final c = courses[i];
      final id = '(${name.substring(0, 9)}-$termNo)-DEMO${100 + i}-0000000-1';
      var raw = c.sessions;
      if (raw.isEmpty) {
        // 往年课程：按学分排 1–2 个时段
        raw = [
          for (var k = 0; k < (c.credit >= 3 ? 2 : 1); k++)
            () {
              final s = _slots[slot++ % _slots.length];
              return _s(s.$1, s.$2);
            }(),
        ];
      }
      final courseSessions = [
        for (final s in raw)
          {
            'id': id,
            'name': c.name,
            'teacher': c.teacher,
            'confirmed': true,
            'firstHalf': s.$3,
            'secondHalf': s.$4,
            'oddWeek': s.$5,
            'evenWeek': s.$6,
            'day': s.$1,
            'time': s.$2,
            'location': c.place,
          }
      ];
      sessions.addAll(courseSessions);
      Map<String, dynamic>? grade;
      if (c.score != null) {
        final sc = c.score!;
        grade = {
          'id': id,
          'name': c.name,
          'credit': c.credit,
          'original': '$sc',
          'fivePoint': _five(sc),
          'fourPoint': _four(sc),
          'fourPointLegacy': _legacy(sc),
          'hundredPoint': sc,
          'gpaIncluded': true,
          'creditIncluded': true,
        };
        grades.add(grade);
        credit += c.credit;
        five += _five(sc) * c.credit;
        four += _four(sc) * c.credit;
        legacy += _legacy(sc) * c.credit;
        hundred += sc * c.credit;
      }
      courseMap[id] = {
        'id': id,
        'name': c.name,
        'confirmed': true,
        'credit': c.credit,
        'grade': grade,
        'teacher': c.teacher,
        'sessions': courseSessions,
        'exams': [],
      };
    }

    // 当前学期：期中 1 场 + 期末 6 场
    if (termNo == 1 && name == '2026-2027秋冬') {
      DateTime d(int y, int m, int day, int h, int min) =>
          DateTime(y, m, day, h, min);
      final plan = [
        ('离散数学及其应用', 0, d(2026, 11, 18, 14, 0), '紫金港西2-104'),
        ('马克思主义基本原理', 1, d(2027, 1, 7, 14, 0), '紫金港西1-211'),
        ('数据结构基础', 1, d(2027, 1, 8, 8, 0), '紫金港东1A-301'),
        ('离散数学及其应用', 1, d(2027, 1, 11, 10, 30), '紫金港西2-104'),
        ('概率论与数理统计', 1, d(2027, 1, 12, 14, 0), '紫金港西1-317'),
        ('面向对象程序设计', 1, d(2027, 1, 13, 10, 30), '紫金港机房'),
        ('数字逻辑设计', 1, d(2027, 1, 14, 8, 0), '紫金港东3-202'),
      ];
      for (var k = 0; k < plan.length; k++) {
        final (cname, type, start, place) = plan[k];
        final id =
            courseMap.entries.firstWhere((e) => e.value['name'] == cname).key;
        final exam = {
          'id': id,
          'name': cname,
          'type': type,
          'time': [
            start.toIso8601String(),
            start.add(const Duration(hours: 2)).toIso8601String()
          ],
          'location': place,
          'seat': '${12 + k * 7}',
        };
        exams.add(exam);
        (courseMap[id]['exams'] as List).add(exam);
      }
    }

    allCredit += credit;
    allFive += five;
    allFour += four;
    allLegacy += legacy;
    allHundred += hundred;
    double avg(double v) => credit == 0 ? 0 : v / credit;
    return {
      'name': name,
      'courses': courseMap,
      'exams': exams,
      'sessions': sessions,
      'grades': grades,
      'gpa': [avg(five), avg(four), avg(legacy), avg(hundred)],
      'credits': credit,
      ...calendars[name] ?? const {},
    };
  }

  final semesters = [
    semesterJson('2026-2027秋冬', 1, _current),
    semesterJson('2025-2026春夏', 2, _past['2025-2026春夏']!),
    semesterJson('2025-2026秋冬', 1, _past['2025-2026秋冬']!),
  ];
  double avg(double v) => allCredit == 0 ? 0 : v / allCredit;

  String at(Duration d) => now.add(d).toIso8601String();
  // (标题, 课程, 距今天几天, 截止时, 分)：截止时间取常见的整点/23:59
  final todos = [
    ('第3次上机实验', '数据结构基础', 0, 23, 59),
    ('习题课作业 4', '离散数学及其应用', 1, 15, 59),
    ('第二章习题', '概率论与数理统计', 3, 23, 59),
    ('课程项目选题报告', '面向对象程序设计', 5, 12, 0),
    ('Essay Draft 1', '学术英语写作', 6, 23, 59),
    ('实验二 组合逻辑电路', '数字逻辑设计', 9, 18, 0),
    ('摄影作业：校园夜景', '摄影基础', 12, 23, 59),
    ('第4次上机实验', '数据结构基础', 13, 23, 59),
    ('读书报告', '马克思主义基本原理', 16, 23, 59),
    ('期中复习题', '离散数学及其应用', 24, 15, 59),
    ('创业计划书初稿', '创新创业基础', 40, 23, 59),
  ];

  final json = <String, dynamic>{
    'semesters': semesters,
    'grades': <String, dynamic>{},
    'gpa': [avg(allFive), avg(allFour), avg(allLegacy), avg(allHundred)],
    'aboardGpa': [avg(allFive), avg(allFour), avg(allLegacy), avg(allHundred)],
    'credit': allCredit,
    'majorGpaAndCredit': [avg(allFive) + 0.06, allCredit - 9],
    'specialDates': specialDates,
    'lastUpdateTimeGrade': at(const Duration(hours: -2)),
    'lastUpdateTimeCourse': at(const Duration(hours: -2)),
    'lastUpdateTimeHomework': at(const Duration(minutes: -3)),
    'todos': [
      for (var i = 0; i < todos.length; i++)
        {
          'id': 'demo-todo-$i',
          'title': todos[i].$1,
          'course_name': todos[i].$2,
          'end_time': DateTime(now.year, now.month, now.day + todos[i].$3,
                  todos[i].$4, todos[i].$5)
              .toIso8601String(),
        }
    ],
  };
  return Scholar.fromJson(json)
    ..isLogan = true
    ..username = '3250000000';
}
