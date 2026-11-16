import 'package:flutter/material.dart';

class Paper {
  static const font = 'Microsoft YaHei UI';
  static const fallbacks = [
    'Microsoft YaHei',
    'Microsoft JhengHei UI',
    'PingFang SC',
    'Noto Sans CJK SC'
  ];
  static const double s1 = 4,
      s2 = 8,
      s3 = 12,
      s4 = 16,
      s5 = 20,
      s6 = 24,
      s8 = 32,
      s10 = 40;
  static const double smallRadius = 6, blockRadius = 8, popoverRadius = 12;
  static const palette = [
    Color(0xFF3E63DD),
    Color(0xFF12A594),
    Color(0xFF30A46C),
    Color(0xFF8DA336),
    Color(0xFFD6A100),
    Color(0xFFE5732E),
    Color(0xFFE5484D),
    Color(0xFFD6409F),
    Color(0xFF8E4EC6),
    Color(0xFF6E56CF)
  ];
  static Color colorFor(String name) {
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}

class PaperColors extends ThemeExtension<PaperColors> {
  const PaperColors(this.dark);
  final bool dark;
  Color get canvas => dark ? const Color(0xFF151517) : const Color(0xFFF7F7F5);
  Color get sidebar => dark ? const Color(0xFF1A1A1D) : const Color(0xFFF0F0EE);
  Color get surface => dark ? const Color(0xFF1E1E22) : const Color(0xFFFFFFFF);
  Color get hover => dark ? const Color(0x0DFFFFFF) : const Color(0x0A000000);
  Color get hairline =>
      dark ? const Color(0xFF2B2B30) : const Color(0xFFE7E7E4);
  Color get hairlineStrong =>
      dark ? const Color(0xFF3A3A40) : const Color(0xFFD5D5D0);
  Color get text => dark ? const Color(0xFFECECEA) : const Color(0xFF1C1C1A);
  Color get text2 => dark ? const Color(0xFFA3A39E) : const Color(0xFF6A6A65);
  Color get text3 => dark ? const Color(0xFF6E6E6A) : const Color(0xFF9C9C96);
  Color get accent => dark ? const Color(0xFF7B98FF) : const Color(0xFF2F5BEA);
  Color get accentSoft =>
      Color.alphaBlend(accent.withValues(alpha: dark ? .18 : .1), surface);
  Color get danger => dark ? const Color(0xFFFF6B70) : const Color(0xFFE5484D);
  Color get warning => dark ? const Color(0xFFF5A524) : const Color(0xFFC56A00);
  Color get success => dark ? const Color(0xFF3DD68C) : const Color(0xFF1F9D55);
  List<BoxShadow> get shadow => [
        BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x1A000000),
            blurRadius: 24,
            offset: const Offset(0, 8))
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
          [Color? color]) =>
      TextStyle(
          fontFamily: Paper.font,
          fontFamilyFallback: Paper.fallbacks,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? PaperColors.of(c).text,
          fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle display(BuildContext c) => base(c, 28, FontWeight.w600, 1.2);
  static TextStyle h1(BuildContext c) => base(c, 20, FontWeight.w600, 1.3);
  static TextStyle h2(BuildContext c) => base(c, 15, FontWeight.w600, 1.35);
  static TextStyle body(BuildContext c) => base(c, 14, FontWeight.w400, 1.45);
  static TextStyle strong(BuildContext c) => base(c, 14, FontWeight.w600, 1.45);
  static TextStyle meta(BuildContext c) =>
      base(c, 12.5, FontWeight.w400, 1.35, PaperColors.of(c).text2);
  static TextStyle label(BuildContext c) =>
      base(c, 11.5, FontWeight.w600, 1.35, PaperColors.of(c).text2)
          .copyWith(letterSpacing: .4);
  static TextStyle number(BuildContext c) => base(c, 26, FontWeight.w600, 1.2);
}
