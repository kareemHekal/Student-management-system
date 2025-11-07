import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';
import '../models/Big invoice.dart';
import '../models/payment.dart';

class AddExpenseDialog extends StatefulWidget {
  final String date;
  final String day;

  const AddExpenseDialog({
    super.key,
    required this.date,
    required this.day,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        "إضافة مصروف جديد",
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: totalAmountController,
              decoration: const InputDecoration(
                labelText: "المبلغ الإجمالي",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال المبلغ';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "الوصف",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;

            await runWithLoading(context, () async {
              final firestore = FirebaseFirestore.instance;
              final docRef =
                  firestore.collection('big_invoices').doc(widget.date);
              final docSnapshot = await docRef.get();

              final newPayment = Payment(
                amount: double.tryParse(totalAmountController.text) ?? 0.0,
                description: descriptionController.text.trim(),
                dateTime: DateTime.now(),
              );

              if (docSnapshot.exists) {
                final data = docSnapshot.data() as Map<String, dynamic>;
                final bigInvoice = BigInvoice.fromJson(data);
                bigInvoice.payments.add(newPayment);
                await docRef.update(bigInvoice.toJson());
              } else {
                final bigInvoice = BigInvoice(
                  date: widget.date,
                  day: widget.day,
                  invoices: [],
                  payments: [newPayment],
                );
                await docRef.set(bigInvoice.toJson());
              }

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/HomeScreen', (route) => false);
              }
            });
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
