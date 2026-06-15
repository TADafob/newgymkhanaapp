import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

class CenterHomeNavs extends StatefulWidget {
  final String title;
  final String imageurl;
  final bool? ischatpage;
  final Icon? icon;
  final VoidCallback onTapped;
  final bool isHomepage;
  final Color accentColor;

  const CenterHomeNavs({
    super.key,
    required this.title,
    this.ischatpage = false,
    required this.icon,
    required this.imageurl,
    required this.onTapped,
    this.isHomepage = false,
    this.accentColor = AppKolors.primary,
  });

  @override
  State<CenterHomeNavs> createState() => _CenterHomeNavsState();
}

class _CenterHomeNavsState extends State<CenterHomeNavs>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget iconWidget;
    if (widget.isHomepage) {
      iconWidget = Icon(
        widget.icon?.icon ?? Icons.error,
        size: 24,
        color: widget.accentColor,
      );
    } else {
      final url = widget.imageurl;
      final img = (url.startsWith('http://') || url.startsWith('https://'))
          ? Image.network(url, width: 26, height: 26, fit: BoxFit.cover)
          : Image.asset(url, width: 26, height: 26, fit: BoxFit.cover);
      iconWidget =
          ClipRRect(borderRadius: BorderRadius.circular(6), child: img);
    }

    return GestureDetector(
      onTap: widget.onTapped,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppKolors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
