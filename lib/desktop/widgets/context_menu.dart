import 'package:flutter/material.dart';
import '../theme/tokens.dart';

Future<T?> paperContextMenu<T>(
        BuildContext context, Offset position, Map<T, String> choices) =>
    showMenu<T>(
        context: context,
        position: RelativeRect.fromRect(
            Rect.fromLTWH(position.dx, position.dy + 6, 0, 0),
            Offset.zero & MediaQuery.sizeOf(context)),
        color: PaperColors.of(context).glassSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: PaperColors.of(context).dark
            ? const Color(0xBB000000)
            : const Color(0x280F172A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: PaperColors.of(context).hairlineStrong)),
        menuPadding: const EdgeInsets.all(6),
        items: [
          for (final entry in choices.entries)
            PopupMenuItem(
                value: entry.key,
                height: 36,
                padding: EdgeInsets.zero,
                child: Builder(
                    builder: (context) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Focus.of(context).hasFocus
                                    ? PaperColors.of(context).accent
                                    : const Color(0x00000000),
                                width: 1.5)),
                        child:
                            Text(entry.value, style: PaperType.body(context)))))
        ]);
