import 'dart:ui';
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
      barrierColor: const Color(0x22000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) {
        final c = PaperColors.of(context);
        return Stack(children: [
          Positioned(
              left: anchor.dx.clamp(16, size.width - 324),
              top: (anchor.dy + box.size.height + 6)
                  .clamp(16, size.height - 340),
              width: 308,
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Paper.popoverRadius),
                      boxShadow: c.shadow),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(Paper.popoverRadius),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                          child: Material(
                              color: c.glassSurface,
                              child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          Paper.popoverRadius),
                                      border: Border.all(
                                          color: c.hairlineStrong)),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Container(
                                              width: 3.5,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                  color: CourseColors(context,
                                                          period.summary)
                                                      .bar,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999))),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: Text(period.summary,
                                                  style:
                                                      PaperType.h2(context))),
                                          PaperIconButton(
                                              icon: Icons.close_rounded,
                                              tooltip: '关闭',
                                              onPressed: () =>
                                                  Navigator.pop(context))
                                        ]),
                                        const SizedBox(height: 14),
                                        _detail(context, Icons.schedule_rounded,
                                            '${fmtDate(period.startTime)} ${fmtRange(period.startTime, period.endTime)}'),
                                        if (period.location.isNotEmpty)
                                          _detail(context, Icons.place_outlined,
                                              period.location),
                                        if (period.description.isNotEmpty)
                                          _detail(context, Icons.notes_rounded,
                                              period.description),
                                      ])))))))
        ]);
      });
}

Widget _detail(BuildContext c, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: PaperColors.of(c).text2),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: PaperType.meta(c),
              maxLines: 6,
              overflow: TextOverflow.ellipsis))
    ]));
