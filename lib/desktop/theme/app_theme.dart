import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildDesktopTheme(Brightness brightness) {
  final c = PaperColors(brightness == Brightness.dark);
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.hairlineStrong));
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme:
        ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness)
            .copyWith(
                primary: c.accent,
                onPrimary: c.onAccent,
                surface: c.surface,
                onSurface: c.text,
                error: c.danger),
    fontFamily: Paper.font,
    fontFamilyFallback: Paper.fallbacks,
    scaffoldBackgroundColor: c.sidebar,
    dividerColor: c.hairline,
    visualDensity: VisualDensity.compact,
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: c.dark ? .30 : .20),
        selectionHandleColor: c.accent),
    scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(5),
        radius: const Radius.circular(999),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.hovered)) {
            return c.text2.withValues(alpha: c.dark ? .55 : .45);
          }
          return c.text3.withValues(alpha: c.dark ? .32 : .25);
        })),
    switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.transparent
                : c.hairlineStrong),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? c.accent
                : c.glassControl),
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.onAccent : c.text2)),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Paper.pillRadius))),
            foregroundColor: WidgetStatePropertyAll(c.text),
            overlayColor: WidgetStatePropertyAll(c.hover),
            side: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? BorderSide(color: c.accent, width: 1.5)
                    : BorderSide.none))),
    iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Paper.pillRadius))),
            overlayColor: WidgetStatePropertyAll(c.hover),
            side: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? BorderSide(color: c.accent, width: 1.5)
                    : BorderSide.none))),
    splashFactory: NoSplash.splashFactory,
    cupertinoOverrideTheme: CupertinoThemeData(brightness: brightness),
    extensions: [c],
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.glassControl,
        isDense: true,
        hintStyle: TextStyle(
            fontFamily: Paper.font,
            fontFamilyFallback: Paper.fallbacks,
            fontSize: 13.5,
            color: c.text3),
        labelStyle: TextStyle(
            fontFamily: Paper.font,
            fontFamilyFallback: Paper.fallbacks,
            fontSize: 13,
            color: c.text2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border,
        enabledBorder: border,
        hoverColor: c.hover,
        focusedBorder: border.copyWith(
            borderSide: BorderSide(color: c.accent, width: 1.5))),
    dividerTheme: DividerThemeData(color: c.hairline, space: 1, thickness: 1),
    dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Paper.popoverRadius),
            side: BorderSide(color: c.hairlineStrong))),
    tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 360),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: c.dark ? const Color(0xE81B202C) : const Color(0xEA1B1F27),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x28FFFFFF)),
            boxShadow: c.shadow),
        textStyle: const TextStyle(
            fontFamily: Paper.font,
            fontFamilyFallback: Paper.fallbacks,
            fontSize: 12,
            height: 1.35,
            color: Color(0xFFE8ECF4))),
  );
  return base.copyWith(
      textTheme: base.textTheme
          .apply(fontFamily: Paper.font)
          .apply(bodyColor: c.text, displayColor: c.text));
}
