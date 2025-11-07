import 'package:flutter/material.dart';

import '../loadingFile/loading_alert/run_with_loading.dart';

class PaidDialog extends StatefulWidget {
  final double paidAmount;
  final double fullPrice;
  final Function(double, String) onSave;

  const PaidDialog({
    Key? key,
    required this.paidAmount,
    required this.fullPrice,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PaidDialog> createState() => _PaidDialogState();
}

class _PaidDialogState extends State<PaidDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController amountController;
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    amountController =
        TextEditingController(text: widget.paidAmount.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.green[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        'تحديث المبلغ المدفوع',
        style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🟢 Paid amount field
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  errorMaxLines: 3,
                  labelText: 'المبلغ المدفوع',
                  labelStyle: TextStyle(color: Colors.green[800]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade700),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.green.shade900, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  final enteredAmount = double.tryParse(value ?? '') ?? -1;

                  if (value == null || value.isEmpty) {
                    return 'من فضلك أدخل المبلغ المدفوع';
                  } else if (enteredAmount < 0) {
                    return 'من فضلك أدخل مبلغاً صالحاً';
                  } else if (enteredAmount > widget.fullPrice) {
                    return 'المبلغ المدفوع لا يمكن أن يتجاوز السعر الكامل للاشتراك';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // 🟢 Description field
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'الوصف أو الملاحظة',
                  labelStyle: TextStyle(color: Colors.green[800]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade700),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.green.shade900, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 10),

              // 🟢 Full price info
              Text(
                'السعر الكامل للاشتراك: \$${widget.fullPrice.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.green[900]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: TextStyle(color: Colors.green[900])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final enteredAmount =
                  double.tryParse(amountController.text) ?? 0.0;
              final description = descriptionController.text.trim();
              await runWithLoading(context, () async {
                await widget.onSave(enteredAmount, description);
              });
              Navigator.pop(context);
            }
          },
          child: Text('حفظ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
