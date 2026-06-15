// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class UserSettings {
//   final bool notificationsEnabled;
//   UserSettings(this.notificationsEnabled);

//   Map<String,dynamic> toJson() => {'notificationsEnabled': notificationsEnabled};
// }

// class UserSettingsNotifier extends StateNotifier<UserSettings> {
//   UserSettingsNotifier(): super(UserSettings(true)) {
//     _load();
//   }


//   Future<void> _load() async {
//     final snap = await FirebaseFirestore.instance
//         .collection('users_members')
//         .doc(currentUid)
//         .get();
//     if (snap.exists) {
//       state = UserSettings(snap.data()?['notificationsEnabled'] ?? true);
//     }
//   }

//   Future<void> setNotifications(bool on) async {
//     state = UserSettings(on);
//     await FirebaseFirestore.instance
//         .collection('users_members')
//         .doc(currentUid)
//         .update({'notificationsEnabled': on});
//     if (on) {
//       // re-subscribe to topic (optional)
//       await FirebaseMessaging.instance.subscribeToTopic('card_updates');
//     } else {
//       await FirebaseMessaging.instance.unsubscribeFromTopic('card_updates');
//     }
//   }
// }

// final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier,UserSettings>(
//   (_) => UserSettingsNotifier()
// );
