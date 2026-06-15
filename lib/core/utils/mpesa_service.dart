import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MpesaService {
  // ── Daraja Sandbox credentials ──────────────────────────────────────────────
  static const _consumerKey =
      '7hK5BcmuB5qgVaIqkuXPBxL2hxbCX2KuYICc5j0GTry1hX62';
  static const _consumerSecret =
      'S7eGAK1ryHn315quobguBot74ylnQarAAKPAjVEt8sd60go4FiHcw2USoGM7vYr9';
  static const _shortcode = '174379'; // Daraja sandbox shortcode
  static const _passkey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'; // sandbox passkey
  static const _callbackUrl =
      'https://564e-102-223-34-114.ngrok-free.app/mpesa/callback';

  static const _authUrl =
      'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';
  static const _stkUrl =
      'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest';

  /// Returns an OAuth access token from Daraja sandbox.
  static Future<String> _getAccessToken() async {
    final credentials =
        base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    final response = await http.get(
      Uri.parse(_authUrl),
      headers: {'Authorization': 'Basic $credentials'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get M-Pesa token: ${response.body}');
    }
    return jsonDecode(response.body)['access_token'] as String;
  }

  /// Initiates an STK push to [phone] for [amount] KES.
  /// [phone] should be in format 2547XXXXXXXX.
  /// Returns the response body map.
  static Future<Map<String, dynamic>> stkPush({
    required String phone,
    required int amount,
    required String accountRef,
    String description = 'Guest Levy Payment',
  }) async {
    final token = await _getAccessToken();

    final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final password = base64Encode(
      utf8.encode('$_shortcode$_passkey$timestamp'),
    );

    // Normalise phone: strip leading 0 or + and ensure 254 prefix
    String normalised = phone.replaceAll(RegExp(r'\s+'), '');
    if (normalised.startsWith('+')) normalised = normalised.substring(1);
    if (normalised.startsWith('0')) {
      normalised = '254${normalised.substring(1)}';
    }

    final body = {
      'BusinessShortCode': _shortcode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount,
      'PartyA': normalised,
      'PartyB': _shortcode,
      'PhoneNumber': normalised,
      'CallBackURL': _callbackUrl,
      'AccountReference': accountRef,
      'TransactionDesc': description,
    };

    final response = await http.post(
      Uri.parse(_stkUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(result['errorMessage'] ?? 'STK push failed');
    }
    return result;
  }
}
