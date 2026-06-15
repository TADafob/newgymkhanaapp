import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class NotificationOverlayService {
  static GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void show({
    required String title,
    required String body,
    IconData icon = Icons.notifications_rounded,
    Color iconColor = const Color(0xFF0693e3),
    bool isTopUp = false,
    bool isCardUpdate = false,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    showTopSnackBar(
      overlay,
      _GymkhanaNotifBanner(
        title: title,
        body: body,
        icon: icon,
        iconColor: isCardUpdate
            ? (isTopUp ? const Color(0xFF00C853) : const Color(0xFFD50000))
            : iconColor,
      ),
      displayDuration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 400),
      reverseAnimationDuration: const Duration(milliseconds: 300),
    );
  }
}

class _GymkhanaNotifBanner extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;

  const _GymkhanaNotifBanner({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
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
