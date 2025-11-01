import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Alert dialogs/DeleteIncomeBillDialog.dart';
import '../Alert dialogs/verifiy_password.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Invoice.dart';
import '../models/subscription_fee.dart';

class InvoiceWidget extends StatefulWidget {
  final Invoice invoice;

  const InvoiceWidget({required this.invoice, super.key});

  @override
  State<InvoiceWidget> createState() => _InvoiceWidgetState();
}

class _InvoiceWidgetState extends State<InvoiceWidget> {
  SubscriptionFee? subscriptionFee;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final sub = await FirebaseFunctions.getSubscriptionById(
      widget.invoice.grade,
      widget.invoice.subscriptionFeeID,
    );

    if (mounted) {
      setState(() {
        subscriptionFee = sub;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return DeleteIncomeBillDialog(
                onConfirm: () async {
                  // Close the confirmation dialog first
                  Navigator.of(dialogContext).pop();

                  // Use the parent context for dialogs and ScaffoldMessenger
                  final parentContext = context;

                  await showVerifyPasswordDialog(
                    context: parentContext,
                    onVerified: () async {
                      try {
                        await FirebaseFunctions.deleteInvoiceFromBigInvoices(
                          date: DateFormat('yyyy-MM-dd')
                              .format(widget.invoice.dateTime),
                          invoice: widget.invoice,
                        );

                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('تم حذف الفاتورة بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Navigate safely
                        if (parentContext.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              parentContext, '/HomeScreen', (_) => false);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text('حدث خطأ أثناء حذف الفاتورة: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
                title: 'حذف فاتورة الإيراد',
                content: 'هل أنت متأكد أنك تريد حذف هذه الفاتورة؟',
              );
            },
          );
        },
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
                _buildInfoRow(
                    context, false, "اسم الطالب:", widget.invoice.studentName),
                _buildInfoRow(context, true, "رقم الطالب:",
                    widget.invoice.studentPhoneNumber),
                _buildInfoRow(
                    context, true, "رقم الأم:", widget.invoice.momPhoneNumber),
                _buildInfoRow(
                    context, true, "رقم الأب:", widget.invoice.dadPhoneNumber),
                _buildInfoRow(context, false, "الصف:", widget.invoice.grade),
                _buildInfoRow(context, false, "المبلغ:",
                    "${widget.invoice.amount.toStringAsFixed(2)} جنيه"),
                _buildInfoRow(
                    context,
                    false,
                    "اسم الأشتراك:",
                    subscriptionFee?.subscriptionName ??
                        " الاشتراك لم يعد موجود "),
                _buildInfoRow(
                  context,
                  false,
                  "الوصف:",
                  widget.invoice.description.isEmpty
                      ? "لا يوجد وصف"
                      : widget.invoice.description,
                ),
                _buildInfoRow(context, false, "التاريخ:",
                    DateFormat('yyyy-MM-dd').format(widget.invoice.dateTime)),
                _buildInfoRow(context, false, "الوقت:",
                    DateFormat('hh:mm a').format(widget.invoice.dateTime)),
              ],
            ),
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
          "تفاصيل الإيراد",
          style: TextStyle(
            color: app_colors.darkGrey,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: app_colors.green,
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
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, bool isPhoneNumber, String label, String value) {
    void _launchPhoneNumber(String phoneNumber) async {
      final String phoneUrl = 'tel:$phoneNumber';
      if (await canLaunchUrlString(phoneUrl)) {
        await launchUrlString(phoneUrl);
      }
    }

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
            child: GestureDetector(
              onTap: isPhoneNumber ? () => _launchPhoneNumber(value) : null,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  value,
                  style: TextStyle(
                    color:
                        isPhoneNumber ? app_colors.green : app_colors.darkGrey,
                    fontSize: 16,
                    fontWeight:
                        isPhoneNumber ? FontWeight.bold : FontWeight.normal,
                    decoration: isPhoneNumber
                        ? TextDecoration.underline
                        : TextDecoration.none,
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
        TextEditingController(text: widget.invoice.amount.toStringAsFixed(2));
    final descriptionController =
        TextEditingController(text: widget.invoice.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تعديل فاتورة الإيراد"),
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
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(widget.invoice.dateTime);

                double parsedAmount = double.tryParse(amountController.text) ??
                    widget.invoice.amount;

                double differenceAmount = (widget.invoice.amount -
                        (double.tryParse(amountController.text) ?? 0)) *
                    -1;
                ;

                Invoice updatedInvoice = Invoice(
                  studentId: widget.invoice.studentId,
                  id: widget.invoice.id,
                  amount: parsedAmount,
                  description: descriptionController.text,
                  dateTime: widget.invoice.dateTime,
                  studentName: widget.invoice.studentName,
                  studentPhoneNumber: widget.invoice.studentPhoneNumber,
                  momPhoneNumber: widget.invoice.momPhoneNumber,
                  subscriptionFeeID: widget.invoice.subscriptionFeeID,
                  dadPhoneNumber: widget.invoice.dadPhoneNumber,
                  grade: widget.invoice.grade,
                );

                FirebaseFunctions.updateInvoiceInBigInvoices(
                  differenceAmount: differenceAmount,
                  updatedInvoice: updatedInvoice,
                  date: formattedDate,
                );

                Navigator.pushNamedAndRemoveUntil(
                    context, "/HomeScreen", (route) => false);
                setState(() {});
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: const Text("تأكيد"),
            ),
          ],
        );
      },
    );
  }
}
