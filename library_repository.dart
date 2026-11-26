import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class ConnectionReport {
  final int stages;
  final int grades;
  final int subjects;
  final int books;
  const ConnectionReport({
    required this.stages,
    required this.grades,
    required this.subjects,
    required this.books,
  });
}

/// الطبقة الوحيدة التي تتحدث مع Supabase.
class LibraryRepository {
  LibraryRepository._();
  static final LibraryRepository instance = LibraryRepository._();

  static const _catalogCacheKey = 'catalog_cache_v1';

  SupabaseClient get _db => Supabase.instance.client;
  List<Stage>? _catalog;

  List<Stage> _parse(List<Map<String, dynamic>> rows) => [
        for (var i = 0; i < rows.length; i++) Stage.fromJson(rows[i], i),
      ];

  /// المراحل والصفوف والمواد. إن انقطع الإنترنت تُستخدم آخر نسخة محفوظة.
  Future<List<Stage>> catalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _catalog != null) return _catalog!;
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await _db.from('stages').select(
          'id, slug, title, sort_order, grades(id, title, sort_order, subjects(id, title, sort_order))');
      final rows = sortedRows(data);
      await prefs.setString(_catalogCacheKey, jsonEncode(rows));
      _catalog = _parse(rows);
      return _catalog!;
    } catch (e) {
      final cached = prefs.getString(_catalogCacheKey);
      if (cached != null) {
        return _parse(sortedRows(jsonDecode(cached)));
      }
      rethrow;
    }
  }

  List<Book> _books(dynamic data) => (data as List)
      .map((e) => Book.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  Future<List<Book>> booksBySubject(String subjectId) async {
    final data = await _db
        .from('book_details')
        .select()
        .eq('subject_id', subjectId)
        .order('title');
    return _books(data);
  }

  Future<List<Book>> recentBooks({int limit = 10}) async {
    final data = await _db
        .from('book_details')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return _books(data);
  }

  Future<List<Book>> popularBooks({int limit = 10}) async {
    final data = await _db
        .from('book_details')
        .select()
        .gt('downloads_count', 0)
        .order('downloads_count', ascending: false)
        .limit(limit);
    return _books(data);
  }

  Future<List<Book>> search(String query) async {
    final q = query.replaceAll(RegExp(r'[,()*%\\"]'), ' ').trim();
    if (q.isEmpty) return [];
    final data = await _db
        .from('book_details')
        .select()
        .or('title.ilike.*$q*,subject_title.ilike.*$q*,grade_title.ilike.*$q*,stage_title.ilike.*$q*')
        .order('title')
        .limit(50);
    return _books(data);
  }

  /// اختبار اتصال حيّ (لا يستخدم النسخة المحفوظة).
  Future<ConnectionReport> testConnection() async {
    final data = await _db
        .from('stages')
        .select('id, grades(id, subjects(id))')
        .timeout(const Duration(seconds: 15));
    var grades = 0;
    var subjects = 0;
    final stages = data as List;
    for (final st in stages) {
      final gs = ((st as Map)['grades'] as List?) ?? const [];
      grades += gs.length;
      for (final g in gs) {
        subjects += (((g as Map)['subjects'] as List?) ?? const []).length;
      }
    }
    final books = await _db
        .from('book_details')
        .select('id')
        .limit(1000)
        .timeout(const Duration(seconds: 15));
    return ConnectionReport(
      stages: stages.length,
      grades: grades,
      subjects: subjects,
      books: (books as List).length,
    );
  }

  /// يزيد عدّاد التحميل. أي فشل هنا لا يؤثر على الطالب.
  Future<void> registerDownload(String bookId) async {
    try {
      await _db.rpc('increment_downloads', params: {'p_book_id': bookId});
    } catch (_) {}
  }
}
