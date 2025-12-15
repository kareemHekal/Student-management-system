import 'package:flutter/material.dart';

import '../models/Big invoice.dart';
import '../pages/one invoice page.dart';
import '../pages/pdf_genrators/pdfGnerator.dart';
import '../theme/colors_app.dart';

class BigInvoiceCard extends StatefulWidget {
  final BigInvoice invoice;

  BigInvoiceCard({required this.invoice, super.key});

  @override
  State<BigInvoiceCard> createState() => _BigInvoiceCardState();
}

class _BigInvoiceCardState extends State<BigInvoiceCard> {
  // Helper method for the decorative background circles (New)
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

  // Helper for Print Button (New - inspired by action circles)
  Widget _buildPrintButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15), // Subtle background
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.print,
          size: 20,
          color: AppColors.white, // White icon for high contrast
        ),
        onPressed: () async {
          await generateBigInvoicePDF(widget.invoice);
        },
      ),
    );
  }

  // ... inside _BigInvoiceCardState

  @override
  Widget build(BuildContext context) {
    // Calculations remain the same
    double totalIncome = 0;
    double totalOutcome = 0;

    for (var inv in widget.invoice.invoices) {
      totalIncome += inv.amount;
    }

    for (var payment in widget.invoice.payments) {
      totalOutcome += payment.amount;
    }

    double total = totalIncome - totalOutcome;

    return Directionality(
        // Ensure RTL context for Arabic labels
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OneInivoicePage(invoice: widget.invoice),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryMain,
                    AppColors.secondaryMain,
                  ],
                  begin: Alignment.bottomLeft,
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
              child: Stack(
                children: [
                  // ===== Decorative Circles (Same new placement) =====
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

                  // ===== Card Content =====
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // --- TOP ROW: Date, Day, and Print Button ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Date and Day (Combined)
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  size: 24,
                                  color: AppColors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.invoice.day}, ${widget.invoice.date}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),

                            // Print Button in Circle
                            _buildPrintButton(),
                          ],
                        ),

                        const Divider(
                            color: AppColors.white, height: 20, thickness: 0.5),

                        // --- BOTTOM ROW: Data Summary with Vertical Dividers ---
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          // IMPORTANT: Wrap the Row in a SizedBox to give the VerticalDivider a defined height
                          child: SizedBox(
                            height: 65,
                            // Explicitly set height for the Row content
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // 1. Total
                                _showDataSummary(
                                    "الإجمالي",
                                    total,
                                    total >= 0
                                        ? AppColors.white
                                        : AppColors.statusAbsent),

                                // VERTICAL DIVIDER 1
                                VerticalDivider(
                                  color: AppColors.white.withOpacity(0.5),
                                  thickness: 1,
                                  width: 16,
                                  // Width of the divider widget area
                                  indent: 8,
                                  // Space above the line
                                  endIndent: 8, // Space below the line
                                ),

                                // 2. Income
                                _showDataSummary("الإيرادات", totalIncome,
                                    AppColors.secondaryMain),

                                SizedBox(
                                  width: 8,
                                ),
                                // // VERTICAL DIVIDER 2
                                // VerticalDivider(
                                //   color: AppColors.white.withOpacity(0.5),
                                //   thickness: 1,
                                //   width: 16,
                                //   indent: 8,
                                //   endIndent: 8,
                                // ),

                                // 3. Outcome
                                _showDataSummary("المصروفات", totalOutcome,
                                    AppColors.statusAbsent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  // Modified to take a color parameter for thematic emphasis
  Widget _showDataSummary(String label, double amount, Color amountColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white, // Label is white
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${amount.toStringAsFixed(2)} ج.م",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: amountColor, // Dynamic color for emphasis
          ),
        ),
      ],
    );
  }

  Future<void> generateBigInvoicePDF(BigInvoice invoice) async {
    await PdfGenerator.createBigInvoicePDF(invoice, context);
  }
}