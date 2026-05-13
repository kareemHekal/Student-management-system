import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_management_system/alert_dialogs/DeleteIncomeBillDialog.dart';
import 'package:student_management_system/alert_dialogs/verifiy_password.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/firebase_functions.dart';
import '../../models/invoice.dart';
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
        // إزالة الارتفاع الثابت لضمان تمدد الكارت مع النصوص الكبيرة
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
            // الدوائر الزخرفية
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  const Divider(
                      color: AppColors.white, thickness: 0.5, height: 25),

                  // صفوف البيانات المحدثة لتكون Responsive
                  _buildInfoRow("اسم الطالب:", widget.invoice.studentName),
                  _buildInfoRow(
                      "رقم الطالب:", widget.invoice.studentPhoneNumber,
                      isPhoneNumber: true),
                  _buildInfoRow("رقم الأم:", widget.invoice.momPhoneNumber,
                      isPhoneNumber: true),
                  _buildInfoRow("رقم الأب:", widget.invoice.dadPhoneNumber,
                      isPhoneNumber: true),
                  _buildInfoRow("الصف:", widget.invoice.grade),
                  _buildInfoRow("المبلغ:",
                      "${widget.invoice.amount.toStringAsFixed(2)} ج.م",
                      isAmount: true),
                  _buildInfoRow(
                      "اسم الأشتراك:",
                      subscriptionFee?.subscriptionName ??
                          " الاشتراك لم يعد موجود "),
                  _buildInfoRow(
                    "الوصف:",
                    widget.invoice.description.isEmpty
                        ? "لا يوجد وصف"
                        : widget.invoice.description,
                  ),
                  _buildInfoRow("التاريخ:",
                      DateFormat('yyyy-MM-dd').format(widget.invoice.dateTime)),
                  _buildInfoRow("الوقت:",
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
        // حماية عنوان "تفاصيل الإيراد" من التداخل مع الأزرار
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              "تفاصيل الإيراد",
              style: TextStyle(
                // استخدمنا ستايل مباشر لضمان التجاوب مع FittedBox
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
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

  // دالة موحدة لبناء صفوف البيانات بمرونة كاملة
  Widget _buildInfoRow(String label, String value,
      {bool isPhoneNumber = false, bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: LayoutBuilder(builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          // لضمان التوازن لو النص نزل سطرين
          children: [
            // النص الثابت (Label)
            SizedBox(
              width: constraints.maxWidth * 0.35,
              // تخصيص مساحة ثابتة للعنوان الثابت
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  label,
                  style: AppTextStyles.customText(
                    color: AppColors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // القيمة المتغيرة (Value)
            Expanded(
              child: GestureDetector(
                onTap: isPhoneNumber
                    ? () async {
                        final String phoneUrl = 'tel:$value';
                        if (await canLaunchUrlString(phoneUrl)) {
                          await launchUrlString(phoneUrl);
                        }
                      }
                    : null,
                child: Text(
                  value,
                  textAlign: TextAlign.left,
                  // محاذاة لليسار لتمييزها عن العنوان الثابت
                  style: AppTextStyles.customText(
                    color: isPhoneNumber
                        ? AppColors.secondaryMain
                        : AppColors.white,
                    fontSize: 15,
                    fontWeight: (isPhoneNumber || isAmount)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ).copyWith(
                    decoration: isPhoneNumber
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                  softWrap: true, // السماح بالنزول لسطر جديد لو الاسم طويل جداً
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showEditDialog(BuildContext context) {
    final amountController =
        TextEditingController(text: widget.invoice.amount.toStringAsFixed(2));
    final descriptionController =
        TextEditingController(text: widget.invoice.description);
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
                const Icon(Icons.edit_note_rounded,
                    color: AppColors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'تعديل فاتورة الإيراد',
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
                      labelText: 'المبلغ الجديد',
                      prefixIcon: const Icon(Icons.monetization_on_outlined,
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
                      labelText: 'وصف الفاتورة / ملاحظات',
                      prefixIcon: const Icon(Icons.description_outlined,
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
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await runWithLoading(context, () async {
                        try {
                          String formattedDate = DateFormat('yyyy-MM-dd')
                              .format(widget.invoice.dateTime);
                          double parsedAmount =
                              double.tryParse(amountController.text) ??
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
                            studentPhoneNumber:
                                widget.invoice.studentPhoneNumber,
                            momPhoneNumber: widget.invoice.momPhoneNumber,
                            subscriptionFeeID: widget.invoice.subscriptionFeeID,
                            dadPhoneNumber: widget.invoice.dadPhoneNumber,
                            grade: widget.invoice.grade,
                          );

                          await FirebaseFunctions.updateInvoiceInBigInvoices(
                            differenceAmount: differenceAmount,
                            updatedInvoice: updatedInvoice,
                            date: formattedDate,
                          );

                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, "/HomeScreen", (route) => false);
                            AppSnackBars.showSuccess(
                                context, "تم تحديث بيانات الفاتورة بنجاح");
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackBars.showError(
                                context, "حدث خطأ أثناء التحديث");
                          }
                        }
                      });
                    },
                    child: Text(
                      "حفظ التعديلات",
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