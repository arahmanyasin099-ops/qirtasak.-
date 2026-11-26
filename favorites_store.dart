import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class FavoritesStore {
  FavoritesStore._();
  static final FavoritesStore instance = FavoritesStore._();

  static const _prefsKey = 'favorite_books_v1';

  final ValueNotifier<int> changes = ValueNotifier<int>(0);
  List<Book> _books = [];

  List<Book> get books => List.unmodifiable(_books);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    final loaded = <Book>[];
    for (final item in raw) {
      try {
        loaded.add(Book.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }
    _books = loaded;
  }

  bool isFavorite(String id) => _books.any((b) => b.id == id);

  Future<void> toggle(Book book) async {
    if (isFavorite(book.id)) {
      _books.removeWhere((b) => b.id == book.id);
    } else {
      _books.insert(0, book);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _books.map((b) => jsonEncode(b.toJson())).toList(),
    );
    changes.value++;
  }
}
