import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Alert dialogs/verifiy_password.dart';
import '../firebase/firebase_functions.dart';
import '../models/payment.dart';
import '../theme/colors_app.dart';

class PaymentWidget extends StatefulWidget {
  final Payment payment;
  int paymentIndex;
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
  // *** Note: The _showDeleteConfirmationDialog is removed as requested ***

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Container(
        // Replace Card properties with Container styling
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
            // ===== Decorative Circles (New Placement) =====

            // 1. Large Circle on the Right Edge
            Positioned(
              top: 0,
              bottom: 0,
              right: -50,
              child: Center(
                child: _CardHelpers.buildCircle(120, 0.1),
              ),
            ),

            // 2. Medium Circle near Top Left Corner
            Positioned(
              top: -10,
              left: 50,
              child: _CardHelpers.buildCircle(80, 0.08),
            ),

            // 3. Small Circle in the Bottom Right Corner
            Positioned(
              bottom: -5,
              left: -5,
              child: _CardHelpers.buildCircle(80, 0.15),
            ),

            // ===== Card Content (Inner Padding) =====
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  // Divider color changed to white
                  const Divider(color: AppColors.white, thickness: 0.5),
                  const SizedBox(height: 8),

                  // Info Rows - Colors updated to contrast dark background
                  _buildInfoRow(
                      context,
                      "المبلغ:",
                      "${widget.payment.amount.toStringAsFixed(2)} ج.م",
                      AppColors.secondaryMain), // Highlight expense amount
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

// ... inside _PaymentWidgetState

// --- Header now includes Edit and Delete icons ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "تفاصيل المصروف",
          style: TextStyle(
            color: AppColors.white, // White text
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Edit Button
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

            // 2. Delete Button (Now calls the passed callback)
            _CardHelpers.buildActionCircle(
              icon: Icons.delete_forever,
              tooltip: 'حذف المصروف',
              circleColor: AppColors.statusAbsent,
              // Red background for delete
              iconColor: AppColors.white,
              onPressed: widget.onDeletePressed, // <-- USES THE CALLBACK
            ),
          ],
        ),
      ],
    );
  }

  // --- Info Row updated to accept amount color and use white labels ---
  Widget _buildInfoRow(
      BuildContext context, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white, // White label text
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
                  style: TextStyle(
                    color: valueColor, // Dynamic color (White or StatusLate)
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

  // --- _showEditDialog remains exactly the same as original ---
  void _showEditDialog(BuildContext context) {
    final amountController =
        TextEditingController(text: widget.payment.amount.toStringAsFixed(2));
    final descriptionController =
        TextEditingController(text: widget.payment.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تعديل الفاتورة"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "المبلغ"),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "الوصف"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("إلغاء"),
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
              child: const Text("تأكيد"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Assuming these helpers are accessible for consistency
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
