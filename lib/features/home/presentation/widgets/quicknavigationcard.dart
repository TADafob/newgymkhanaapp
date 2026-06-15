import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/features/home/domain/navitems.dart';

import '../../../../core/utils/appcolors.dart';
import '../../../../core/utils/appfonts.dart';

class QuickNavigationCard extends StatelessWidget {
  const QuickNavigationCard({
    super.key,
    required this.cardData,
    required this.navItems,
    required this.ref,
  });

  final AsyncValue<DocumentSnapshot> cardData;
  final List<NavigationItem> navItems;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a2e35), Color(0xFF2c4a5a)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1a2e35).withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative blobs
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppKolors.accent.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -15,
              left: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppKolors.primary.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance label + chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CARD BALANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: AppKolors.accent,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Balance amount
                  cardData.when(
                    data: (card) {
                      if (!card.exists) {
                        return const Text('Card not found',
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 14));
                      }
                      final balance = card['card_Balance'] as num? ?? 0;
                      final formatted =
                          NumberFormat('#,###.00').format(balance);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Ksh ',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            formatted,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color:
                                  balance == 0 ? Colors.white38 : Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (balance == 0) ...{
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.4)),
                              ),
                              child: const Text('Low',
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          },
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppKolors.accent),
                    ),
                    error: (e, _) =>
                        Text('Error', style: AppFonts.newstitlebody2),
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 14),
                  // Nav pills row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: navItems
                        .map((item) => _NavPill(item: item, ref: ref))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends ConsumerWidget {
  const _NavPill({required this.item, required this.ref});
  final NavigationItem item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final badgeCount = ref.watch(item.badgeProvider).value ?? 0;
    final extraCount = item.extraBadgeProvider != null
        ? ref.watch(item.extraBadgeProvider!).value ?? 0
        : 0;
    final totalCount = badgeCount + extraCount;
    final isPendingPayment = extraCount > 0;

    return GestureDetector(
      onTap: () async {
        if (badgeCount > 0) await item.onDataTap();
        context.go(item.route);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPendingPayment
                  ? Colors.amber.withOpacity(0.15)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPendingPayment
                    ? Colors.amber.withOpacity(0.5)
                    : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: Colors.white.withOpacity(0.9), size: 20),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isPendingPayment
                      ? const Color(0xFFf59e0b)
                      : const Color(0xFFef4444),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$totalCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
