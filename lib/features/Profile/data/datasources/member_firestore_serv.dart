import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Stream<Map<String, dynamic>> userRelatedDataStream() {
    final currentDate = DateTime.now();

    // Listen for changes in bookings
    final bookingsStream = _firestore
        .collection('bookings_collection')
        .where('user_Id', isEqualTo: userId)
        .where('booking_Date', isGreaterThanOrEqualTo: currentDate)
        .snapshots();

    // Listen for changes in transactions
    final transactionsStream = _firestore
        .collection('members_cards')
        .where('uid', isEqualTo: userId)
        .snapshots();

    // Listen for changes in subscriptions
    final subscriptionsStream = _firestore
        .collection('subscriptions_collection')
        .where('user_Id', isEqualTo: userId)
        .where('expiry_Date', isGreaterThanOrEqualTo: currentDate)
        .snapshots();

    // Combine all three streams so that updates in any collection trigger a new value.
    return Rx.combineLatest3(
      bookingsStream,
      transactionsStream,
      subscriptionsStream,
      (QuerySnapshot bookingsSnapshot, QuerySnapshot transactionsSnapshot,
          QuerySnapshot subscriptionsSnapshot) {
        final bookingsCount = bookingsSnapshot.docs.length;

        // Process transactions snapshot data.
        int futureTransactions = 0;
        if (transactionsSnapshot.docs.isNotEmpty) {
          final data = transactionsSnapshot.docs.first.data();
          final transactions =
              ((data as Map<String, dynamic>?)?['card_Transactions'] as List<dynamic>?) ?? [];
          futureTransactions = transactions.where((item) {
            final transactionDate =
                (item['trans_Date'] as Timestamp?)?.toDate();
            return transactionDate != null && transactionDate.isAfter(currentDate);
          }).length;
        }

        final subscriptionsCount = subscriptionsSnapshot.docs.length;

        return {
          "bookingsCount": bookingsCount,
          "transactionsCount": futureTransactions,
          "subscriptionsCount": subscriptionsCount,
        };
      },
    );
  }
}
