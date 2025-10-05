import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Alert dialogs/verifiy_password.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Invoice.dart';

class InvoiceWidget extends StatefulWidget {
  final Invoice invoice;

  InvoiceWidget({required this.invoice, super.key});

  @override
  State<InvoiceWidget> createState() => _InvoiceWidgetState();
}

class _InvoiceWidgetState extends State<InvoiceWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
                  context, false, "Student Name:", widget.invoice.studentName),
              _buildInfoRow(context, true, "Student Phone:",
                  widget.invoice.studentPhoneNumber),
              _buildInfoRow(
                  context, true, "Mom's Phone:", widget.invoice.momPhoneNumber),
              _buildInfoRow(
                  context, true, "Dad's Phone:", widget.invoice.dadPhoneNumber),
              _buildInfoRow(context, false, "Grade:", widget.invoice.grade),
              _buildInfoRow(context, false, "Amount:",
                  "\$${widget.invoice.amount.toStringAsFixed(2)}"),
              _buildInfoRow(
                  context, false, "Description:", widget.invoice.description),
              _buildInfoRow(context, false, "Date:",
                  DateFormat('yyyy-MM-dd').format(widget.invoice.dateTime)),
              _buildInfoRow(context, false, "Time:",
                  DateFormat('hh:mm a').format(widget.invoice.dateTime)),
            ],
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
          "InCome Details",
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
                    });
                // Show the edit dialog
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
      } else {
        print('Could not launch $phoneNumber');
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
          title: const Text("Edit Income Bill"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without changes
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(widget.invoice.dateTime);
                // Parse the new amount
                double parsedAmount = double.tryParse(amountController.text) ??
                    widget.invoice.amount;

                // Create an updated Invoice object
                Invoice updatedInvoice = Invoice(
                  studentId: widget.invoice.studentId,
                  id: widget.invoice.id,
                  amount: parsedAmount,
                  description: descriptionController.text,
                  dateTime: widget.invoice.dateTime,
                  // Keep the same date and time
                  studentName: widget.invoice.studentName,
                  studentPhoneNumber: widget.invoice.studentPhoneNumber,
                  momPhoneNumber: widget.invoice.momPhoneNumber,
                  dadPhoneNumber: widget.invoice.dadPhoneNumber,
                  grade: widget.invoice.grade,
                );

                FirebaseFunctions.updateInvoiceInBigInvoices(
                  updatedInvoice: updatedInvoice,
                  date: formattedDate,
                );
                Navigator.of(context).pop();
                setState(() {});
                // Close the dialog after updating
              },
              child: const Text("OK"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // Text color
              ),
            ),
          ],
        );
      },
    );
  }
}
