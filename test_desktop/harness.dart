// All accounts, calendars and content are synthetic. No personal Hive reads.
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
import 'package:celechron/desktop/shell/shell.dart';
import 'package:celechron/desktop/state/desktop_controller.dart';
import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme/app_theme.dart';
import 'package:celechron/desktop/theme/tokens.dart';
import 'package:celechron/page/option/option_controller.dart';
import 'demo_data.dart';

const desktopSizes = [Size(1000, 700), Size(1200, 820), Size(1600, 1000)];
final demoNow = DateTime(2026, 11, 16, 12, 4);

class MatrixSurface {
  const MatrixSurface(
    this.name, {
    required this.destination,
    this.scheduleMode = ScheduleMode.day,
    this.academicsTab = AcademicsTab.exams,
    this.semesterIndex = 0,
  });

  final String name;
  final DesktopDestination destination;
  final ScheduleMode scheduleMode;
  final AcademicsTab academicsTab;
  final int semesterIndex;
}

const v4Surfaces = [
  MatrixSurface(
    'schedule_day',
    destination: DesktopDestination.schedule,
    scheduleMode: ScheduleMode.day,
  ),
  MatrixSurface(
    'schedule_week',
    destination: DesktopDestination.schedule,
    scheduleMode: ScheduleMode.week,
  ),
  MatrixSurface(
    'schedule_month',
    destination: DesktopDestination.schedule,
    scheduleMode: ScheduleMode.month,
  ),
  MatrixSurface(
    'tasks',
    destination: DesktopDestination.tasks,
  ),
  MatrixSurface(
    'academics_exams',
    destination: DesktopDestination.academics,
    academicsTab: AcademicsTab.exams,
  ),
  MatrixSurface(
    'academics_grades',
    destination: DesktopDestination.academics,
    academicsTab: AcademicsTab.grades,
    semesterIndex: 1,
  ),
  MatrixSurface(
    'academics_hours',
    destination: DesktopDestination.academics,
    academicsTab: AcademicsTab.hours,
  ),
];

Future<void> loadFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final loader = FontLoader(family);
  final bytes = await file.readAsBytes();
  loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Map<String, dynamic> syntheticCalendar(DateTime first) => {
      'sessionToTime': [
        [],
        for (final minutes in [
          480,
          530,
          595,
          645,
          695,
          805,
          855,
          905,
          970,
          1020,
          1110,
          1160,
          1210
        ])
          [minutes, minutes + 45]
      ],
      'dayOfWeekToDays': [
        for (var half = 0; half < 2; half++)
          [
            for (var parity = 0; parity < 2; parity++)
              [
                <String>[],
                for (var day = 1; day <= 7; day++)
                  [
                    for (var week = parity; week < 8; week += 2)
                      first
                          .add(Duration(days: half * 56 + week * 7 + day - 1))
                          .toIso8601String()
                  ]
              ]
          ]
      ],
      'holidays': <String, String>{},
      'exchanges': <String, String>{},
    };

Future<DesktopStore> setupDemo() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => call.method == 'readAll' ? <String, String>{} : null);
  final temp =
      await Directory.systemTemp.createTemp('celechron_v4_fixture_');
  Hive.init(temp.path);
  final db = Get.put(DatabaseHelper(), tag: 'db');
  await db.init();
  Get.put(
      buildDemoScholar(calendars: {
        '2026-2027秋冬': syntheticCalendar(DateTime(2026, 9, 14)),
        '2025-2026春夏': syntheticCalendar(DateTime(2026, 2, 23)),
        '2025-2026秋冬': syntheticCalendar(DateTime(2025, 9, 15))
      }, specialDates: {}, now: demoNow)
          .obs,
      tag: 'scholar');
  Get.put(db.getTaskList().obs, tag: 'taskList');
  Get.put(db.getTaskListUpdateTime().obs, tag: 'taskListLastUpdate');
  Get.put(db.getFlowList().obs, tag: 'flowList');
  Get.put(db.getFlowListUpdateTime().obs, tag: 'flowListLastUpdate');
  Get.put(db.getOption(), tag: 'option');
  Get.put(db.getFuse().obs, tag: 'fuse');
  Get.put(OptionController(), tag: 'optionController');
  await loadFont(DesktopFonts.primary, 'C:/Windows/Fonts/segoeui.ttf');
  await loadFont('Microsoft YaHei UI', 'C:/Windows/Fonts/msyh.ttc');
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'D:/dev/flutter';
  await loadFont('MaterialIcons',
      '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  return DesktopStore()
    ..now = demoNow
    ..lastRefreshAt = demoNow;
}

Future<void> disposeDemo(WidgetTester tester, DesktopStore store) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)));
  await tester.pumpWidget(const SizedBox());
  store.dispose();
  await Get.deleteAll(force: true);
  await tester.runAsync(() => Hive.close());
  debugDefaultTargetPlatformOverride = null;
  tester.view.reset();
}

Future<void> saveSnapshot(
    WidgetTester tester, GlobalKey boundary, String path) async {
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await render.toImage();
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(png!.buffer.asUint8List());
    img.dispose();
  });
}

Future<void> renderMatrix(
  WidgetTester tester,
  DesktopStore store,
  String output, {
  bool savePng = true,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  final out = Directory(output)..createSync(recursive: true);
  final problems = <String>[];
  for (final size in desktopSizes) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    for (final brightness in Brightness.values) {
      for (final surface in v4Surfaces) {
        final name =
            '${size.width.toInt()}x${size.height.toInt()}_${brightness.name}_${surface.name}';
        final boundary = GlobalKey();
        store.selectSemester(surface.semesterIndex);
        await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildDesktopTheme(brightness),
            home: DesktopShell(
              key: ValueKey(name),
              store: store,
              initialDestination: surface.destination,
              initialScheduleMode: surface.scheduleMode,
              initialAcademicsTab: surface.academicsTab,
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        Object? error;
        while ((error = tester.takeException()) != null) {
          problems.add('$name: $error');
        }
        if (savePng) {
          await saveSnapshot(tester, boundary, '${out.path}/$name.png');
        }
      }
    }
  }
  // ignore: avoid_print
  print('PROBE ${problems.length} overflow items; PNGs: ${out.path}');
  expect(problems, isEmpty, reason: problems.join('\n'));
}
