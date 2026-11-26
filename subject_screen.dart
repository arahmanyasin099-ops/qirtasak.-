import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../data/library_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import '../book/open_book.dart';

/// صفحة كتب المادة، تقرأ الكتب الحقيقية من Supabase.
class SubjectScreen extends StatefulWidget {
  final Stage stage;
  final Grade grade;
  final Subject subject;

  const SubjectScreen({
    super.key,
    required this.stage,
    required this.grade,
    required this.subject,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  late Future<List<Book>> _future;

  @override
  void initState() {
    super.initState();
    _future = LibraryRepository.instance.booksBySubject(widget.subject.id);
  }

  Future<void> _reload() async {
    final f = LibraryRepository.instance.booksBySubject(widget.subject.id);
    setState(() => _future = f);
    await f.then<void>((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: qAppBar(widget.subject.title),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              '${widget.stage.title}  ›  ${widget.grade.title}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Book>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingState();
                }
                if (snap.hasError) {
                  return ErrorState(
                    message: friendlyError(snap.error!),
                    onRetry: _reload,
                  );
                }
                final books = snap.data ?? const <Book>[];
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: books.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 60),
                            EmptyState(
                              icon: Icons.library_books_outlined,
                              title: 'لا توجد كتب لهذه المادة بعد',
                              message: 'ستظهر الكتب هنا فور إضافتها إلى المكتبة.',
                              boxed: false,
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: books.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => BookTile(
                            book: books[i],
                            onTap: () => openBook(context, books[i]),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
