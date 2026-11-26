import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../data/download_service.dart';
import '../../data/library_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import '../book/open_book.dart';

/// البحث باسم الكتاب أو المادة أو الصف أو المرحلة.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<Book> _results = const [];
  bool _loading = false;
  bool _offline = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(value));
    setState(() {});
  }

  Future<void> _run(String value) async {
    final q = value.trim();
    _query = q;
    if (q.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
        _offline = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await LibraryRepository.instance.search(q);
      if (!mounted || q != _query) return;
      setState(() {
        _results = r;
        _loading = false;
        _offline = false;
      });
    } catch (e) {
      if (!mounted || q != _query) return;
      final local = DownloadService.instance.books.where((b) {
        final hay =
            '${b.title} ${b.subjectTitle} ${b.gradeTitle} ${b.stageTitle}';
        return hay.contains(q);
      }).toList();
      setState(() {
        _results = local;
        _loading = false;
        _offline = true;
        _error = local.isEmpty ? friendlyError(e) : null;
      });
    }
  }

  Widget _body() {
    if (_query.length < 2) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'ابحث في مكتبة قرطاسك',
        message: 'اكتب اسم الكتاب أو المادة أو الصف أو المرحلة.',
        boxed: false,
      );
    }
    if (_loading) return const LoadingState();
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: () => _run(_query));
    }
    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج مطابقة',
        message: 'جرّب كلمات أخرى أو اكتب جزءاً من الاسم.',
        boxed: false,
      );
    }
    return Column(
      children: [
        if (_offline)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF4D6),
            padding: const EdgeInsets.all(10),
            child: const Text(
              'أنت غير متصل بالإنترنت. النتائج من الكتب المحملة على هاتفك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => BookTile(
              book: _results[i],
              onTap: () => openBook(context, _results[i]),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: qAppBar('البحث'),
      body: Column(
        children: [
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              decoration: InputDecoration(
                hintText: 'ابحث عن كتاب أو مادة...',
                filled: true,
                fillColor: AppColors.white,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _run('');
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}
