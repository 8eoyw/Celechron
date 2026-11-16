import 'package:flutter/material.dart';
import '../theme/tokens.dart';

Future<T?> paperContextMenu<T>(
        BuildContext context, Offset position, Map<T, String> choices) =>
    showMenu<T>(
        context: context,
        position: RelativeRect.fromRect(
            Rect.fromLTWH(position.dx, position.dy, 0, 0),
            Offset.zero & MediaQuery.sizeOf(context)),
        color: PaperColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        items: [
          for (final entry in choices.entries)
            PopupMenuItem(
                value: entry.key,
                child: Builder(
                    builder: (context) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Focus.of(context).hasFocus
                                    ? PaperColors.of(context).accent
                                    : const Color(0x00000000),
                                width: 2)),
                        child:
                            Text(entry.value, style: PaperType.body(context)))))
        ]);
