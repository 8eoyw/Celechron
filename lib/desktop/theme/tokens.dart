import 'package:flutter/material.dart';

/// Celechron Desktop v3 ("Antigravity Studio") design constants.
class Paper {
  static const font = 'Segoe UI';
  static const fallbacks = [
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Microsoft JhengHei UI',
    'PingFang SC',
    'Noto Sans CJK SC'
  ];

  // 4px spacing grid
  static const double s1 = 4,
      s2 = 8,
      s3 = 12,
      s4 = 16,
      s5 = 20,
      s6 = 24,
      s8 = 32,
      s10 = 40;

  // Strict 3-tier concentric corner radius system: 4 / 8 / 12.
  static const double chipRadius = 4,
      smallRadius = 8,
      blockRadius = 12,
      popoverRadius = 12,
      frameRadius = 12,
      pillRadius = 8;

  // Unified top chrome height (matches Antigravity's sleek 46px title bar).
  static const double topBarHeight = 46;

  // Official Google Calendar M3 6-hue course palette (zero muddy brown/olive;
  // coral-red & amber reserved strictly for exams, overdue, imminent deadlines, and now).
  static const paletteDark = [
    Color(0xFF8AB4F8), // Google Blue
    Color(0xFF6DD5A8), // Google Sage Mint
    Color(0xFFA5A8F6), // Google Lavender Indigo
    Color(0xFF67D4E8), // Google Sky Cyan
    Color(0xFFC79AF7), // Google Iris Grape
    Color(0xFF5EC9BA), // Google Eucalyptus Teal
  ];
  static const paletteLight = [
    Color(0xFF1A73E8), // Google Blue
    Color(0xFF1E8E68), // Google Sage
    Color(0xFF5C6BC0), // Google Indigo
    Color(0xFF0288D1), // Google Sky
    Color(0xFF8E24AA), // Google Grape
    Color(0xFF00897B), // Google Teal
  ];

  static int colorIndexFor(String name) {
    // FNV-1a 32-bit hash for even spread across Chinese course names.
    var hash = 0x811c9dc5;
    for (final c in name.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash % paletteDark.length;
  }

  static Color colorFor(String name, {bool dark = false}) =>
      (dark ? paletteDark : paletteLight)[colorIndexFor(name)];
}

/// True Antigravity neutral graphite dark + Google Workspace studio light tokens.
class PaperColors extends ThemeExtension<PaperColors> {
  const PaperColors(this.dark);
  final bool dark;

  // ─── Surface Hierarchy (NO box-in-box nesting) ───
  /// Outer window chrome: sidebar + unified top bar.
  Color get sidebar => dark ? const Color(0xFF18181A) : const Color(0xFFF0F4F9);

  /// Primary inset workspace canvas (sits inside the chrome with a 12px frame).
  Color get canvas => dark ? const Color(0xFF0F0F11) : const Color(0xFFFFFFFF);

  /// Subtle secondary inspector / rail pane inside the workspace (1 tonal step).
  Color get rail => dark ? const Color(0xFF131316) : const Color(0xFFF8FAFD);

  /// Floating overlays, dialogs, inputs, and subtle surface blocks.
  Color get surface => dark ? const Color(0xFF1A1A1E) : const Color(0xFFFFFFFF);

  /// Elevated interactive chip / table header / hover surface.
  Color get surfaceElevated =>
      dark ? const Color(0xFF232328) : const Color(0xFFE9EEF6);

  /// Frosted translucent overlay for CommandPalette, Popover, ContextMenu.
  Color get glassSurface =>
      dark ? const Color(0xE01A1A1F) : const Color(0xEBFFFFFF);

  /// Subtle translucent control fill (inputs, segmented track, neutral counters).
  Color get glassControl =>
      dark ? const Color(0x0DFFFFFF) : const Color(0x090F172A);

  /// Antigravity flat borderless translucent selection fill (dark) / Gmail tonal pill (light).
  Color get selectionFill =>
      dark ? const Color(0x16FFFFFF) : const Color(0xFFD3E3FD);
  Color get selectionInk =>
      dark ? const Color(0xFFF3F4F6) : const Color(0xFF041E49);

