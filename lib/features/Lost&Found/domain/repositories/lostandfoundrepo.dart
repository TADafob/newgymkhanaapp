import 'package:nrbgymkhana/features/Lost&Found/domain/entities/item_entities.dart';

abstract class LostAndFoundRepository {
  Stream<List<LostAndFoundItem>> watchAllItems();
}
