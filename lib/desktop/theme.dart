import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart';

/// 桌面版设计规范（所有页面必须只用这里的 token，不要写死颜色/字号/间距）。
///
/// 字体：Windows 上系统 Segoe UI 可能被替换成等宽字体，必须显式指定
/// 「Microsoft YaHei UI」（中英文都清晰，Windows 自带）。
class DS {
  DS._();

  static const String font = 'Microsoft YaHei UI';
  static const List<String> fontFallback = [
    'Microsoft YaHei',
    'Microsoft JhengHei UI',
    'PingFang SC',
    'Noto Sans CJK SC',
  ];

  // 间距（4 的倍数）
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24;

  // 圆角
  static const double radius = 10;
  static const double radiusSm = 6;

  // 外壳尺寸
  static const double railWidth = 76;
  static const double topBarHeight = 52;
  static const double homeworkPanelWidth = 300;

  // 密度：列表行高、表格行高
  static const double rowHeight = 32;
  static const double rowHeightDense = 26;

  // 字号
  static const double fsTitle = 18; // 页面标题
  static const double fsCardTitle = 13.5; // 卡片标题
  static const double fsBody = 13;
  static const double fsSmall = 11.5;
  static const double fsKpi = 22; // 指标数字

  /// 课程/科目配色（按名字哈希取色，浅色底 + 深色字）
  static const List<Color> palette = [
    Color(0xFF4F7CFF),
    Color(0xFF16A37F),
    Color(0xFFF08A24),
    Color(0xFFD9488B),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5C6),
    Color(0xFFCA8A04),
    Color(0xFFE5484D),
    Color(0xFF6366F1),
    Color(0xFF65A30D),
  ];

  static Color colorFor(String key) {
    var h = 0;
    for (final c in key.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return palette[h % palette.length];
  }

  // 语义色
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF08A24);
  static const Color success = Color(0xFF16A37F);
}

/// 卡片/面板的背景、边框等，随明暗主题变化
class DSColors extends ThemeExtension<DSColors> {
  const DSColors({
    required this.canvas,
    required this.card,
    required this.border,
    required this.subtle,
    required this.muted,
    required this.rail,
  });

  /// 窗口底色
  final Color canvas;

  /// 卡片底色
  final Color card;

  /// 卡片描边、分隔线
  final Color border;

  /// 卡片内的次级底色（行悬停、标签底）
  final Color subtle;

  /// 次要文字
  final Color muted;

  /// 侧边栏底色
  final Color rail;

  static DSColors of(BuildContext context) =>
      Theme.of(context).extension<DSColors>()!;

  @override
  DSColors copyWith() => this;

  @override
  DSColors lerp(DSColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

ThemeData buildDesktopTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = dark
      ? const DSColors(
          canvas: Color(0xFF16171A),
          card: Color(0xFF1F2024),
          border: Color(0xFF2E3036),
          subtle: Color(0xFF292B30),
          muted: Color(0xFF9A9CA5),
          rail: Color(0xFF1B1C1F),
        )
      : const DSColors(
          canvas: Color(0xFFF4F5F7),
          card: Color(0xFFFFFFFF),
          border: Color(0xFFE4E6EB),
          subtle: Color(0xFFF1F2F5),
          muted: Color(0xFF6B7080),
          rail: Color(0xFFFAFAFB),
        );
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F7CFF),
    brightness: brightness,
  ).copyWith(surface: colors.card);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: DS.font,
    fontFamilyFallback: DS.fontFallback,
    scaffoldBackgroundColor: colors.canvas,
    visualDensity: VisualDensity.compact,
    splashFactory: NoSplash.splashFactory,
    dividerColor: colors.border,
    extensions: [colors],
    // 数据层的验证码弹窗等仍是 Cupertino 组件，统一字体
    cupertinoOverrideTheme: CupertinoThemeData(brightness: brightness),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: DS.font),
    tooltipTheme:
        const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
    dividerTheme:
        DividerThemeData(color: colors.border, space: 1, thickness: 1),
  );
}
