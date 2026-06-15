// lib/features/lost_and_found/domain/entities/lost_and_found_item.dart

class LostAndFoundItem {
  final String id;
  final String name;
  final String location;
  final DateTime? dateFound;
  final String image;
  final List<String>? images;
  final String? description;
  final bool isClaimed;
  final bool isCollected;

  const LostAndFoundItem({
    required this.id,
    required this.name,
    required this.location,
    required this.dateFound,
    required this.image,
    this.description,
    this.images,
    required this.isClaimed,
    required this.isCollected,
  });
}
