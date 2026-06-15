import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/thewall/presentation/widgets/dateconfigwidget.dart';
import 'package:rxdart/rxdart.dart';


final authStateProvider = StreamProvider<User?>((ref) =>
    FirebaseAuth.instance.authStateChanges());

final unreadCountProvider = StreamProvider.family<int, CollectionConfig>((ref, config) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(0);
  final uid = user.uid;

  final collectionPath = config.collectionPath;
  final dateField = config.dateField;

  final allDocsStream = FirebaseFirestore.instance
      .collection(collectionPath)
      .snapshots();

  final lastReadStream = FirebaseFirestore.instance
      .collection('users_members')
      .doc(uid)
      .collection('reads')
      .doc(collectionPath)
      .snapshots()
      .map((docSnap) {
    return docSnap.data()?['lastReadAt'] as Timestamp? ?? Timestamp(0, 0);
  });

  return Rx.combineLatest2(allDocsStream, lastReadStream, (QuerySnapshot snapshot, Timestamp lastReadAt) {
    return snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final docTimestamp = data[dateField] as Timestamp?;
      return docTimestamp != null && docTimestamp.compareTo(lastReadAt) > 0;
    }).length;
  });
});

Future<void> markAllRead(String collectionPath, WidgetRef ref) async {
  final user = ref.read(authStateProvider).value;
  if (user == null) return;
  final uid = user.uid;

  await FirebaseFirestore.instance
      .collection('users_members')
      .doc(uid)
      .collection('reads')
      .doc(collectionPath)
      .set({'lastReadAt': Timestamp.now()});
}

// StreamProvider<int> unreadNoticesCount = StreamProvider<int>((ref) {
//   final uid = ref.watch(firebaseAuthProvider).currentUser!.uid;

//   final allNotices = FirebaseFirestore.instance
//     .collection('clubNotices')
//     .snapshots();

//   final reads = FirebaseFirestore.instance
//     .collection('users/$uid/reads/notices')
//     .snapshots()
//     .map((snap) => snap.docs.map((d) => d.id).toSet());

//   // Combine streams: every time either changes, compute difference
//   return Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, Set<String>, int>(
//     allNotices,
//     reads,
//     (snap, readIds) {
//       return snap.docs.where((d) => !readIds.contains(d.id)).length;
//     },
//   );
// });

// Events unread count
// final eventsUnreadCountProvider = StreamProvider<int>((ref) {
//   final col = FirebaseFirestore.instance
//     .collection('events_collection')
//     .where('isRead', isEqualTo: false);
//   return col.snapshots().map((snap) => snap.docs.length);
// });

// // Lost and Found unread count
// final lostandFoundUnreadCountProvider = StreamProvider<int>((ref) {
//   final col = FirebaseFirestore.instance
//     .collection('lostandfound_collection')
//     .where('isRead', isEqualTo: false);
//   return col.snapshots().map((snap) => snap.docs.length);
// });

// // Clubs unread count
// final clubFacilitiesUnreadCountProvider = StreamProvider<int>((ref) {
//   final col = FirebaseFirestore.instance
//     .collection('Facilities')
//     .where('isNew', isEqualTo: true);
//   return col.snapshots().map((snap) => snap.docs.length);
// });

// final reportsUnreadCountProvider = StreamProvider<int>((ref) {
//   final String uid = FirebaseAuth.instance.currentUser!.uid; 
//   final col = FirebaseFirestore.instance
//     .collection('reports_Collection').
//     where('reported_By', isEqualTo: uid)
//     .where('isResolved', isEqualTo: false);
//   return col.snapshots().map((snap) => snap.docs.length);
// });
