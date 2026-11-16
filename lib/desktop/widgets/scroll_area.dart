import 'package:flutter/material.dart';

class ScrollArea extends StatefulWidget {
  const ScrollArea({super.key, required this.child});
  final Widget child;
  @override
  State<ScrollArea> createState() => _ScrollAreaState();
}

class _ScrollAreaState extends State<ScrollArea> {
  final controller = ScrollController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.only(right: 8),
          child: widget.child));
}
