import 'package:flutter/material.dart';

class topContainerNavs extends StatefulWidget {
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
  State<topContainerNavs> createState() => _topContainerNavsState();
}

class _topContainerNavsState extends State<topContainerNavs> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTapped,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color:
              _pressed ? widget.ckolor : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                _pressed ? widget.ckolor : Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              (widget.cicon.icon)!,
              color:
                  _pressed ? Colors.white : Colors.white.withValues(alpha: 0.9),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              widget.ctitlte,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _pressed
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
