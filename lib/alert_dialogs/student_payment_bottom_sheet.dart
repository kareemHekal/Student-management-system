import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_management_system/cards/student/student_subscriptions_card.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/models/grade_subscriptions_model.dart'; // Adjust path
import 'package:student_management_system/models/student_paid_subscription.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'edit_on_payment.dart';

class StudentPaymentBottomSheet extends StatefulWidget {
  final Studentmodel student;

  const StudentPaymentBottomSheet({super.key, required this.student});

  @override
  State<StudentPaymentBottomSheet> createState() =>
      _StudentPaymentBottomSheetState();
}

class _StudentPaymentBottomSheetState extends State<StudentPaymentBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Height can be adjusted or set to dynamic
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle & Header Section
          _buildHeader(context),

          const Divider(height: 1),

          // 2. Content Section
          Expanded(
            child: StreamBuilder<GradeSubscriptionsModel?>(
              stream: FirebaseFunctions.getGradeSubscriptionsStream(
                  widget.student.grade ?? ""),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final gradeSubs = snapshot.data;
                final subscriptions = gradeSubs?.subscriptions ?? [];

                if (subscriptions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final sub = subscriptions[index];
                    final paidSub =
                        widget.student.studentPaidSubscriptions?.firstWhere(
                      (s) => s.subscriptionId == sub.id,
                      orElse: () => StudentPaidSubscriptions(
                        subscriptionId: sub.id,
                        paidAmount: 0,
                        description: "",
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => changePayment(
                            paidSub, sub.subscriptionAmount, context),
                        child: StudentSubscriptionsCard(
                          studentPaidSubscription: paidSub!,
                          subscriptionFee: sub,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Grey Drag Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close Button (Or an "Add" button if needed)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.student.name ?? "طالب غير معروف",
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.clip,
                      style: AppTextStyles.customText(
                        color: AppColors.primaryMain,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'إدارة اشتراكات الصف',
                      style: AppTextStyles.customText(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Empty space to balance the Row or place an q Elevated Button here
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'لا توجد اشتراكات لهذا الصف',
        style: AppTextStyles.customText(color: AppColors.textSecondary),
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
            // 1. Update list locally
            widget.student.studentPaidSubscriptions ??= [];
            int index = widget.student.studentPaidSubscriptions!.indexWhere(
                (sub) =>
                    sub.subscriptionId ==
                    studentPaidSubscription.subscriptionId);

            if (index != -1) {
              widget.student.studentPaidSubscriptions![index] =
                  StudentPaidSubscriptions(
                      description: comingDescription,
                      paidAmount: allAmount,
                      subscriptionId: studentPaidSubscription.subscriptionId);
            } else {
              widget.student.studentPaidSubscriptions!.add(
                  StudentPaidSubscriptions(
                      description: comingDescription,
                      paidAmount: allAmount,
                      subscriptionId: studentPaidSubscription.subscriptionId));
            }

          try {
            await FirebaseFunctions.updateStudentInCollection(
                  widget.student.grade ?? "",
                  widget.student.id,
                  widget.student);

              await FirebaseFunctions.addInvoiceToBigInvoices(
                subscriptionFeeID: studentPaidSubscription.subscriptionId,
                date: DateTime.now().toIso8601String().substring(0, 10),
                day: DateFormat('EEEE').format(DateTime.now()),
                amount: newAmount,
              description: comingDescription,
                grade: widget.student.grade ?? "",
                phoneNumber: widget.student.phoneNumber ?? "",
                motherPhone: widget.student.motherPhone ?? "",
                fatherPhone: widget.student.fatherPhone ?? "",
                studentId: widget.student.id,
                studentName: widget.student.name ?? "",
              );

              // --- THE IMPORTANT PART ---
              // Trigger setState to refresh the UI inside the bottom sheet
              if (mounted) {
                setState(() {});
              }
          } catch (e) {
              // Important: Rethrow the error so the Dialog can catch it and show the error SnackBar
              throw e;
            }
          }),
    );
  }
}
