import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../data/library_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import '../book/open_book.dart';
import '../stages/stage_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSearchTap;
  const HomeScreen({super.key, required this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Stage>> _stages;
  late Future<List<Book>> _recent;
  late Future<List<Book>> _popular;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load({bool force = false}) {
    final repo = LibraryRepository.instance;
    _stages = repo.catalog(forceRefresh: force);
    _recent = repo.recentBooks();
    _popular = repo.popularBooks();
  }

  Future<void> _refresh() async {
    setState(() => _load(force: true));
    await Future.wait([
      _stages.then<void>((_) {}, onError: (_) {}),
      _recent.then<void>((_) {}, onError: (_) {}),
      _popular.then<void>((_) {}, onError: (_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      edgeOffset: MediaQuery.of(context).padding.top + 60,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header(onSearchTap: widget.onSearchTap)),
          SliverToBoxAdapter(
            child: _StagesSection(
              future: _stages,
              onRetry: () => setState(() => _load(force: true)),
            ),
          ),
          SliverToBoxAdapter(
            child: _BooksSection(
              title: 'المضافة حديثاً',
              emptyText: 'ستظهر الكتب الجديدة هنا فور إضافتها.',
              future: _recent,
              onRetry: () => setState(() => _load(force: true)),
            ),
          ),
          SliverToBoxAdapter(
            child: _BooksSection(
              title: 'الأكثر تحميلاً',
              emptyText: 'ستظهر الكتب الأكثر تحميلاً هنا.',
              future: _popular,
              onRetry: () => setState(() => _load(force: true)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSearchTap;
  const _Header({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'قرطاسك',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Qirtasak',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'كل كتبك... في مكان واحد.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ابحث عن كتاب أو مادة...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
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

class _StagesSection extends StatelessWidget {
  final Future<List<Stage>> future;
  final VoidCallback onRetry;
  const _StagesSection({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('المراحل التعليمية'),
          const SizedBox(height: 12),
          FutureBuilder<List<Stage>>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(height: 120, child: LoadingState());
              }
              if (snap.hasError) {
                return ErrorState(
                  message: friendlyError(snap.error!),
                  onRetry: onRetry,
                  boxed: true,
                );
              }
              final stages = snap.data ?? const <Stage>[];
              if (stages.isEmpty) {
                return const EmptyState(
                  icon: Icons.layers_clear_rounded,
                  title: 'لم تتم إضافة مراحل بعد',
                );
              }
              return Column(
                children: [
                  for (final stage in stages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StageCard(stage: stage),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Stage stage;
  const _StageCard({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StageScreen(stage: stage)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: stage.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(stage.icon, color: stage.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${stage.grades.length} صفوف',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BooksSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final Future<List<Book>> future;
  final VoidCallback onRetry;

  const _BooksSection({
    required this.title,
    required this.emptyText,
    required this.future,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionTitle(title),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Book>>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(height: 120, child: LoadingState());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ErrorState(
                    message: friendlyError(snap.error!),
                    onRetry: onRetry,
                    boxed: true,
                  ),
                );
              }
              final books = snap.data ?? const <Book>[];
              if (books.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: EmptyState(
                    icon: Icons.library_books_outlined,
                    title: emptyText,
                  ),
                );
              }
              return SizedBox(
                height: 268,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => BookCardH(
                    book: books[i],
                    onTap: () => openBook(context, books[i]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
