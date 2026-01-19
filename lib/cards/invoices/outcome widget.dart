import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_management_system/alert_dialogs/verifiy_password.dart';
import 'package:student_management_system/theme/text_style.dart'; // تأكد من صحة المسار

import '../../firebase/firebase_functions.dart';
import '../../models/payment.dart';
import '../../theme/colors_app.dart';

class PaymentWidget extends StatefulWidget {
  final Payment payment;
  final int paymentIndex;
  final VoidCallback onDeletePressed;

  PaymentWidget(
      {required this.payment,
      required this.onDeletePressed,
      required this.paymentIndex,
      super.key});

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
            colors: [
              AppColors.primaryMain,
              AppColors.secondaryMain,
            ],
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
              child: Center(
                child: _CardHelpers.buildCircle(120, 0.1),
              ),
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
                children: [
                  _buildHeader(context),
                  const Divider(color: AppColors.white, thickness: 0.5),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      context,
                      "المبلغ:",
                      "${widget.payment.amount.toStringAsFixed(2)} ج.م",
                      AppColors.secondaryMain),
                  _buildInfoRow(context, "الوصف:", widget.payment.description,
                      AppColors.white),
                  _buildInfoRow(
                    context,
                    "التاريخ:",
                    DateFormat('yyyy-MM-dd').format(widget.payment.dateTime),
                    AppColors.white,
                  ),
                  _buildInfoRow(
                    context,
                    "الوقت:",
                    DateFormat('hh:mm a').format(widget.payment.dateTime),
                    AppColors.white,
                  ),
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
        Text(
          "تفاصيل المصروف",
          style: AppTextStyles.customText(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHelpers.buildActionCircle(
              icon: Icons.edit,
              tooltip: 'تعديل المصروف',
              circleColor: AppColors.white.withOpacity(0.15),
              iconColor: AppColors.white,
              onPressed: () {
                _showEditDialog(context);
              },
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

  Widget _buildInfoRow(
      BuildContext context, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.customText(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.customText(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final amountController =
        TextEditingController(text: widget.payment.amount.toStringAsFixed(2));
    final descriptionController =
        TextEditingController(text: widget.payment.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "تعديل الفاتورة",
            style: AppTextStyles.customText(
                fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.customText(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "المبلغ",
                  labelStyle: AppTextStyles.customText(fontSize: 14),
                ),
              ),
              TextFormField(
                controller: descriptionController,
                style: AppTextStyles.customText(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "الوصف",
                  labelStyle: AppTextStyles.customText(fontSize: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "إلغاء",
                style: AppTextStyles.customText(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                showVerifyPasswordDialog(
                  context: context,
                  onVerified: () async {
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

                    Navigator.pushNamedAndRemoveUntil(
                        context, "/HomeScreen", (route) => false);

                    setState(() {
                      widget.payment.amount = updatedPayment.amount;
                      widget.payment.description = updatedPayment.description;
                    });
                  },
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: Text(
                "تأكيد",
                style: AppTextStyles.customText(color: AppColors.white),
              ),
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
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}