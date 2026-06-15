import 'package:flutter/material.dart';

class CustomNavigationDestination {
  const CustomNavigationDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

const List<CustomNavigationDestination> destinations =
    <CustomNavigationDestination>[
  CustomNavigationDestination(icon: Icons.home, label: 'Home'),
  CustomNavigationDestination(icon: Icons.calendar_today, label: 'Wall'),
  CustomNavigationDestination(icon: Icons.notifications, label: 'Notif'),
  CustomNavigationDestination(icon: Icons.person, label: 'Profile'),
];

// lib/features/common/widgets/nav_bar_item_widget.dart

class NavBarItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const NavBarItemWidget({
    required this.icon,
    required this.label,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final selectedIconColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF80D8FF) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSelected ? 30 : 25,
            color: isSelected ? selectedIconColor : iconColor,
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                fontSize: 10,
              ),
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}
