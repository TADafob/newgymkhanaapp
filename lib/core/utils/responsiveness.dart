import 'package:flutter/material.dart';

class responsiveLayout extends StatelessWidget {
  final Widget smallScreen;
  final Widget mediumScreen;

  const responsiveLayout({super.key, 
    required this.smallScreen,
    required this.mediumScreen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return smallScreen;
        } else {
          return mediumScreen;
        }
      },
    );
  }
}
