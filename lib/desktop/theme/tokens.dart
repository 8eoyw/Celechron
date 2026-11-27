import 'package:flutter/material.dart';

/// Strict concentric radius scale following Google Material 3 + Antigravity.
/// Small tags/badges use 4–6px so they never distort into stubby ovals.
abstract final class DesktopRadius {
  static const double sheet = 16;
  static const double dialog = 16;
  static const double popover = 12;
  static const double card = 12;
  static const double block = 8;
  static const double chip = 8;
  static const double input = 8;
  static const double badge = 6;
  static const double tag = 4;
  static const double pill =
      999; // Reserved strictly for wide horizontal pills.
}

abstract final class DesktopFonts {
  static const String primary = 'Segoe UI';
  static const List<String> fallback = ['Microsoft YaHei UI', 'PingFang SC'];
}

@immutable
class DesktopColors extends ThemeExtension<DesktopColors> {
  const DesktopColors({
    required this.chrome,
    required this.sheet,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.hover,
    required this.selectedFill,
    required this.selectedBorder,
    required this.hairline,
    required this.gridHour,
    required this.gridHalf,
    required this.pastScrim,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.railIndicator,
    required this.onRailIndicator,
    required this.danger,
    required this.dangerFill,
    required this.warning,
    required this.warningFill,
    required this.success,
    required this.successFill,
  });

  final Color chrome;
  final Color sheet;
  final Color surfaceLow;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color hover;
  final Color selectedFill;
  final Color selectedBorder;
  final Color hairline;
  final Color gridHour;
  final Color gridHalf;
  final Color pastScrim;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final Color railIndicator;
  final Color onRailIndicator;
  final Color danger;
  final Color dangerFill;
  final Color warning;
  final Color warningFill;
  final Color success;
  final Color successFill;

  static const light = DesktopColors(
    chrome: Color(0xFFF3F6FC),
    sheet: Color(0xFFFFFFFF),
    surfaceLow: Color(0xFFF8FAFD),
    surfaceHigh: Color(0xFFE9EEF6),
    surfaceHighest: Color(0xFFDDE3EA),
    hover: Color(0x0D1F1F1F),
    selectedFill: Color(0x1A0B57D0),
    selectedBorder: Color(0x520B57D0),
    hairline: Color(0xFFE1E5EC),
    gridHour: Color(0xFFE3E7EE),
    gridHalf: Color(0xFFF1F3F7),
    pastScrim: Color(0x081F1F1F),
    text1: Color(0xFF1F1F1F),
    text2: Color(0xFF444746),
    text3: Color(0xFF6B7075),
    primary: Color(0xFF0B57D0),
    primaryContainer: Color(0xFFD3E3FD),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF041E49),
    railIndicator: Color(0xFFC2E7FF),
    onRailIndicator: Color(0xFF001D35),
    danger: Color(0xFFB3261E),
    dangerFill: Color(0xFFFCE8E6),
    warning: Color(0xFFB06000),
    warningFill: Color(0xFFFEF3E2),
    success: Color(0xFF137333),
    successFill: Color(0xFFE6F4EA),
  );

  static const dark = DesktopColors(
    chrome: Color(0xFF131314),
    sheet: Color(0xFF1B1C1F),
    surfaceLow: Color(0xFF17181B),
    surfaceHigh: Color(0xFF25272B),
    surfaceHighest: Color(0xFF303339),
    hover: Color(0x12E8EAED),
    selectedFill: Color(0x268AB4F8),
    selectedBorder: Color(0x66A8C7FA),
    hairline: Color(0xFF2B2E34),
    gridHour: Color(0xFF2A2D33),
    gridHalf: Color(0xFF212328),
    pastScrim: Color(0x14000000),
    text1: Color(0xFFE8EAED),
    text2: Color(0xFFBDC1C6),
    text3: Color(0xFF8C929C),
    primary: Color(0xFFA8C7FA),
    primaryContainer: Color(0xFF173A73),
    onPrimary: Color(0xFF062E6F),
    onPrimaryContainer: Color(0xFFD3E3FD),
    railIndicator: Color(0xFF1B3A5C),
    onRailIndicator: Color(0xFFC2E7FF),
    danger: Color(0xFFF2B8B5),
    dangerFill: Color(0x33F2B8B5),
    warning: Color(0xFFFDD663),
    warningFill: Color(0x29FDD663),
    success: Color(0xFF81C995),
    successFill: Color(0x2681C995),
  );

  static DesktopColors of(BuildContext context) =>
      Theme.of(context).extension<DesktopColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  DesktopColors copyWith({
    Color? chrome,
    Color? sheet,
    Color? surfaceLow,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? hover,
    Color? selectedFill,
    Color? selectedBorder,
    Color? hairline,
    Color? gridHour,
    Color? gridHalf,
    Color? pastScrim,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? onPrimaryContainer,
    Color? railIndicator,
    Color? onRailIndicator,
    Color? danger,
    Color? dangerFill,
    Color? warning,
    Color? warningFill,
    Color? success,
    Color? successFill,
  }) =>
      DesktopColors(
        chrome: chrome ?? this.chrome,
        sheet: sheet ?? this.sheet,
        surfaceLow: surfaceLow ?? this.surfaceLow,
        surfaceHigh: surfaceHigh ?? this.surfaceHigh,
        surfaceHighest: surfaceHighest ?? this.surfaceHighest,
        hover: hover ?? this.hover,
        selectedFill: selectedFill ?? this.selectedFill,
        selectedBorder: selectedBorder ?? this.selectedBorder,
        hairline: hairline ?? this.hairline,
        gridHour: gridHour ?? this.gridHour,
        gridHalf: gridHalf ?? this.gridHalf,
        pastScrim: pastScrim ?? this.pastScrim,
        text1: text1 ?? this.text1,
        text2: text2 ?? this.text2,
        text3: text3 ?? this.text3,
        primary: primary ?? this.primary,
        primaryContainer: primaryContainer ?? this.primaryContainer,
        onPrimary: onPrimary ?? this.onPrimary,
        onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
        railIndicator: railIndicator ?? this.railIndicator,
        onRailIndicator: onRailIndicator ?? this.onRailIndicator,
        danger: danger ?? this.danger,
        dangerFill: dangerFill ?? this.dangerFill,
        warning: warning ?? this.warning,
        warningFill: warningFill ?? this.warningFill,
        success: success ?? this.success,
        successFill: successFill ?? this.successFill,
      );

  @override
  DesktopColors lerp(DesktopColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DesktopColors(
      chrome: l(chrome, other.chrome),
      sheet: l(sheet, other.sheet),
      surfaceLow: l(surfaceLow, other.surfaceLow),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      surfaceHighest: l(surfaceHighest, other.surfaceHighest),
      hover: l(hover, other.hover),
      selectedFill: l(selectedFill, other.selectedFill),
      selectedBorder: l(selectedBorder, other.selectedBorder),
      hairline: l(hairline, other.hairline),
      gridHour: l(gridHour, other.gridHour),
      gridHalf: l(gridHalf, other.gridHalf),
      pastScrim: l(pastScrim, other.pastScrim),
      text1: l(text1, other.text1),
      text2: l(text2, other.text2),
      text3: l(text3, other.text3),
      primary: l(primary, other.primary),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimary: l(onPrimary, other.onPrimary),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      railIndicator: l(railIndicator, other.railIndicator),
      onRailIndicator: l(onRailIndicator, other.onRailIndicator),
      danger: l(danger, other.danger),
      dangerFill: l(dangerFill, other.dangerFill),
      warning: l(warning, other.warning),
      warningFill: l(warningFill, other.warningFill),
      success: l(success, other.success),
      successFill: l(successFill, other.successFill),
    );
  }
}

