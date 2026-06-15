import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A model representing an item in the bottom navigation or quick-nav area.
/// It now carries its own badge provider and read-mark callback.
class NavigationItem {
  /// The title label shown below the icon.
  final String title;

  /// The icon to display.
  final IconData icon;

  /// The accent color for the icon/text.
  final Color color;

  /// The named route or path to navigate on tap.
  final String route;

  /// A Riverpod provider that emits the current badge count.
  final StreamProvider<int> badgeProvider;

  /// Called when the user taps while there are unread items.
  /// Should mark items as "read" in Firestore (timestamp or per-item).
  final Future<void> Function() onDataTap;

  /// An optional second badge provider whose count is added to badgeProvider.
  final StreamProvider<int>? extraBadgeProvider;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    required this.badgeProvider,
    required this.onDataTap,
    this.extraBadgeProvider,
  });
}
