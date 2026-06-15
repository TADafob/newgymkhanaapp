import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/constraints.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/features/common/widgets/quicknavigationpart/memcardnavitems.dart';

class QuickNavigationCard extends StatelessWidget {
  const QuickNavigationCard({
    super.key,
    required this.constraints,
    required this.cardData,
    required this.navItems,
    this.onStatementPressed,
  });

  final ScreenConstraints constraints;
  final AsyncValue<DocumentSnapshot<Object?>> cardData;
  final List<NavigationItem> navItems;
  final VoidCallback? onStatementPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppKolors.primary, AppKolors.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppKolors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative bubbles
            Positioned(top: -30, right: -20, child: _Bubble(120, 0.07)),
            Positioned(top: 20, right: 80, child: _Bubble(60, 0.05)),
            Positioned(bottom: -20, left: -20, child: _Bubble(100, 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.credit_card_rounded,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Card Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      if (onStatementPressed != null)
                        GestureDetector(
                          onTap: onStatementPressed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Statement',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Balance
                  cardData.when(
                    data: (card) {
                      if (!card.exists) {
                        return const Text('Card not found',
                            style: TextStyle(color: Colors.redAccent, fontSize: 14));
                      }
                      final balance = card['card_Balance'] ?? 0;
                      final formatted = NumberFormat('#,###.00').format(balance);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Ksh $formatted',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (balance == 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.5)),
                              ),
                              child: const Text(
                                'Low Balance',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                    error: (e, _) => Text('Error: $e',
                        style: const TextStyle(color: Colors.redAccent)),
                  ),

                  const SizedBox(height: 18),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: navItems
                        .map((item) => _ActionButton(item: item))
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

class _ActionButton extends StatelessWidget {
  final NavigationItem item;
  const _ActionButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: item.color.withOpacity(0.5), width: 1.5),
            ),
            child: IconTheme(
              data: IconThemeData(color: Colors.white, size: 20),
              child: item.icon,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble(this.size, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}
