// lib/features/home/presentation/widgets/quick_navigation_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/features/home/domain/navitems.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/topcontainernavs.dart';

import '../../../../core/utils/appcolors.dart';
import '../../../../core/utils/appfonts.dart';
import '../../../../core/utils/constraints.dart';

class QuickNavigationCard extends ConsumerWidget {
  const QuickNavigationCard({
    super.key,
    required this.constraints,
    required this.cardData,
    required this.navItems, // ← pull this in!
  });

  final ScreenConstraints constraints;
  final AsyncValue<DocumentSnapshot> cardData;
  final List<NavigationItem> navItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      height:
          (constraints.screenHeight >= 600 && constraints.screenHeight <= 900)
              ? constraints.height(.295)
              : constraints.height(.26),
      width: constraints.width(.88),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(70)),
        color: AppKolors.secondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Balance'),
          const SizedBox(height: 8),
          cardData.when(
            data: (card) {
              if (!card.exists) {
                return Text(
                  'Card not found',
                  style: AppFonts.newstitlebody2.copyWith(color: Colors.red),
                );
              }
              final balance = card['card_Balance'] as num? ?? 0;
              final formatted = NumberFormat('#,###.00').format(balance);
              if (balance == 0) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text('Ksh. 0.00',
                        style: context.headline1.copyWith(color: Colors.grey)),
                    const Positioned(
                      top: -5,
                      right: -17,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text('!',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                  ],
                );
              }
              return Text('Ksh $formatted', style: context.headline1);
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // ← use the passed‐in list instead of recreating it:
            children: navItems
                .map((item) => _NavItemWithBadge(item: item, ref: ref))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Internal widget that reads the provider, shows the badge, and wires the tap
class _NavItemWithBadge extends ConsumerWidget {
  const _NavItemWithBadge({
    required this.item,
    required this.ref,
  });

  final NavigationItem item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final badgeCount = ref.watch(item.badgeProvider).value ?? 0;

    // Combine “markRead” + navigation
    VoidCallback? combinedTap;
    if (badgeCount > 0) {
      combinedTap = () async {
        await item.onDataTap();
        context.go(item.route);
      };
    } else {
      combinedTap = () {
        context.go(item.route);
      };
    }

    return Stack(
      children: [
        topContainerNavs(
          ctitlte: item.title,
          cicon: Icon(item.icon),
          ckolor: item.color,
          onTapped: combinedTap,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}
