import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildDesktopTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? DesktopColors.dark : DesktopColors.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primaryContainer,
    onPrimaryContainer: c.onPrimaryContainer,
    secondary: c.primary,
    onSecondary: c.onPrimary,
    secondaryContainer: c.railIndicator,
    onSecondaryContainer: c.onRailIndicator,
    tertiary: c.success,
    onTertiary: c.onPrimary,
    error: c.danger,
    onError: c.onPrimary,
    surface: c.sheet,
    onSurface: c.text1,
    onSurfaceVariant: c.text2,
    outline: c.hairline,
    outlineVariant: c.hairline,
    surfaceContainerLowest: c.sheet,
    surfaceContainerLow: c.surfaceLow,
    surfaceContainer: c.chrome,
    surfaceContainerHigh: c.surfaceHigh,
    surfaceContainerHighest: c.surfaceHighest,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.chrome,
    canvasColor: c.sheet,
    fontFamily: DesktopFonts.primary,
    fontFamilyFallback: DesktopFonts.fallback,
    extensions: [c],
    dividerTheme: DividerThemeData(
      color: c.hairline,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF32353B) : const Color(0xFF202124),
        borderRadius: BorderRadius.circular(DesktopRadius.badge),
      ),
      textStyle: const TextStyle(
        fontFamily: DesktopFonts.primary,
        fontFamilyFallback: DesktopFonts.fallback,
        fontSize: 12,
        color: Color(0xFFF8FAFD),
        height: 1.35,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.sheet,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopRadius.dialog),
        side: BorderSide(color: c.hairline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          isDark ? const Color(0xFF303339) : const Color(0xFF202124),
      contentTextStyle: const TextStyle(
        fontFamily: DesktopFonts.primary,
        fontFamilyFallback: DesktopFonts.fallback,
        fontSize: 13,
        color: Color(0xFFF8FAFD),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopRadius.chip),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll(false),
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.dragged)) {
          return c.text3.withValues(alpha: 0.55);
        }
        return c.text3.withValues(alpha: 0.28);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceLow,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesktopRadius.input),
        borderSide: BorderSide(color: c.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesktopRadius.input),
        borderSide: BorderSide(color: c.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesktopRadius.input),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.primary,
      selectionColor: c.selectedFill,
    ),
  );
}
