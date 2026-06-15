// // lib/features/home/presentation/widgets/top_home_container.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:go_router/go_router.dart';
// import 'package:shimmer/shimmer.dart';

// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/core/utils/appfonts.dart';
// import 'package:nrbgymkhana/core/utils/constraints.dart';
// import 'package:nrbgymkhana/core/utils/greetings.dart';

// import 'package:nrbgymkhana/features/home/domain/navitems.dart';
// import 'package:nrbgymkhana/features/home/presentation/widgets/quicknavigationcard.dart';
// import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';

// class TopHomeContainer extends ConsumerStatefulWidget {
//   const TopHomeContainer({super.key});

//   @override
//   _TopHomeContainerState createState() => _TopHomeContainerState();
// }

// class _TopHomeContainerState extends ConsumerState<TopHomeContainer> {
//   @override
//   Widget build(BuildContext context) {
//     final constraints = ScreenConstraints(context);
//     final userData = ref.watch(userStreamProvider);
//     final cardData = ref.watch(cardStreamProvider);

//     // 1) Build a “config” list of NavigationItems:
//     final navItems = <NavigationItem>[
//       NavigationItem(
//         title: 'Subs',
//         icon: Icons.subscriptions,
//         color: AppKolors.primary,
//         badgeProvider: subsBadgeProvider,
//         onDataTap: () async {
//           context.go('/subspage');
//           await markSubsRead();
//         },
//         route: '/subspage',
//       ),
//       NavigationItem(
//         title: 'Bookings',
//         icon: Icons.calendar_month_outlined,
//         color: AppKolors.accent2,
//         badgeProvider: bookingsBadgeProvider,
//         onDataTap: () async {
//           context.go('/book-facility');
//           await markBookingsRead();
//         },
//         route: '/book-facility',
//       ),
//       NavigationItem(
//         title: 'My Card',
//         icon: Icons.credit_card_outlined,
//         color: AppKolors.primary,
//         badgeProvider: cardsBadgeProvider,
//         onDataTap: () async {
//           context.go('/card-manager');
//           await markCardsRead();
//         },
//         route: '/card-manager',
//       ),
//       NavigationItem(
//         title: 'Updates',
//         icon: Icons.update_outlined,
//         color: AppKolors.accent3,
//         badgeProvider: noticesBadgeProvider,
//         onDataTap: () async {
//           context.go('/updates');
//           await markNoticesRead();
//         },
//         route: '/updates',
//       ),
//     ];

//     return SizedBox(
//       height:
//           (constraints.screenHeight >= 600 && constraints.screenHeight <= 900)
//               ? constraints.height(.42)
//               : constraints.height(.38),
//       child: Stack(
//         children: [
//           // Top greeting bar - now floating
//           Positioned(
//             child: Transform.translate(
//               offset: const Offset(0, -10),
//               child: Material(
//                 elevation: 8,
//                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
//                 child: Container(
//                   height: (constraints.screenHeight >= 600 &&
//                       constraints.screenHeight <= 900)
//                     ? constraints.height(.40)
//                     : constraints.height(.36),
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//                   decoration: BoxDecoration(
//                     color: AppKolors.primary,
//                     borderRadius: const BorderRadius.vertical(
//                       bottom: Radius.circular(50),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.25),
//                         blurRadius: 25,
//                         offset: const Offset(0, 10),
//                       ),
//                     ],
//                   ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Text(
//                   //   getGreeting(),
//                   //   style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
//                   // ),
//                   const SizedBox(height: 15),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 0),
//                     child: userData.when(
//                       data: (user) => Text(
//                         '${getGreeting()}, ${user['f_Name']}',
//                         style: context.headline1,
//                       ),
//                       loading: () => Shimmer.fromColors(
//                         baseColor: Colors.grey[300]!,
//                         highlightColor: Colors.grey[100]!,
//                         child: Container(
//                           height: 32,
//                           width: 150,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         ),
//                       ),
//                       error: (err, _) {
//                         Fluttertoast.showToast(msg: 'Error loading user: $err');
//                         return Text('Error', style: AppFonts.newstitlebody2);
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // ─── Quick nav card ───────────────────────────────
//           Positioned(
//             top: constraints.height(.22),
//             left: constraints.width(.065),
//             child: QuickNavigationCard(
//               constraints: constraints,
//               cardData: cardData,
//               navItems: navItems,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
