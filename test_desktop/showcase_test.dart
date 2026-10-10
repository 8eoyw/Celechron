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

    Future<void> page(int i) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(
          LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i - 1));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> tap(String text) async {
      await tester.tap(find.text(text));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await app(Brightness.light);
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
    await snap('07_总览_深色');
    await page(2);
    await snap('08_课表_周_深色');

    store.dispose();
    Get.deleteAll(force: true);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    tester.view.reset();
  });
}
