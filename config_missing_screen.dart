import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../shared/widgets.dart';

class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final secret = AppConfig.isSecretKey;
    return Scaffold(
      body: EmptyState(
        icon: Icons.settings_suggest_rounded,
        title: secret
            ? 'تم رفض المفتاح السري'
            : 'لم يتم ربط التطبيق بقاعدة البيانات',
        message: secret
            ? 'استخدم المفتاح العام (publishable / anon) فقط، ولا تضع Secret key أو service_role داخل التطبيق.'
            : 'أضف SUPABASE_ANON_KEY (المفتاح العام) في أسرار GitHub أو في lib/core/config.dart ثم أعد بناء التطبيق.',
        boxed: false,
      ),
    );
  }
}