  /// Hover wash for rows & buttons.
  Color get hover => dark ? const Color(0x0BFFFFFF) : const Color(0x080F172A);

  /// Structural dividers and inset workspace rim.
  Color get hairline =>
      dark ? const Color(0x14FFFFFF) : const Color(0x120F172A);

  /// Control border for inputs, dropdown triggers, floating menus.
  Color get hairlineStrong =>
      dark ? const Color(0x22FFFFFF) : const Color(0x1F0F172A);

  /// Dedicated timeline grid lines (full hour vs half hour).
  Color get gridHour =>
      dark ? const Color(0x14FFFFFF) : const Color(0x130F172A);
  Color get gridHalf =>
      dark ? const Color(0x07FFFFFF) : const Color(0x070F172A);

  // ─── WCAG AA+ Typography Inks ───
  Color get text => dark ? const Color(0xFFECEEF2) : const Color(0xFF1A1D24);
  Color get text2 => dark ? const Color(0xFFA0A4AE) : const Color(0xFF4A5260);
  Color get text3 => dark ? const Color(0xFF7B808C) : const Color(0xFF6B7280);

  // ─── Google M3 Semantic Accent Roles ───
  Color get accent => dark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8);
  Color get accentSoft =>
      dark ? const Color(0x208AB4F8) : const Color(0x151A73E8);
  Color get accentSelectionBorder =>
      dark ? const Color(0x3D8AB4F8) : const Color(0x331A73E8);
  Color get danger => dark ? const Color(0xFFF28B82) : const Color(0xFFD93025);
  Color get warning => dark ? const Color(0xFFFDD663) : const Color(0xFFB06000);
  Color get success => dark ? const Color(0xFF81C995) : const Color(0xFF1E8E3E);

  /// High-contrast ink on solid accent/danger pills.
  Color get onAccent =>
      dark ? const Color(0xFF0F0F11) : const Color(0xFFFFFFFF);

  List<BoxShadow> get shadow => [
        BoxShadow(
            color: dark ? const Color(0xA6000000) : const Color(0x1C0F172A),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12)),
        BoxShadow(
            color: dark ? const Color(0x4D000000) : const Color(0x0D0F172A),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ];

  static PaperColors of(BuildContext context) =>
      Theme.of(context).extension<PaperColors>()!;
  @override
  PaperColors copyWith({bool? dark}) => PaperColors(dark ?? this.dark);
  @override
  PaperColors lerp(PaperColors? other, double t) =>
      t < .5 ? this : other ?? this;
}

class PaperType {
  static TextStyle base(
          BuildContext c, double size, FontWeight weight, double height,
          [Color? color, double? letterSpacing]) =>
      TextStyle(
          fontFamily: Paper.font,
          fontFamilyFallback: Paper.fallbacks,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: letterSpacing,
          color: color ?? PaperColors.of(c).text,
          fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle display(BuildContext c) =>
      base(c, 15.5, FontWeight.w600, 1.25, null, -0.2);
  static TextStyle h1(BuildContext c) =>
      base(c, 15, FontWeight.w600, 1.25, null, -0.15);
  static TextStyle h2(BuildContext c) =>
      base(c, 14, FontWeight.w600, 1.3, null, -0.1);
  static TextStyle cardTitle(BuildContext c) =>
      base(c, 13.5, FontWeight.w600, 1.3, PaperColors.of(c).text, -0.1);
  static TextStyle body(BuildContext c) => base(c, 13.5, FontWeight.w400, 1.45);
  static TextStyle strong(BuildContext c) =>
      base(c, 13.5, FontWeight.w500, 1.45);
  static TextStyle meta(BuildContext c) =>
      base(c, 12, FontWeight.w400, 1.35, PaperColors.of(c).text2);
  static TextStyle label(BuildContext c) =>
      base(c, 11.5, FontWeight.w500, 1.3, PaperColors.of(c).text3, 0.25);
  static TextStyle number(BuildContext c) =>
      base(c, 24, FontWeight.w600, 1.2, null, -0.4);
}
