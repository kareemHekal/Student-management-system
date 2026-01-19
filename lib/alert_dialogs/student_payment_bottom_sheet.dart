import 'package:flutter/material.dart';
import 'package:student_management_system/cards/student/student_subscriptions_card.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/models/grade_subscriptions_model.dart'; // Adjust path
import 'package:student_management_system/models/student_paid_subscription.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import 'edit_on_payment.dart';

class StudentPaymentBottomSheet extends StatelessWidget {
  final Studentmodel student;

  const StudentPaymentBottomSheet({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: StreamBuilder<GradeSubscriptionsModel?>(
        stream:
            FirebaseFunctions.getGradeSubscriptionsStream(student.grade ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator()));
          }

          final gradeSubs = snapshot.data;
          final subscriptions = gradeSubs?.subscriptions ?? [];

          return Column(
            mainAxisSize: MainAxisSize.min, // Important for bottom sheets
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Student Name Header
              Text(
                student.name ?? "طالب غير معروف",
                textAlign: TextAlign.center,
                style: AppTextStyles.customText(
                  color: AppColors.primaryMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'إدارة اشتراكات الصف',
                textAlign: TextAlign.center,
                style: AppTextStyles.customText(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const Divider(height: 24),

              if (subscriptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'لا توجد اشتراكات لهذا الصف',
                      style: AppTextStyles.customText(
                          color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                Flexible(
                  // Use Flexible to allow scrolling if list is long
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];

                      // Find if student has record for this sub
                      final paidSub =
                          student.studentPaidSubscriptions?.firstWhere(
                        (s) => s.subscriptionId == sub.id,
                        orElse: () => StudentPaidSubscriptions(
                          subscriptionId: sub.id,
                          paidAmount: 0,
                          description: "",
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: InkWell(
                          onTap: () => changePayment(
                              paidSub, sub.subscriptionAmount, context),
                          child: StudentSubscriptionsCard(
                            // Use your existing card
                            studentPaidSubscription: paidSub!,
                            subscriptionFee: sub,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void changePayment(StudentPaidSubscriptions studentPaidSubscription,
      double fullPrice, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditPaidDialog(
        paidAmount: studentPaidSubscription.paidAmount,
        fullPrice: fullPrice,
        onSave: (newAmount, allAmount, comingDescription) async {
          // 1. Update list locally in the Student object
          student.studentPaidSubscriptions ??= [];

          int index = student.studentPaidSubscriptions!.indexWhere((sub) =>
              sub.subscriptionId == studentPaidSubscription.subscriptionId);

          if (index != -1) {
            student.studentPaidSubscriptions![index] = StudentPaidSubscriptions(
                description: comingDescription,
                paidAmount: allAmount,
                subscriptionId: studentPaidSubscription.subscriptionId);
          } else {
            student.studentPaidSubscriptions!.add(StudentPaidSubscriptions(
                description: comingDescription,
                paidAmount: allAmount,
                subscriptionId: studentPaidSubscription.subscriptionId));
          }

          try {
            // 2. Update Student Collection
            await FirebaseFunctions.updateStudentInCollection(
                student.grade ?? "", student.id, student);

            // 3. ADD INVOICE CALL (New step)
            // Note: Ensure 'date' and 'day' are accessible in this scope
            // (e.g., from the parent widget or a global helper)
            await FirebaseFunctions.addInvoiceToBigInvoices(
              subscriptionFeeID: studentPaidSubscription.subscriptionId ?? "",
              date: DateTime.now().toIso8601String().substring(0, 10),
              // Current Date
              day: DateTime.now().weekday.toString(),
              // Current Day name
              amount: newAmount,
              // The amount paid JUST NOW in the dialog
              description: comingDescription,
              grade: student.grade ?? "",
              phoneNumber: student.phoneNumber ?? "",
              motherPhone: student.motherPhone ?? "",
              fatherPhone: student.fatherPhone ?? "",
              studentId: student.id,
              studentName: student.name ?? "",
            );

            if (context.mounted) {
              AppSnackBars.showSuccess(
                  context, "تم تحديث الدفع وإضافة الفاتورة بنجاح");
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackBars.showError(context, "فشل التحديث: $e");
            }
          }
        },
      ),
    );
  }

// Helper for Arabic Day names if needed
  String _getArabicDayName(int day) {
    const days = [
      "الأثنين",
      "الثلاثاء",
      "الأربعاء",
      "الخميس",
      "الجمعة",
      "السبت",
      "الأحد"
    ];
    return days[day - 1];
  }
}
