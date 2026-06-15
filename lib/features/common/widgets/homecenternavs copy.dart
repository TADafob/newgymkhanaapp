import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CenterHomeNavs extends StatefulWidget {
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
    this.isHomepage = false,
  });

  @override
  State<CenterHomeNavs> createState() => _CenterHomeNavsState();
}

class _CenterHomeNavsState extends State<CenterHomeNavs> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF0693e3);

    Widget displayWidget;

    if (widget.isHomepage) {
      displayWidget = Icon(
        widget.icon?.icon ?? Icons.error,
        size: 22.w,
        color: _pressed ? Colors.white : primary,
      );
    } else {
      final imageurl = widget.imageurl;
      final img = (imageurl.startsWith('https://') ||
              imageurl.startsWith('http://'))
          ? Image.network(imageurl, height: 28, width: 28, fit: BoxFit.cover)
          : Image.asset(imageurl, height: 28, width: 28, fit: BoxFit.cover);
      displayWidget = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: img,
      );
    }

    return GestureDetector(
      onTap: widget.onTapped,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: _pressed
              ? primary
              : (isDark
                  ? const Color.fromARGB(255, 255, 255, 255)
                      .withValues(alpha: 0.06)
                  : const Color.fromARGB(255, 247, 248, 240)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _pressed
                ? primary
                : (isDark ? Colors.white12 : const Color(0xFFE5E9EF)),
            width: 1.5,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            displayWidget,
            const SizedBox(height: 7),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: _pressed
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF2c3e50)),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
