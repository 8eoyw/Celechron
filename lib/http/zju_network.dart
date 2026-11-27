import 'dart:io';

/// Network route & retry helpers modeled after zju-learning-cli (`zju.py`):
/// - Prefer DIRECT connections for `*.zju.edu.cn` hosts so local overseas proxies
///   (e.g. Clash/Mihomo) don't break campus TLS/intranet routes.
/// - Automatically fall back to system proxy when direct route times out or
///   refuses connection, remembering whichever route last succeeded.
class ZjuNetwork {
  ZjuNetwork._();

  static const Duration connectTimeout = Duration(seconds: 6);
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

  static bool isZjuHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'zju.edu.cn' || lower.endsWith('.zju.edu.cn');
  }

  static HttpClient createClient({bool preferDirectForZju = true}) {
    final client = HttpClient();
    client.connectionTimeout = connectTimeout;
    client.userAgent = desktopUserAgent;
    if (preferDirectForZju) {
      client.findProxy = (uri) => isZjuHost(uri.host)
          ? 'DIRECT'
          : HttpClient.findProxyFromEnvironment(uri);
    }
    return client;
  }

  /// True when [error] looks like a route/transport problem where flipping
  /// between DIRECT and system proxy may recover connectivity.
  static bool isRouteTransportError(Object error) {
    if (error is SocketException || error is HandshakeException) return true;
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('handshakeexception') ||
        msg.contains('connection timed out') ||
        msg.contains('connection refused') ||
        msg.contains('connection closed') ||
        msg.contains('timed out') ||
        msg.contains('超时') ||
        msg.contains('网络错误');
  }

  /// Parse `Retry-After` header (seconds) or fall back to exponential backoff,
  /// capped to keep interactive desktop sync responsive.
  static Duration rateLimitDelay(HttpClientResponse response, int attempt) {
    final raw = response.headers.value(HttpHeaders.retryAfterHeader)?.trim();
    if (raw != null) {
      final secs = int.tryParse(raw);
      if (secs != null && secs > 0) {
        return Duration(seconds: secs.clamp(1, 15));
      }
    }
    final secs = (2 * (1 << attempt)).clamp(2, 12);
    return Duration(seconds: secs);
  }
}
