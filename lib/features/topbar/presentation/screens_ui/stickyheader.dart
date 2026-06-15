import 'package:flutter/material.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? logoAssetPath;
  final String? profileImageUrl;
  final VoidCallback? onProfileTap;

  StickyHeaderDelegate({
    required this.title,
    this.logoAssetPath,
    this.profileImageUrl,
    this.onProfileTap,
    required double maxExtent,
  }) : _maxExtent = maxExtent;

  final double _maxExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.lightBlueAccent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (logoAssetPath != null)
              Image.asset(
                logoAssetPath!,
                height: 30,
                width: 30,
                fit: BoxFit.contain,
              )
            else
              const SizedBox(width: 30), // Placeholder for alignment
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 15,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: profileImageUrl == null
                    ? const Icon(Icons.person, color: Colors.grey, size: 20)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => kToolbarHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}
