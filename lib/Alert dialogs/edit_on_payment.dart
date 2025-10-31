import 'package:flutter/material.dart';

class EditPaidDialog extends StatefulWidget {
  final double paidAmount;
  final double fullPrice;
  final Function(double newAmount, double allAmount, String description) onSave;

  const EditPaidDialog({
    Key? key,
    required this.paidAmount,
    required this.fullPrice,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditPaidDialog> createState() => _EditPaidDialogState();
}

class _EditPaidDialogState extends State<EditPaidDialog> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.green[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        'اضافة المبلغ الزائد',
        style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ الجديد',
                  labelStyle: TextStyle(color: Colors.green[800]),
                  errorText: _errorText,
                  errorMaxLines: 3,
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
              ),
              const SizedBox(height: 10),
              TextField(
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
              Text(
                'السعر الكامل للاشتراك: \$ ${widget.fullPrice.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.green[900]),
              ),
              Text(
                'المبلغ المدفوع الحالي: \$ ${widget.paidAmount.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.green[900]),
              ),
              Text(
                'المبلغ المتبقي للدفع: \$ ${(widget.fullPrice - widget.paidAmount).toStringAsFixed(0)}',
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
          onPressed: () {
            final newAmount = double.tryParse(amountController.text) ?? 0;
            final allPaid = widget.paidAmount + newAmount;
            final description = descriptionController.text.trim();

            setState(() {
              if (newAmount <= 0) {
                _errorText = 'من فضلك أدخل مبلغاً صالحاً';
              } else if (allPaid > widget.fullPrice) {
                _errorText =
                    'المبلغ الجديد لا يمكن أن يتجاوز القبمه المتبقه من الاشتراك';
              } else {
                _errorText = null;
              }
            });

            if (_errorText == null) {
              widget.onSave(newAmount, allPaid, description);
              Navigator.pop(context);
            }
          },
          child: const Text(
            'تعديل',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
