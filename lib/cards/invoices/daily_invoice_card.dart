import 'package:flutter/material.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';

import '../../models/daily_invoice.dart';
import '../../pages/invoices/one invoice page.dart';
import '../../pages/pdf_genrators/big_invoice_pdf.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart';

class DailyInvoiceCard extends StatefulWidget {
  final DailyInvoice invoice;
  const DailyInvoiceCard({required this.invoice, super.key});

  @override
  State<DailyInvoiceCard> createState() => _DailyInvoiceCardState();
}

class _DailyInvoiceCardState extends State<DailyInvoiceCard> {
  Widget _buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeaderButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: AppColors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildPrintButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.print, size: 20, color: AppColors.white),
        onPressed: () async => await generateBigInvoicePDF(widget.invoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalOutcome = 0;
    for (var inv in widget.invoice.invoices) totalIncome += inv.amount;
    for (var payment in widget.invoice.payments) totalOutcome += payment.amount;
    double total = totalIncome - totalOutcome;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [AppColors.primaryMain, AppColors.secondaryMain],
              begin: Alignment.bottomLeft,
              end: Alignment.topLeft,
            ),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -4),
            ],
          ),
          child: Stack(
            children: [
              Positioned(top: -10, right: -10, child: _buildCircle(60, 0.17)),
              Positioned(bottom: -40, left: -40, child: _buildCircle(100, 0.1)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- الصف العلوي ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 24, color: AppColors.white),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${widget.invoice.day}, ${widget.invoice.date}',
                                    style: AppTextStyles.customText(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderButton(
                            icon: Icons.arrow_forward_ios,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OneInivoicePage(
                                        invoice: widget.invoice)))),
                        SizedBox(
                          width: 8,
                        ),
                        _buildPrintButton(),
                      ],
                    ),
                    const Divider(
                        color: AppColors.white, height: 20, thickness: 0.5),

                    // --- الصف السفلي (الـ 3 أرقام جمب بعض زي ما تحب) ---
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _showDataSummary(
                            "صافي الربح",
                            total,
                            total >= 0
                                ? AppColors.white
                                : AppColors.statusAbsent,
                          ),
                          _buildVerticalDivider(),
                          _showDataSummary(
                            "الإيرادات",
                            totalIncome,
                            AppColors.secondaryMain,
                          ),
                          _buildVerticalDivider(),
                          _showDataSummary(
                            "المصروفات",
                            totalOutcome,
                            const Color(0xFFFFCDD2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
        height: 40, width: 1, color: AppColors.white.withOpacity(0.3));
  }

  // الـ Widget دي هي اللي فيها السر عشان تضمن إن النصوص الثابتة والمبالغ ما تكسرش الـ Row
  Widget _showDataSummary(String label, double amount, Color amountColor) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // النص الثابت محمي بـ FittedBox عشان لو الخط كبر يصغر الكلمة بدل ما يزق اللي جنبه
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.customText(
                fontSize: 13, // صغرنا الخط سنة لزيادة مساحة الأمان
                fontWeight: FontWeight.w600,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // المبلغ محمي بـ FittedBox عشان لو الرقم كبير (ملايين مثلاً) يفضل في مكانه
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${amount.toStringAsFixed(0)} ج.م",
              style: AppTextStyles.customText(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> generateBigInvoicePDF(DailyInvoice invoice) async {
    runWithLoading(context, () async {
      await InvoicePdfGenerator.createDailyInvoicePDF(invoice, context);
    });
  }
}