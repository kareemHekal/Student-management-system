import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

abstract class EasyKashService {
  static String? _cachedKey;
  static const String _baseUrl = "https://back.easykash.net/api";

  /// Fetch the private key from Firestore instead of hardcoding it
  static Future<String> _getPrivateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('payment_config')
        .get();
    _cachedKey = doc.data()?['easykash_private_key'] ?? '';
    return _cachedKey!;
  }

  static Future<Map<String, String>> get _headers async {
    final key = await _getPrivateKey();
    return {
      "Authorization": key,
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  /// Clear cached key (call on logout)
  static void clearCache() {
    _cachedKey = null;
  }

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
      final headers = await _headers;
      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));

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
      final headers = await _headers;
      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
