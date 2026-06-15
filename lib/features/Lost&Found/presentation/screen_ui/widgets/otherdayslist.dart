// lib/features/Lost&Found/presentation/screen_ui/widgets/other_days_list_widget.dart

import 'package:flutter/material.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/entities/item_entities.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/screens/item_detail_page.dart';

class OtherDaysListWidget extends StatelessWidget {
  final List<LostAndFoundItem> items;

  const OtherDaysListWidget({
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withAlpha(100),
                    width: 1.0,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailPage(documentId: item.id),
                  ),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.image,
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Area: ${item.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.isCollected || item.isClaimed)
                      Text(
                        item.isCollected ? 'Collected' : 'Claimed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.isCollected ? Colors.green : Colors.red,
                        ),
                      ),
                    Text(
                      item.dateFound != null
                          ? item.dateFound!
                              .toLocal()
                              .toString()
                              .split(' ')[0]
                          : '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
