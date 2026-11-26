import 'package:flutter/material.dart';

import '../../data/favorites_store.dart';
import '../../shared/widgets.dart';
import '../book/open_book.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: qAppBar('المفضلة'),
      body: ValueListenableBuilder<int>(
        valueListenable: FavoritesStore.instance.changes,
        builder: (context, _, __) {
          final books = FavoritesStore.instance.books;
          if (books.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'لم تضف أي كتاب إلى المفضلة بعد',
              message: 'اضغط على القلب في صفحة أي كتاب لإضافته هنا.',
              boxed: false,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => BookTile(
              book: books[i],
              onTap: () => openBook(context, books[i]),
            ),
          );
        },
      ),
    );
  }
}
