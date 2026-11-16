import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: PaperType.meta(context)));
}
