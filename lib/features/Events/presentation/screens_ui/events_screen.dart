import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/constraints.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/Events/presentation/providers/eventsproviders.dart'
    as events;
import 'package:nrbgymkhana/features/Events/presentation/providers/eventsproviders.dart';
import 'package:nrbgymkhana/features/Events/presentation/screens_ui/bookedmarkedevents.dart';
import 'package:nrbgymkhana/features/Events/presentation/screens_ui/myticketspage.dart';
import 'package:nrbgymkhana/features/Events/presentation/widgets/eventsbottom.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
import 'package:nrbgymkhana/features/common/widgets/sectionheader.dart';
import 'package:nrbgymkhana/features/Events/presentation/widgets/trendingevents.dart';
import '../../../../core/utils/responsiveness.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingEventsAsync = ref.watch(events.upcomingEventsProvider);
    final pastEventsAsync = ref.watch(events.pastEventsProvider);
    final eventsAsync = ref.watch(events.allEventsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: responsiveLayout(
          smallScreen: _buildSmallScreen(
              context, ref, eventsAsync, upcomingEventsAsync, pastEventsAsync),
          mediumScreen: _buildMediumScreen(
              context, ref, eventsAsync, upcomingEventsAsync, pastEventsAsync),
        ),
      ),
    );
  }

  Widget _buildSmallScreen(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<QuerySnapshot<Map<String, dynamic>>> eventsAsync,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        upcomingEventsAsync,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        pastEventsAsync,
  ) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final constraints = ScreenConstraints(context);

    return Column(
      children: [
        CommonTopContainer(
          title: 'Events Page',
          Image_url: 'assets/images/common/calendar.png',
          titleposition: 150,
        ),
        Expanded(
          child: Column(
            children: [
              _buildTabBar(isDark),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildEventsTab(
                        context, ref, upcomingEventsAsync, pastEventsAsync),
                    BookmarkedEventsPage(),
                    MyTicketsPage(userId: userId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1E33) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TabBar(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          dividerColor: Colors.transparent,
          labelColor: AppKolors.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          indicator: BoxDecoration(
            color: AppKolors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          splashBorderRadius: BorderRadius.circular(10),
          tabs: const [
            Tab(text: 'Events'),
            Tab(text: 'Bookmarks'),
            Tab(text: 'My Tickets'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        upcomingEventsAsync,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        pastEventsAsync,
  ) {
    return upcomingEventsAsync.when(
      data: (upcoming) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(upcomingEventsProvider);
            ref.invalidate(pastEventsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                SectionHeader(title: "Upcoming Events", onSeeAll: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: upcoming.length,
                    itemBuilder: (context, index) {
                      final ev = upcoming[index];
                      final evData = ev.data();
                      final imageUrl = evData['image_Url'] ??
                          'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png';
                      final cats = evData['ticketCategories'];
                      final bool isFree = (evData['isFree'] as bool?) ?? false;
                      final String priceDisplay;
                      if (!isFree && cats is List && cats.isNotEmpty) {
                        final prices = cats
                            .map((c) => (c['price'] as num?)?.toInt() ?? 0)
                            .where((p) => p > 0)
                            .toList();
                        if (prices.isNotEmpty) {
                          prices.sort();
                          priceDisplay = 'From ${NumberFormat('#,###').format(prices.first)}';
                        } else {
                          priceDisplay = evData['price']?.toString() ?? '';
                        }
                      } else {
                        priceDisplay = evData['price']?.toString() ?? '';
                      }
                      return Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: TrendingEventCard(
                          eventId: ev.id,
                          imageUrl: imageUrl,
                          title: evData['title'] ?? '',
                          location: evData['location'] ?? '',
                          date: evData['date'] ?? '',
                          price: priceDisplay,
                          isFree: isFree,
                          onTapped: () => context.go(
                              '/the-wall/Events-thewall/event-details',
                              extra: ev),
                          status: evData['status'] ?? '',
                          isSingleEvent: upcoming.length == 1,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "No upcoming events yet",
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              SectionHeader(title: "Past Events", onSeeAll: () {}),
              const SizedBox(height: 12),
              pastEventsAsync.when(
                data: (past) {
                  if (past.isEmpty) {
                    return Center(
                      child: Text(
                        "No past events yet",
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                    );
                  }
                  return _buildEventsNearYou(context, ref, past);
                },
                loading: () => const PageShimmer(itemCount: 5),
                error: (error, _) =>
                    Center(child: Text('Error loading past events: $error')),
              ),
            ],
          ),
        );
      },
      loading: () => const PageShimmer(itemCount: 5),
      error: (error, _) => Center(child: Text('Error loading events: $error')),
    );
  }

  Widget _buildMediumScreen(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<QuerySnapshot<Map<String, dynamic>>> eventsAsync,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        upcomingEventsAsync,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        pastEventsAsync,
  ) {
    return Center(
      child: SizedBox(
        width: 400,
        child: _buildSmallScreen(
            context, ref, eventsAsync, upcomingEventsAsync, pastEventsAsync),
      ),
    );
  }

  Widget _buildEventsNearYou(
    BuildContext context,
    WidgetRef ref,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> events,
  ) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.65,
      ),
      itemCount: events.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final event = events[index];
        final data = event.data();
        final cats = data['ticketCategories'];
        final bool isFree = (data['isFree'] as bool?) ?? false;
        final String priceDisplay;
        if (!isFree && cats is List && cats.isNotEmpty) {
          final prices = cats
              .map((c) => (c['price'] as num?)?.toInt() ?? 0)
              .where((p) => p > 0)
              .toList();
          if (prices.isNotEmpty) {
            prices.sort();
            priceDisplay = 'From ${NumberFormat('#,###').format(prices.first)}';
          } else {
            priceDisplay = NumberFormat('#,###').format(data['price'] ?? 0);
          }
        } else {
          priceDisplay = isFree ? 'Free' : NumberFormat('#,###').format(data['price'] ?? 0);
        }
        return GestureDetector(
          onTap: () => _navigateToDetails(context, ref, event),
          child: EventCard(
            eventId: event.id,
            imageUrl: data['image_Url'] ?? '',
            title: data['title'] ?? '',
            location: data['location'] ?? '',
            date: data['date'],
            status: data['status'] ?? '',
            price: priceDisplay,
            isFree: isFree,
          ),
        );
      },
    );
  }

  void _navigateToDetails(
    BuildContext context,
    WidgetRef ref,
    QueryDocumentSnapshot<Map<String, dynamic>> event,
  ) {
    context.go('/the-wall/Events-thewall/event-details', extra: event);
  }
}
