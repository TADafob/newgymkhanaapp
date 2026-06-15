import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Substypecontainer extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color outericoncolor;
  final String title;
  final Color containerColor;
  final VoidCallback onPress;
  final String? subtitle;
  final IconData trailingIcon;
  final String? imagePath;

  const Substypecontainer({
    super.key,
    required this.containerColor,
    required this.title,
    required this.outericoncolor,
    required this.icon,
    required this.iconColor,
    required this.onPress,
    this.subtitle,
    this.trailingIcon = Icons.arrow_forward_ios,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: AspectRatio(
        aspectRatio: 0.85,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await HapticFeedback.mediumImpact();
              onPress();
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: containerColor,
                boxShadow: [
                  BoxShadow(
                    color: containerColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Background image ──────────────────────────
                    if (imagePath != null)
                      CachedNetworkImage(
                        imageUrl: imagePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: containerColor),
                        errorWidget: (_, __, ___) =>
                            Container(color: containerColor),
                      ),

                    // ── Gradient overlay ──────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // ── Icon — top right ──────────────────────────
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: outericoncolor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                    ),

                    // ── Title + subtitle — bottom left ────────────
                    Positioned(
                      left: 14,
                      right: 60,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Arrow button — bottom right ───────────────
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          trailingIcon,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
