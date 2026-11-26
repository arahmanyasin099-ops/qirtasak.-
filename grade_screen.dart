import 'package:flutter/material.dart';

import '../../core/subject_icons.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import 'subject_screen.dart';

/// صفحة مواد الصف.
class GradeScreen extends StatelessWidget {
  final Stage stage;
  final Grade grade;
  const GradeScreen({super.key, required this.stage, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: qAppBar(grade.title),
      body: grade.subjects.isEmpty
          ? const EmptyState(
              icon: Icons.layers_clear_rounded,
              title: 'لا توجد مواد في هذا الصف بعد',
              boxed: false,
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: grade.subjects.length,
              itemBuilder: (context, i) {
                final subject = grade.subjects[i];
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
                          builder: (_) => SubjectScreen(
                            stage: stage,
                            grade: grade,
                            subject: subject,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: stage.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(subjectIcon(subject.title),
                                color: stage.color, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subject.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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
