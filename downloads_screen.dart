import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/download_service.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import '../reader/pdf_reader_screen.dart';

/// الكتب المحملة. تعمل بالكامل دون إنترنت.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التحميل'),
        content: Text('هل تريد حذف «${book.title}» من هاتفك؟'),
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
    if (ok == true) await DownloadService.instance.delete(book.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: qAppBar('التحميلات'),
      body: ValueListenableBuilder<int>(
        valueListenable: DownloadService.instance.changes,
        builder: (context, _, __) {
          final books = DownloadService.instance.books;
          if (books.isEmpty) {
            return const EmptyState(
              icon: Icons.download_for_offline_outlined,
              title: 'لا توجد كتب محملة بعد',
              message: 'الكتب التي تحملها تظهر هنا وتعمل دون إنترنت.',
              boxed: false,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final book = books[i];
              return BookTile(
                book: book,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PdfReaderScreen(
                        book: book,
                        path: DownloadService.instance.pathFor(book.id),
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  tooltip: 'حذف التحميل',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => _confirmDelete(context, book),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
