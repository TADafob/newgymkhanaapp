import 'package:flutter/material.dart';

class topContainerNavs extends StatelessWidget {
  final Color ckolor;
  final Icon cicon;
  final String ctitlte;
  final VoidCallback onTapped;
  const topContainerNavs(
      {super.key,
      required this.cicon,
      required this.ckolor,
      required this.ctitlte,
      required this.onTapped});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return GestureDetector(
      onTap: onTapped,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              height: 63,
              width: 63,
              decoration: BoxDecoration(
                color: ckolor,
                shape: BoxShape.circle,
              ),
              child: cicon,
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              ctitlte,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
