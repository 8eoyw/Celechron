import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class CourseColors {
  CourseColors(BuildContext context, String name) {
    final c = PaperColors.of(context);
    final hue = Paper.colorFor(name);
    bar = c.dark ? Color.alphaBlend(const Color(0x1FFFFFFF), hue) : hue;
    tint =
        Color.alphaBlend(hue.withValues(alpha: c.dark ? .20 : .11), c.surface);
    ink = HSLColor.fromColor(hue).withLightness(c.dark ? .80 : .35).toColor();
  }
  late final Color bar, tint, ink;
}
