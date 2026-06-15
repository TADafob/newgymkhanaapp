import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/subscriptions/data/model/subsmodel.dart';

final categoryDataProvider = Provider<Map<String, List<Map<String, String>>>>((ref) {
  return {
    'Membership': [
      {'title': 'Annual Membership', 'imageurl': 'assets/images/subspage/member-card.png'},
      {'title': 'Yoga \nPractices', 'imageurl': 'assets/images/subspage/meditation.png'},
      {'title': 'Chess\n Practices', 'imageurl': 'assets/images/subspage/strategy.png'},
    ],
    'Gym': [
      {'title': 'Couple', 'imageurl': 'assets/images/subspage/couple.png'},
      {'title': 'Individual Member', 'imageurl': 'assets/images/subspage/individual.png'},
      {'title': 'Junior Member', 'imageurl': 'assets/images/subspage/juniors.png'},
    ],
  };
});


final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  return FirebaseFirestore.instance
      .collection('subscriptions_collection')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Subscription(
        subsId: data['subs_Id'],
        subsPlan: data['subs_Plan'],
        subsCatId: data['subs_cat_Id'],
        subsDate: (data['subs_Date'] as Timestamp).toDate(),
        amount: data['amount'],
        isPaid: data['isPaid'],
        status: data['status'], 
        userId: data['user_Id'], 
        expiryDate: data['expiry_Date'],
      );
    }).toList();
  });
});

final subsCategoryProvider = StreamProvider<Map<String, String>>((ref) {
  return FirebaseFirestore.instance
      .collection('Subs_sub_Category')
      .snapshots()
      .map((snapshot) {
    return Map.fromEntries(
      snapshot.docs.map((doc) {
        final data = doc.data();
        return MapEntry(
          doc.id, // Document ID as the key
          data['name'], // Subcategory name
        );
      }),
    );
  });
});


