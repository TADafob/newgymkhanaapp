import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';
import '../../app_auths/presentation/providers/auth_provider.dart';

class MenuItem {
  const MenuItem({
    required this.text,
    required this.icon,
    this.hasNotification = false,
  });

  final String text;
  final IconData icon;
  final bool hasNotification; // Add a flag for notifications
}

abstract class MenuItems {
  static const List<MenuItem> firstItems = [
    home,
    share,
    settings,
  ];

  static const List<MenuItem> secondItems = [logout];

  static const home = MenuItem(text: 'Chats', icon: Icons.home, hasNotification: true);
  static const share = MenuItem(text: 'Reports', icon: Icons.share, hasNotification: true);
  static const settings = MenuItem(text: 'Profile', icon: Icons.settings);
  static const logout = MenuItem(text: 'Log Out', icon: Icons.logout);

  static Widget buildItem(MenuItem item) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Icon(item.icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.text,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            if (item.hasNotification)
              Positioned(
                right: -10, // Adjust position as needed
                top: 0,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static void onChanged(BuildContext context, MenuItem item, WidgetRef ref) {
    switch (item) {
      case MenuItems.home:
        debugPrint('Clicked on Chats');
        break;
      case MenuItems.share:
        debugPrint('Clicked on Reports');
        break;
      case MenuItems.settings:
        debugPrint('Clicked on Profile');
        break;
      case MenuItems.logout:
        signOut(ref);
        break;
    }
  }

  static void signOut(WidgetRef ref) {
    ref.read(signOutUseCaseProvider).call();
    ref.invalidate(userStreamProvider);
    ref.invalidate(cardStreamProvider);
  }
}
