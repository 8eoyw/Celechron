// Celechron 桌面版入口：与移动端共用数据层（lib/http、lib/model、lib/database），
// 界面全部在 lib/desktop/ 下重写。构建：flutter build windows -t lib/main_desktop.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:celechron/database/database_helper.dart';
import 'package:celechron/desktop/shell.dart';
import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/model/option.dart';
import 'package:celechron/page/option/option_controller.dart';
import 'package:celechron/services/refresh_coordinator.dart';
import 'package:celechron/utils/global.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RefreshCoordinator.setForegroundActive(true);

  // 与移动端 main() 相同的注册，数据层内部依赖这些 Get.find
  await Hive.initFlutter();
  final db = Get.put(DatabaseHelper(), tag: 'db');
  await db.init();
  Get.put((await db.getScholar()).obs, tag: 'scholar');
  Get.put(db.getTaskList().obs, tag: 'taskList');
  Get.put(db.getTaskListUpdateTime().obs, tag: 'taskListLastUpdate');
  Get.put(db.getFlowList().obs, tag: 'flowList');
  Get.put(db.getFlowListUpdateTime().obs, tag: 'flowListLastUpdate');
  Get.put(db.getOption(), tag: 'option');
  Get.put(db.getFuse().obs, tag: 'fuse');
  // 数据层（Scholar 刷新时读课程号映射与 GPA 口径）依赖它；移动端在设置页注册
  Get.put(OptionController(), tag: 'optionController');

  final store = DesktopStore()..start();
  runApp(DesktopApp(store: store));
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key, required this.store});

  final DesktopStore store;

  @override
  Widget build(BuildContext context) {
    final option = Get.find<Option>(tag: 'option');
    return Obx(() {
      final mode = switch (option.brightnessMode.value) {
        BrightnessMode.light => ThemeMode.light,
        BrightnessMode.dark => ThemeMode.dark,
        BrightnessMode.system => ThemeMode.system,
      };
      return GetMaterialApp(
        title: 'Celechron',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: buildDesktopTheme(Brightness.light),
        darkTheme: buildDesktopTheme(Brightness.dark),
        themeMode: mode,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: DesktopShell(store: store),
      );
    });
  }
}
