import 'package:flutter/material.dart';
import '../format.dart';
import '../theme/tokens.dart';

Color deadlineColor(BuildContext c, DateTime t, DateTime now) => t.isBefore(now)
    ? PaperColors.of(c).danger
    : t.difference(now).inHours < 24
        ? PaperColors.of(c).warning
        : PaperColors.of(c).text2;

class CountdownText extends StatelessWidget {
  const CountdownText(
      {super.key, required this.target, required this.now, this.exam = false});
  final DateTime target, now;
  final bool exam;
  @override
  Widget build(BuildContext context) {
    final days = calendarDaysBetween(now, target);
    final c = PaperColors.of(context);
    return Text(
        exam ? examCountdown(target, now) : fmtDeadlineCountdown(target, now),
        maxLines: 1,
        style: (exam ? PaperType.number(context) : PaperType.meta(context))
            .copyWith(
                color: exam
                    ? days <= 1
                        ? c.danger
                        : days <= 3
                            ? c.warning
                            : c.text2
                    : deadlineColor(context, target, now)));
  }
}
