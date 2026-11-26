import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/reading_store.dart';
import '../../shared/widgets.dart';

/// قارئ PDF: تنقل بين الصفحات، تكبير بالقرص أو النقر المزدوج،
/// انتقال لصفحة محددة، وحفظ آخر صفحة.
class PdfReaderScreen extends StatefulWidget {
  final Book book;
  final String path;
  const PdfReaderScreen({super.key, required this.book, required this.path});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  PdfController? _controller;
  int _page = 1;
  int _total = 0;
  bool _error = false;

  static const _anim = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final saved = await ReadingStore.instance.lastPage(widget.book.id);
    if (!mounted) return;
    setState(() {
      _page = saved;
      _controller = PdfController(
        document: PdfDocument.openFile(widget.path),
        initialPage: saved,
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final c = _controller;
    if (c == null || page < 1 || (_total > 0 && page > _total)) return;
    c.animateToPage(page, duration: _anim, curve: Curves.easeOut);
  }

  Future<void> _askPage() async {
    final ctrl = TextEditingController(text: '$_page');
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الانتقال إلى صفحة'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'من 1 إلى $_total'),
          onSubmitted: (v) => Navigator.pop(ctx, parseDigits(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, parseDigits(ctrl.text)),
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
    if (result != null) _goToPage(result);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F27),
      appBar: qAppBar(widget.book.title),
      body: _error
          ? const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'تعذر فتح الكتاب',
              message: 'الملف قد يكون تالفاً. جرّب حذف التحميل ثم تحميله من جديد.',
              boxed: false,
            )
          : controller == null
              ? const LoadingState()
              : Column(
                  children: [
                    Expanded(
                      child: PdfView(
                        controller: controller,
                        scrollDirection: Axis.vertical,
                        onDocumentLoaded: (doc) {
                          if (!mounted) return;
                          setState(() => _total = doc.pagesCount);
                          if (_page > doc.pagesCount) _goToPage(1);
                        },
                        onDocumentError: (error) {
                          if (mounted) setState(() => _error = true);
                        },
                        onPageChanged: (page) {
                          if (!mounted) return;
                          setState(() => _page = page);
                          ReadingStore.instance
                              .saveLastPage(widget.book.id, page);
                        },
                      ),
                    ),
                    Container(
                      color: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'الصفحة السابقة',
                              color: AppColors.white,
                              onPressed:
                                  _page > 1 ? () => _goToPage(_page - 1) : null,
                              icon: const Icon(Icons.keyboard_arrow_up_rounded,
                                  size: 32),
                            ),
                            TextButton(
                              onPressed: _total > 0 ? _askPage : null,
                              child: Text(
                                _total > 0
                                    ? 'صفحة $_page من $_total'
                                    : 'جاري الفتح...',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'الصفحة التالية',
                              color: AppColors.white,
                              onPressed: (_total > 0 && _page < _total)
                                  ? () => _goToPage(_page + 1)
                                  : null,
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 32),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
