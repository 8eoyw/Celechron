import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Google Calendar-inspired M3 tonal event colors blended directly over the
/// primary canvas (opaque over grid lines, zero muddy brown/olive).
class CourseColors {
  CourseColors(BuildContext context, String name) {
    final c = PaperColors.of(context);
    final hue = Paper.colorFor(name, dark: c.dark);
    bar = hue;
    tint = Color.alphaBlend(
        hue.withValues(alpha: c.dark ? .17 : .11), c.canvas);
    border = Color.alphaBlend(
        hue.withValues(alpha: c.dark ? .38 : .28), c.canvas);
    ink = c.dark
        ? Color.alphaBlend(const Color(0xADFFFFFF), hue)
        : HSLColor.fromColor(hue).withLightness(.24).toColor();
  }
  late final Color bar, tint, border, ink;
}
