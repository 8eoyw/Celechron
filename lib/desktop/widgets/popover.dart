import 'package:flutter/material.dart';
import '../../model/period.dart';
import '../format.dart';
import '../theme/tokens.dart';
import 'course_colors.dart';
import 'list_row.dart';

Future<void> showPeriodPopover(BuildContext context, Period period) async {
  final box = context.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(Offset.zero);
  final size = MediaQuery.sizeOf(context);
  await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭详情',
      barrierColor: const Color(0x00000000),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) => Stack(children: [
            Positioned(
                left: anchor.dx.clamp(16, size.width - 316),
                top: (anchor.dy + box.size.height).clamp(16, size.height - 340),
                width: 300,
                child: Material(
                    color: PaperColors.of(context).surface,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: PaperColors.of(context).hairline),
                            boxShadow: PaperColors.of(context).shadow),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                    width: 3,
                                    height: 24,
                                    color: CourseColors(context, period.summary)
                                        .bar),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(period.summary,
                                        style: PaperType.h2(context))),
                                PaperIconButton(
                                    icon: Icons.close,
                                    tooltip: '关闭',
                                    onPressed: () => Navigator.pop(context))
                              ]),
                              const SizedBox(height: 16),
                              _detail(context, Icons.schedule,
                                  '${fmtDate(period.startTime)} ${fmtRange(period.startTime, period.endTime)}'),
                              if (period.location.isNotEmpty)
                                _detail(context, Icons.place_outlined,
                                    period.location),
                              if (period.description.isNotEmpty)
                                _detail(
                                    context, Icons.notes, period.description),
                            ])))),
          ]));
}

Widget _detail(BuildContext c, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: PaperColors.of(c).text2),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: PaperType.meta(c),
              maxLines: 6,
              overflow: TextOverflow.ellipsis))
    ]));
