import 'dart:io';

import 'package:flutter/foundation.dart';

final class PlatformFeatures {
  static bool get hasBackgroundRefresh {
    return Platform.isIOS || Platform.isAndroid;
  }

  static bool get hasWidgetSupport {
    return Platform.isIOS || Platform.isAndroid;
  }

  static bool get isMobile {
    return Platform.isIOS || Platform.isAndroid;
  }

  /// 以 defaultTargetPlatform 判断：运行时即实际平台；widget 测试默认模拟
  /// Android，可用 debugDefaultTargetPlatformOverride 切换桌面/移动布局
  static bool get isDesktop {
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux =>
        true,
      _ => false,
    };
  }
}
