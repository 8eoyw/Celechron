import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:celechron/desktop/pages/schedule/day_timeline.dart';
import 'package:celechron/desktop/shell/shell.dart';
import 'package:celechron/desktop/state/desktop_controller.dart';
import 'package:celechron/desktop/theme/app_theme.dart';
import 'harness.dart';

void main() {
  testWidgets(
      'v4 day timeline keeps course height and now progression strictly proportional',
      (tester) async {
    final store = await tester.runAsync(setupDemo);
    final out = Platform.environment['CELECHRON_TIMELINE_OUT'];
    try {
      tester.view.physicalSize = const Size(1200, 820);
      tester.view.devicePixelRatio = 1;

      Future<void> pumpAt(DateTime when, String snapName) async {
        store!.now = when;
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildDesktopTheme(Brightness.light),
            home: DesktopShell(
              key: ValueKey(snapName),
              store: store,
              initialDestination: DesktopDestination.schedule,
              initialScheduleMode: ScheduleMode.day,
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: snapName);
        if (out != null) {
          Directory(out).createSync(recursive: true);
          await saveSnapshot(tester, boundary, '$out/$snapName.png');
        }
      }

      // 1. Monday 12:04: 145-min class (09:55-12:20) vs 95-min class (16:10-17:45)
      await pumpAt(DateTime(2026, 11, 16, 12, 4), 'mon_1204');
      final inDay = find.byType(ScheduleDayTimeline);
      final longBlock = tester.getRect(find
          .ancestor(
            of: find.descendant(of: inDay, matching: find.text('数据结构基础')),
            matching: find.byType(Tooltip),
          )
          .first);
      final shortBlock = tester.getRect(find
          .ancestor(
            of: find.descendant(of: inDay, matching: find.text('面向对象程序设计')),
            matching: find.byType(Tooltip),
          )
          .first);
      // 145 min vs 95 min (ratio ~1.526); both heights include -2px blockGap.
      final ratio = (longBlock.height + 2) / (shortBlock.height + 2);
      expect(ratio, closeTo(145 / 95, 0.01));

      // Verify the now badge advances proportionally across the same ongoing block.
      final now1204Y = tester.getCenter(find.text('12:04')).dy;
      await pumpAt(DateTime(2026, 11, 16, 10, 55), 'mon_1055');
      final now1055Y = tester.getCenter(find.text('10:55')).dy;
      final blockAt1055 = tester.getRect(find
          .ancestor(
            of: find.descendant(of: inDay, matching: find.text('数据结构基础')),
            matching: find.byType(Tooltip),
          )
          .first);
      // 69 minutes elapsed between 10:55 and 12:04 -> exact 69/145 of block span
      // Note: scroll offset may shift both by the same delta, so compare relative to block top!
      final rel1204 = now1204Y - longBlock.top;
      final rel1055 = now1055Y - blockAt1055.top;
      final expectedDelta = (blockAt1055.height + 2) * (69 / 145);
      expect(rel1204 - rel1055, closeTo(expectedDelta, 1.5));

      // 2. Wednesday 14:30: overlapping class & exam
      await pumpAt(DateTime(2026, 11, 18, 14, 30), 'wed_1430_overlap');
      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('概率论与数理统计'), findsWidgets);
      expect(find.text('考试'), findsAtLeastNWidgets(1));

      // 3. Monday 20:00: all classes ended
      await pumpAt(DateTime(2026, 11, 16, 20, 0), 'mon_2000_ended');
      expect(find.text('今日课程已结束'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);

      // 4. Saturday 10:30: empty day
      await pumpAt(DateTime(2026, 11, 21, 10, 30), 'sat_empty');
      expect(find.text('今天没有课'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
    } finally {
      await disposeDemo(tester, store!);
    }
  });
}
