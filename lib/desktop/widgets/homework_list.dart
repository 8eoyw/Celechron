import 'package:flutter/material.dart';
import '../../model/todo.dart';
import '../format.dart';
import 'homework_row.dart';
import 'scroll_area.dart';
import 'section_label.dart';

Map<String, List<Todo>> homeworkGroups(List<Todo> todos, DateTime now) {
  final groups = <String, List<Todo>>{};
  for (final todo in todos) {
    final end = todo.endTime;
    final days = end == null ? null : calendarDaysBetween(now, end);
    final label = end == null
        ? '无截止时间'
        : end.isBefore(now)
            ? '已逾期'
            : days! <= 7
                ? dayGroup(end, now)
                : '之后';
    groups.putIfAbsent(label, () => []).add(todo);
  }
  return groups;
}

/// Internal scrolling with an initial viewport ending on a complete row.
class HomeworkList extends StatelessWidget {
  const HomeworkList(
      {super.key,
      required this.todos,
      required this.now,
      this.showOverdueCount = false});
  final List<Todo> todos;
  final DateTime now;
  final bool showOverdueCount;
  @override
  Widget build(BuildContext context) {
    final row = homeworkRowHeightOf(context);
    final header = MediaQuery.textScalerOf(context).scale(32);
    final children = <Widget>[];
    final rowEnds = <double>[];
    var extent = 0.0;
    for (final group in homeworkGroups(todos, now).entries) {
      children.add(SizedBox(
          height: header,
          child: SectionLabel(
              group.key == '已逾期' && showOverdueCount
                  ? '已逾期 ${group.value.length}'
                  : group.key,
              danger: group.key == '已逾期')));
      extent += header;
      for (final todo in group.value) {
        children.add(HomeworkRow(todo: todo, now: now));
        extent += row;
        rowEnds.add(extent);
      }
    }
    return LayoutBuilder(builder: (context, bounds) {
      final complete = rowEnds.where((height) => height <= bounds.maxHeight);
      final height = complete.isEmpty ? bounds.maxHeight : complete.last;
      return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
              height: height,
              child: ScrollArea(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children))));
    });
  }
}
