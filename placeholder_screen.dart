import 'package:flutter/material.dart';

import '../../shared/widgets.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: qAppBar(title),
      body: EmptyState(icon: icon, title: message, boxed: false),
    );
  }
}
