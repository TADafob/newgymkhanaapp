// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// // Provider for fetching user data
// final userStreamProvider = StreamProvider<DocumentSnapshot>((ref) {
//   final user = FirebaseAuth.instance.currentUser;

//   if (user == null) {
//     return Stream<DocumentSnapshot>.empty();
//   }

//   final userId = user.uid;
//   return FirebaseFirestore.instance
//         .collection('users_members')
//         .doc(userId)
//         .snapshots();
// });

// // Provider for fetching news
// final newsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
//   return FirebaseFirestore.instance
//       .collection('news_collection')  
//       .where('is_Published', isEqualTo: true)  
//       .orderBy('posted_At', descending: true)  
//       .snapshots(); 
// });

// // provider for members cards

// final cardStreamProvider = StreamProvider<DocumentSnapshot>((ref) {
//   final user = FirebaseAuth.instance.currentUser; 
//    if (user == null) {
//     return Stream<DocumentSnapshot>.empty();
//   }


//   final userId = user.uid;

//   return FirebaseFirestore.instance
//         .collection('members_cards')       
//         .doc(userId)                    
//         .snapshots();                  
// });


// // 3. Badge counts

// /// Number of “new” subscriptions
// final subsCountProvider = StreamProvider<int>((ref) {
//   final uid = FirebaseAuth.instance.currentUser!.uid;
//   return FirebaseFirestore.instance
//       .collection('subscriptions_collection')
//       .where('userId', isEqualTo: uid)
//       .where('isNew', isEqualTo: true)
//       .snapshots()
//       .map((snap) => snap.docs.length);
// });

// /// Bookings with a status change flag
// final bookingsCountProvider = StreamProvider<int>((ref) {
//   final uid = FirebaseAuth.instance.currentUser!.uid;
//   return FirebaseFirestore.instance
//       .collection('bookings')
//       .where('userId', isEqualTo: uid)
//       .where('statusChanged', isEqualTo: true)
//       .snapshots()
//       .map((snap) => snap.docs.length);
// });

// /// Card-transaction updates
// final transactionsCountProvider = StreamProvider<int>((ref) {
//   final uid = FirebaseAuth.instance.currentUser!.uid;
//   return FirebaseFirestore.instance
//       .collection('cardTransactions')
//       .where('userId', isEqualTo: uid)
//       .where('hasUpdate', isEqualTo: true)
//       .snapshots()
//       .map((snap) => snap.docs.length);
// });

// /// Generic “updates” collection
// final updatesCountProvider = StreamProvider<int>((ref) {
//   final uid = FirebaseAuth.instance.currentUser!.uid;
//   return FirebaseFirestore.instance
//       .collection('updates')
//       .where('userId', isEqualTo: uid)
//       .snapshots()
//       .map((snap) => snap.docs.length);
// });
