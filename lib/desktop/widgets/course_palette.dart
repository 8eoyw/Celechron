import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Google Calendar-inspired curated course swatch:
/// 8 distinct, non-muddy hues balanced for both Light and Dark surfaces.
@immutable
class CourseSwatch {
  const CourseSwatch({
    required this.fill,
    required this.bar,
    required this.ink,
    required this.meta,
  });

  final Color fill;
  final Color bar;
  final Color ink;
  final Color meta;
}

class CoursePalette {
  CoursePalette._();

  // Light mode: crisp Google Calendar pastel fills + high-contrast dark inks.
  static const List<CourseSwatch> _lightSwatches = [
    // Blueberry
    CourseSwatch(
      fill: Color(0xFFE8F0FE),
      bar: Color(0xFF1A73E8),
      ink: Color(0xFF174EA6),
      meta: Color(0xFF3367D6),
    ),
    // Peacock / Teal
    CourseSwatch(
      fill: Color(0xFFE4F4F6),
      bar: Color(0xFF00838F),
      ink: Color(0xFF005662),
      meta: Color(0xFF007680),
    ),
    // Sage
    CourseSwatch(
      fill: Color(0xFFE6F4EA),
      bar: Color(0xFF1E8E3E),
      ink: Color(0xFF0D652D),
      meta: Color(0xFF188038),
    ),
    // Lavender / Indigo
    CourseSwatch(
      fill: Color(0xFFEDEBF9),
      bar: Color(0xFF5E5CE6),
      ink: Color(0xFF39369E),
      meta: Color(0xFF524FD0),
    ),
    // Flamingo / Rose
    CourseSwatch(
      fill: Color(0xFFFCE8EE),
      bar: Color(0xFFD81B60),
      ink: Color(0xFF880E4F),
      meta: Color(0xFFB51751),
    ),
    // Tangerine / Amber (clean warm orange, never olive)
    CourseSwatch(
      fill: Color(0xFFFEF0E3),
      bar: Color(0xFFE37400),
      ink: Color(0xFF8C4600),
      meta: Color(0xFFB06000),
    ),
    // Grape
    CourseSwatch(
      fill: Color(0xFFF3E8FD),
      bar: Color(0xFF8E24AA),
      ink: Color(0xFF5B1272),
      meta: Color(0xFF7B1FA2),
    ),
    // Slate Cobalt
    CourseSwatch(
      fill: Color(0xFFE8EEF5),
      bar: Color(0xFF456990),
      ink: Color(0xFF28415C),
      meta: Color(0xFF3B5A7A),
    ),
  ];

  // Dark mode: deep muted tonal tints on #1B1C1F with luminous Google M3 pastel bars & inks.
  static const List<CourseSwatch> _darkSwatches = [
    // Blueberry
    CourseSwatch(
      fill: Color(0xFF1B2B44),
      bar: Color(0xFF8AB4F8),
      ink: Color(0xFFD2E3FC),
      meta: Color(0xFFA4C2F4),
    ),
    // Peacock / Teal
    CourseSwatch(
      fill: Color(0xFF172F34),
      bar: Color(0xFF78D9EC),
      ink: Color(0xFFCBF0F8),
      meta: Color(0xFF93DBE9),
    ),
    // Sage
    CourseSwatch(
      fill: Color(0xFF1A2F23),
      bar: Color(0xFF81C995),
      ink: Color(0xFFCEEAD6),
      meta: Color(0xFF9BD4AA),
    ),
    // Lavender / Indigo
    CourseSwatch(
      fill: Color(0xFF242442),
      bar: Color(0xFFB2B4FA),
      ink: Color(0xFFDFE0FE),
      meta: Color(0xFFC1C3FB),
    ),
    // Flamingo / Rose
    CourseSwatch(
      fill: Color(0xFF361F2A),
      bar: Color(0xFFF48FB1),
      ink: Color(0xFFFCD5E2),
      meta: Color(0xFFF2A6C0),
    ),
    // Tangerine (warm luminous amber, never muddy brown)
    CourseSwatch(
      fill: Color(0xFF312419),
      bar: Color(0xFFF6AE49),
      ink: Color(0xFFFEECC8),
      meta: Color(0xFFF5C97A),
    ),
    // Grape
    CourseSwatch(
      fill: Color(0xFF2E203B),
      bar: Color(0xFFD7AEFB),
      ink: Color(0xFFEEDBFE),
      meta: Color(0xFFDAB7FA),
    ),
    // Slate Cobalt
    CourseSwatch(
      fill: Color(0xFF212A36),
      bar: Color(0xFF94B4D4),
      ink: Color(0xFFD5E3F1),
      meta: Color(0xFFA8C2DC),
    ),
  ];

  static int indexFor(String key) {
    // Murmur-style avalanche over UTF-16 code units for even spread across 8 hues.
    var h = 0x811c9dc5;
    for (var i = 0; i < key.length; i++) {
      h ^= key.codeUnitAt(i);
      h = (h * 0x01000193) & 0xffffffff;
    }
    h ^= (h >> 16);
    h = (h * 0x85ebca6b) & 0xffffffff;
    h ^= (h >> 13);
    h = (h * 0xc2b2ae35) & 0xffffffff;
    h ^= (h >> 16);
    return (h & 0x7fffffff) % _lightSwatches.length;
  }

  static CourseSwatch of(BuildContext context, String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = isDark ? _darkSwatches : _lightSwatches;
    return list[indexFor(key)];
  }

  /// Exam blocks intentionally carry higher visual salience so they stand out immediately.
  static CourseSwatch exam(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const CourseSwatch(
        fill: Color(0xFF3D2518),
        bar: Color(0xFFFFB74D),
        ink: Color(0xFFFFE0B2),
        meta: Color(0xFFFFCC80),
      );
    }
    return const CourseSwatch(
      fill: Color(0xFFFEEAD2),
      bar: Color(0xFFD96500),
      ink: Color(0xFF7A3500),
      meta: Color(0xFFA34B00),
    );
  }

  /// Auto-planned learning flow blocks use subtle primary tonal tint.
  static CourseSwatch flow(BuildContext context) {
    final c = DesktopColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CourseSwatch(
      fill: isDark ? const Color(0xFF1A2538) : const Color(0xFFEEF4FF),
      bar: c.primary,
      ink: isDark ? const Color(0xFFD3E3FD) : const Color(0xFF0B57D0),
      meta: c.text2,
    );
  }
}
