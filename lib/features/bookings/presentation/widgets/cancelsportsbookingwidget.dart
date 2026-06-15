import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/bookings/data/models/bookingmodel.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/dateformatterbookings.dart';

void showCancelDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Booking booking,
}) {
  final theme = Theme.of(context);
  
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 32),
            const SizedBox(height: 12),
            Text(
              'Cancel Booking',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this booking?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, color: theme.primaryColor, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Facility', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600)),
                              Text(
                                booking.facilityName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: theme.primaryColor, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600)),
                              Text(
                                booking.bookingDate.toLocal().toIso8601String().split('T')[0],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, color: theme.primaryColor, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Time', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600)),
                              Text(
                                formatDateRangeWithSuffix(booking.startTime, booking.endTime),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  side: BorderSide(color: theme.primaryColor),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'No',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  final bookingDoc = FirebaseFirestore.instance
                      .collection('bookings_collection')
                      .doc(booking.bookingId);
                  final docSnapshot = await bookingDoc.get();
                  if (docSnapshot.exists) {
                    final existingData = docSnapshot.data() as Map<String, dynamic>;
                    bool? isPaid = existingData['reaction']?['isPaid'];
                    await bookingDoc.update({
                      'reaction': {
                        'status': 'Cancelled',
                        'reaction_Date': DateTime.now(),
                        'reacted_By': userId,
                        'reaction_Id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'isPaid': isPaid,
                      },
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Booking cancelled successfully.'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Yes, Cancel',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}