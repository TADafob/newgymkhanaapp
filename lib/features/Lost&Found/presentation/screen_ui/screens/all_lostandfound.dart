// lib/features/lost_and_found/presentation/screen_ui/screens/all_lost_and_found_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/Lost&Found/domain/entities/item_entities.dart';
import 'package:nrbgymkhana/features/Lost&Found/enums.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/providers/lostfoundproviders.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/imagecarousel.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/statuschip.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/screens/item_detail_page.dart';

class AllLostAndFoundPage extends ConsumerStatefulWidget {
  final DateFilter initialFilter;
  const AllLostAndFoundPage({super.key, this.initialFilter = DateFilter.all});

  @override
  ConsumerState<AllLostAndFoundPage> createState() =>
      _AllLostAndFoundPageState();
}

class _AllLostAndFoundPageState extends ConsumerState<AllLostAndFoundPage> {
  String searchQuery = '';
  late DateFilter selectedFilter;
  late StatusFilter selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    selectedStatusFilter = StatusFilter.all;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(watchAllItemsProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('All Lost & Found')),
      body: itemsAsync.when(
        data: (allItems) {
          // 1) Date‐filter
          var filtered = allItems.where((item) {
            final d = item.dateFound;
            if (d == null) return false;
            switch (selectedFilter) {
              case DateFilter.today:
                return d.year == now.year &&
                    d.month == now.month &&
                    d.day == now.day;
              case DateFilter.last7Days:
                return d.isAfter(now.subtract(const Duration(days: 7))) &&
                    !(d.year == now.year &&
                        d.month == now.month &&
                        d.day == now.day);
              case DateFilter.older:
                return d.isBefore(now.subtract(const Duration(days: 7)));
              case DateFilter.all:
                return true;
            }
          }).toList();

          // 2) Search
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            filtered = filtered
                .where((item) =>
                    item.name.toLowerCase().contains(q) ||
                    item.location.toLowerCase().contains(q))
                .toList();
          }

          // 3) Status filter
          switch (selectedStatusFilter) {
            case StatusFilter.collected:
              filtered = filtered.where((i) => i.isCollected).toList();
              break;
            case StatusFilter.claimed:
            case StatusFilter.notCollected:
              filtered =
                  filtered.where((i) => i.isClaimed && !i.isCollected).toList();
              break;
            case StatusFilter.notClaimed:
              filtered = filtered.where((i) => !i.isClaimed).toList();
              break;
            case StatusFilter.all:
              break;
          }

          return Column(
            children: [
              // Search bar
              Container(
                height: 60,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Focus(
                  child: Builder(
                    builder: (context) {
                      final isFocused = Focus.of(context).hasFocus;
                      return TextField(
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 18),
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by name or location',
                          filled: true,
                          fillColor: isFocused
                              ? Colors.white
                              : Colors.grey.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => searchQuery = v),
                      );
                    },
                  ),
                ),
              ),

              // Filters & count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Date:'),
                        const SizedBox(width: 8),
                        DropdownButton<DateFilter>(
                          value: selectedFilter,
                          items: DateFilter.values
                              .map((f) => DropdownMenuItem(
                                  value: f, child: Text(f.name)))
                              .toList(),
                          onChanged: (f) => setState(() {
                            if (f != null) selectedFilter = f;
                          }),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Status:'),
                        const SizedBox(width: 8),
                        DropdownButton<StatusFilter>(
                          value: selectedStatusFilter,
                          items: StatusFilter.values
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.name)))
                              .toList(),
                          onChanged: (s) => setState(() {
                            if (s != null) selectedStatusFilter = s;
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Show filter summary only if filters are applied
              if (selectedFilter != DateFilter.all ||
                  selectedStatusFilter != StatusFilter.all)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 30, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Date filter chip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Filters: '),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _dateFilterLabel(selectedFilter),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.blue),
                                ),
                              ),
                              // Status filter chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _statusFilterLabel(selectedStatusFilter),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 26,
                          ),
                          // Number of items chip
                          Row(
                            children: [
                              Text('Found: '),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.only(left: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${filtered.length} items',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.deepPurple),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const Divider(),

              // Full list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(watchAllItemsProvider);
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Card(
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ItemDetailPage(documentId: item.id),
                              ),
                            ),

                            // Constrain carousel to avoid leading-too-wide error:
                            leading: SizedBox(
                              width: 80,
                              height: 80,
                              child: ImageCarousel(_extractImages(item)),
                            ),

                            title: Text(item.name),
                            subtitle: Text(item.location),

                            trailing: StatusChip(
                              label: item.isCollected
                                  ? 'Collected'
                                  : item.isClaimed
                                      ? 'Claimed'
                                      : 'Unclaimed',
                              color: item.isCollected
                                  ? Colors.green
                                  : item.isClaimed
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const PageShimmer(itemCount: 5),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<String> _extractImages(LostAndFoundItem item) {
    // 1) Use multi-image list if available
    if (item.images != null && item.images!.isNotEmpty) {
      return item.images!;
    }

    // 2) Else fall back to single-image URL
    if (item.image.isNotEmpty) {
      return [item.image];
    }

    // 3) Nothing available
    return <String>[];
  }

  String _dateFilterLabel(DateFilter f) {
    switch (f) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.last7Days:
        return 'Last 7 Days';
      case DateFilter.older:
        return 'Older';
      case DateFilter.all:
        return 'All Dates';
    }
  }

  String _statusFilterLabel(StatusFilter s) {
    switch (s) {
      case StatusFilter.all:
        return 'All Statuses';
      case StatusFilter.collected:
        return 'Collected';
      case StatusFilter.claimed:
        return 'Claimed';
      case StatusFilter.notCollected:
        return 'Not Collected';
      case StatusFilter.notClaimed:
        return 'Not Claimed';
    }
  }
}