abstract final class DesktopType {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle _base(
    BuildContext context,
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
    bool numeric = false,
  }) =>
      TextStyle(
        fontFamily: DesktopFonts.primary,
        fontFamilyFallback: DesktopFonts.fallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: numeric ? tabular : null,
      );

  static TextStyle display(BuildContext context, {bool numeric = true}) =>
      _base(context, 28, FontWeight.w500, DesktopColors.of(context).text1,
          height: 1.2, letterSpacing: -0.4, numeric: numeric);

  static TextStyle title(BuildContext context) =>
      _base(context, 19, FontWeight.w500, DesktopColors.of(context).text1,
          height: 1.25, letterSpacing: -0.2);

  static TextStyle section(BuildContext context) =>
      _base(context, 14, FontWeight.w600, DesktopColors.of(context).text1,
          height: 1.35);

  static TextStyle body(BuildContext context, {bool numeric = false}) =>
      _base(context, 13.5, FontWeight.w400, DesktopColors.of(context).text1,
          height: 1.4, numeric: numeric);

  static TextStyle strong(BuildContext context, {bool numeric = false}) =>
      _base(context, 13.5, FontWeight.w600, DesktopColors.of(context).text1,
          height: 1.35, numeric: numeric);

  static TextStyle meta(BuildContext context, {bool numeric = false}) =>
      _base(context, 12, FontWeight.w400, DesktopColors.of(context).text2,
          height: 1.35, numeric: numeric);

  static TextStyle caption(BuildContext context, {bool numeric = false}) =>
      _base(context, 11.5, FontWeight.w500, DesktopColors.of(context).text3,
          height: 1.3, numeric: numeric);

  static TextStyle label(BuildContext context) =>
      _base(context, 11.5, FontWeight.w600, DesktopColors.of(context).text2,
          height: 1.25, letterSpacing: 0.25);

  static TextStyle mono(BuildContext context, {double size = 12}) =>
      _base(context, size, FontWeight.w500, DesktopColors.of(context).text2,
          height: 1.25, numeric: true);
}
