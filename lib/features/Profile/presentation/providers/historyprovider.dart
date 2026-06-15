import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/Profile/data/datasources/member_firestore_serv.dart';
import 'package:nrbgymkhana/features/Profile/domain/entities/user_data.dart';
import 'package:rxdart/rxdart.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final userDataProvider = StreamProvider<UserData>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.userRelatedDataStream().map((dataMap) {
    return UserData(
      activeSubscriptions: dataMap['subscriptionsCount'] as int,
      // Map additional fields if needed.
    );
  });
  
});
final reportCountProvider = FutureProvider<int>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return 0;
  final snapshot = await FirebaseFirestore.instance
      .collection('reports_Collection')
      .where('reported_By', isEqualTo: uid)
      .get();
  return snapshot.docs.length;
});

final clockProvider = StreamProvider<DateTime>((ref) {
  // Automatically cancel when nobody’s listening
  return Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  ).startWith(DateTime.now());
});


final upcomingBookingsProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // 1️⃣ Listen to our clock
  final clockStream = ref.watch(clockProvider.stream);

  // 2️⃣ Listen to Firestore changes
  final bookingsStream = FirebaseFirestore.instance
      .collection('bookings_collection')
      .where('user_Id', isEqualTo: uid)
      .where('reaction.status', isNotEqualTo: 'Cancelled')
      .orderBy('start_Time')
      .snapshots();

  // 3️⃣ Combine them: whenever either ticks, recompute the count
  return Rx.combineLatest2<DateTime, QuerySnapshot<Map<String, dynamic>>, int>(
    clockStream,
    bookingsStream,
    (now, snap) {
      print ('found ${snap.docs.length} bookings');
      
      final nowTs = Timestamp.fromDate(now);
      // only count docs whose start_Time is STILL in the future
      final valid = snap.docs.where((doc) {
        final ts = doc.data()['start_Time'] as Timestamp;
        return ts.compareTo(nowTs) > 0;
      });

      print ('found ${valid.length} valid bookings');

      return valid.length;
    },
  );
});