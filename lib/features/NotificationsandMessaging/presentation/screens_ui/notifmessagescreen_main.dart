import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/presentation/screens_ui/notificationscreen.dart';
import 'package:nrbgymkhana/features/common/sharedpreff/localstorage.dart';
import 'package:nrbgymkhana/features/common/common_providers/providers.dart';
import '../../../../core/utils/responsiveness.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _markAllNotificationsAsRead();
  }

  Future<void> _markAllNotificationsAsRead() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      await markNotificationsAsRead(currentUserId);
      ref.invalidate(unreadNotificationsProvider); // Refresh unread count
      await LocalStorage.setLastOpenedTime(DateTime.now()); // Reset counter
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: TopAppBar(),
      body: responsiveLayout(
        smallScreen: _buildSmallScreen(),
        mediumScreen: _buildMediumScreen(),
      ),
    );
  }

  Widget _buildSmallScreen() {
    return NotificationsPage();
  }

  Widget _buildMediumScreen() {
    return Center(
      child: SizedBox(
        width: 400,
        child: _buildSmallScreen(),
      ),
    );
  }
}

Future<void> markNotificationsAsRead(String userId) async {
  final notificationsQuery = await FirebaseFirestore.instance
      .collection('notifications_collection')
      .where('readBy', arrayContains: userId)
      .get();

  for (var doc in notificationsQuery.docs) {
    await FirebaseFirestore.instance
        .collection('notifications_collection')
        .doc(doc.id)
        .update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }
}
