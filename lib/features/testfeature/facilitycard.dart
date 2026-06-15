import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FacilityCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool hasSlots;

  const FacilityCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.hasSlots = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to booking page
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasSlots ? 'slots available' : 'no slots available',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: hasSlots ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}