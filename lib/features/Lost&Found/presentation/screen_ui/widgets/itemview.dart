import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/providers/lostfoundproviders.dart';

class ItemDetailPage extends ConsumerStatefulWidget {
  final String documentId;

  const ItemDetailPage({
    super.key,
    required this.documentId,
  });

  @override
  ItemDetailPageState createState() => ItemDetailPageState();
}

class ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  int _current = 0;

  Future<void> claimItem(BuildContext context, WidgetRef ref) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String claimDate = DateTime.now().toUtc().toString();

    bool confirmClaim = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text("Confirm Claim"),
              ],
            ),
            content: const Text(
              "Are you sure you want to claim this item? After claiming, please visit the reception for confirmation and pick up.",
            ),
            actions: [
              OutlinedButton(
                onPressed: Navigator.of(context).pop,
                child: const Text("Cancel"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmClaim) {
      final snackBar = SnackBar(
        content: const Text("Item claimed successfully!"),
        backgroundColor: Colors.green.shade600,
        action: SnackBarAction(label: "OK", onPressed: () {}),
      );

      try {
        await FirebaseFirestore.instance
            .collection("lostandfound_collection")
            .doc(widget.documentId)
            .update({
          "reaction.claimed_By": userId,
          "reaction.claim_Date": claimDate,
          "reaction.isClaimed": true,
        });
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to claim item: $e"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    final theme = Theme.of(context);

    if (imageUrls.isEmpty) {
      return SizedBox(
        height: 250,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 60),
              SizedBox(height: 8),
              Text("No image available"),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          items: imageUrls.map((url) {
            return Builder(
              builder: (BuildContext context) {
                return SizedBox(
                  width: double.infinity,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported, size: 80),
                    ),
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enableInfiniteScroll: imageUrls.length > 1,
            autoPlay: imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: imageUrls.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => setState(() => _current = entry.key),
                  child: Container(
                    width: _current == entry.key ? 16.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: theme.colorScheme.primary.withValues(
                        alpha: _current == entry.key ? 0.9 : 0.4,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context,
      {required String label, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Claimed' || label == 'Available'
                ? label == 'Claimed'
                    ? Icons.check_circle
                    : Icons.hourglass_empty
                : label == 'Collected'
                    ? Icons.done_all
                    : Icons.storage,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemSnapshot = ref.watch(itemProvider(widget.documentId));

    return itemSnapshot.when(
      data: (snapshot) {
        if (!snapshot.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Item Not Found",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("The requested item could not be found"),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: Navigator.of(context).pop,
                    child: const Text("Back"),
                  ),
                ],
              ),
            ),
          );
        }

        final itemData = snapshot.data() as Map<String, dynamic>;
        final isClaimed = itemData['reaction']?['isClaimed'] ?? false;
        final isCollected = itemData['reaction']?['isCollected'] ?? false;

        // Extract images
        List<String> imageUrls = [];
        final dynamic imagesField = itemData['images'];
        if (imagesField is List && imagesField.isNotEmpty) {
          imageUrls = imagesField.map((e) => e.toString()).toList();
        } else if (itemData['image'] != null) {
          final String? singleImage = itemData['image'] as String?;
          if (singleImage != null && singleImage.isNotEmpty) {
            imageUrls = [singleImage];
          }
        }

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(
                    itemData['item_Name'] ?? 'Unknown Item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  expandedHeight: 250,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildImageCarousel(imageUrls),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusChip(
                            context,
                            label: isClaimed ? "Claimed" : "Available",
                            color: isClaimed
                                ? AppKolors.accent3
                                : theme.colorScheme.primary,
                          ),
                          _buildStatusChip(
                            context,
                            label: isCollected ? "Collected" : "In Storage",
                            color: isCollected
                                ? Colors.green.shade600
                                : theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailRow(
                              context,
                              icon: Icons.calendar_today,
                              text: (itemData['date_Found'] is Timestamp)
                                  ? (itemData['date_Found'] as Timestamp)
                                      .toDate()
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0]
                                  : '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildDetailRow(
                              context,
                              icon: Icons.location_on,
                              text:
                                  "${itemData['location'] ?? 'Unknown Location'}",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Item Description:",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        itemData['description'] ?? 'No description available',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Report ID: ${widget.documentId}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.all(20),
                        ),
                        onPressed:
                            isClaimed ? null : () => claimItem(context, ref),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isClaimed
                                ? Icons.check_circle
                                : Icons.add_circle_outline),
                            const SizedBox(width: 12),
                            Text(
                              isCollected
                                  ? "Already Collected"
                                  : isClaimed
                                      ? "Already Claimed"
                                      : "Claim This Item",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "(If you believe this item is yours, please claim it. After claiming, visit the reception for confirmation and pick up.)",
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
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Loading Item Details...",
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 60, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                "Error Loading Item",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                onPressed: () =>
                    ref.invalidate(itemProvider(widget.documentId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
