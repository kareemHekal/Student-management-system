import 'Invoice.dart';
import 'payment.dart';

class DailyInvoice {
  final String date; // Change from DateTime to String
  final String day;
  final List<Invoice> invoices; // الدواخل
  final List<Payment> payments; // الخوارج

  DailyInvoice({
    required this.date,
    required this.day,
    required this.invoices,
    required this.payments,
  });

  // From JSON
  factory DailyInvoice.fromJson(Map<String, dynamic> json) {
    return DailyInvoice(
      date: json['date'] ?? "",
      day: json['day'] ?? "",
      invoices: (json['invoices'] as List? ?? [])
          .map((invoiceJson) => Invoice.fromJson(invoiceJson))
          .toList(),
      payments: (json['payments'] as List? ?? [])
          .map((paymentJson) => Payment.fromJson(paymentJson))
          .toList(),
    );
  }


  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date, // Store the date as a String
      'day': day,
      'invoices': invoices.map((invoice) => invoice.toJson()).toList(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }
}
