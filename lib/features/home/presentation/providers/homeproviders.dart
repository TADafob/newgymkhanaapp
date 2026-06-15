import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:nrbgymkhana/features/app_auths/presentation/providers/auth_provider.dart';

/// USER, NEWS & CARD STREAM PROVIDERS with optimization

/// Provider for fetching user data - cached for 5 minutes
final userStreamProvider = StreamProvider<DocumentSnapshot>((ref) {
  final user = ref.watch(authStateChangesProvider).value?.uid;
  if (user == null) return const Stream<DocumentSnapshot>.empty();
  return FirebaseFirestore.instance
    .collection('users_members')
    .doc(user)
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
  final user = ref.watch(authStateChangesProvider).value?.uid;
  if (user == null) return const Stream<DocumentSnapshot>.empty();
  return FirebaseFirestore.instance
    .collection('members_cards')
    .doc(user)
    .snapshots();
});

/// STREAM PROVIDERS with optimized queries

final subsBadgeProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(0);

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
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(0);

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
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(0);

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
    .collection('notifications_collection')
    .where('recipientId', isEqualTo: uid)
    .where('type', isEqualTo: 'card_update')
    .limit(50)
    .snapshots();

  return Rx.combineLatest2<DateTime, QuerySnapshot, int>(
    lastViewedStream,
    txStream,
    (lastViewed, snap) {
      return snap.docs.where((doc) {
        final m = doc.data() as Map<String, dynamic>? ?? {};
        final ts = m['timestamp'] as Timestamp?;
        if (ts == null) return false;
        return ts.toDate().isAfter(lastViewed) && (m['isNew'] as bool? ?? false);
      }).length;
    },
  );
});

final noticesBadgeProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(0);

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

/// Pending guest-levy payments due within 3 days
final pendingPaymentsBadgeProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(0);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final threeDaysLater = today.add(const Duration(days: 3));

  return FirebaseFirestore.instance
      .collection('bookings_collection')
      .where('user_Id', isEqualTo: uid)
      .where('reaction.isPaid', isEqualTo: false)
      .where('start_Time', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
      .where('start_Time', isLessThanOrEqualTo: Timestamp.fromDate(threeDaysLater))
      .snapshots()
      .asyncMap((snap) async {
        int count = 0;
        for (final doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final participants = data['Participants_Details'] as Map<String, dynamic>? ?? {};
          final guestCount = (participants['guests'] as num?)?.toInt() ?? 0;
          if (guestCount <= 0) continue;
          count++;
          final notifId = 'pending_pay_${doc.id}';
          final notifRef = FirebaseFirestore.instance
              .collection('notifications_collection')
              .doc(notifId);
          final existing = await notifRef.get();
          if (!existing.exists) {
            final startTime = (data['start_Time'] as Timestamp).toDate();
            final daysLeft = startTime.difference(today).inDays;
            final levy = guestCount * 200;
            await notifRef.set({
              'recipientId': uid,
              'type': 'booking',
              'title': 'Guest Levy Payment Due',
              'description': 'You have an unpaid guest levy of KSH $levy for your booking on '
                  '${startTime.day}/${startTime.month}/${startTime.year}. '
                  'Payment is due in $daysLeft day${daysLeft == 1 ? '' : 's'}.',
              'timestamp': FieldValue.serverTimestamp(),
              'isNew': true,
            });
          }
        }
        return count;
      });
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
  // Mark the reads timestamp
  await FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('cards')
    .set({'lastViewed': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  // Mark all unread card notifications as read
  final unread = await FirebaseFirestore.instance
    .collection('notifications_collection')
    .where('recipientId', isEqualTo: uid)
    .where('type', isEqualTo: 'card_update')
    .where('isNew', isEqualTo: true)
    .get();
  final batch = FirebaseFirestore.instance.batch();
  for (final doc in unread.docs) {
    batch.update(doc.reference, {'isNew': false});
  }
  if (unread.docs.isNotEmpty) await batch.commit();
}

Future<void> markNoticesRead() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance
    .collection('users_members').doc(uid)
    .collection('reads').doc('notices')
    .set({'lastReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}
