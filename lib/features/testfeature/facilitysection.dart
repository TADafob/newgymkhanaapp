import 'package:flutter/material.dart';
import 'package:nrbgymkhana/features/testfeature/colors.dart';
import 'package:nrbgymkhana/features/testfeature/facilitycard.dart';
import 'package:google_fonts/google_fonts.dart';

class FacilitiesSection extends StatelessWidget {
  const FacilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Facility',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            FacilityCard(
              title: 'Squash Court',
              imageUrl: 'https://as2.ftcdn.net/v2/jpg/10/00/69/33/1000_F_1000693396_oQMcBCPrWaIfOU1Kt6M9NAZ3nNEJ74Mn.jpg',
              hasSlots: true,
            ),
            FacilityCard(
              title: 'Cricket Ground',
              imageUrl: 'https://i.pinimg.com/736x/e8/f0/69/e8f0697f338f6bfb8740a34390e806ab.jpg',
              hasSlots: true,
            ),
            FacilityCard(
              title: 'Tennis Court',
              imageUrl: 'https://images.unsplash.com/photo-1567220720374-a67f33b2a6b9?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8dGVubmlzJTIwY291cnR8ZW58MHx8MHx8fDA%3D',
              hasSlots: true,
            ),
            FacilityCard(
              title: 'Badminton Court',
              imageUrl: 'https://t4.ftcdn.net/jpg/03/33/14/19/360_F_333141947_xz1nD223W2f9EW43iZbjGqCRFC3WAgTy.jpg',
              hasSlots: true,
            ),
            FacilityCard(
              title: 'Volleyball Court',
              imageUrl: 'https://thumbs.dreamstime.com/b/outdoor-volleyball-court-blue-surface-metal-fence-city-park-concept-sports-health-340427956.jpg',
              hasSlots: true,
            ),
          ],
        ),
      ],
    );
  }
}