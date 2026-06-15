import 'package:flutter/material.dart';

class BookingScreen2 extends StatelessWidget {
  // Replace this with your asset image path (see instructions below)
  final _assetImage = 'assets/tennis.jpg';

  const BookingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9F0EE), // soft background to make device pop
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 18, // phone-like vertical card
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    // Top image
                    Positioned.fill(
                      child: Column(
                        children: [
                          Expanded(
                            flex: 60,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    _assetImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // top-left back button
                                Positioned(
                                  left: 16,
                                  top: 16,
                                  child:
                                      _CircleIconButton(icon: Icons.arrow_back),
                                ),
                                // top-right profile/search-like button
                                Positioned(
                                  right: 16,
                                  top: 16,
                                  child: _CircleIconButton(icon: Icons.person),
                                ),
                              ],
                            ),
                          ),
                          Expanded(flex: 40, child: Container()),
                        ],
                      ),
                    ),

                    // Bottom card overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _BottomCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  const _CircleIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.black87),
        onPressed: () {},
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  final Color cardColor = Color(0xFF163B35); // deep green

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row small text + dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outdoor Hard',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('Green Valley Club',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              _VenueDropdown(),
            ],
          ),

          SizedBox(height: 14),
          Text('Reservation Date',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 10),

          // Date selector
          SizedBox(
            height: 62,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(6, (i) {
                // example days 12-17
                int day = 12 + i;
                String weekday =
                    ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'][i % 6];
                bool isSelected = (i == 1); // mimic 13 Mon selected in image
                return Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: _DateCard(
                      day: day, weekday: weekday, selected: isSelected),
                );
              }),
            ),
          ),

          SizedBox(height: 14),
          Text('Select Time',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 10),

          // Time row
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TimeChip('11:10 - 12:10 PM', selected: false),
                SizedBox(width: 8),
                _TimeChip('2:30 - 3:30 PM', selected: true),
                SizedBox(width: 8),
                _TimeChip('4:30 - 4:20 PM', selected: false),
                SizedBox(width: 8),
                _TimeChip('6:00 - 7:00 PM', selected: false),
              ],
            ),
          ),

          SizedBox(height: 18),

          // price + button row
          Row(
            children: [
              Text('\$25',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              SizedBox(width: 6),
              Text('/hour',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                icon: Icon(Icons.sports_tennis_outlined),
                label: Text('Book Match',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _VenueDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text('Valley, A1', style: TextStyle(color: Colors.white)),
          SizedBox(width: 6),
          Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final int day;
  final String weekday;
  final bool selected;

  const _DateCard(
      {required this.day, required this.weekday, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white : Colors.white24;
    final textColor = selected ? Colors.black87 : Colors.white;

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day.toString(),
              style: TextStyle(
                  color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(weekday,
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String text;
  final bool selected;
  const _TimeChip(this.text, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white : Colors.white24;
    final txt = selected ? Colors.black87 : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(text, style: TextStyle(color: txt, fontSize: 13)),
    );
  }
}
