import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'harness.dart';

void main() {
  testWidgets('every desktop page, size and theme has zero overflows',
      (tester) async {
    final store = await tester.runAsync(setupDemo);
    try {
      await renderMatrix(
          tester,
          store!,
          Platform.environment['CELECHRON_PROBE_OUT'] ??
              '${Directory.systemTemp.path}/celechron_paper_probe');
    } finally {
      await disposeDemo(tester, store!);
    }
  });
}
