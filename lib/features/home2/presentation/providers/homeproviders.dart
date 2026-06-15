import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

/// USER, NEWS & CARD STREAM PROVIDERS with optimization

/// Provider for fetching user data - cached for 5 minutes
final userStreamProvider = StreamProvider<DocumentSnapshot>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream<DocumentSnapshot>.empty();
  return FirebaseFirestore.instance
    .collection('users_members')
    .doc(user.uid)
    .snapshots();
});

/// Provider for fetching published news - limited to 20 items
final newsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
    .collection('news_collection')
    .where('is_Published', isEqualTo: true)
    .orderBy('posted_At', descending: true)
    .limit(20)
    .snapshots();
});

/// Provider for fetching the current user's card data
final cardStreamProvider = StreamProvider<DocumentSnapshot>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream<DocumentSnapshot>.empty();
  return FirebaseFirestore.instance
    .collection('members_cards')
    .doc(user.uid)
    .snapshots();
});

/// STREAM PROVIDERS with optimized queries

final subsBadgeProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);
  final uid = user.uid;

  final readRef = FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('subs');

  final lastViewedStream = readRef.snapshots().map((snap) {
    final data = snap.data() ?? {};
    final ts   = data['lastViewed'] as Timestamp?;
    return ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
  });

  final subsStream = FirebaseFirestore.instance
    .collection('subscriptions_collection')
    .where('user_Id', isEqualTo: uid)
    .limit(100)
    .snapshots();

  return Rx.combineLatest2<DateTime, QuerySnapshot, int>(
    lastViewedStream,
    subsStream,
    (lastViewed, snap) {
      return snap.docs.where((doc) {
        final m = doc.data() as Map<String, dynamic>? ?? {};
        final createdTs = m['createdAt'] as Timestamp?;
        return createdTs != null && createdTs.toDate().isAfter(lastViewed);
      }).length;
    },
  );
});

final bookingsBadgeProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);
  final uid = user.uid;

  final readRef = FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('bookings');

  final lastViewedStream = readRef.snapshots().map((snap) {
    final data = snap.data() ?? {};
    final ts   = data['lastViewed'] as Timestamp?;
    return ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  final bookingsStream = FirebaseFirestore.instance
    .collection('bookings_collection')
    .where('user_Id', isEqualTo: uid)
    .where('start_Time', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
    .limit(50)
    .snapshots();

  return Rx.combineLatest2<DateTime, QuerySnapshot, int>(
    lastViewedStream,
    bookingsStream,
    (lastViewed, snap) {
      var count = 0;
      for (final doc in snap.docs) {
        final m    = doc.data() as Map<String, dynamic>? ?? {};
        final react = m['reaction'] as Map<String, dynamic>? ?? {};
        final status   = react['status'] as String?;
        final reactedBy= react['reacted_By'] as String?;
        final rawDate  = react['reaction_Date'];
        DateTime? when;
        if (rawDate is Timestamp) {
          when = rawDate.toDate();
        } else if (rawDate is String) when = DateTime.tryParse(rawDate);
        if (when != null
            && (status == 'Cancelled' || status == 'Confirmed')
            && reactedBy != uid
            && when.isAfter(lastViewed)
        ) {
          count++;
        }
      }
      return count;
    },
  );
});

final cardsBadgeProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(0);
  }
  final uid = user.uid;

  final readRef = FirebaseFirestore.instance
    .collection('users_members')
    .doc(uid)
    .collection('reads')
    .doc('cards');

  final lastViewedStream = readRef.snapshots().map((snap) {
    final data = snap.data() ?? {};
    final ts = data['lastViewed'] as Timestamp?;
    return ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
  });

  final txStream = FirebaseFirestore.instance
    .collection('members_cards')
    .doc(uid)
    .collection('card_Transactions')
    .limit(50)
    .snapshots();

  return Rx.combineLatest2<DateTime, QuerySnapshot, int>(
    lastViewedStream,
    txStream,
    (lastViewed, snap) {
      return snap.docs.where((doc) {
        final m = doc.data() as Map<String, dynamic>? ?? {};
        final ts = m['trans_Date'] as Timestamp?;
        if (ts == null) return false;
        return ts.toDate().isAfter(lastViewed);
      }).length;
    },
  );
});

final noticesBadgeProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);
  final uid = user.uid;

  final readRef = FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('notices');

  final lastViewedStream = readRef.snapshots().map((snap) {
    final data = snap.data() ?? {};
    final ts   = data['lastReadAt'] as Timestamp?;
    return ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
  });

  final noticesStream = FirebaseFirestore.instance
    .collection('notices')
    .limit(50)
    .snapshots();

  return Rx.combineLatest2<DateTime, QuerySnapshot, int>(
    lastViewedStream,
    noticesStream,
    (lastViewed, snap) => snap.docs.where((doc) {
      final m      = doc.data() as Map<String, dynamic>? ?? {};
      final addedTs= m['date_Added'] as Timestamp?;
      return addedTs != null && addedTs.toDate().isAfter(lastViewed);
    }).length,
  );
});

/// MARK-READ FUNCTIONS

Future<void> markSubsRead() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('subs')
    .set({'lastViewed': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

Future<void> markBookingsRead() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('bookings')
    .set({'lastViewed': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

Future<void> markCardsRead() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('cards')
    .set({'lastViewed': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

Future<void> markNoticesRead() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('notices')
    .set({'lastReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}
