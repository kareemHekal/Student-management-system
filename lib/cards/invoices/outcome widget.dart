import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_management_system/alert_dialogs/verifiy_password.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../../firebase/firebase_functions.dart';
import '../../models/payment.dart';
import '../../theme/colors_app.dart';

class PaymentWidget extends StatefulWidget {
  final Payment payment;
  final int paymentIndex;
  final VoidCallback onDeletePressed;

  const PaymentWidget({
    required this.payment,
    required this.onDeletePressed,
    required this.paymentIndex,
    super.key,
  });

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [AppColors.primaryMain, AppColors.secondaryMain],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryMain.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: -50,
              child: Center(child: _CardHelpers.buildCircle(120, 0.1)),
            ),
            Positioned(
              top: -10,
              left: 50,
              child: _CardHelpers.buildCircle(80, 0.08),
            ),
            Positioned(
              bottom: -5,
              left: -5,
              child: _CardHelpers.buildCircle(80, 0.15),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // لجعل الكارت مرناً رأسياً
                children: [
                  _buildHeader(context),
                  const Divider(
                      color: AppColors.white, thickness: 0.5, height: 25),

                  // صفوف البيانات بمرونة كاملة
                  _buildResponsiveInfoRow(
                      "المبلغ:",
                      "${widget.payment.amount.toStringAsFixed(2)} ج.م",
                      AppColors.secondaryMain,
                      isAmount: true),
                  _buildResponsiveInfoRow(
                      "الوصف:", widget.payment.description, AppColors.white),
                  _buildResponsiveInfoRow(
                      "التاريخ:",
                      DateFormat('yyyy-MM-dd').format(widget.payment.dateTime),
                      AppColors.white),
                  _buildResponsiveInfoRow(
                      "الوقت:",
                      DateFormat('hh:mm a').format(widget.payment.dateTime),
                      AppColors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // حماية النص الثابت من التصادم مع الأزرار
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              "تفاصيل المصروف",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHelpers.buildActionCircle(
              icon: Icons.edit,
              tooltip: 'تعديل المصروف',
              circleColor: AppColors.white.withOpacity(0.15),
              iconColor: AppColors.white,
              onPressed: () => _showEditDialog(context),
            ),
            const SizedBox(width: 8),
            _CardHelpers.buildActionCircle(
              icon: Icons.delete_forever,
              tooltip: 'حذف المصروف',
              circleColor: AppColors.statusAbsent,
              iconColor: AppColors.white,
              onPressed: widget.onDeletePressed,
            ),
          ],
        ),
      ],
    );
  }

  // دالة مطورة للتعامل مع نصوص المصاريف الطويلة والخطوط الكبيرة
  Widget _buildResponsiveInfoRow(String label, String value, Color valueColor,
      {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حجز 30% من العرض للنص الثابت وحمايته بـ FittedBox
              SizedBox(
                width: constraints.maxWidth * 0.30,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    label,
                    style: AppTextStyles.customText(
                      color: AppColors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // القيمة تأخذ باقي المساحة وتنزل لسطر جديد لو الوصف طويل
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.left,
                  softWrap: true,
                  style: AppTextStyles.customText(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final amountController =
        TextEditingController(text: widget.payment.amount.toStringAsFixed(2));
    final descriptionController =
        TextEditingController(text: widget.payment.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryMain,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_document,
                    color: AppColors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'تعديل تفاصيل الفاتورة',
                  style: AppTextStyles.customText(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 15),
                  // حقل المبلغ
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.customText(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      prefixIcon: const Icon(Icons.payments_outlined,
                          color: AppColors.primaryMain),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: AppColors.primaryMain, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'يرجى إدخال المبلغ';
                      if (double.tryParse(value) == null)
                        return 'يرجى إدخال رقم صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // حقل الوصف
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    style: AppTextStyles.customText(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'وصف الفاتورة',
                      prefixIcon: const Icon(Icons.notes_rounded,
                          color: AppColors.primaryMain),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: AppColors.primaryMain, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "إلغاء",
                      style: AppTextStyles.customText(
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;

                      showVerifyPasswordDialog(
                        context: context,
                        onVerified: () async {
                          await runWithLoading(context, () async {
                            try {
                              String formattedDate = DateFormat('yyyy-MM-dd')
                                  .format(widget.payment.dateTime);
                              double parsedAmount =
                                  double.tryParse(amountController.text) ??
                                      widget.payment.amount;

                              Payment updatedPayment = Payment(
                                amount: parsedAmount,
                                description: descriptionController.text,
                                dateTime: widget.payment.dateTime,
                              );

                              await FirebaseFunctions.updatePaymentInBigInvoice(
                                date: formattedDate,
                                updatedPayment: updatedPayment,
                                paymentIndex: widget.paymentIndex,
                              );

                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                    context, "/HomeScreen", (route) => false);
                                AppSnackBars.showSuccess(
                                    context, "تم تحديث الفاتورة بنجاح");
                              }

                              setState(() {
                                widget.payment.amount = updatedPayment.amount;
                                widget.payment.description =
                                    updatedPayment.description;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBars.showError(
                                    context, "حدث خطأ أثناء التحديث");
                              }
                            }
                          });
                        },
                      );
                    },
                    child: Text(
                      "تأكيد التعديل",
                      style: AppTextStyles.customText(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CardHelpers {
  static Widget buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: AppColors.white.withOpacity(opacity), shape: BoxShape.circle),
    );
  }

  static Widget buildActionCircle({
    required IconData icon,
    required Color circleColor,
    required Color iconColor,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, color: iconColor, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}