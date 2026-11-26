import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors.dart';
import 'library_repository.dart';
import 'models.dart';

typedef ProgressCallback = void Function(int received, int total);

class CancelToken {
  bool isCancelled = false;
  void cancel() => isCancelled = true;
}

/// تحميل الكتب وإدارتها على الهاتف.
/// - الكتب المحملة (Documents/books) تبقى حتى يحذفها الطالب.
/// - كتب القراءة المباشرة تُحفظ في مجلد مؤقت قد يمسحه النظام.
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  static const _prefsKey = 'downloaded_books_v1';

  late final Directory _booksDir;
  late final Directory _cacheDir;
  final ValueNotifier<int> changes = ValueNotifier<int>(0);
  List<Book> _books = [];

  List<Book> get books => List.unmodifiable(_books);

  Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _booksDir = Directory('${docs.path}/books');
    await _booksDir.create(recursive: true);
    final tmp = await getTemporaryDirectory();
    _cacheDir = Directory('${tmp.path}/reading');
    await _cacheDir.create(recursive: true);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    final loaded = <Book>[];
    for (final item in raw) {
      try {
        final book = Book.fromJson(jsonDecode(item) as Map<String, dynamic>);
        if (File(pathFor(book.id)).existsSync()) loaded.add(book);
      } catch (_) {}
    }
    _books = loaded;
  }

  String pathFor(String bookId) => '${_booksDir.path}/$bookId.pdf';
  String _cachePathFor(String bookId) => '${_cacheDir.path}/$bookId.pdf';

  bool isDownloaded(String bookId) => File(pathFor(bookId)).existsSync();

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _books.map((b) => jsonEncode(b.toJson())).toList(),
    );
    changes.value++;
  }

  /// تحميل دائم للهاتف.
  Future<String> download(
    Book book, {
    ProgressCallback? onProgress,
    CancelToken? cancel,
  }) async {
    final path = pathFor(book.id);
    await _fetch(book, File(path), onProgress: onProgress, cancel: cancel);
    _books.removeWhere((b) => b.id == book.id);
    _books.insert(0, book);
    await _persist();
    LibraryRepository.instance.registerDownload(book.id);
    return path;
  }

  /// مسار ملف جاهز للقراءة: المحمّل إن وُجد، وإلا نسخة مؤقتة.
  Future<String> readablePath(
    Book book, {
    ProgressCallback? onProgress,
    CancelToken? cancel,
  }) async {
    if (isDownloaded(book.id)) return pathFor(book.id);
    final cached = File(_cachePathFor(book.id));
    if (await cached.exists() && await cached.length() > 0) return cached.path;
    await _fetch(book, cached, onProgress: onProgress, cancel: cancel);
    return cached.path;
  }

  Future<void> delete(String bookId) async {
    final f = File(pathFor(bookId));
    if (await f.exists()) await f.delete();
    _books.removeWhere((b) => b.id == bookId);
    await _persist();
  }

  Future<void> _fetch(
    Book book,
    File dest, {
    ProgressCallback? onProgress,
    CancelToken? cancel,
  }) async {
    final uri = Uri.parse(book.pdfUrl);
    if (uri.scheme != 'https') {
      throw const DownloadException('رابط الكتاب غير آمن.');
    }
    final part = File('${dest.path}.part');
    if (await part.exists()) await part.delete();

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    IOSink? sink;
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) {
        throw DownloadException('تعذر تحميل الكتاب (رمز ${res.statusCode}).');
      }
      final total =
          res.contentLength > 0 ? res.contentLength : (book.fileSizeBytes ?? -1);
      sink = part.openWrite();
      var received = 0;
      await for (final chunk in res.timeout(const Duration(seconds: 30))) {
        if (cancel?.isCancelled ?? false) throw const DownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      final raf = await part.open();
      final head = await raf.read(5);
      await raf.close();
      if (String.fromCharCodes(head) != '%PDF-') {
        throw const DownloadException('الملف الذي تم تحميله ليس PDF صالحاً.');
      }
      if (await dest.exists()) await dest.delete();
      await part.rename(dest.path);
    } catch (e) {
      try {
        await sink?.close();
      } catch (_) {}
      if (await part.exists()) await part.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }
}
