import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

class CenterHomeNavs extends StatelessWidget {
  final String title;
  final String imageurl;
  final bool? ischatpage;
  final Icon? icon;
  final VoidCallback onTapped;
  final bool isHomepage;

  const CenterHomeNavs({
    super.key,
    required this.title,
    this.ischatpage = false,
    required this.icon,
    required this.imageurl,
    required this.onTapped,
    this.isHomepage = false, // Default to false if not provided.
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    Widget displayWidget;

    // If it's the homepage, use the icon inside a CircleAvatar.
    if (isHomepage) {
      displayWidget = CircleAvatar(
        backgroundColor: AppKolors.primary,
        radius: 30.w,
        child: Icon(
          icon?.icon ?? Icons.error,
          size: 24.w,
          color: iconColor,
        ),
      );
    } else {
      // If not homepage, check if the imageurl is a network image or asset.
      // (A basic check here; you can adjust this logic as needed.)
      if (imageurl.startsWith('https://') || imageurl.startsWith('http://')) {
        displayWidget = Image.network(
          imageurl,
          height: 75,
          width: 75,
          fit: BoxFit.cover,
        );
      } else {
        displayWidget = Image.asset(
          imageurl,
          height: 75,
          width: 75,
          fit: BoxFit.cover,
        );
      }
    }

    return GestureDetector(
      onTap: onTapped,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          displayWidget,
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
