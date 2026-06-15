import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Optionally, if you need the user id for certain calls:
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Method for user-related data (bookings, transactions, subscriptions)
  Future<Map<String, dynamic>> getUserRelatedData() async {
    final currentDate = DateTime.now();

    // Fetch bookings
    final bookingsQuery = await _firestore
        .collection('bookings_collection')
        .where('user_Id', isEqualTo: userId)
        .where('booking_Date', isGreaterThanOrEqualTo: currentDate)
        .get();

    // Fetch transactions
    final transactionsQuery = await _firestore
        .collection('members_cards')
        .where('uid', isEqualTo: userId)
        .get();

    int futureTransactions = 0;
    if (transactionsQuery.docs.isNotEmpty) {
      final data = transactionsQuery.docs.first.data();
      final transactions = (data['card_Transactions'] as List<dynamic>?) ?? [];
      futureTransactions = transactions.where((item) {
        final transactionDate = (item['trans_Date'] as Timestamp?)?.toDate();
        return transactionDate != null && transactionDate.isAfter(currentDate);
      }).length;
    }

    // Fetch subscriptions
    final subscriptionsQuery = await _firestore
        .collection('subscriptions_collection')
        .where('user_Id', isEqualTo: userId)
        .where('expiry_Date', isGreaterThanOrEqualTo: currentDate)
        .get();

    return {
      "bookingsCount": bookingsQuery.docs.length,
      "transactionsCount": futureTransactions,
      "subscriptionsCount": subscriptionsQuery.docs.length,
    };
  }

  // Method for member data (profile-specific details)
  Future<Map<String, dynamic>> getMemberData(String uid) async {
    final snapshot =
        await _firestore.collection('users_members').doc(uid).get();
    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> getMemberByUserId(String userId) async {
    final query = await _firestore
        .collection('users_members')
        .where('uid', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getMembersByUserIds(
      List<String> userIds) async {
    final List<Map<String, dynamic>> members = [];
    for (final id in userIds) {
      final member = await getMemberByUserId(id);
      if (member != null) {
        members.add(member);
      }
    }
    return members;
  }
}
