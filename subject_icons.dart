import 'package:flutter/material.dart';

IconData subjectIcon(String title) {
  if (title.contains('العربية')) return Icons.translate_rounded;
  if (title.contains('الإنجليزية')) return Icons.language_rounded;
  if (title.contains('الرياضيات')) return Icons.calculate_rounded;
  if (title.contains('الإسلامية')) return Icons.mosque_rounded;
  if (title.contains('الفيزياء')) return Icons.bolt_rounded;
  if (title.contains('الكيمياء')) return Icons.biotech_rounded;
  if (title.contains('الأحياء')) return Icons.eco_rounded;
  if (title.contains('العلوم')) return Icons.science_rounded;
  if (title.contains('التاريخ')) return Icons.history_edu_rounded;
  if (title.contains('الجغرافيا')) return Icons.public_rounded;
  if (title.contains('الاجتماعية')) return Icons.groups_rounded;
  return Icons.menu_book_rounded;
}
