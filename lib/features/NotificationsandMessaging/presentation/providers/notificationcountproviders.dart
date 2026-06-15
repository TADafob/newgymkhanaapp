import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsBadgeProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);
  final uid = user.uid;

  return FirebaseFirestore.instance
    .collection('notifications_collection')
    .where('recipientId', isEqualTo: uid)
    .where('isNew', isEqualTo: true)
    .snapshots()
    .map((snap) => snap.docs.length);
});

final chatsBadgeProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);
  final uid = user.uid;

  return FirebaseFirestore.instance
    .collection('chats_collection')
    .snapshots()
    .map((snap) {
      var total = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        // unreadCounts is a map of userId->int
        final raw = data['unreadCounts'] as Map<String, dynamic>? ?? {};
        final count = raw[uid] as int? ?? 0;
        total += count;
      }
      return total;
    });
});