import 'package:shared_preferences/shared_preferences.dart';

/// يحفظ آخر صفحة وصل إليها الطالب في كل كتاب.
class ReadingStore {
  ReadingStore._();
  static final ReadingStore instance = ReadingStore._();

  String _key(String bookId) => 'last_page_$bookId';

  Future<int> lastPage(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getInt(_key(bookId)) ?? 1;
    return p < 1 ? 1 : p;
  }

  Future<void> saveLastPage(String bookId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(bookId), page);
  }
}
