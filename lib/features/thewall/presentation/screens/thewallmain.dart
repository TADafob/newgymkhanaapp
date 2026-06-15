import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
import 'package:nrbgymkhana/features/thewall/presentation/providers/thewallcountersproviders.dart';
import 'package:nrbgymkhana/features/thewall/presentation/widgets/dateconfigwidget.dart';

class TheWall extends ConsumerWidget {
  const TheWall({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noticeCount = ref.watch(unreadCountProvider(
      const CollectionConfig(
          collectionPath: 'notices', dateField: 'date_Added'),
    ));
    final eventsCount = ref.watch(unreadCountProvider(
      const CollectionConfig(
          collectionPath: 'events_collection', dateField: 'date_Added'),
    ));
    final lostFoundCount = ref.watch(unreadCountProvider(
      const CollectionConfig(
          collectionPath: 'lostandfound_collection', dateField: 'date_Added'),
    ));
    final facCount = ref.watch(unreadCountProvider(
      const CollectionConfig(
          collectionPath: 'Facilities', dateField: 'date_Added'),
    ));

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8),
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor:
      //       isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8),
      //   systemOverlayStyle: SystemUiOverlayStyle(
      //     statusBarColor:
      //         isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8),
      //     statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
      //     statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      //   ),
      // ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppKolors.primary,
          onRefresh: () async {
            ref.invalidate(unreadCountProvider(
              const CollectionConfig(collectionPath: 'notices', dateField: 'date_Added'),
            ));
            ref.invalidate(unreadCountProvider(
              const CollectionConfig(collectionPath: 'events_collection', dateField: 'date_Added'),
            ));
            ref.invalidate(unreadCountProvider(
              const CollectionConfig(collectionPath: 'lostandfound_collection', dateField: 'date_Added'),
            ));
            ref.invalidate(unreadCountProvider(
              const CollectionConfig(collectionPath: 'Facilities', dateField: 'date_Added'),
            ));
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
                child: CommonTopContainer(
              title: 'The Wall',
              Image_url: 'assets/images/common/calendar.png',
              titleposition: 150,
            )),
            SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: _buildWallSection(
                context: context,
                ref: ref,
                title: 'Club Updates',
                subtitle: 'Stay informed',
                items: [
                  _WallItem(
                    title: 'Notices',
                    icon: Icons.assignment_outlined,
                    color: AppKolors.primary,
                    collectionPath: 'notices',
                    goRoute: '/the-wall/noticeboard-thewall',
                    badgeCount: noticeCount,
                  ),
                  _WallItem(
                    title: 'Events',
                    icon: Icons.calendar_month_outlined,
                    color: AppKolors.accent,
                    collectionPath: 'events_collection',
                    goRoute: '/the-wall/Events-thewall',
                    badgeCount: eventsCount,
                  ),
                  _WallItem(
                    title: 'Facilities',
                    icon: Icons.sports_cricket_outlined,
                    color: const Color(0xFF7c3aed),
                    collectionPath: 'Facilities',
                    goRoute: '/the-wall/club-facilities-thewall',
                    badgeCount: facCount,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            SliverToBoxAdapter(
              child: _buildWallSection(
                context: context,
                ref: ref,
                title: 'Community',
                subtitle: 'Connect with members',
                items: [
                  _WallItem(
                    title: 'Lost & Found',
                    icon: Icons.backpack_outlined,
                    color: const Color(0xFFf59e0b),
                    collectionPath: 'lostandfound_collection',
                    goRoute: '/the-wall/lost-found-thewall',
                    badgeCount: lostFoundCount,
                  ),
                  _WallItem(
                    title: 'Report Issue',
                    icon: Icons.report_outlined,
                    color: const Color(0xFFef4444),
                    collectionPath: 'notices',
                    goRoute: '/the-wall/report-incident',
                    badgeCount: const AsyncValue.data(0),
                    isReport: true,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildWallSection({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required List<_WallItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppKolors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.headline2.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppKolors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D1E33) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : accentColor.withOpacity(0.10),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.85,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: items.map((item) {
                  return GestureDetector(
                    onTap: () async {
                      await markAllRead(item.collectionPath, ref);
                      context.go(item.goRoute);
                    },
                    child: Builder(
                      builder: (context) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final badgeCount = item.badgeCount.maybeWhen(
                          data: (cnt) => cnt,
                          orElse: () => 0,
                        );

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedScale(
                                scale:
                                    0.94, // subtle press effect without controller for simplicity
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color:
                                            item.color.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          item.icon,
                                          size: 24,
                                          color: item.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : AppKolors.textPrimary,
                                          height: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!item.isReport && badgeCount > 0)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFef4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      badgeCount > 99 ? '99+' : '$badgeCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WallItem {
  final String title;
  final IconData icon;
  final Color color;
  final String collectionPath;
  final String goRoute;
  final AsyncValue<int> badgeCount;
  final bool isReport;

  _WallItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.collectionPath,
    required this.goRoute,
    required this.badgeCount,
    this.isReport = false,
  });
}
