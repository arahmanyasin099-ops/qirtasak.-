import 'dart:async';
import 'dart:io';

class DownloadException implements Exception {
  final String message;
  const DownloadException(this.message);
  @override
  String toString() => message;
}

class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// يحوّل أي خطأ تقني إلى رسالة عربية مفهومة للطالب.
String friendlyError(Object e) {
  if (e is DownloadException) return e.message;
  final s = e.toString().toLowerCase();
  if (e is SocketException ||
      e is TimeoutException ||
      e is HandshakeException ||
      s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('clientexception') ||
      s.contains('connection')) {
    return 'تعذر الاتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
  }
  if (s.contains('no space') || s.contains('enospc')) {
    return 'مساحة التخزين في هاتفك ممتلئة.';
  }
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
