import 'package:flutter/material.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/daily_invoice.dart';
import 'package:student_management_system/pages/invoices/weekly_invoices_page.dart';
import 'package:student_management_system/pages/pdf_genrators/big_invoice_pdf.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

class MonthlyInvoiceCard extends StatelessWidget {
  final String monthKey;
  final List<DailyInvoice> weeklyInvoices;

  const MonthlyInvoiceCard({
    required this.monthKey,
    required this.weeklyInvoices,
    super.key,
  });

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

  String _formatMonthAr(String key) {
    try {
      List<String> parts = key.split('-');
      String year = parts[0];
      String month = parts[1];

      Map<String, String> monthsAr = {
        '01': 'يناير',
        '02': 'فبراير',
        '03': 'مارس',
        '04': 'أبريل',
        '05': 'مايو',
        '06': 'يونيو',
        '07': 'يوليو',
        '08': 'أغسطس',
        '09': 'سبتمبر',
        '10': 'أكتوبر',
        '11': 'نوفمبر',
        '12': 'ديسمبر',
      };

      return "${monthsAr[month]} ($month) $year";
    } catch (e) {
      return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalOutcome = 0;

    for (var daily in weeklyInvoices) {
      for (var inv in daily.invoices) {
        totalIncome += inv.amount;
      }
      for (var payment in daily.payments) {
        totalOutcome += payment.amount;
      }
    }

    double totalNet = totalIncome - totalOutcome;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [AppColors.primaryMain, AppColors.secondaryMain],
              begin: Alignment.topRight,
              end: Alignment.topLeft,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(top: -10, right: -10, child: _buildCircle(60, 0.17)),
                Positioned(
                    bottom: -40, left: -40, child: _buildCircle(100, 0.1)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- الصف العلوي: العنوان والأزرار ---
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                "تقرير شهر: ${_formatMonthAr(monthKey)}",
                                style: AppTextStyles.customText(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // أزرار الأكشن
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeaderButton(
                                icon: Icons.arrow_forward_ios,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WeeklyReportsPage(
                                      monthTitle: monthKey,
                                      weeklyInvoices: weeklyInvoices,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderButton(
                                icon: Icons.print,
                                onTap: () {
                                  runWithLoading(context, () async {
                                    await InvoicePdfGenerator
                                        .createMonthlyInvoicePDF(weeklyInvoices,
                                            _formatMonthAr(monthKey), context);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(
                          color: AppColors.white, height: 25, thickness: 0.5),

                      // --- الصف السفلي: ملخص الأرقام الشهري ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSummaryItem(
                              "صافي الشهر",
                              totalNet,
                              totalNet >= 0
                                  ? AppColors.white
                                  : AppColors.statusAbsent),
                          _buildVerticalDivider(),
                          _buildSummaryItem("إجمالي الإيراد", totalIncome,
                              AppColors.secondaryMain),
                          _buildVerticalDivider(),
                          _buildSummaryItem("إجمالي المصروف", totalOutcome,
                              const Color(0xFFFFCDD2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildVerticalDivider() {
    return Container(
      height: 35,
      width: 1,
      color: AppColors.white.withOpacity(0.3),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حماية النص الثابت (Label)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.customText(
                fontSize: 12, // تصغير بسيط للمساحة
                fontWeight: FontWeight.w600,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // حماية الرقم (Amount)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${amount.toStringAsFixed(0)} ج.م",
              style: AppTextStyles.customText(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}