import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_management_system/alert_dialogs/DeleteIncomeBillDialog.dart';
import 'package:student_management_system/alert_dialogs/verifiy_password.dart';
import 'package:student_management_system/theme/text_style.dart'; // تأكد من المسار الصحيح
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/firebase_functions.dart';
import '../../models/Invoice.dart';
import '../../models/subscription_fee.dart';
import '../../theme/colors_app.dart';

class InComeWidget extends StatefulWidget {
  final Invoice invoice;

  const InComeWidget({required this.invoice, super.key});

  @override
  State<InComeWidget> createState() => _InComeWidgetState();
}

class _InComeWidgetState extends State<InComeWidget> {
  SubscriptionFee? subscriptionFee;

  @override
  void initState() {
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DeleteIncomeBillDialog(
          onConfirm: () async {
            Navigator.of(dialogContext).pop();
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
                    SnackBar(
                      content: Text(
                        'تم حذف الفاتورة بنجاح',
                        style: AppTextStyles.customText(color: AppColors.white),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  if (parentContext.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        parentContext, '/HomeScreen', (_) => false);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'حدث خطأ أثناء حذف الفاتورة: $e',
                        style: AppTextStyles.customText(color: AppColors.white),
                      ),
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
  }

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
              left: -20,
              child: _CardHelpers.buildCircle(90, 0.15),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const Divider(color: AppColors.white, thickness: 0.5),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, false, "اسم الطالب:",
                      widget.invoice.studentName),
                  _buildInfoRow(context, true, "رقم الطالب:",
                      widget.invoice.studentPhoneNumber),
                  _buildInfoRow(context, true, "رقم الأم:",
                      widget.invoice.momPhoneNumber),
                  _buildInfoRow(context, true, "رقم الأب:",
                      widget.invoice.dadPhoneNumber),
                  _buildInfoRow(context, false, "الصف:", widget.invoice.grade),
                  _buildInfoRow(context, false, "المبلغ:",
                      "${widget.invoice.amount.toStringAsFixed(2)} ج.م"),
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
          "تفاصيل الإيراد",
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
              tooltip: 'تعديل الفاتورة',
              circleColor: AppColors.white.withOpacity(0.15),
              iconColor: AppColors.white,
              onPressed: () {
                showVerifyPasswordDialog(
                  context: context,
                  onVerified: () {
                    _showEditDialog(context);
                  },
                );
              },
            ),
            const SizedBox(width: 8),
            _CardHelpers.buildActionCircle(
              icon: Icons.delete_forever,
              tooltip: 'حذف الفاتورة',
              circleColor: AppColors.statusAbsent,
              iconColor: AppColors.white,
              onPressed: () {
                _showDeleteConfirmationDialog(context);
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
            child: GestureDetector(
              onTap: isPhoneNumber ? () => _launchPhoneNumber(value) : null,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.customText(
                    color: isPhoneNumber
                        ? AppColors.secondaryMain
                        : AppColors.white,
                    fontSize: 16,
                    fontWeight:
                        isPhoneNumber ? FontWeight.bold : FontWeight.normal,
                  ).copyWith(
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
          title: Text("تعديل فاتورة الإيراد",
              style: AppTextStyles.customText(
                  fontWeight: FontWeight.bold, fontSize: 18)),
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
              child: Text("إلغاء",
                  style: AppTextStyles.customText(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(widget.invoice.dateTime);
                double parsedAmount = double.tryParse(amountController.text) ??
                    widget.invoice.amount;
                double differenceAmount =
                    (widget.invoice.amount - parsedAmount) * -1;

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
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: Text("تأكيد",
                  style: AppTextStyles.customText(color: AppColors.white)),
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
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}