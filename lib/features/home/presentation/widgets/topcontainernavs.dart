import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

class topContainerNavs extends StatefulWidget {
  final Color ckolor;
  final Icon cicon;
  final String ctitlte;
  final VoidCallback onTapped;

  const topContainerNavs({
    super.key,
    required this.cicon,
    required this.ckolor,
    required this.ctitlte,
    required this.onTapped,
  });

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
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: _pressed ? widget.ckolor : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _pressed ? widget.ckolor : AppKolors.accent.withOpacity(0.22),
            width: 1.2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                      color: widget.ckolor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.cicon.icon!,
              color: _pressed ? Colors.white : Colors.white.withOpacity(0.88),
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              widget.ctitlte,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _pressed ? Colors.white : Colors.white.withOpacity(0.80),
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
