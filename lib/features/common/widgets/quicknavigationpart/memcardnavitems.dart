import 'package:flutter/material.dart';

class NavigationItem {
  final String title;
  final Icon icon;
  final Color color;
  final VoidCallback onTap;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}