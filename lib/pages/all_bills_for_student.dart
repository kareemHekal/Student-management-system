import 'package:flutter/material.dart';

import '../Alert dialogs/DeleteIncomeBillDialog.dart';
import '../cards/In come widget.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Invoice.dart';
import 'package:intl/intl.dart';

class AllBillsForStudent extends StatefulWidget {
  final String studentId;

  const AllBillsForStudent({required this.studentId, super.key});

  @override
  State<AllBillsForStudent> createState() => _AllBillsForStudentState();
}

class _AllBillsForStudentState extends State<AllBillsForStudent> {
  List<Invoice> invoices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }Future<void> _loadInvoices() async {
    try {
      List<Invoice> loadedInvoices =
      await FirebaseFunctions.getInvoicesByStudentNumber(widget.studentId);

      if (!mounted) return; // prevent setState after dispose

      setState(() {
        isLoading = false;
        invoices = loadedInvoices;
      });
    } catch (e, stack) {
      if (!mounted) return;
      setState(() {
        isLoading = false; // stop loading even if error happens
        invoices = [];
      });
      debugPrint("❌ Error loading invoices: $e\n$stack");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(invoices.length.toString(),style: TextStyle(color: app_colors.white,fontWeight: FontWeight.w700),),
          )
        ],
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset("assets/images/2....2.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : invoices.isEmpty
          ? const Center(
        child: Text(
          "No bills for this student",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder( // 👈 removed Expanded
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return DeleteIncomeBillDialog(
                    onConfirm: () async {
                      String formattedDate = DateFormat('yyyy-MM-dd')
                          .format(invoices[index].dateTime);

                      await FirebaseFunctions
                          .deleteInvoiceFromBigInvoices(
                        date: formattedDate,
                        invoiceId: invoices[index].id,
                      );

                      await _loadInvoices(); // reload after delete
                    },
                    title: 'Delete Income Bill',
                    content:
                    'Are you sure you want to delete this income bill?',
                  );
                },
              );
            },
            child: InvoiceWidget(invoice: invoices[index]),
          );
        },
      ),
    );
  }

}
