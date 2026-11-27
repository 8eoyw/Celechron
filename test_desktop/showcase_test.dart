import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:celechron/desktop/format.dart';
import 'package:celechron/desktop/pages/tasks/tasks_page.dart';
import 'package:celechron/desktop/shell/companion_panel.dart';
import 'package:celechron/desktop/shell/shell.dart';
import 'package:celechron/desktop/state/desktop_controller.dart';
import 'package:celechron/desktop/theme/app_theme.dart';
import 'package:celechron/desktop/widgets/command_palette.dart';
import 'package:celechron/desktop/widgets/common_ui.dart';
import 'package:celechron/desktop/widgets/login_gate.dart';
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
      'end_time': '2026-11-16T15:59:00Z',
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

  testWidgets('v4 showcase matrix and interaction flows', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });

    final store = await tester.runAsync(setupDemo);
    try {
      final out = Platform.environment['CELECHRON_SHOWCASE_OUT'] ??
          '${Directory.systemTemp.path}/celechron_v4_showcase';
      await renderMatrix(tester, store!, out);

      // 1. Companion panel docks at 1200x820, overlays at 1000x700 via Ctrl+\
      tester.view.physicalSize = const Size(1200, 820);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDesktopTheme(Brightness.dark),
        home: DesktopShell(key: UniqueKey(), store: store),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CompanionPanel), findsOneWidget);
      expect(find.text('已逾期 1'), findsOneWidget);
      expect(find.text('12:04'), findsOneWidget);

      // Clicking a course block opens Course Inspector in the Companion Panel
      await tester.tap(find.text('数据结构基础').first);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('课程详情'), findsOneWidget);
      expect(find.text('本学期课时进度'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Save an inspector screenshot for visual verification
      final inspectorBoundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: inspectorBoundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildDesktopTheme(Brightness.dark),
          home: DesktopShell(key: UniqueKey(), store: store),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('数据结构基础').first);
      await tester.pump(const Duration(milliseconds: 250));
      await saveSnapshot(
          tester, inspectorBoundary, '$out/1200x820_dark_course_inspector.png');

      // Esc closes inspector back to Up Next
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('待办与近期'), findsOneWidget);

      // Narrow 1000x700 hides docked companion until Ctrl+\ toggles overlay
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDesktopTheme(Brightness.light),
        home: DesktopShell(key: UniqueKey(), store: store),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CompanionPanel), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.backslash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CompanionPanel), findsOneWidget);

      // 2. Command Palette (Ctrl+K) search + Enter navigation
      tester.view.physicalSize = const Size(1200, 820);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDesktopTheme(Brightness.light),
        home: DesktopShell(key: UniqueKey(), store: store),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CommandPalette), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(CommandPalette),
          matching: find.byType(TextField),
        ),
        '实验报告一',
      );
      await tester.pump();
      expect(find.text('实验报告一'), findsWidgets);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(TasksPage), findsOneWidget);
      expect(find.text('作业详情'), findsOneWidget);

      // 3. Course filter & right-click copy title on Tasks page
      await tester.tap(find.text('全部课程'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('数字逻辑设计（2）'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeworkItemRow), findsNWidgets(2));
      await tester.tap(
        find.descendant(
            of: find.byType(TasksPage), matching: find.text('实验报告一')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.text('在浏览器打开'), findsOneWidget);
      await tester.tap(find.text('复制标题').last);
      await tester.pumpAndSettle();
      expect(copiedText, '实验报告一');

      // 4. Text scaling safety on HomeworkItemRow
      await tester.pumpWidget(MaterialApp(
        theme: buildDesktopTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: HomeworkItemRow(
                  todo: store.todos.first,
                  now: store.now,
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      for (final element in find.byType(RichText).evaluate()) {
        expect(
          (element.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }
      expect(tester.takeException(), isNull);

      // 5. Logged-out gate & screenshot coverage
      store.scholar.isLogan = false;
      for (final size in desktopSizes) {
        tester.view.physicalSize = size;
        for (final brightness in Brightness.values) {
          final boundary = GlobalKey();
          await tester.pumpWidget(RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildDesktopTheme(brightness),
              home: DesktopShell(key: UniqueKey(), store: store),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(LoginForm), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (size == const Size(1200, 820)) {
            await saveSnapshot(tester, boundary,
                '$out/1200x820_${brightness.name}_logged_out.png');
          }
        }
      }

      // 6. Offline sync error keeps cached data visible
      store.scholar.isLogan = true;
      store.lastErrors = ['示范离线错误'];
      tester.view.physicalSize = const Size(1200, 820);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDesktopTheme(Brightness.light),
        home: DesktopShell(key: UniqueKey(), store: store),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('同步失败'), findsOneWidget);
      expect(find.text('实验报告一'), findsOneWidget);

      // 7. Initial loading skeleton & empty state
      store.scholar.semesters.clear();
      store.scholar.todos.clear();
      store.refreshing = true;
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDesktopTheme(Brightness.light),
        home: DesktopShell(key: UniqueKey(), store: store),
      ));
      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsWidgets);

      store.refreshing = false;
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDesktopTheme(Brightness.light),
        home: DesktopShell(
          key: UniqueKey(),
          store: store,
          initialDestination: DesktopDestination.tasks,
        ),
      ));
      await tester.pump();
      expect(find.text('暂无待办任务'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await disposeDemo(tester, store!);
    }
  });
}
