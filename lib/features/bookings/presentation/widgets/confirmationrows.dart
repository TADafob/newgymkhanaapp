import 'package:flutter/material.dart';

class confirmationrow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  const confirmationrow({
    super.key, required this.title, required this.subtitle, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(subtitle, style: TextStyle(color: color),)
      ],
    );
  }
}