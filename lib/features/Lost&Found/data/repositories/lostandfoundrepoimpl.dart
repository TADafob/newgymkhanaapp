import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nrbgymkhana/features/Lost&Found/data/models/item_model.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/entities/item_entities.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/repositories/lostandfoundrepo.dart';

class LostAndFoundRepositoryImpl implements LostAndFoundRepository {
  final FirebaseFirestore _firestore;
  LostAndFoundRepositoryImpl(this._firestore);

  @override
  Stream<List<LostAndFoundItem>> watchAllItems() {
    return _firestore
        .collection('lostandfound_collection')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LostAndFoundItemModel.fromFirestore(doc).toEntity())
            .toList());
  }
}
