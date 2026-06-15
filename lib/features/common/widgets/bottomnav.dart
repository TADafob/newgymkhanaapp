// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// class BottomNavBar extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Access the current location through GoRouter state
//     final location = GoRouterState.of(context).uri.toString(); 

//     return BottomNavigationBar(
//       backgroundColor: Colors.lightBlueAccent,
//       currentIndex: _calculateSelectedIndex(location),
//       onTap: (index) {
//         switch (index) {
//           case 0:
//             GoRouter.of(context).go('/');
//             break;
//           case 1:
//             GoRouter.of(context).go('/calendar');
//             break;
//           case 2:
//             GoRouter.of(context).go('/chat');
//             break;
//           case 3:
//             GoRouter.of(context).go('/profile');
//             break;
//         }
//       },
//       items: [
//         BottomNavigationBarItem(
//           backgroundColor: Colors.lightBlueAccent,
//           icon: Icon(Icons.home),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           backgroundColor: Colors.lightBlueAccent,
//           icon: Icon(Icons.calendar_today),
//           label: 'Calendar',
//         ),
//         BottomNavigationBarItem(
//           backgroundColor: Colors.lightBlueAccent,
//           icon: Icon(Icons.chat),
//           label: 'Chat',
//         ),
//         BottomNavigationBarItem(
//           backgroundColor: Colors.lightBlueAccent,
//           icon: Icon(Icons.person),
//           label: 'Profile',
//         ),
//       ],
//     );
//   }

//   int _calculateSelectedIndex(String location) {
//     if (location == '/') {
//       return 0;
//     }
//     if (location == '/calendar') {
//       return 1;
//     }
//     if (location == '/chat') {
//       return 2;
//     }
//     if (location == '/profile') {
//       return 3;
//     }
//     return 0;
//   }
// }

