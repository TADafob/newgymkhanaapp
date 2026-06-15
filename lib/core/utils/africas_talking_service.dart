import 'dart:convert';
import 'package:http/http.dart' as http;

enum ATChannel { sms, whatsapp, email }

class AfricasTalkingService {
  // Change this to your server's URL when deployed
  // For local testing use your machine's IP (not localhost) e.g. http://192.168.x.x:3000
  static const String _baseUrl = 'http://192.168.88.233:3000';

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Request failed');
    return data;
  }

  /// Sports facility booking (with court number, time slot, optional payment).
  static Future<void> sendSportsBookingConfirmation({
    required String phone,
    required String userName,
    required String facilityName,
    required String courtNo,
    required String date,
    required String timeSlot,
    int? amountDue,
    String? qrLink,
    ATChannel channel = ATChannel.sms,
  }) {
    final paymentLine = amountDue != null && amountDue > 0
        ? '\nAmount to be Paid: Ksh $amountDue for Guest Levy.'
        : '';
    final qrLine = qrLink != null && qrLink.isNotEmpty
        ? '\nBooking QR Code: $qrLink'
        : '';
    final msg = 'Hi $userName,\nYour booking for $facilityName has been confirmed'
        ' for Court No. $courtNo on $date, $timeSlot.$paymentLine$qrLine'
        '\nFor any queries or changes please contact the club reception.';
    return _post('/at/notify', {'phone': phone, 'message': msg, 'channel': channel.name});
  }

  /// Banda booking (no court number, has time slot).
  static Future<void> sendBandaBookingConfirmation({
    required String phone,
    required String userName,
    required String facilityName,
    required String date,
    required String timeSlot,
    int? amountDue,
    String? qrLink,
    ATChannel channel = ATChannel.sms,
  }) {
    final paymentLine = amountDue != null && amountDue > 0
        ? '\nAmount to be Paid: Ksh $amountDue.'
        : '';
    final qrLine = qrLink != null && qrLink.isNotEmpty
        ? '\nBooking QR Code: $qrLink'
        : '';
    final msg = 'Hi $userName,\nYour Banda booking for $facilityName has been confirmed'
        ' on $date, $timeSlot.$paymentLine$qrLine'
        '\nFor any queries or changes please contact the club reception.';
    return _post('/at/notify', {'phone': phone, 'message': msg, 'channel': channel.name});
  }

  /// Club facility booking request (no court, no time slots — date range only).
  static Future<void> sendClubBookingRequest({
    required String phone,
    required String userName,
    required String facilityName,
    required String dateRange,
    String? qrLink,
    ATChannel channel = ATChannel.sms,
  }) {
    final qrLine = qrLink != null && qrLink.isNotEmpty
        ? '\nBooking QR Code: $qrLink'
        : '';
    final msg = 'Hi $userName,\nYour booking request for $facilityName'
        ' for $dateRange has been received and is pending confirmation.$qrLine'
        '\nFor any queries or changes please contact the club reception.';
    return _post('/at/notify', {'phone': phone, 'message': msg, 'channel': channel.name});
  }

  static Future<void> sendPaymentConfirmation({
    required String phone,
    required int amount,
    required String receiptNo,
    ATChannel channel = ATChannel.sms,
  }) =>
      _post('/at/notify', {
        'phone': phone,
        'message':
            'NRB Gymkhana: Payment of KSH $amount received. M-Pesa receipt: $receiptNo. Thank you!',
        'channel': channel.name,
      });

  static Future<void> sendSubscriptionNotification({
    required String phone,
    required String subsPlan,
    String? expiryDate,
    String type = 'activated',
    ATChannel channel = ATChannel.sms,
  }) {
    final messages = {
      'activated': 'NRB Gymkhana: Your $subsPlan subscription is now active. Enjoy!',
      'expiring_soon':
          'NRB Gymkhana: Your $subsPlan subscription expires on $expiryDate. Renew now.',
      'expired': 'NRB Gymkhana: Your $subsPlan subscription has expired. Renew today.',
    };
    return _post('/at/notify', {
      'phone': phone,
      'message': messages[type] ?? messages['activated'],
      'channel': channel.name,
    });
  }

  // Keep old method name as alias so nothing else breaks
  static Future<void> sendBookingNotification({
    required String phone,
    required String facilityType,
    required String startTime,
    required String bookingId,
    ATChannel channel = ATChannel.sms,
  }) =>
      sendSportsBookingConfirmation(
        phone: phone,
        userName: '',
        facilityName: facilityType,
        courtNo: '',
        date: startTime,
        timeSlot: '',
        channel: channel,
      );

  static Future<void> sendPasswordChangeAlert({
    required String phone,
    required String userName,
    ATChannel channel = ATChannel.sms,
  }) =>
      _post('/at/notify', {
        'phone': phone,
        'message':
            'NRB Gymkhana: Hi $userName, your account password was successfully changed. If this wasn\'t you, contact support immediately at 0708 042 394.',
        'channel': channel.name,
      });

  /// Sandbox test — verify integration is working
  static Future<Map<String, dynamic>> testSend({
    required String phone,
    ATChannel channel = ATChannel.sms,
  }) =>
      _post('/at/test', {'phone': phone, 'channel': channel.name});
}
