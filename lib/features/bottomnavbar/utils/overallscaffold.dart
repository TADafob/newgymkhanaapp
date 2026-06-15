import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/presentation/providers/notificationcountproviders.dart';
import 'package:nrbgymkhana/features/bottomnavbar/models/destination.dart';
import 'package:nrbgymkhana/features/common/widgets/topBar.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';
import 'package:nrbgymkhana/features/thewall/presentation/providers/thewallcountersproviders.dart';
import 'package:nrbgymkhana/features/thewall/presentation/widgets/dateconfigwidget.dart';
import 'dart:ui';

final wallBadgeProvider = StreamProvider<int>((_) => Stream.value(0));
final profileBadgeProvider = StreamProvider<int>((_) => Stream.value(0));

class OverallScaffold extends ConsumerWidget {
  const OverallScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int currentIndex = navigationShell.currentIndex;
    final currentRoute =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

    if (currentRoute.contains('/calendar/details')) {
      currentIndex = destinations.indexWhere((d) => d.label == 'Wall');
    } else if (currentRoute.contains('/notifications')) {
      currentIndex = destinations.indexWhere((d) => d.label == 'Notif');
    } else {
      currentIndex = currentIndex < destinations.length ? currentIndex : 0;
    }

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

    final homeCount = (ref.watch(subsBadgeProvider).value ?? 0) +
        (ref.watch(bookingsBadgeProvider).value ?? 0) +
        (ref.watch(cardsBadgeProvider).value ?? 0) +
        (ref.watch(noticesBadgeProvider).value ?? 0);

    final wallCount = (noticeCount.value ?? 0) +
        (eventsCount.value ?? 0) +
        (lostFoundCount.value ?? 0) +
        (facCount.value ?? 0);

    final notificationsCount = ref.watch(notificationsBadgeProvider).value ?? 0;
    final profileCount = ref.watch(profileBadgeProvider).value ?? 0;

    final counts = [homeCount, wallCount, notificationsCount, profileCount];

    return Scaffold(
      appBar: const TopAppBar(),
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: _GlassFloatingNavBar(
          currentIndex: currentIndex,
          onDestinationSelected: (int idx) {
            if (idx == navigationShell.currentIndex) {
              navigationShell.goBranch(idx, initialLocation: true);
            } else {
              navigationShell.goBranch(idx);
            }
          },
          counts: counts,
        ),
      ),
    );
  }
}

class _GlassFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final List<int> counts;

  const _GlassFloatingNavBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.08),
                    ]
                  : [
                      const Color(0xFF0693e3).withValues(alpha: 0.12),
                      const Color(0xFF057ab8).withValues(alpha: 0.08),
                    ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFF0693e3).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              destinations.length,
              (index) => _NavBarItem(
                destination: destinations[index],
                isSelected: currentIndex == index,
                badgeCount: counts[index],
                onTap: () => onDestinationSelected(index),
                isDarkMode: isDarkMode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final CustomNavigationDestination destination;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _NavBarItem({
    required this.destination,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              const Color(0xFF0693e3).withValues(alpha: 0.4),
                              const Color(0xFF057ab8).withValues(alpha: 0.3),
                            ]
                          : [
                              const Color(0xFF0693e3).withValues(alpha: 0.25),
                              const Color(0xFF057ab8).withValues(alpha: 0.15),
                            ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.4)
                          : const Color(0xFF0693e3).withValues(alpha: 0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  destination.icon,
                  size: isSelected ? 26 : 22,
                  color: isSelected
                      ? const Color(0xFF0693e3)
                      : isDarkMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.6),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Text(
                    destination.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0693e3),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFef4444),
                      Color(0xFFdc2626),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFef4444).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
