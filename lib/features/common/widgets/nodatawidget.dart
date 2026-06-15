import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class nodatawidget extends StatelessWidget {
  final String title;
  const nodatawidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.grey;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: textColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Opacity(
              opacity:
                  0.4, // Set the opacity (0.0 is fully transparent, 1.0 is fully opaque)
              child: Image.asset(
                'assets/images/common/logo.png',
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
