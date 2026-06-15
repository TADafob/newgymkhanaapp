import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingGameForm extends ConsumerWidget {
  final String facilityName;
  final String imageUrl;
  final int numberOfCourts;
  final VoidCallback? onBookingConfirmed;

  const BookingGameForm({super.key, 
    required this.facilityName,
    required this.imageUrl,
    required this.numberOfCourts,
    this.onBookingConfirmed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod providers
    final selectedTabProvider = StateProvider<int>((ref) => 0); 
    final selectedCourtProvider = StateProvider<int>((ref) => 1); // Court number starts from 1
    final participantCountsProvider = StateProvider<Map<String, int>>(
      (ref) => {
        'Member': 0,
        'Child Member': 0,
        'Guest': 0,
        'Marker': 0,
      },
    );

    final selectedTab = ref.watch(selectedTabProvider);
    final selectedCourt = ref.watch(selectedCourtProvider);
    final participantCounts = ref.watch(participantCountsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility Image and Name
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Text(
                  facilityName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Header Tabs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedTab == 0 ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Today',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedTab == 1 ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Tomorrow',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Court Selection
          Text('Select Court', style: TextStyle(fontSize: 16)),
          Wrap(
            spacing: 10,
            children: List.generate(numberOfCourts, (index) {
              final courtNumber = index + 1;
              return ChoiceChip(
                label: Text('Court $courtNumber'),
                selected: selectedCourt == courtNumber,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedCourtProvider.notifier).state = courtNumber;
                  }
                },
              );
            }),
          ),
          SizedBox(height: 16),

          // Start Time
          Text('Start Time', style: TextStyle(fontSize: 16)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('6:00 AM (2 Players Slot Available)', style: TextStyle(fontSize: 16)),
                Icon(Icons.access_time, color: Colors.grey),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Participants
          ...participantCounts.keys.map((type) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type, style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        final counts = Map<String, int>.from(participantCounts);
                        if (counts[type]! > 0) {
                          counts[type] = counts[type]! - 1;
                          ref.read(participantCountsProvider.notifier).state = counts;
                        }
                      },
                    ),
                    Text(
                      participantCounts[type]!.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        final counts = Map<String, int>.from(participantCounts);
                        counts[type] = counts[type]! + 1;
                        ref.read(participantCountsProvider.notifier).state = counts;
                      },
                    ),
                  ],
                ),
              ],
            );
          }),
          SizedBox(height: 16),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBookingConfirmed,
              child: Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}
