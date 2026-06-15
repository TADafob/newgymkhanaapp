// lib/features/lost_and_found/data/models/lost_and_found_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/entities/item_entities.dart';
class LostAndFoundItemModel {
  final String id;
  final String name;
  final String location;
  final DateTime? dateFound;
  final String image;
  final bool isClaimed;
  final bool isCollected;

  LostAndFoundItemModel({
    required this.id,
    required this.name,
    required this.location,
    required this.dateFound,
    required this.image,
    required this.isClaimed,
    required this.isCollected,
  });

  factory LostAndFoundItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostAndFoundItemModel(
      id: doc.id,
      name: data['item_Name'] as String,
      location: data['location'] as String,
      dateFound: (data['date_Found'] as Timestamp?)?.toDate(),
      image: data['image'] as String? ?? '',
      isClaimed: (data['reaction']?['isClaimed'] ?? false) as bool,
      isCollected: (data['reaction']?['isCollected'] ?? false) as bool,
    );
  }

  /// Converts this data-model into the domain-level entity.
  LostAndFoundItem toEntity() {
    return LostAndFoundItem(
      id: id,
      name: name,
      location: location,
      dateFound: dateFound,
      image: image,
      isClaimed: isClaimed,
      isCollected: isCollected,
    );
  }
}
