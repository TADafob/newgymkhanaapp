import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/providers/lostfoundproviders.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/detailrow.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/imagecarousel.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/statuschip.dart';
import '../widgets/claim_button.dart';

class ItemDetailPage extends ConsumerWidget {
  final String documentId;
  const ItemDetailPage({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemAsync = ref.watch(itemProvider(documentId));

    return itemAsync.when(
      data: (snap) {
        if (!snap.exists) {
          return _buildNotFound(context, theme);
        }

        final data = snap.data()! as Map<String, dynamic>;
        final isClaimed = data['reaction']?['isClaimed'] ?? false;
        final isCollected = data['reaction']?['isCollected'] ?? false;
        final List<String> images = _extractImages(data);

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(data['item_Name'] ?? 'Unknown'),
                  expandedHeight: 250,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ImageCarousel(images),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StatusChip(
                            label: isClaimed ? "Claimed" : "Available",
                            color: isClaimed
                                ? AppKolors.accent3
                                : theme.colorScheme.primary,
                          ),
                          StatusChip(
                            label: isCollected ? "Collected" : "In Storage",
                            color: isCollected
                                ? Colors.green.shade600
                                : theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      DetailRow(
                        icon: Icons.calendar_today,
                        text: (data['date_Found'] is Timestamp)
                            ? (data['date_Found'] as Timestamp)
                                .toDate()
                                .toLocal()
                                .toIso8601String()
                                .split('T')[0]
                            : '',
                      ),
                      const SizedBox(height: 16),
                      DetailRow(
                        icon: Icons.location_on,
                        text: data['location'] ?? 'Unknown Location',
                      ),
                      const SizedBox(height: 24),
                      Text("Item Description:",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? 'No description available'),
                      const SizedBox(height: 24),
                      Text("Report ID: $documentId",
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace')),
                      const SizedBox(height: 32),
                      ClaimButton(
                        isClaimed: isClaimed,
                        isCollected: isCollected,
                        documentId: documentId,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "(If you believe this item is yours…)  ",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  Widget _buildNotFound(BuildContext context, ThemeData theme) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text("Item Not Found",
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
              const Text("The requested item could not be found"),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: () => Navigator.pop(context), child: const Text("Back")),
            ],
          ),
        ),
      );

  List<String> _extractImages(Map<String, dynamic> data) {
    final imgField = data['images'];
    if (imgField is List && imgField.isNotEmpty) {
      return imgField.cast<String>();
    }
    final s = data['image'] as String?;
    return (s != null && s.isNotEmpty) ? [s] : [];
  }
}
