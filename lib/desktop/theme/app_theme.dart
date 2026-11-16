import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart';
import '../theme.dart' show DSColors;
import 'tokens.dart';

ThemeData buildDesktopTheme(Brightness brightness) {
  final c = PaperColors(brightness == Brightness.dark);
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: c.hairlineStrong));
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme:
        ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness)
            .copyWith(
                primary: c.accent,
                surface: c.surface,
                onSurface: c.text,
                error: c.danger),
    fontFamily: Paper.font,
    fontFamilyFallback: Paper.fallbacks,
    scaffoldBackgroundColor: c.canvas,
    dividerColor: c.hairline,
    visualDensity: VisualDensity.compact,
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            side: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? BorderSide(color: c.accent, width: 2)
                    : BorderSide.none))),
    iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
            side: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? BorderSide(color: c.accent, width: 2)
                    : BorderSide.none))),
    splashFactory: NoSplash.splashFactory,
    cupertinoOverrideTheme: CupertinoThemeData(brightness: brightness),
    extensions: [
      c,
      DSColors(
          canvas: c.canvas,
          card: c.surface,
          border: c.hairline,
          subtle: c.hover,
          muted: c.text2,
          rail: c.sidebar)
    ],
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder:
            border.copyWith(borderSide: BorderSide(color: c.accent, width: 2))),
    dividerTheme: DividerThemeData(color: c.hairline, space: 1, thickness: 1),
    dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    tooltipTheme:
        const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
  );
  return base.copyWith(
      textTheme: base.textTheme
          .apply(fontFamily: Paper.font)
          .apply(bodyColor: c.text, displayColor: c.text));
}
