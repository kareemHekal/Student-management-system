import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Alert dialogs/verifiy_password.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/payment.dart';

class PaymentWidget extends StatefulWidget {
  final Payment payment;
  int paymentIndex;

  PaymentWidget({required this.payment, required this.paymentIndex, super.key});

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: app_colors.ligthGreen,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(color: app_colors.darkGrey, thickness: 1),
              const SizedBox(height: 8),
              _buildInfoRow(context, "المبلغ:",
                  "\$${widget.payment.amount.toStringAsFixed(2)}"),
              _buildInfoRow(context, "الوصف:", widget.payment.description),
              _buildInfoRow(
                context,
                "التاريخ:",
                DateFormat('yyyy-MM-dd').format(widget.payment.dateTime),
              ),
              _buildInfoRow(
                context,
                "الوقت:",
                DateFormat('hh:mm a').format(widget.payment.dateTime),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "تفاصيل المصروف",
          style: TextStyle(
            color: app_colors.darkGrey,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.edit,
            color: app_colors.green,
            size: 30,
          ),
          onPressed: () {
            showVerifyPasswordDialog(
              context: context,
              onVerified: () {
                _showEditDialog(context);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: app_colors.darkGrey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                value,
                style: const TextStyle(
                  color: app_colors.darkGrey,
                  fontSize: 16,
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
              onPressed: () async {
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(widget.payment.dateTime);
                double parsedAmount = double.tryParse(amountController.text) ??
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
