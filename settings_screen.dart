import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../data/library_repository.dart';
import '../../shared/widgets.dart';

/// الإعدادات + اختبار الاتصال بقاعدة البيانات.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _testing = false;
  ConnectionReport? _report;
  String? _error;

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _report = null;
      _error = null;
    });
    try {
      final r = await LibraryRepository.instance.testConnection();
      if (!mounted) return;
      setState(() => _report = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(AppConfig.supabaseUrl)?.host ?? '';
    return Scaffold(
      appBar: qAppBar('الإعدادات'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الاتصال بقاعدة البيانات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _row('الخادم', host),
                if (_report != null) ...[
                  const Divider(height: 20),
                  _row('المراحل', '${_report!.stages}'),
                  _row('الصفوف', '${_report!.grades}'),
                  _row('المواد', '${_report!.subjects}'),
                  _row('الكتب المنشورة', '${_report!.books}'),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.green, size: 20),
                      SizedBox(width: 6),
                      Text('الاتصال ناجح',
                          style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _testing ? null : _test,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded),
                    label: Text(_testing ? 'جارٍ الاختبار...' : 'اختبار الاتصال'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
