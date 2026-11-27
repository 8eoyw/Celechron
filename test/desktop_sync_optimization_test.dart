import 'dart:io';

import 'package:celechron/http/ugrs_spider.dart';
import 'package:celechron/http/zju_network.dart';
import 'package:celechron/http/zjuServices/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZjuNetwork', () {
    test('identifies campus ZJU hosts strictly', () {
      expect(ZjuNetwork.isZjuHost('zju.edu.cn'), isTrue);
      expect(ZjuNetwork.isZjuHost('courses.zju.edu.cn'), isTrue);
      expect(ZjuNetwork.isZjuHost('ZDBK.ZJU.EDU.CN'), isTrue);
      expect(ZjuNetwork.isZjuHost('zjuam.zju.edu.cn'), isTrue);
      expect(ZjuNetwork.isZjuHost('fakezju.edu.cn'), isFalse);
      expect(ZjuNetwork.isZjuHost('github.com'), isFalse);
    });

    test('distinguishes route/transport errors from credential failures', () {
      expect(
        ZjuNetwork.isRouteTransportError(const SocketException('refused')),
        isTrue,
      );
      expect(
        ZjuNetwork.isRouteTransportError(const HandshakeException('eof')),
        isTrue,
      );
      expect(
        ZjuNetwork.isRouteTransportError(Exception('请求超时')),
        isTrue,
      );
      expect(
        ZjuNetwork.isRouteTransportError(LoginException('学号或密码错误')),
        isFalse,
      );
    });
  });

  group('UgrsSpider lean desktop mode', () {
    test('omits practice module label when includePractice is false', () {
      final full = UgrsSpider('3250000000', 'demo');
      final lean = UgrsSpider(
        '3250000000',
        'demo',
        includePractice: false,
        probeGraduate: false,
      );
      expect(full.fetchLabels, contains('实践'));
      expect(full.fetchLabels, hasLength(7));
      expect(lean.fetchLabels, isNot(contains('实践')));
      expect(lean.fetchLabels, hasLength(6));
    });
  });
}
