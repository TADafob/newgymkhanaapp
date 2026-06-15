import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:nrbgymkhana/core/utils/constraints.dart';
import 'package:nrbgymkhana/core/utils/greetings.dart';

import 'package:nrbgymkhana/features/home/domain/navitems.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/quicknavigationcard.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';

class TopHomeContainer extends ConsumerWidget {
  const TopHomeContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constraints = ScreenConstraints(context);
    final userData = ref.watch(userStreamProvider);
    final cardData = ref.watch(cardStreamProvider);

    final navItems = <NavigationItem>[
      NavigationItem(
        title: 'Subs',
        icon: Icons.subscriptions_outlined,
        color: AppKolors.primary,
        badgeProvider: subsBadgeProvider,
        onDataTap: () async {
          context.go('/subspage');
          await markSubsRead();
        },
        route: '/subspage',
      ),
      NavigationItem(
        title: 'Bookings',
        icon: Icons.calendar_month_outlined,
        color: AppKolors.accent,
        badgeProvider: bookingsBadgeProvider,
        onDataTap: () async {
          context.go('/book-facility');
          await markBookingsRead();
        },
        route: '/book-facility',
        extraBadgeProvider: pendingPaymentsBadgeProvider,
      ),
      NavigationItem(
        title: 'My Card',
        icon: Icons.credit_card_outlined,
        color: AppKolors.primary,
        badgeProvider: cardsBadgeProvider,
        onDataTap: () async {
          context.go('/card-manager');
          await markCardsRead();
        },
        route: '/card-manager',
      ),
      NavigationItem(
        title: 'Updates',
        icon: Icons.notifications_outlined,
        color: const Color(0xFFf59e0b),
        badgeProvider: noticesBadgeProvider,
        onDataTap: () async {
          context.go('/updates');
          await markNoticesRead();
        },
        route: '/updates',
      ),
    ];

    return SizedBox(
      height: constraints.height(.45),
      child: Stack(
        children: [
          // Bluish top container - taller and floating
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: double.infinity,
                height: constraints.height(.30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppKolors.primary, AppKolors.darkCard],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppKolors.primary.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      // Bubble circles
                      Positioned(top: -30, right: -20, child: _Bubble(80, 0.08)),
                      Positioned(top: 10, right: 60, child: _Bubble(50, 0.06)),
                      Positioned(bottom: -10, left: -20, child: _Bubble(90, 0.07)),
                      Positioned(bottom: 20, left: 80, child: _Bubble(40, 0.05)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  getGreeting(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                _NotificationBell(ref: ref, navItems: navItems),
                              ],
                            ),
                            const SizedBox(height: 6),
                            userData.when(
                              data: (userDoc) {
                                final userData =
                                    userDoc.data() as Map<String, dynamic>? ?? {};
                                final firstName = userData['f_Name'] ?? 'Member';
                                final lastName = userData['l_Name'] ?? '';
                                final userType = userData['mem_Type'] ??
                                    'Nairobi Gymkhana Member';
                                final fullUserType = '$userType Member';
                                final fullName = '$firstName $lastName'.trim();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppKolors.accent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppKolors.accent
                                                .withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        fullUserType,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppKolors.accent,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => Shimmer.fromColors(
                                baseColor: Colors.white24,
                                highlightColor: Colors.white38,
                                child: Container(
                                  height: 28,
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              error: (err, _) {
                                Fluttertoast.showToast(msg: 'Error: $err');
                                return Text('Welcome',
                                    style: AppFonts.headline2
                                        .copyWith(color: Colors.white));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Card balance container - overlapped halfway
          Positioned(
            top: constraints.height(.18),
            left: 0,
            right: 0,
            child: QuickNavigationCard(
              ref: ref,
              cardData: cardData,
              navItems: navItems,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.size, this.opacity);
  final double size;
  final double opacity;

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

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.ref, required this.navItems});
  final WidgetRef ref;
  final List<NavigationItem> navItems;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final totalBadge = navItems.fold<int>(
      0,
      (sum, item) =>
          sum +
          (ref.watch(item.badgeProvider).value ?? 0) +
          (item.extraBadgeProvider != null
              ? ref.watch(item.extraBadgeProvider!).value ?? 0
              : 0),
    );
    return GestureDetector(
      onTap: () => context.go('/notifications'),
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 20),
          ),
          if (totalBadge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFef4444),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    totalBadge > 9 ? '9+' : '$totalBadge',
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
