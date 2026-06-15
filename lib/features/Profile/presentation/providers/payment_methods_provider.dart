import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/Profile/data/models/payment_method.dart';

CollectionReference<Map<String, dynamic>> _col() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users_members')
      .doc(uid)
      .collection('payment_methods');
}

final paymentMethodsProvider = StreamProvider<List<PaymentMethod>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users_members')
      .doc(uid)
      .collection('payment_methods')
      .orderBy('isDefault', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => PaymentMethod.fromMap(d.id, d.data()))
          .toList());
});

Future<void> addPaymentMethod(PaymentMethod method) async {
  final col = _col();
  // If this is the first method or marked default, clear others' default
  if (method.isDefault) await _clearDefaults();
  await col.add(method.toMap());
}

Future<void> deletePaymentMethod(String id) async {
  await _col().doc(id).delete();
}

Future<void> setDefaultPaymentMethod(String id) async {
  await _clearDefaults();
  await _col().doc(id).update({'isDefault': true});
}

Future<void> _clearDefaults() async {
  final snap = await _col().where('isDefault', isEqualTo: true).get();
  for (final doc in snap.docs) {
    await doc.reference.update({'isDefault': false});
  }
}
