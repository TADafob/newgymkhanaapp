// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/core/utils/appfonts.dart';
// import 'package:nrbgymkhana/core/utils/constraints.dart';
// import 'package:nrbgymkhana/core/utils/greetings.dart';
// import 'package:nrbgymkhana/features/common/widgets/quicknavigationpart/navitems.dart';
// import 'package:nrbgymkhana/features/common/widgets/quicknavigationpart/quicknavigationcard.dart';
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

//     return SizedBox(
//       height: constraints.screenHeight >= 600 && constraints.screenHeight <= 900 ?  constraints.height(.42) : constraints.height(.38),
//       child: Stack(
//         children: [
//           Positioned(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//               height: constraints.screenHeight >= 600 && constraints.screenHeight <= 900 ?  constraints.height(.27) : constraints.height(.24),
//               width: double.maxFinite,
//               decoration: BoxDecoration(
//                 color: AppKolors.primary,
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(50),
//                   bottomRight: Radius.circular(50),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     getGreeting(), // Dynamic greeting
//                     style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 20),
//                     child: userData.when(
//                       data: (user) => Text(
//                         user['f_Name'], 
//                         style: AppFonts.headline1,
//                       ),
//                       loading: () => CircularProgressIndicator(),
//                       error: (error, stack) => Text('Error: $error'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Positioned(
//             top: constraints.height(.11),
//             left: constraints.width(.065),
//             child: QuickNavigationCard(
//               constraints: constraints, 
//               cardData: cardData, 
//               navItems: [
//                 NavigationItem(
//       title: 'Subs',
//       icon: Icon(Icons.card_membership_outlined),
//       color: AppKolors.accent,
//       onTap: () => context.go('/subspage'),
//     ),
//     NavigationItem(
//       title: 'Bookings',
//       icon: Icon(Icons.calendar_month_outlined),
//       color: AppKolors.accent2,
//       onTap: () => context.go('/book-facility'),
//     ),
//     NavigationItem(
//       title: 'My Card',
//       icon: Icon(Icons.credit_card_outlined),
//       color: AppKolors.primary,
//       onTap: () => context.go('/card-manager'),
//     ),
//     NavigationItem(
//       title: 'Updates',
//       icon: Icon(Icons.update_outlined),
//       color: AppKolors.accent3,
//       onTap: () => context.go('/news'),
//     ),
//               ],),
//           ),
//         ],
//       ),
//     );
//   }
// }

