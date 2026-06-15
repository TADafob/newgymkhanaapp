// lib/features/home/presentation/widgets/quick_navigation_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:nrbgymkhana/core/utils/constraints.dart';
import 'package:nrbgymkhana/features/home/domain/navitems.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/topcontainernavs.dart';

class QuickNavigationCard extends ConsumerWidget {
  const QuickNavigationCard({
    super.key,
    required this.constraints,
    required this.cardData,
    required this.navItems,
  });

  final ScreenConstraints constraints;
  final AsyncValue<DocumentSnapshot> cardData;
  final List<NavigationItem> navItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      height:
          (constraints.screenHeight >= 600 && constraints.screenHeight <= 900)
              ? constraints.height(.295)
              : constraints.height(.26),
      width: constraints.width(.88),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(70),
          topRight: Radius.circular(16),
          topLeft: Radius.circular(16),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a2e35), Color(0xFF2c4a5a)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF07d8c3).withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0693e3).withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CARD BALANCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF07d8c3),
                ),
              ),
              const SizedBox(height: 6),
              cardData.when(
                data: (card) {
                  if (!card.exists) {
                    return Text(
                      'Card not found',
                      style:
                          AppFonts.newstitlebody2.copyWith(color: Colors.red),
                    );
                  }
                  final balance = card['card_Balance'] as num? ?? 0;
                  final formatted = NumberFormat('#,###.00').format(balance);
                  if (balance == 0) {
                    return Row(
                      children: [
                        Text(
                          'Ksh. 0.00',
                          style:
                              context.headline1.copyWith(color: Colors.white60),
                        ),
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.red,
                          child: Text('!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ],
                    );
                  }
                  return Text(
                    'Ksh $formatted',
                    style: context.headline1.copyWith(color: Colors.white),
                  );
                },
                loading: () => const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF07d8c3),
                  ),
                ),
                error: (e, st) => Text('Error: $e',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: navItems
                    .map((item) => _NavItemWithBadge(item: item, ref: ref))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Stack(
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
      ),
    );
  }
}
