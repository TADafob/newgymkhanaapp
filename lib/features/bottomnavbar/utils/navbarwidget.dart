// lib/features/bottomnavbar/widgets/home_nav_icon.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/bottomnavbar/models/destination.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';

/// Home‐tab icon+label that also overlays a red dot if *any* badge > 0.
class HomeNavIcon extends ConsumerWidget {
  final bool isSelected;

  const HomeNavIcon({ 
    required this.isSelected, 
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsCount     = ref.watch(subsBadgeProvider).value     ?? 0;
    final bookingsCount = ref.watch(bookingsBadgeProvider).value ?? 0;
    final cardsCount    = ref.watch(cardsBadgeProvider).value    ?? 0;
    final noticesCount  = ref.watch(noticesBadgeProvider).value  ?? 0;

    final hasAnyBadge = (subsCount + bookingsCount + cardsCount + noticesCount) > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        NavBarItemWidget(
          icon: Icons.home,
          label: 'Home',
          isSelected: isSelected,
        ),
        if (hasAnyBadge)
          const Positioned(
            top: -2,
            right: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 8, height: 8),
            ),
          ),
      ],
    );
  }
}
