import 'package:nrbgymkhana/features/Lost&Found/domain/entities/item_entities.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/repositories/lostandfoundrepo.dart';

class WatchAllItems {
  final LostAndFoundRepository _repo;
  WatchAllItems(this._repo);

  Stream<List<LostAndFoundItem>> call() => _repo.watchAllItems();
}
