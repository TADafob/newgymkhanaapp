// lib/features/home/presentation/widgets/top_home_container.dart

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

class TopHomeContainer extends ConsumerStatefulWidget {
  const TopHomeContainer({super.key});

  @override
  _TopHomeContainerState createState() => _TopHomeContainerState();
}

class _TopHomeContainerState extends ConsumerState<TopHomeContainer> {
  @override
  Widget build(BuildContext context) {
    final constraints = ScreenConstraints(context);
    final userData = ref.watch(userStreamProvider);
    final cardData = ref.watch(cardStreamProvider);

    // 1) Build a “config” list of NavigationItems:
    final navItems = <NavigationItem>[
      NavigationItem(
        title: 'Subs',
        icon: Icons.subscriptions,
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
        color: AppKolors.accent2,
        badgeProvider: bookingsBadgeProvider,
        onDataTap: () async {
          context.go('/book-facility');
          await markBookingsRead();
        },
        route: '/book-facility',
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
    ];

    return SizedBox(
      height:
          (constraints.screenHeight >= 600 && constraints.screenHeight <= 900)
              ? constraints.height(.42)
              : constraints.height(.38),
      child: Stack(
        children: [
          // Top greeting bar
          Positioned(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              height: (constraints.screenHeight >= 600 &&
                      constraints.screenHeight <= 900)
                  ? constraints.height(.27)
                  : constraints.height(.24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppKolors.primary,
                    AppKolors.primary.withValues(alpha: 0.85)
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppKolors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   getGreeting(),
                  //   style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                  // ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: userData.when(
                      data: (user) => Text(
                        '${getGreeting()}, ${user['f_Name']}',
                        style: context.headline1,
                      ),
                      loading: () => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 32,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      error: (err, _) {
                        Fluttertoast.showToast(msg: 'Error loading user: $err');
                        return Text('Error', style: AppFonts.newstitlebody2);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Quick nav card ───────────────────────────────
          Positioned(
            top: constraints.height(.11),
            left: constraints.width(.065),
            child: QuickNavigationCard(
              cardData: cardData,
              navItems: navItems, ref: ref, // ← pass our new list
            ),
          ),
        ],
      ),
    );
  }
}
