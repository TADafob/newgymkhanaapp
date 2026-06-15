// lib/features/Lost&Found/presentation/screen_ui/widgets/section_header_widget.dart

import 'package:flutter/material.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const SectionHeaderWidget({
    required this.title,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title + underline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
              ),
              Divider(
                endIndent: 7,
                color: primary.withAlpha(100),
              ),
            ],
          ),

          // Optional “See All Items” button
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(foregroundColor: primary),
              child: const Text('See All Items'),
            ),
        ],
      ),
    );
  }
}
