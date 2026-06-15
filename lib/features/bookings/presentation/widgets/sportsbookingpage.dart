import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String formatDateWithSuffix(DateTime date) {
    final day = date.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    return '${DateFormat('MMMM').format(date)} $day$suffix ${date.year}';
  }

  Future<void> _showHoverCard(
      BuildContext context, Map<String, dynamic> bookingData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final usersColl = FirebaseFirestore.instance.collection('users_members');
    final bookingUserId =
        bookingData['userId'] ?? bookingData['user_Id'] as String;
    final userDoc = await usersColl.doc(bookingUserId).get();
    final memNumber = userDoc.data()?['mem_Number'] ?? 'Member';

    bool isCurrentUser = bookingUserId == currentUser?.uid;
    String status = bookingData['status'] as String;
    String displayText;
    if (status == 'Unconfirmed') {
      displayText = isCurrentUser
          ? 'Pending Confirmation\n(blocked for you)'
          : 'Pending Confirmation\n(blocked for $memNumber)';
    } else if (status == 'Confirmed') {
      displayText = isCurrentUser
          ? 'Booking Confirmed\nreserved for you'
          : 'Booking Confirmed\nreserved for $memNumber';
    } else {
      displayText = status;
    }

    List<dynamic> interestedMembers =
        bookingData['interested_Members'] as List<dynamic>? ?? [];
    bool alreadyInterested =
        currentUser != null && interestedMembers.contains(currentUser.uid);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8)
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    displayText,
                    style: status == 'Unconfirmed'
                        ? TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppKolors.accent3,
                          )
                        : TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppKolors.accent2,
                          ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (isCurrentUser)
                    Text(
                      'This booking has been made successfully by you',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppKolors.primary.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: alreadyInterested
                          ? null
                          : () {
                              _showInterestButton(
                                  context, bookingData['booking_Id'] as String);
                              Navigator.of(context).pop();
                            },
                      icon: Icon(
                        alreadyInterested
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        alreadyInterested ? 'Interest Shown' : 'Show Interest',
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alreadyInterested
                            ? Colors.grey.shade300
                            : Theme.of(context).primaryColorDark,
                        foregroundColor:
                            alreadyInterested ? Colors.black54 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInterestButton(
      BuildContext context, String bookingId) async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Fluttertoast.showToast(
        msg: 'User not logged in.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }
    try {
      final bookingDocRef =
          firestore.collection('bookings_collection').doc(bookingId);
      await firestore.runTransaction((tx) async {
        final snap = await tx.get(bookingDocRef);
        if (!snap.exists) throw Exception('Booking does not exist.');
        List<dynamic> interested =
            snap.data()?['interested_Members'] as List<dynamic>? ?? [];
        if (!interested.contains(currentUser.uid)) {
          interested.add(currentUser.uid);
          tx.update(bookingDocRef, {'interested_Members': interested});
        } else {
          Fluttertoast.showToast(
            msg: 'You have already shown interest.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      });
      Fluttertoast.showToast(
        msg: 'Interest shown successfully; you\'ll be notified when available.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error updating booking: $e');
      Fluttertoast.showToast(
        msg: 'Failed to show interest. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedCourt = ref.watch(selectedCourtProvider);
    final selectedFacility = ref.watch(selectedFacilityProvider);
    final noofattendees = ref.read(participantCountsProvider.notifier).state;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Fluttertoast.showToast(
        msg: 'User not logged in.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return Scaffold(
        body: nodatawidget(
          title: 'User not logged in. Please sign in to continue.',
        ),
      );
    }

    final firestore = FirebaseFirestore.instance;
    final userId = currentUser.uid;

    // build timeSlots list...
    List<String> timeSlots = List.generate(15, (index) {
      final startHour = 7 + index;
      final startTime = DateTime(0, 0, 0, startHour);
      final endTime = startTime.add(const Duration(hours: 1));
      return '${DateFormat('h:mm a').format(startTime)}\n - \n${DateFormat('h:mm a').format(endTime)}';
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Date and Time Slot",
          style: TextStyle(fontSize: 20.w),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DatePicker(
              DateTime.now(),
              height: 90.h,
              initialSelectedDate: selectedDate ?? DateTime.now(),
              selectionColor: AppKolors.secondary.withValues(alpha: 0.9),
              selectedTextColor: AppKolors.background,
              deactivatedColor: AppKolors.accent3.withValues(alpha: 0.4),
              daysCount: 7,
              monthTextStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppKolors.primary.withValues(alpha: 0.8),
              ),
              dayTextStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              dateTextStyle: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
              inactiveDates: _generateDeactivatedDates(),
              onDateChange: (date) {
                final now = DateTime.now();
                final dateLimit = now.add(const Duration(hours: 48));
                // Only allow selecting dates before the 48-hour threshold.
                if (date.isBefore(dateLimit)) {
                  ref.read(selectedDateProvider.notifier).state = date;
                  // Clear previously selected time slot when date changes.
                  ref.read(selectedTimeSlotProvider.notifier).state = [];
                } else {
                  Fluttertoast.showToast(
                    msg: 'You can only select dates within the next 48 hours.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusLegend(
                    Icons.check_circle, 'Available', Colors.lightBlueAccent),
                _buildStatusLegend(Icons.timelapse, 'Pending', Colors.yellow),
                _buildStatusLegend(Icons.block, 'Booked', Colors.red),
                _buildStatusLegend(Icons.lock, 'Blocked', Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<int>(
              future: firestore
                  .collection('bookings_collection')
                  .where('user_Id', isEqualTo: currentUser.uid)
                  .where('facility_Id', isEqualTo: selectedFacility)
                  .where('reaction.status', isEqualTo: 'Confirmed')
                  .where('facility_Type', isEqualTo: 'Sports')
                  .count()
                  .get()
                  .then((snapshot) => snapshot.count ?? 0),
              builder: (context, countSnapshot) {
                final userConfirmedBookingsOnFacility = countSnapshot.data ?? 0;
                final limitReached = userConfirmedBookingsOnFacility >= 2;

                return StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('bookings_collection')
                      .where('booking_Date',
                          isEqualTo: Timestamp.fromDate(
                              selectedDate ?? DateTime.now()))
                      .where('facility_Id', isEqualTo: selectedFacility)
                      .where('reaction.status', isNotEqualTo: 'Cancelled')
                      .where('facility_Type', isEqualTo: 'Sports')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final allBookings = snapshot.data?.docs ?? [];

                    final Map<String, Map<String, dynamic>> slotData = {};
                    for (var doc in allBookings) {
                      try {
                        final start = (doc['start_Time'] as Timestamp).toDate();
                        final slot =
                            '${DateFormat('h:mm a').format(start)}\n - \n${DateFormat('h:mm a').format(start.add(const Duration(hours: 1)))}';
                        slotData[slot] = {
                          'status': doc['reaction']['status'],
                          'userId': doc['user_Id'],
                          'mem_Number': doc['mem_Number'] ?? 'Member',
                          'booking_Id': doc['booking_Id'],
                          'interested_Members': doc['interested_Members'] ?? [],
                        };
                      } catch (_) {}
                    }

                    return GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: 1,
                      ),
                      itemCount: timeSlots.length,
                      itemBuilder: (context, i) {
                        final slot = timeSlots[i];
                        Color color = Colors.lightBlueAccent;
                        bool clickable = true;
                        final now = DateTime.now();
                        final slotStart = DateTime(
                          (selectedDate ?? now).year,
                          (selectedDate ?? now).month,
                          (selectedDate ?? now).day,
                          7 + i,
                        );
                        final slotEnd = slotStart.add(const Duration(hours: 1));
                        final windowEnd = now.add(const Duration(hours: 48));

                        if (slotEnd.isBefore(now) ||
                            slotStart.isAfter(windowEnd)) {
                          clickable = false;
                          color = Colors.grey;
                        }

                        if (slotData.containsKey(slot)) {
                          final s = slotData[slot]!['status'] as String;
                          if (s == 'Confirmed') {
                            color = Colors.red;
                            clickable = false;
                          } else if (s == 'Unconfirmed') {
                            color = Colors.yellow;
                            clickable = false;
                          }
                        }
                        if (limitReached && !slotData.containsKey(slot)) {
                          clickable = false;
                          color = Colors.grey;
                        }

                        return GestureDetector(
                          onTap: () {
                            if (!clickable && slotData.containsKey(slot)) {
                              _showHoverCard(context, slotData[slot]!);
                            } else if (clickable) {
                              ref
                                  .read(selectedTimeSlotProvider.notifier)
                                  .state = [slot];
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: ref
                                      .watch(selectedTimeSlotProvider)
                                      .contains(slot)
                                  ? Colors.pinkAccent
                                  : color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                slot,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      clickable ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Request Booking Button
          Padding(
            padding: EdgeInsets.fromLTRB(
                50.w, 5.h, 50.w, MediaQuery.of(context).padding.bottom + 12.h),
            child: SizedBox(
              height: 45.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKolors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onPressed: () async {
                  final selectedSlots = ref.watch(selectedTimeSlotProvider);
                  if (selectedSlots.isEmpty) {
                    Fluttertoast.showToast(
                      msg: 'Please select a valid time slot.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                    return;
                  }
                  await showConfirmationDialog(
                    context,
                    ref,
                    selectedDate,
                    selectedSlots.first,
                    selectedFacility,
                    selectedCourt,
                    noofattendees.values
                        .fold<int>(0, (p, e) => p + e)
                        .toString(),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18, color: AppKolors.background),
                    const SizedBox(width: 10),
                    Text(
                      "Request Booking",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppKolors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatusLegend(IconData icon, String label, Color color) {
  return Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

List<DateTime> _generateDeactivatedDates() {
  final now = DateTime.now();
  final limit = now.add(const Duration(hours: 48));
  final dates = <DateTime>[];
  for (int i = 0; i < 30; i++) {
    final d = now.add(Duration(days: i));
    if (d.isAfter(limit)) dates.add(d);
  }
  return dates;
}
