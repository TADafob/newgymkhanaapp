import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches all bookings for a given eventId, cached & auto‑disposed.
final bookingsProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, eventId) {
  return FirebaseFirestore.instance
      .collection('events_collection')
      .doc(eventId)
      .collection('bookings')
      .snapshots();
});
