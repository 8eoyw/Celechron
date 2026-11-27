import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/todo.dart';
import '../format.dart';
import '../theme/tokens.dart';
import 'countdown.dart';
import 'context_menu.dart';
import 'list_row.dart';

Uri homeworkUri(Todo todo) => Uri.parse(todo.courseId == null
    ? 'https://courses.zju.edu.cn/user/index'
    : 'https://courses.zju.edu.cn/course/${todo.courseId}/learning-activity#/${Uri.encodeComponent(todo.id)}');
Future<void> openHomework(Todo todo) async {
  try {
    await launchUrl(homeworkUri(todo), mode: LaunchMode.externalApplication);
  } catch (_) {
    // 没有可用浏览器等情况：静默失败，不让异常冒到 UI
  }
}

double homeworkRowHeightOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(44).clamp(44, double.infinity);

class HomeworkRow extends StatelessWidget {
  const HomeworkRow({super.key, required this.todo, required this.now});
  final Todo todo;
  final DateTime now;
  @override
  Widget build(BuildContext context) => PaperAction(
      tooltip:
          '${todo.name}\n${todo.course} · ${todo.endTime == null ? '无截止时间' : fmtDeadline(todo.endTime!, now)}',
      onTap: () => openHomework(todo),
      onSecondaryTapDown: (details) async {
        final action = await paperContextMenu(
            context, details.globalPosition, {0: '在浏览器打开', 1: '复制标题'});
        if (action == 0) await openHomework(todo);
        if (action == 1) {
          await Clipboard.setData(ClipboardData(text: todo.name));
        }
      },
      child: SizedBox(
          height: homeworkRowHeightOf(context),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Builder(builder: (context) {
                        final c = PaperColors.of(context);
                        final end = todo.endTime;
                        final dotColor = end == null
                            ? c.text3
                            : end.isBefore(now)
                                ? c.danger
                                : end.difference(now) <=
                                        const Duration(hours: 24)
                                    ? c.warning
                                    : calendarDaysBetween(now, end) <= 7
                                        ? c.accent
                                        : c.text3;
                        return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: dotColor, shape: BoxShape.circle));
                      }),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(todo.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PaperType.strong(context))),
                      if (todo.endTime != null) ...[
                        const SizedBox(width: 8),
                        CountdownText(target: todo.endTime!, now: now)
                      ]
                    ]),
                    Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Row(children: [
                          Flexible(
                              child: Text(todo.course,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PaperType.meta(context))),
                          Text(' · ', style: PaperType.meta(context)),
                          Text(
                              todo.endTime == null
                                  ? '无截止时间'
                                  : fmtDeadline(todo.endTime!, now),
                              maxLines: 1,
                              style: PaperType.meta(context)),
                        ]))
                  ]))));
}
