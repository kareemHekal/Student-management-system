import 'package:flutter/material.dart';

import '../colors_app.dart';
import '../models/Studentmodel.dart';
import '../pages/all_bills_for_student.dart';
import '../pages/all_student_exam_grades.dart';

class StudentActionsBottomSheet {
  static void show({
    required BuildContext context,
    required Studentmodel student,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionItem(
                icon: Icons.list_alt,
                label: 'الفواتير',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllBillsForStudent(studentId: student.id),
                    ),
                  );
                },
              ),
              _ActionItem(
                icon: Icons.assessment,
                label: 'الدرجات',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllStudentExamGrades(student: student),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Reusable widget for action icon + label
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: app_colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: app_colors.green, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
