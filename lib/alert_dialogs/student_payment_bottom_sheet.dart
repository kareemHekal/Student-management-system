import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_management_system/cards/student/student_subscriptions_card.dart';
import 'package:student_management_system/firebase/firebase_functions.dart';
import 'package:student_management_system/models/Student_model.dart';
import 'package:student_management_system/models/grade_subscriptions_model.dart';
import 'package:student_management_system/models/invoice.dart';
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
        maxHeight: MediaQuery.of(context).size.height * 0.6,
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
            // Get invoice ID first (counter increment)
            int invoiceId = await FirebaseFunctions.getAndIncrementInvoiceId();
            final now = DateTime.now();
            final dateStr = now.toIso8601String().substring(0, 10);
            final dayStr = DateFormat('EEEE').format(now);

            final newInvoice = Invoice(
              id: invoiceId.toString(),
              studentId: widget.student.id,
              studentName: widget.student.name ?? "",
              subscriptionFeeID: studentPaidSubscription.subscriptionId,
              studentPhoneNumber: widget.student.phoneNumber ?? "",
              momPhoneNumber: widget.student.motherPhone ?? "",
              dadPhoneNumber: widget.student.fatherPhone ?? "",
              grade: widget.student.grade ?? "",
              amount: newAmount,
              description: comingDescription,
              dateTime: now,
            );

            // Atomic batch: student update + invoice in one commit
            final batch = FirebaseFirestore.instance.batch();

            final studentRef = FirebaseFirestore.instance
                .doc(FirebaseFunctions.teacherPath)
                .collection(widget.student.grade ?? "")
                .doc(widget.student.id);
            batch.update(studentRef, widget.student.toJson());

            final invoiceRef = FirebaseFirestore.instance
                .doc(FirebaseFunctions.teacherPath)
                .collection('big_invoices')
                .doc(dateStr);
            batch.set(invoiceRef, {
              'date': dateStr,
              'day': dayStr,
              'invoices': FieldValue.arrayUnion([newInvoice.toJson()]),
            }, SetOptions(merge: true));

            await batch.commit();

              if (mounted) {
                setState(() {});
              }
          } catch (e) {
              rethrow;
            }
          }),
    );
  }
}
