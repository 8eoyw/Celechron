import 'package:flutter/material.dart';
import '../../store.dart';
import '../../theme/tokens.dart';
import '../../widgets/course_colors.dart';
import '../../widgets/empty_state.dart';

class CalendarHoursView extends StatelessWidget {
  const CalendarHoursView({super.key, required this.store});
  final DesktopStore store;

  String _number(num value) => value == value.roundToDouble()
      ? '${value.toInt()}'
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final semester = store.selectedSemester;
    final hours = semester == null ? null : store.hoursOf(semester);
    if (hours == null || hours.courses.isEmpty) {
      return const EmptyState('这个学期没有课程安排');
    }
    final colors = PaperColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.all(20),
          child: Text('已上 ${hours.done} / 总 ${hours.total} 课时',
              style: PaperType.h2(context))),
      _row(context, header: true, children: [
        const Text('课程'),
        const Text('学分'),
        const Text('已上 / 总课时'),
        const Text('进度'),
        const Text('每周')
      ]),
      Expanded(
          child: ListView.builder(
              padding: EdgeInsets.zero,
              itemExtent: 48 * scale,
              itemCount: hours.courses.length,
              itemBuilder: (context, index) {
                final course = hours.courses[index];
                final tint = CourseColors(context, course.name);
                final progress =
                    course.total == 0 ? 0.0 : course.done / course.total;
                return _row(context, children: [
                  Row(children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: tint.bar, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(course.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis))
                  ]),
                  Text(_number(course.credit)),
                  Text('${course.done} / ${course.total}'),
                  Semantics(
                      label: '${course.name}进度',
                      value: '${(progress * 100).round()}%',
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                              value: progress.clamp(0, 1),
                              minHeight: 4,
                              color: tint.bar,
                              backgroundColor: colors.hairline))),
                  Text('${_number(course.perWeek)} 节')
                ]);
              }))
    ]);
  }

  Widget _row(BuildContext context,
          {required List<Widget> children, bool header = false}) =>
      Container(
          height: header ? MediaQuery.textScalerOf(context).scale(40) : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: PaperColors.of(context).hairline))),
          child: DefaultTextStyle.merge(
              style:
                  header ? PaperType.label(context) : PaperType.meta(context),
              child: Row(children: [
                for (var i = 0; i < children.length; i++)
                  Expanded(
                      flex: const [5, 1, 2, 3, 2][i],
                      child: Padding(
                          padding: EdgeInsets.only(right: i == 4 ? 0 : 16),
                          child: children[i]))
              ])));
}
