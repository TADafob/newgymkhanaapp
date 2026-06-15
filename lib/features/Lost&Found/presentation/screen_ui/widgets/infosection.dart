import 'package:flutter/material.dart';

Widget InfoSectionWidget(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Card(
      elevation: 0,
      color:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to Claim Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                children: const [
                  WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.info_outline, size: 16),
                    ),
                  ),
                  TextSpan(
                    text: 'Tap any item to view details and claim options',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                children: const [
                  WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.location_on, size: 16),
                    ),
                  ),
                  TextSpan(
                    text: 'Visit reception for item pickup after claiming',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
