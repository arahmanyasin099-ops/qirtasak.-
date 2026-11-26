import 'package:flutter/material.dart';

import '../core/theme.dart';

List<Map<String, dynamic>> sortedRows(dynamic raw) {
  final list = ((raw as List?) ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  list.sort((a, b) => ((a['sort_order'] ?? 0) as num)
      .compareTo((b['sort_order'] ?? 0) as num));
  return list;
}

String? _nullIfEmpty(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class Subject {
  final String id;
  final String title;
  const Subject({required this.id, required this.title});

  factory Subject.fromJson(Map<String, dynamic> j) =>
      Subject(id: j['id'].toString(), title: j['title'].toString());
}

class Grade {
  final String id;
  final String title;
  final List<Subject> subjects;
  const Grade({required this.id, required this.title, required this.subjects});

  factory Grade.fromJson(Map<String, dynamic> j) => Grade(
        id: j['id'].toString(),
        title: j['title'].toString(),
        subjects: sortedRows(j['subjects']).map(Subject.fromJson).toList(),
      );
}

class Stage {
  final String id;
  final String slug;
  final String title;
  final int position;
  final List<Grade> grades;
  const Stage({
    required this.id,
    required this.slug,
    required this.title,
    required this.position,
    required this.grades,
  });

  factory Stage.fromJson(Map<String, dynamic> j, int position) => Stage(
        id: j['id'].toString(),
        slug: j['slug'].toString(),
        title: j['title'].toString(),
        position: position,
        grades: sortedRows(j['grades']).map(Grade.fromJson).toList(),
      );

  IconData get icon {
    switch (slug) {
      case 'primary':
        return Icons.child_care_rounded;
      case 'middle':
        return Icons.auto_stories_rounded;
      case 'secondary':
        return Icons.school_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color get color {
    const palette = [AppColors.green, AppColors.blue, AppColors.navyLight];
    return palette[position % palette.length];
  }
}

class Book {
  final String id;
  final String title;
  final String? coverUrl;
  final String pdfUrl;
  final int? pages;
  final int? fileSizeBytes;
  final int downloadsCount;
  final DateTime? createdAt;
  final String subjectId;
  final String subjectTitle;
  final String gradeId;
  final String gradeTitle;
  final String stageId;
  final String stageTitle;

  const Book({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.pdfUrl,
    required this.pages,
    required this.fileSizeBytes,
    required this.downloadsCount,
    required this.createdAt,
    required this.subjectId,
    required this.subjectTitle,
    required this.gradeId,
    required this.gradeTitle,
    required this.stageId,
    required this.stageTitle,
  });

  /// المفاتيح مطابقة لأعمدة view اسمه book_details في Supabase.
  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'].toString(),
        title: j['title'].toString(),
        coverUrl: _nullIfEmpty(j['cover_url']),
        pdfUrl: j['pdf_url'].toString(),
        pages: (j['pages'] as num?)?.toInt(),
        fileSizeBytes: (j['file_size_bytes'] as num?)?.toInt(),
        downloadsCount: (j['downloads_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        subjectId: j['subject_id'].toString(),
        subjectTitle: j['subject_title'].toString(),
        gradeId: j['grade_id'].toString(),
        gradeTitle: j['grade_title'].toString(),
        stageId: j['stage_id'].toString(),
        stageTitle: j['stage_title'].toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cover_url': coverUrl,
        'pdf_url': pdfUrl,
        'pages': pages,
        'file_size_bytes': fileSizeBytes,
        'downloads_count': downloadsCount,
        'created_at': createdAt?.toIso8601String(),
        'subject_id': subjectId,
        'subject_title': subjectTitle,
        'grade_id': gradeId,
        'grade_title': gradeTitle,
        'stage_id': stageId,
        'stage_title': stageTitle,
      };
}
