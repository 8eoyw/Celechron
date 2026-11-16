import 'package:celechron/utils/json_utils.dart';

class Todo {
  String id;
  String name;
  String course;
  DateTime? endTime;

  Todo.fromJson(Map<String, dynamic> json)
      : id = asString(json["id"]) ?? '',
        name = asString(json["title"]) ?? '未命名作业',
        course = asString(json["course_name"]) ?? '未知课程',
        // 学在浙大返回 UTC（如 2026-11-12T15:59:00Z），必须转成本地时间，
        // 否则 23:59 截止会显示成 15:59，按日分组也会错一天。
        endTime = DateTime.tryParse(asString(json["end_time"]) ?? '')?.toLocal();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': name,
        'course_name': course,
        'end_time': endTime?.toUtc().toIso8601String(),
      };

  static List<Todo> getAllFromCourses(Map<String, dynamic> json) {
    final rawTodos = asDynamicList(json["todo_list"]) ?? const [];
    final todos = <Todo>[];
    for (final rawTodo in rawTodos) {
      final todoMap = asStringMap(rawTodo);
      if (todoMap == null || asBool(todoMap["is_student"]) != true) continue;
      try {
        final todo = Todo.fromJson(todoMap);
        if (todo.id.isNotEmpty) todos.add(todo);
      } catch (_) {
        // 单条作业字段异常不影响其它作业。
      }
    }
    return todos;
  }

  // TODO: 对于助教/老师，是否需要将批改作业当作 todo 来显示？

  bool isInOneDay() => endTime != null
      ? endTime!.subtract(const Duration(days: 1)).isBefore(DateTime.now())
      : false;

  bool isInOneWeek() => endTime != null
      ? endTime!.subtract(const Duration(days: 7)).isBefore(DateTime.now())
      : false;
}
