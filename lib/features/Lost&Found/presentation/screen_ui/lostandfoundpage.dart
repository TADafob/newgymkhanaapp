// lib/features/Lost&Found/presentation/screen_ui/screens/lostandfoundpage.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/Lost&Found/enums.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/providers/lostfoundproviders.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/screens/all_lostandfound.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/infosection.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/otherdayslist.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/sectionheaderwidget.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/widgets/todayslistwidget.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';

import '../../domain/entities/item_entities.dart';

class LostandFoundPage extends ConsumerWidget {
  const LostandFoundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Now returns AsyncValue<List<LostAndFoundItem>>
    final itemsAsync = ref.watch(watchAllItemsProvider);

    return Scaffold(
      body: responsiveLayout(
        smallScreen: _buildSmallScreen(context, itemsAsync, ref),
        mediumScreen: _buildMediumScreen(context, itemsAsync, ref),
      ),
    );
  }

  Widget _buildSmallScreen(BuildContext context,
      AsyncValue<List<LostAndFoundItem>> itemsAsync, WidgetRef ref) {
    return itemsAsync.when(
      data: (items) {
        final now = DateTime.now();

        // Filter using entity fields
        final todayItems = items.where((item) {
          final d = item.dateFound;
          return d != null &&
              d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        }).toList();

        final last7DaysItems = items.where((item) {
          final d = item.dateFound;
          return d != null &&
              d.isAfter(now.subtract(const Duration(days: 7))) &&
              !(d.year == now.year && d.month == now.month && d.day == now.day);
        }).toList();

        final moreThan7DaysItems = items.where((item) {
          final d = item.dateFound;
          return d != null && d.isBefore(now.subtract(const Duration(days: 7)));
        }).toList();

        final last7Preview = last7DaysItems.length > 3
            ? last7DaysItems.sublist(0, 3)
            : last7DaysItems;
        final moreThan7Preview = moreThan7DaysItems.length > 3
            ? moreThan7DaysItems.sublist(0, 3)
            : moreThan7DaysItems;

        return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(watchAllItemsProvider);
            },
            child: Column(
              children: [
                const CommonTopContainer(
                  title: 'LOST AND FOUND',
                  Image_url: 'assets/images/common/calendar.png',
                  titleposition: 120,
                ),
                Expanded(
                  child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Today
                        if (todayItems.isNotEmpty) ...[
                          SectionHeaderWidget(
                            title: 'Posted Today',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllLostAndFoundPage(
                                    initialFilter: DateFilter.all,
                                  ),
                                ),
                              );
                            },
                          ),
                          TodaysListWidget(items: todayItems),
                        ],

                        // Last 7 days
                        if (last7DaysItems.isNotEmpty) ...[
                          SectionHeaderWidget(
                              title: 'Posted within Last 7 days'),
                          OtherDaysListWidget(items: last7Preview),
                        ],

                        // Older than 7 days
                        if (moreThan7DaysItems.isNotEmpty) ...[
                          SectionHeaderWidget(
                              title: 'Posted More than 7 days ago'),
                          OtherDaysListWidget(items: moreThan7Preview),
                        ],

                        // Info
                        InfoSectionWidget(context),

                        // Empty state
                        if (todayItems.isEmpty &&
                            last7DaysItems.isEmpty &&
                            moreThan7DaysItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'No lost and found items available',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          ),
                      ]),
                ),
              ],
            ));
      },
      loading: () => const PageShimmer(itemCount: 5),
      error: (error, _) => Center(child: Text('Error loading items: $error')),
    );
  }

  Widget _buildMediumScreen(BuildContext context,
      AsyncValue<List<LostAndFoundItem>> itemsAsync, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: _buildSmallScreen(context, itemsAsync, ref),
      ),
    );
  }
}
