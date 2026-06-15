import 'package:flutter/material.dart';

class ScreenConstraints {
  final BuildContext context;

  ScreenConstraints(this.context);

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  double height(double percentage) => screenHeight * percentage;
  double width(double percentage) => screenWidth * percentage;

  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;
  bool get isLargeScreen => screenWidth >= 1200;
}
