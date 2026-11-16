import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:celechron/desktop/format.dart';
import 'package:celechron/desktop/shell/shell.dart';
import 'package:celechron/desktop/shell/sidebar.dart';
import 'package:celechron/desktop/shell/command_palette.dart';
import 'package:celechron/desktop/theme/app_theme.dart';
import 'package:celechron/desktop/widgets/homework_row.dart';
import 'package:celechron/desktop/widgets/login_form.dart';
import 'package:celechron/desktop/widgets/skeleton.dart';
import 'package:celechron/desktop/widgets/scroll_area.dart';
import 'package:celechron/model/todo.dart';
import 'harness.dart';

void main() {
  test('calendar days, UTC homework roundtrip and deep links', () {
    final now = DateTime(2026, 11, 16, 23, 59);
    expect(calendarDaysBetween(now, DateTime(2026, 11, 17, 9)), 1);
    expect(examCountdown(DateTime(2026, 11, 17, 9), now), '明天');
    expect(fmtDeadline(DateTime(2026, 11, 18, 23, 59), now), '周三 11/18 23:59');
    final todo = Todo.fromJson({
      'id': '42',
      'course_id': '123',
      'type': 'homework',
      'end_time': '2026-11-16T15:59:00Z'
    });
    expect(todo.endTime, DateTime.parse('2026-11-16T15:59:00Z').toLocal());
    expect(todo.toJson()['end_time'], '2026-11-16T15:59:00.000Z');
    expect(todo.toJson()['course_id'], 123);
    expect(todo.toJson()['type'], 'homework');
    expect(homeworkUri(todo).toString(),
        'https://courses.zju.edu.cn/course/123/learning-activity#/42');
    todo.courseId = null;
    expect(homeworkUri(todo).path, '/user/index');
  });
  testWidgets('showcase matrix and interaction states', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData')
        copiedText = (call.arguments as Map)['text'] as String?;
      return null;
    });
    final store = await tester.runAsync(setupDemo);
    try {
      await renderMatrix(
          tester,
          store!,
          Platform.environment['CELECHRON_SHOWCASE_OUT'] ??
              '${Directory.systemTemp.path}/celechron_paper_showcase');
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: DesktopShell(key: UniqueKey(), store: store)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          tester.widget<DesktopSidebar>(find.byType(DesktopSidebar)).collapsed,
          isTrue);
      expect(find.text('已逾期 1'), findsOneWidget);
      expect(find.text('12:04'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'initial rail');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.backslash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
          tester.widget<DesktopSidebar>(find.byType(DesktopSidebar)).collapsed,
          isFalse);
      expect(tester.takeException(), isNull, reason: 'manual expand');
      tester.view.physicalSize = const Size(1200, 820);
      await tester.pump();
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'threshold reset');
      // Palette search includes the course name, supports arrows/Enter, and navigates.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CommandPalette), findsOneWidget);
      await tester.enterText(
          find.descendant(
              of: find.byType(CommandPalette),
              matching: find.byType(TextField)),
          '数字逻辑设计');
      await tester.pump();
      expect(find.text('实验报告一'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          tester.widget<DesktopSidebar>(find.byType(DesktopSidebar)).selected,
          DesktopPage.homework);
      // Course filter and context menu remain usable with keyboard focus.
      await tester.tap(find.text('全部课程'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('数字逻辑设计（2）'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeworkRow), findsNWidgets(2));
      await tester.tap(find.text('实验报告一'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(find.text('在浏览器打开'), findsOneWidget);
      await tester.tap(find.text('复制标题'));
      await tester.pumpAndSettle();
      expect(copiedText, '实验报告一');
      expect(tester.takeException(), isNull);
      expect(
          tester.widget<DesktopSidebar>(find.byType(DesktopSidebar)).collapsed,
          isTrue);
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
              child: Scaffold(
                  body: Center(
                      child: SizedBox(
                          width: 340,
                          child: HomeworkRow(
                              todo: store.todos.first, now: store.now)))))));
      await tester.pump();
      for (final element in find.byType(RichText).evaluate()) {
        expect((element.renderObject! as RenderParagraph).didExceedMaxLines,
            isFalse);
      }
      expect(tester.takeException(), isNull);
      store.scholar.isLogan = false;
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: DesktopShell(key: UniqueKey(), store: store)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.widgetWithText(TextField, '学号'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, '学号'), 'demo');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
          tester.widget<DesktopSidebar>(find.byType(DesktopSidebar)).selected,
          DesktopPage.today);
      expect(tester.takeException(), isNull);
      // Logged-out bodies for every destination, and PNG coverage at all sizes/themes.
      final out = Platform.environment['CELECHRON_SHOWCASE_OUT'] ??
          '${Directory.systemTemp.path}/celechron_paper_showcase';
      for (final size in desktopSizes) {
        tester.view.physicalSize = size;
        for (final brightness in Brightness.values) {
          final boundary = GlobalKey();
          await tester.pumpWidget(RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildDesktopTheme(brightness),
                  home: DesktopShell(key: UniqueKey(), store: store))));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(LoginForm), findsOneWidget);
          expect(tester.takeException(), isNull);
          await saveSnapshot(tester, boundary,
              '$out/${size.width.toInt()}x${size.height.toInt()}_${brightness.name}_logged_out.png');
        }
      }
      for (final page in DesktopPage.values) {
        await tester.pumpWidget(MaterialApp(
            theme: buildDesktopTheme(Brightness.light),
            home: DesktopShell(
                key: UniqueKey(), store: store, initialPage: page)));
        await tester.pump();
        expect(find.byType(LoginForm), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      store.scholar.isLogan = true;
      store.lastErrors = ['示范离线错误'];
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: DesktopShell(key: UniqueKey(), store: store)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('同步失败'), findsOneWidget);
      expect(find.text('实验报告一'), findsOneWidget);
      // First refresh without cached data uses skeletons. A settled empty list uses an empty state.
      store.scholar.semesters.clear();
      store.scholar.todos.clear();
      store.refreshing = true;
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: DesktopShell(key: UniqueKey(), store: store)));
      await tester.pump();
      expect(find.byType(SkeletonRows), findsOneWidget);
      expect(find.byType(ScrollArea), findsNothing);
      store.refreshing = false;
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: DesktopShell(
              key: UniqueKey(),
              store: store,
              initialPage: DesktopPage.homework)));
      await tester.pump();
      expect(find.text('没有待交作业'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await disposeDemo(tester, store!);
    }
  });
}
