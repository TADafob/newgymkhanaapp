import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nrbgymkhana/features/app_auths/presentation/providers/auth_provider.dart';

// Provider to fetch unread notifications
final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final currentUserId = ref.watch(authStateChangesProvider).value?.uid;
  if (currentUserId == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('notifications_collection')
      .where('readBy', arrayContains: currentUserId, isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
