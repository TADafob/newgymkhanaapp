import 'package:flutter/material.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final String? logoAssetPath;
  final String? profileImageUrl;
  final Color backgroundColor;
  final double expandedHeight;
  final String? headImageAssetPath;
  final String? headTitle;
  final VoidCallback? onProfileTap;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.logoAssetPath,
    this.profileImageUrl,
    this.backgroundColor = Colors.lightBlueAccent,
    this.expandedHeight = 250, // Default expanded height
    this.headImageAssetPath,
    this.headTitle,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      toolbarHeight: kToolbarHeight, // Ensures a visible toolbar when collapsed
      backgroundColor: backgroundColor,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double appBarHeight = constraints.biggest.height;
          final bool isCollapsed = appBarHeight <= kToolbarHeight;

          return FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isCollapsed) ...[
                    // Expanded State Content (Image and Title)
                    if (headImageAssetPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            height: 80,
                            width: 80,
                            color: const Color.fromARGB(255, 254, 206, 47),
                            child: Image.asset(
                              headImageAssetPath!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    if (headTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          headTitle!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ] else ...[
                    // Collapsed State Content (Logo, Title, Profile Pic)
                    Row(
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
                          const SizedBox(
                              width: 30), // Placeholder for alignment
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
                                ? const Icon(Icons.person,
                                    color: Colors.grey, size: 20)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
