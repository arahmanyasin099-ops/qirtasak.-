import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'data/download_service.dart';
import 'data/favorites_store.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/config_missing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  await DownloadService.instance.init();
  await FavoritesStore.instance.init();
  runApp(const QirtasakApp());
}

class QirtasakApp extends StatelessWidget {
  const QirtasakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'قرطاسك',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppConfig.isConfigured
          ? const AppShell()
          : const ConfigMissingScreen(),
    );
  }
}
