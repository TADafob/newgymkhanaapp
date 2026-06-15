import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nrbgymkhana/core/utils/payment_selector_sheet.dart';

Future<void> showRenewSubsDialog(
  BuildContext context,
  WidgetRef ref, {
  required String subsDocId,
  required String title,
  required int amount,
  required String subsCatId,
  required DateTime expiryDate,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  DateTime newExpiry(String catId) {
    final now = DateTime.now();
    if (catId.contains('Monthly')) return now.add(const Duration(days: 31));
    if (catId.contains('Quarterly')) return now.add(const Duration(days: 120));
    if (catId.contains('Semi')) return now.add(const Duration(days: 180));
    return DateTime(now.year, 12, 31, 23, 59, 59);
  }

  if (!context.mounted) return;
  final paid = await showPaymentSelectorSheet(
    context,
    ref,
    amount: amount,
    accountRef: 'SubsRenewal',
    description: 'Subscription Renewal - $title',
    title: 'Renew Subscription',
    onSuccess: (data) async {
      final checkoutRequestId = data['CheckoutRequestID'] as String? ??
          data['mpesaReceiptNumber'] as String? ?? '';
      final subsRef = FirebaseFirestore.instance
          .collection('subscriptions_collection')
          .doc(subsDocId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(subsRef);
        if (snap.data()?['reaction']?['reaction_Id'] == checkoutRequestId) return;
        tx.update(subsRef, {
          'reaction.isPaid': true,
          'reaction.status': 'Confirmed',
          'reaction.reaction_Id': checkoutRequestId,
          'expiry_Date': Timestamp.fromDate(newExpiry(subsCatId)),
          'subs_Date': Timestamp.fromDate(DateTime.now()),
        });
      });
    },
  );
  if (paid == true) {
    Fluttertoast.showToast(
      msg: 'Subscription renewed successfully!',
      backgroundColor: Colors.green,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}
