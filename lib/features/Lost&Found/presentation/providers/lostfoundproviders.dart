import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/Lost&Found/data/repositories/lostandfoundrepoimpl.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/entities/item_entities.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/repositories/lostandfoundrepo.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/usecases/watch_all_items.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/providers/firestore_provider.dart';


// final itemsStreamProvider = StreamProvider.autoDispose((ref) {
//   return FirebaseFirestore.instance
//       .collection('lostandfound_collection')
//       .snapshots()
//       .map((snapshot) {
//     return snapshot.docs.map((doc) {
//       final data = doc.data();
//       return {
//         'id': doc.id, // Ensure document ID is included
//         'name': data['item_Name'] as String,
//         'location': data['location'] as String,
//         'dateFound': (data['date_Found'] as Timestamp?)?.toDate(),
//         'image': data['image'] as String,
//         'reaction': data['reaction'] ?? {}, // Ensure nested field is handled
//       };
//     }).toList();
//   });
// });

final itemProvider = StreamProvider.autoDispose.family<DocumentSnapshot, String>((ref, documentId) {
  return FirebaseFirestore.instance.collection('lostandfound_collection').doc(documentId).snapshots();
});


final lostAndFoundRepoProvider = Provider<LostAndFoundRepository>(
  (ref) => LostAndFoundRepositoryImpl(ref.watch(firestoreProvider)),
);

final watchAllItemsProvider = StreamProvider.autoDispose<List<LostAndFoundItem>>(
  (ref) => WatchAllItems(ref.watch(lostAndFoundRepoProvider))(),
);


