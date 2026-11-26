import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/download_service.dart';
import '../../data/favorites_store.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import '../reader/pdf_reader_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _busy = false;
  double? _progress;
  double _lastShown = 0;
  int _received = 0;
  String _label = '';
  CancelToken? _cancel;

  Book get book => widget.book;

  Future<void> _run(
    String label,
    Future<void> Function(ProgressCallback onProgress, CancelToken cancel)
        task,
  ) async {
    final cancel = CancelToken();
    setState(() {
      _busy = true;
      _progress = null;
      _lastShown = 0;
      _received = 0;
      _label = label;
      _cancel = cancel;
    });
    try {
      await task((received, total) {
        if (!mounted) return;
        final p = total > 0 ? received / total : null;
        if (p == null || p - _lastShown >= 0.01 || p >= 1) {
          setState(() {
            _progress = p;
            _received = received;
            if (p != null) _lastShown = p;
          });
        }
      }, cancel);
    } on DownloadCancelled {
      // ألغى الطالب العملية
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _cancel = null;
        });
      }
    }
  }

  Future<void> _read() async {
    await _run('جاري تجهيز الكتاب...', (onProgress, cancel) async {
      final path = await DownloadService.instance
          .readablePath(book, onProgress: onProgress, cancel: cancel);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(book: book, path: path),
        ),
      );
    });
  }

  Future<void> _download() async {
    await _run('جاري تحميل الكتاب...', (onProgress, cancel) async {
      await DownloadService.instance
          .download(book, onProgress: onProgress, cancel: cancel);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحميل الكتاب. يمكنك قراءته دون إنترنت.')),
      );
    });
  }

  Future<void> _deleteDownload() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التحميل'),
        content: const Text('سيُحذف الكتاب من هاتفك، ويمكنك تحميله مجدداً لاحقاً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DownloadService.instance.delete(book.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloaded = DownloadService.instance.isDownloaded(book.id);

    return Scaffold(
      appBar: qAppBar(
        'تفاصيل الكتاب',
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: FavoritesStore.instance.changes,
            builder: (_, __, ___) {
              final fav = FavoritesStore.instance.isFavorite(book.id);
              return IconButton(
                tooltip: fav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                icon: Icon(fav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded),
                onPressed: () => FavoritesStore.instance.toggle(book),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: BookCover(
                url: book.coverUrl, width: 160, height: 220, radius: 16),
          ),
          const SizedBox(height: 16),
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 14),
          _InfoCard(rows: [
            ('المرحلة والصف', '${book.stageTitle} • ${book.gradeTitle}'),
            ('المادة', book.subjectTitle),
            if (book.pages != null) ('عدد الصفحات', '${book.pages}'),
            if (book.fileSizeBytes != null)
              ('حجم الملف', formatBytes(book.fileSizeBytes!)),
          ]),
          const SizedBox(height: 18),
          if (_busy) ...[
            Text(_label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.green,
            ),
            const SizedBox(height: 6),
            Text(
              _progress != null
                  ? '${(_progress! * 100).toStringAsFixed(0)}%  (${formatBytes(_received)})'
                  : formatBytes(_received),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => _cancel?.cancel(),
                child: const Text('إلغاء'),
              ),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _read,
              icon: const Icon(Icons.chrome_reader_mode_rounded),
              label: const Text('قراءة الكتاب'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 10),
            if (downloaded) ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done_rounded,
                      size: 18, color: AppColors.green),
                  SizedBox(width: 6),
                  Text('محمّل على هاتفك • يعمل دون إنترنت'),
                ],
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _deleteDownload,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('حذف التحميل'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download_rounded),
                label: const Text('تحميل PDF'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<(String, String)> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(rows[i].$1,
                      style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
