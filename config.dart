import 'dart:convert';

/// القيم تُمرَّر وقت البناء عبر --dart-define (من أسرار GitHub)،
/// وإن لم تُمرَّر تُستخدم القيم الافتراضية أدناه.
/// المسموح داخل التطبيق: المفتاح العام فقط (anon / publishable).
class AppConfig {
  static const _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const _keyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// رابط المشروع (عام وليس سرّاً).
  static const _defaultUrl = 'https://ywuibxvraxxgvqykptoo.supabase.co';

  /// يمكنك لصق المفتاح العام (sb_publishable_... أو anon) هنا بدل أسرار GitHub.
  /// لا تضع هنا أبداً Secret key ولا service_role.
  static const _embeddedKey = 'sb_publishable_odLHKugbpSHqLaUeEjstYQ_ovAXCa8u';

  static String get supabaseUrl =>
      _urlDefine.isNotEmpty ? _urlDefine : _defaultUrl;

  static String get supabaseAnonKey =>
      _keyDefine.isNotEmpty ? _keyDefine : _embeddedKey;

  /// يرفض التطبيق تشغيل أي مفتاح سرّي حمايةً لقاعدة البيانات.
  static bool get isSecretKey {
    final k = supabaseAnonKey.trim();
    if (k.startsWith('sb_secret_')) return true;
    final parts = k.split('.');
    if (parts.length == 3) {
      try {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        return payload.contains('service_role');
      } catch (_) {}
    }
    return false;
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && !isSecretKey;
}
