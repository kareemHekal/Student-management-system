import 'package:flutter/material.dart';
import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/models/daily_invoice.dart';
import 'package:student_management_system/pages/invoices/daily_invoices_page.dart';
import 'package:student_management_system/pages/pdf_genrators/big_invoice_pdf.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

class MonthlyInvoiceCard extends StatelessWidget {
  final String monthKey;
  final List<DailyInvoice> dailyInvoices;

  const MonthlyInvoiceCard({
    required this.monthKey,
    required this.dailyInvoices,
    super.key,
  });

  // دائرة زخرفية للخلفية (للحفاظ على نفس الثيم)
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

    for (var daily in dailyInvoices) {
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
          // التعديل المطلوب في اللون والتدرج والظلال هنا
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryMain,
                AppColors.secondaryMain,
              ],
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
            // لمنع الدوائر من الخروج عن حدود الكارت
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // دوائر زخرفية لتعطي نفس روح الكارت اليومي
                Positioned(
                  top: -10,
                  right: -10,
                  child: _buildCircle(60, 0.17),
                ),
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: _buildCircle(100, 0.1),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                "تقرير شهر: ${_formatMonthAr(monthKey)}",
                                style: AppTextStyles.customText(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: AppColors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => dailyInvoicesPage(
                                      monthTitle: _formatMonthAr(monthKey),
                                      invoices: dailyInvoices,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.print,
                                size: 18,
                                color: AppColors.white,
                              ),
                              onPressed: () {
                                runWithLoading(context, () async {
                                  await InvoicePdfGenerator
                                      .createMonthlyInvoicePDF(dailyInvoices,
                                          _formatMonthAr(monthKey), context);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                          color: AppColors.white, height: 25, thickness: 0.5),
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
        children: [
          Text(
            label,
            style: AppTextStyles.customText(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${amount.toStringAsFixed(0)} ج.م",
            style: AppTextStyles.customText(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
