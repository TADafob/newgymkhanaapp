import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider((_) => FirebaseFirestore.instance);
// final lostAndFoundRepositoryProvider = Provider((ref) {
//   final firestore = ref.watch(firestoreProvider);
//   return LostAndFoundRepositoryImpl(firestore);
// });