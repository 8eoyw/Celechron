import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0;
                i < (constraints.maxHeight / 56).floor().clamp(0, 6);
                i++)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                            widthFactor: .65 - (i % 3) * .1,
                            child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                    color: PaperColors.of(context).hairline,
                                    borderRadius: BorderRadius.circular(4)))),
                        const SizedBox(height: 8),
                        FractionallySizedBox(
                            widthFactor: .35,
                            child: Container(
                                height: 8,
                                color: PaperColors.of(context).hairline))
                      ]))
          ]));
}
