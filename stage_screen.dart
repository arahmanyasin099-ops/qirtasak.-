import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import 'grade_screen.dart';

/// صفحة صفوف المرحلة.
class StageScreen extends StatelessWidget {
  final Stage stage;
  const StageScreen({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: qAppBar(stage.title),
      body: stage.grades.isEmpty
          ? const EmptyState(
              icon: Icons.layers_clear_rounded,
              title: 'لا توجد صفوف في هذه المرحلة بعد',
              boxed: false,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: stage.grades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final grade = stage.grades[i];
                return Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 1,
                  shadowColor: Colors.black12,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              GradeScreen(stage: stage, grade: grade),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: stage.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: stage.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              grade.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
