import 'package:flutter/material.dart';

import '../../data/models.dart';
import 'book_details_screen.dart';

void openBook(BuildContext context, Book book) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
  );
}
