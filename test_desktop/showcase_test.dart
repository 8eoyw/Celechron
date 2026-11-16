// 桌面版宣传截图（不打开窗口、不联网、不改动真实数据）：
// 画面上的学生数据全部是虚构的（test_desktop/demo_data.dart），不会出现本机账号的课程、成绩、作业：
// 只从本机缓存的 dbuser.hive 里读取校历（节次时间、日期、节假日调休），其它 Hive 库一律为空。
// 以 1.5 倍分辨率输出各页面截图。
//
// 运行：flutter test test_desktop/showcase_test.dart
// 可选环境变量：CELECHRON_HIVE_DIR（默认 %USERPROFILE%\Documents）、
//              CELECHRON_SHOWCASE_OUT（默认 系统临时目录\celechron_probe）
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:celechron/database/database_helper.dart';
import 'package:celechron/desktop/shell.dart';
import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';
import 'package:celechron/desktop/side_panels.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/page/option/option_controller.dart';

import 'demo_data.dart';

const _size = Size(1184, 781);

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) {
      final bytes = await f.readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await loader.load();
}

void main() {
  late DesktopStore store;
  late Directory outDir;

  test('deadline calendar labels and overdue countdown', () {
    final now = DateTime(2026, 11, 16, 12);
    expect(fmtDeadline(DateTime(2026, 11, 16, 23, 59), now), '今天 23:59');
    expect(fmtDeadline(DateTime(2026, 11, 17, 15, 59), now), '明天 15:59');
    expect(fmtDeadline(DateTime(2026, 11, 18, 23, 59), now), '周三 23:59');
    expect(fmtDeadline(DateTime(2026, 11, 23, 23, 59), now), '周一 23:59');
    expect(fmtDeadline(DateTime(2026, 11, 28, 23, 59), now), '11/28 周六 23:59');
    expect(
        fmtDeadline(DateTime(2027, 1, 1, 0, 5), DateTime(2026, 12, 31, 23, 59)),
        '明天 00:05');
    expect(fmtDeadlineCountdown(now.subtract(const Duration(days: 2)), now),
        '已逾期 2 天');
    expect(fmtDeadlineCountdown(now.add(const Duration(hours: 11)), now),
        '11 小时后');
  });

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // flutter_secure_storage 在测试环境没有原生实现：返回空，不读取真实凭据
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => call.method == 'readAll' ? <String, String>{} : null,
    );

    final src = Platform.environment['CELECHRON_HIVE_DIR'] ??
        '${Platform.environment['USERPROFILE']}\\Documents';
    final tmp = await Directory.systemTemp.createTemp('celechron_hive_');
    for (final f in Directory(src).listSync().whereType<File>()) {
      if (f.path.endsWith('dbuser.hive')) {
        await f.copy(
            '${tmp.path}${Platform.pathSeparator}${f.uri.pathSegments.last}');
      }
    }
    Hive.init(tmp.path);
    final db = Get.put(DatabaseHelper(), tag: 'db');
    await db.init();
    // 只取校历这类全校公共字段，真实课程/成绩/作业不进入画面
    final real = await db.getScholar();
    final calendars = <String, Map<String, dynamic>>{
      for (final sem in real.semesters)
        sem.name: {
          for (final k in [
            'sessionToTime',
            'dayOfWeekToDays',
            'holidays',
            'exchanges'
          ])
            k: sem.toJson()[k],
        },
    };
    final demo = buildDemoScholar(
      calendars: calendars,
      specialDates:
          real.specialDates.map((k, v) => MapEntry(k.toIso8601String(), v)),
      now: DateTime.now(),
    );
    Get.put(demo.obs, tag: 'scholar');
    Get.put(db.getTaskList().obs, tag: 'taskList');
    Get.put(db.getTaskListUpdateTime().obs, tag: 'taskListLastUpdate');
    Get.put(db.getFlowList().obs, tag: 'flowList');
    Get.put(db.getFlowListUpdateTime().obs, tag: 'flowListLastUpdate');
    Get.put(db.getOption(), tag: 'option');
    Get.put(db.getFuse().obs, tag: 'fuse');
    Get.put(OptionController(), tag: 'optionController');

    await _loadFont(DS.font, ['C:\\Windows\\Fonts\\msyh.ttc']);
    final flutterRoot =
        Platform.environment['FLUTTER_ROOT'] ?? 'D:\\dev\\flutter';
    await _loadFont('MaterialIcons', [
      '$flutterRoot\\bin\\cache\\artifacts\\material_fonts\\MaterialIcons-Regular.otf'
    ]);

    outDir = Directory(Platform.environment['CELECHRON_SHOWCASE_OUT'] ??
        '${Directory.systemTemp.path}${Platform.pathSeparator}celechron_showcase')
      ..createSync(recursive: true);
  });

  testWidgets('desktop showcase', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1.0;

    store = DesktopStore()..start(autoRefresh: false);
    if (store.gpaHidden) store.toggleGpaHidden(); // 虚构数据，绩点直接显示
    store.lastRefreshAt = DateTime.now(); // 顶栏显示「同步于 刚刚」
    final boundary = GlobalKey();
    Future<void> app(Brightness b) async {
      await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildDesktopTheme(b),
          home: DesktopShell(store: store),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> snap(String name) => tester.runAsync(() async {
          final ro = boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final ui.Image img = await ro.toImage(pixelRatio: 1.5);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${outDir.path}${Platform.pathSeparator}$name.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        });

    void checkLayout() {
      expect(tester.takeException(), isNull);
      for (final element in find.byType(Scrollable).evaluate()) {
        final state = (element as StatefulElement).state as ScrollableState;
        if (!state.position.hasContentDimensions ||
            state.position.maxScrollExtent <= 0.5) continue;
        expect(element.findAncestorWidgetOfExactType<DScrollArea>() != null,
            isTrue,
            reason: 'PAGE-SCROLL');
      }
      for (final element in find
          .descendant(of: find.byType(KpiTile), matching: find.byType(RichText))
          .evaluate()) {
        final text = element.renderObject! as RenderParagraph;
        expect(text.didExceedMaxLines, isFalse, reason: 'KPI caption clipped');
      }
    }

    Future<void> page(int i) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(
          LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i - 1));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 300));
      checkLayout();
    }

    Future<void> tap(String text) async {
      await tester.tap(find.text(text));
      await tester.pump(const Duration(milliseconds: 300));
      checkLayout();
    }

    await app(Brightness.light);
    checkLayout();
    void checkOverviewHomework() {
      final rows = find.descendant(
          of: find.byType(HomeworkList), matching: find.byType(DRow));
      expect(rows.evaluate().length, greaterThanOrEqualTo(5),
          reason: 'Overview must show at least five complete homework rows');
    }

    checkOverviewHomework();
    await snap('01_总览');
    await page(2);
    // 本周是国庆假期，课很少，展示下一周
    await tester.tap(find.byTooltip('下一周'));
    await tester.pump(const Duration(milliseconds: 300));
    await snap('02_课表_周');
    await tap('月');
    await snap('03_课表_月');
    await tap('统计');
    await snap('04_课表_课时统计');
    await tap('周');
    await page(4);
    await snap('05_考试');
    final graded = store.semesters.indexWhere((x) => x.grades.isNotEmpty);
    if (graded >= 0) store.selectSemester(graded);
    await page(3);
    await snap('06_成绩');

    store.selectSemester(0);
    await page(1);
    await app(Brightness.dark);
    checkOverviewHomework();
    await snap('07_总览_深色');
    await page(2);
    await snap('08_课表_周_深色');
    await tap('月');
    await snap('09_课表_月_深色');
    await tap('统计');
    await snap('10_课表_课时统计_深色');
    await tap('周');
    await page(4);
    await snap('11_考试_深色');
    if (graded >= 0) store.selectSemester(graded);
    await page(3);
    await snap('12_成绩_深色');

    // Footer is actionable and the complete list stays in a desktop dialog.
    await page(1);
    final homework = find.byType(HomeworkList);
    final footer =
        find.descendant(of: homework, matching: find.byType(TextButton));
    expect(footer, findsOneWidget);
    await tester.tap(footer);
    await tester.pump();
    expect(find.text('全部作业'), findsOneWidget);
    checkLayout();
    await tester.tap(find.text('关闭'));
    await tester.pump();

    // Every homework density has complete rows and an accurate remainder.
    for (final height in [32.0, 96.0, 128.0, 300.0, 720.0]) {
      final host = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: Scaffold(
              body: Center(
                  child: SizedBox(
                      key: host,
                      width: 284,
                      height: height,
                      child: HomeworkList(store: store))))));
      final shown = store.todos
          .where((t) => find.text(t.name).evaluate().isNotEmpty)
          .length;
      expect(find.text('还有 ${store.todos.length - shown} 项'),
          shown < store.todos.length ? findsOneWidget : findsNothing);
      expect(find.byType(ColorBarTile), findsNWidgets(shown));
      final bounds = tester.getRect(find.byKey(host));
      for (final row in find.byType(DRow).evaluate()) {
        final rect = tester.getRect(find.byWidget(row.widget));
        expect(rect.top >= bounds.top && rect.bottom <= bounds.bottom, isTrue,
            reason: 'Partial homework row at height $height');
      }
      for (final todo in store.todos
          .where((t) => find.text(t.name).evaluate().isNotEmpty)) {
        final date = todo.endTime == null
            ? '无截止时间'
            : fmtDeadline(todo.endTime!, store.now);
        final dateRect = tester.getRect(find.text(date));
        expect(dateRect.left >= bounds.left && dateRect.right <= bounds.right,
            isTrue,
            reason: 'Deadline must stay fully visible');
        if (todo.endTime != null) {
          final titleRect = tester.getRect(find.text(todo.name));
          final countdown = tester.getRect(
              find.text(fmtDeadlineCountdown(todo.endTime!, store.now)));
          expect(countdown.center.dy, closeTo(titleRect.center.dy, 0.5));
          expect(countdown.right, closeTo(bounds.right - DS.s2, 0.5));
        }
      }
      expect(tester.takeException(), isNull);
    }

    // Height and width determine which details fit, with title priority in overlaps.
    final period = Period(
        summary: '短时段课程',
        location: '示范教室',
        startTime: store.now,
        endTime: store.now.add(const Duration(minutes: 30)));
    for (final height in [22.0, 40.0, 50.0, 64.0, 100.0]) {
      await tester.pumpWidget(MaterialApp(
          theme: buildDesktopTheme(Brightness.light),
          home: Scaffold(
              body: Center(
                  child: SizedBox(
                      width: 300,
                      height: height,
                      child: TimelineBlock(period: period))))));
      expect(find.text('短时段课程'), findsOneWidget);
      expect(find.textContaining('示范教室'),
          height < 44 ? findsNothing : findsOneWidget);
      final time = fmtRange(period.startTime, period.endTime);
      if (height >= 64) {
        expect(find.text(time), findsOneWidget);
        expect(find.text('示范教室'), findsOneWidget);
      } else if (height == 40) {
        expect(find.text(time), findsOneWidget);
      } else if (height == 50) {
        expect(find.text('$time · 示范教室'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    final narrowPeriod =
        period.copyWith(summary: '离散数学及其应用', location: '紫金港东1A-201示范教室');
    await tester.pumpWidget(MaterialApp(
        theme: buildDesktopTheme(Brightness.light),
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 80,
                    height: 100,
                    child: TimelineBlock(period: narrowPeriod))))));
    final titleParagraph = tester.renderObject<RenderParagraph>(find.descendant(
        of: find.text(narrowPeriod.summary), matching: find.byType(RichText)));
    expect(titleParagraph.didExceedMaxLines, isFalse);
    expect(find.text(fmtRange(period.startTime, period.endTime)), findsNothing);
    expect(tester.takeException(), isNull);

    store.dispose();
    Get.deleteAll(force: true);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    tester.view.reset();
  });
}
