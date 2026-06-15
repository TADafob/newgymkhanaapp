import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime dateTime;
  final bool isNew;
  final IconData icon;
  final Color iconColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.dateTime,
    required this.isNew,
    required this.icon,
    required this.iconColor,
  });

  factory NotificationModel.fromFirestore(String id, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'booking';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    final handlers = _notificationHandlers();

    final handler = handlers[type] ?? handlers['default']!;
    final result = handler(data);

    return NotificationModel(
      id: id,
      title: result['title'],
      body: result['body'],
      dateTime: timestamp,
      isNew: data['isNew'] as bool? ?? true,
      icon: result['icon'],
      iconColor: result['iconColor'],
    );
  }

  static Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>
      _notificationHandlers() {
    return {
      'card_update': (data) {
        final isTopUp = data['isTopUp'] as bool? ?? true;
        final title = data['title'] as String? ?? (isTopUp ? 'Card Top-Up' : 'Card Transaction');

        // Use pre-built body if available (written by receipt monitor)
        String body = data['body'] as String? ?? '';

        // Fallback: build body from raw fields for older notifications
        if (body.isEmpty) {
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateStr = DateFormat('dd-MMM-yy').format(timestamp);
          final timeStr = DateFormat('hh:mm a').format(timestamp);
          final rcpt = data['receiptNo'] as String? ?? '';
          final method = data['paymentMethod'] as String? ?? '';
          final rawAmt = data['amount'];
          final amt = (rawAmt is num)
              ? rawAmt.toDouble()
              : double.tryParse(rawAmt?.toString() ?? '') ?? 0.0;
          final rcptLine = rcpt.isNotEmpty ? 'Receipt #$rcpt: ' : '';
          final methodLine = method.isNotEmpty ? ' via $method' : '';
          if (isTopUp) {
            body = '${rcptLine}Ksh ${amt.toStringAsFixed(2)} was added to your card$methodLine on $dateStr at $timeStr.';
          } else {
            final descr = data['transDescr'] as String? ?? '';
            final descrLine = descr.isNotEmpty ? ' for $descr' : '';
            body = '${rcptLine}Ksh ${amt.toStringAsFixed(2)} was deducted from your card on $dateStr at $timeStr$descrLine.';
          }
        }

        return {
          'title': title,
          'body': body,
          'icon': Icons.credit_card,
          'iconColor': isTopUp ? Colors.green : Colors.red,
        };
      },
      'booking': (data) {
        return {
          'title': data['title'] as String? ?? 'Booking Notification',
          'body': data['description'] as String? ?? '',
          'icon': Icons.event_available,
          'iconColor': Colors.blue,
        };
      },
      'booking_reminder': (data) {
        return {
          'title': data['title'] as String? ?? 'Booking Reminder',
          'body': data['description'] as String? ?? '',
          'icon': Icons.alarm_rounded,
          'iconColor': Colors.orange,
        };
      },
      'payment_reminder': (data) {
        return {
          'title': data['title'] as String? ?? 'Payment Pending',
          'body': data['description'] as String? ?? '',
          'icon': Icons.payment_rounded,
          'iconColor': Colors.deepOrange,
        };
      },
      'subscription_reminder': (data) {
        return {
          'title': data['title'] as String? ?? 'Subscription Expiring',
          'body': data['description'] as String? ?? '',
          'icon': Icons.card_membership_rounded,
          'iconColor': Colors.purple,
        };
      },
      'security': (data) {
        return {
          'title': data['title'] as String? ?? 'Security Alert',
          'body': data['description'] as String? ?? '',
          'icon': Icons.lock_reset_rounded,
          'iconColor': Colors.green,
        };
      },
      // Add more types here
      'default': (data) {
        return {
          'title': data['title'] as String? ?? 'Notification',
          'body': data['description'] as String? ?? '',
          'icon': Icons.notifications,
          'iconColor': Colors.grey,
        };
      },
    };
  }
}
