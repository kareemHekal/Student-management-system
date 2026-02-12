import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class EasyKashService {
  static const String _privateKey = "n0yudcqv9iib48u3";
  static const String _baseUrl = "https://back.easykash.net/api";

  static Map<String, String> get _headers => {
        "Authorization": _privateKey,
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  /// إنشاء رابط الدفع
  static Future<String?> createPaymentLink({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String reference,
    required String redirectUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/directpayv1/pay');

    // ضفنا الـ callbackUrl هنا لأنه كان سبب الـ 400 Bad Request
    final body = {
      "amount": amount,
      "currency": "EGP",
      "paymentOptions": [1, 2, 4, 5, 6, 31],
      "name": customerName,
      "email": customerEmail,
      "mobile": customerPhone,
      "customerReference": reference,
      "redirectUrl": redirectUrl,
      "callbackUrl": redirectUrl, // بنستخدم نفس الرابط كـ Callback لضمان القبول
      "type": "Direct Pay"
    };

    try {
      final response =
          await http.post(url, headers: _headers, body: jsonEncode(body));

      // دي أهم خطوة عشان لو فشل تاني تعرف السبب من الـ Console
      print("EasyKash Status: ${response.statusCode}");
      print("EasyKash Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['redirectUrl'];
      }
      return null;
    } catch (e) {
      print("EasyKash Error: $e");
      rethrow;
    }
  }

  /// الاستعلام عن الحالة
  static Future<Map<String, dynamic>?> checkPaymentStatus(
      String reference) async {
    final url = Uri.parse('$_baseUrl/cash-api/inquire');
    final body = {"customerReference": reference};

    try {
      final response =
          await http.post(url, headers: _headers, body: jsonEncode(body));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
