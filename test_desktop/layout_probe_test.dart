// 桌面版离屏版面检查（不打开窗口、不联网、不改动真实数据）：
// 把本机 Hive 数据复制到临时目录，以 1184×781（1200×820 窗口的客户区）渲染每个页面，
// 报告：溢出（RenderFlex overflow）、需要滚动的滚动区域，并把每页存成 PNG。
//
// 运行：flutter test test_desktop/layout_probe_test.dart
// 可选环境变量：CELECHRON_HIVE_DIR（默认 %USERPROFILE%\Documents）、
//              CELECHRON_PROBE_OUT（默认 系统临时目录\celechron_probe）
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
import 'package:celechron/desktop/side_panels.dart';
import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';
import 'package:celechron/page/option/option_controller.dart';

const _pages = ['总览', '课表', '成绩', '考试', '任务', '设置'];
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
      if (f.path.endsWith('.hive')) {
        await f.copy(
            '${tmp.path}${Platform.pathSeparator}${f.uri.pathSegments.last}');
      }
    }
    Hive.init(tmp.path);
    final db = Get.put(DatabaseHelper(), tag: 'db');
    await db.init();
    Get.put((await db.getScholar()).obs, tag: 'scholar');
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

    outDir = Directory(Platform.environment['CELECHRON_PROBE_OUT'] ??
        '${Directory.systemTemp.path}${Platform.pathSeparator}celechron_probe')
      ..createSync(recursive: true);
  });

  testWidgets('desktop layout probe', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1.0;

    final problems = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final where = RegExp(r'lib/desktop/[\w/]+\.dart:\d+')
          .allMatches(details.toString())
          .map((m) => m.group(0))
          .toSet()
          .join(' ');
      problems.add(
          'ERROR: ${details.exceptionAsString().split('\n').first} @ $where');
    };

    store = DesktopStore()..start(autoRefresh: false);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDesktopTheme(Brightness.light),
        home: DesktopShell(store: store),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // 成绩页选一个已出成绩的学期，才看得到成绩表
    final graded = store.semesters.indexWhere((x) => x.grades.isNotEmpty);
    if (graded >= 0) store.selectSemester(graded);

    Future<void> snap(String name) => tester.runAsync(() async {
          final ro = boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final ui.Image img = await ro.toImage(pixelRatio: 1.0);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${outDir.path}${Platform.pathSeparator}$name.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        });

    for (var i = 0; i < _pages.length; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(
          LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 300));

      // 需要滚动的区域：作业栏与 DScrollArea 允许，其它都算问题
      for (final element in find.byType(Scrollable).evaluate()) {
        final state = (element as StatefulElement).state as ScrollableState;
        final pos = state.position;
        if (!pos.hasContentDimensions || pos.maxScrollExtent <= 0.5) continue;
        if (pos.axis == Axis.horizontal &&
            element.findAncestorWidgetOfExactType<PopupMenuButton<int>>() !=
                null) continue;
        final offstage = element.findAncestorWidgetOfExactType<Offstage>();
        if (offstage != null && offstage.offstage) continue;
        final allowed =
            element.findAncestorWidgetOfExactType<DScrollArea>() != null ||
                element.findAncestorWidgetOfExactType<SidePanel>() != null;
        problems.add(
            '${_pages[i]}: ${allowed ? 'inner-scroll(ok)' : 'PAGE-SCROLL'} '
            '${pos.axis.name} overflow=${pos.maxScrollExtent.toStringAsFixed(0)}px');
      }

      await snap('page_${i + 1}');
    }

    // 课表的月视图、切到最早学期后的周视图与月视图
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('月'));
    await tester.pump(const Duration(milliseconds: 300));
    await snap('page_2_month');
    if (store.semesters.length > 1) {
      store.selectSemester(store.semesters.length - 1);
      await tester.pump(const Duration(milliseconds: 300));
      await snap('page_2_month_oldest');
      await tester.tap(find.text('周'));
      await tester.pump(const Duration(milliseconds: 300));
      await snap('page_2_week_oldest');
      await tester.tap(find.text('统计'));
      await tester.pump(const Duration(milliseconds: 300));
      await snap('page_2_stats_oldest');
      store.selectSemester(0);
      await tester.pump(const Duration(milliseconds: 300));
      await snap('page_2_stats_newest');
    }

    FlutterError.onError = oldOnError;
    // ignore: avoid_print
    print(
        'PROBE out=${outDir.path}\n${problems.toSet().join('\n')}\nPROBE_END ${problems.length} items');

    store.dispose();
    Get.deleteAll(force: true);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    tester.view.reset();
  });
}
