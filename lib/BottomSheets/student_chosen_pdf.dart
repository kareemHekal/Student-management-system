import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/pages/pdf_genrators/detaild_students_pdf.dart';
import 'package:student_management_system/provider.dart';

import '../models/Student_model.dart';
import '../theme/colors_app.dart';

class StudentChosenPdf {
  static void show({
    required BuildContext context,
    required List<Studentmodel> students,
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
                label: 'بيانات الطلاب ',
                onPressed: () async {
                  await runWithLoading(context, () async {
                    await StudentsPdfGenerator.generateStudentsDetailsPdf(
                        students);
                  });
                },
              ),
              _ActionItem(
                icon: Icons.qr_code_rounded,
                label: 'qr codes',
                onPressed: () async {
                  final teacher =
                      Provider.of<TeacherProvider>(context, listen: false)
                          .teacher;

                  await runWithLoading(context, () async {
                    await StudentsPdfGenerator.generateQrCodesPdf(
                        students, teacher?.name ?? "");
                  });
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
              color: AppColors.secondaryMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondaryMain, size: 32),
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
