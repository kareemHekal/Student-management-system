import 'package:flutter/material.dart';

import '../Alert dialogs/DeleteIncomeBillDialog.dart';
import '../Alert dialogs/DeleteOutcomeBillDialog.dart';
import '../Alert dialogs/verifiy_password.dart';
import '../cards/In come widget.dart';
import '../cards/outcome widget.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Big invoice.dart';
import '../models/Invoice.dart';

class OneInivoicePage extends StatefulWidget {
  final BigInvoice invoice;

  OneInivoicePage({required this.invoice, super.key});

  @override
  State<OneInivoicePage> createState() => _OneInivoicePageState();
}

class _OneInivoicePageState extends State<OneInivoicePage> {
  final TextEditingController _incomeSearchController = TextEditingController();

  List<Invoice> filteredIncomeInvoices = [];

  @override
  void initState() {
    super.initState();
    filteredIncomeInvoices = widget.invoice.invoices;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: app_colors.darkGrey,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
          ),
          title: Image.asset(
            "assets/images/logo.png",
            height: 100,
            width: 90,
          ),
          toolbarHeight: 130,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.invoice.day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.invoice.date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const TabBar(
                  dividerHeight: 0,
                  tabs: [
                    Tab(text: "الإيرادات"),
                    Tab(text: "المصروفات"),
                  ],
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Income Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _incomeSearchController,
                    decoration: const InputDecoration(
                      labelText: 'ابحث باسم الطالب',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filteredIncomeInvoices = widget.invoice.invoices
                            .where((invoice) => invoice.studentName
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredIncomeInvoices.length,
                    itemBuilder: (context, filteredIndex) {
                      return GestureDetector(
                        onLongPress: () {
                          showVerifyPasswordDialog(
                            context: context,
                            onVerified: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return DeleteIncomeBillDialog(
                                    onConfirm: () async {
                                      await FirebaseFunctions
                                          .deleteInvoiceFromBigInvoices(
                                              date: widget.invoice.date,
                                              invoiceId: widget.invoice
                                                  .invoices[filteredIndex].id);
                                      setState(() {});
                                      print("تم حذف الفاتورة");
                                    },
                                    title: 'حذف فاتورة الإيراد',
                                    content:
                                        'هل أنت متأكد أنك تريد حذف هذه الفاتورة؟',
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: InvoiceWidget(
                          invoice: filteredIncomeInvoices[filteredIndex],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${filteredIncomeInvoices.length} فاتورة إيراد',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),

            // Outcome Tab
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.invoice.payments.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onLongPress: () async {
                          final parentContext =
                              context; // context of the surrounding widget

                          showDialog(
                            context: parentContext,
                            builder: (BuildContext dialogContext) {
                              return DeleteOutcomeBillDialog(
                                title: 'حذف فاتورة المصروفات',
                                content:
                                    'هل أنت متأكد أنك تريد حذف هذه الفاتورة؟',
                                onConfirm: () async {
                                  // Close the confirmation dialog first
                                  Navigator.of(dialogContext).pop();

                                  // Show password verification
                                  await showVerifyPasswordDialog(
                                    context: parentContext,
                                    onVerified: () async {
                                      try {
                                        widget.invoice.payments.remove(
                                            widget.invoice.payments[index]);
                                        await FirebaseFunctions
                                            .updateBigInvoice(
                                          widget.invoice.date,
                                          widget.invoice,
                                        );

                                        // Update UI
                                        if (mounted) setState(() {});

                                        // Show SnackBar
                                        ScaffoldMessenger.of(parentContext)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('تم حذف الفاتورة بنجاح'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(parentContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'حدث خطأ أثناء حذف الفاتورة: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: PaymentWidget(
                          paymentIndex: index,
                          payment: widget.invoice.payments[index],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${widget.invoice.payments.length} فاتورة مصروفات',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
