import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:nrbgymkhana/core/utils/payment_selector_sheet.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/common/widgets/dateformat.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/africas_talking_service.dart';

Future<void> showConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
  DateTime selectedDate,
  String selectedTimeSlot,
  String selectedFacility,
  String selectedCourt,
  String noOfAttendees,
) async {
  final firestore = FirebaseFirestore.instance;

  // Fetch facility details
  String facilityName = '';
  String facilityImageUrl = '';
  String facilityDescription = '';
  try {
    // selectedFacility is the Firestore doc ID — fetch directly
    final docSnap =
        await firestore.collection('Facilities').doc(selectedFacility).get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      facilityName = data['facility_Name'] ?? 'Unknown Facility';
      facilityImageUrl = data['image'] ?? '';
      facilityDescription =
          data['description'] ?? 'Sports Facility at the club';
    } else {
      // fallback: try querying by facility_Id field
      final q = await firestore
          .collection('Facilities')
          .where('facility_Id', isEqualTo: selectedFacility)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        facilityName = data['facility_Name'] ?? 'Unknown Facility';
        facilityImageUrl = data['image'] ?? '';
        facilityDescription =
            data['description'] ?? 'Sports Facility at the club';
      } else {
        Fluttertoast.showToast(msg: 'Facility not found.');
        return;
      }
    }
  } catch (e) {
    Fluttertoast.showToast(msg: 'Failed to retrieve facility details.');
    return;
  }

  // Price calculation (demo values)
  final totalparticipantCounts =
      ref.read(participantCountsProvider.notifier).state;
  final totalmemberparticipants = totalparticipantCounts['Member'] ?? 0;
  final totalGuestPlayers = totalparticipantCounts['Guest'] ?? 0;
  final totalChildMembers = totalparticipantCounts['Child Member'] ?? 0;
  int total = totalGuestPlayers * 200;

  // Show animated confirmation dialog
  await showGeneralDialog(
    context: context,
    barrierLabel: "Book Facility",
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
        child: child,
      );
    },
    pageBuilder: (dialogContext, animation, secondaryAnimation) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.07,
        vertical: 10,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor.withValues(alpha: 0.95),
              Theme.of(context).cardColor.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: Navigator.of(dialogContext).pop,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Book Facility',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: Navigator.of(dialogContext).pop,
                    ),
                  ),
                ],
              ),
              const Divider(height: 8),

              // Facility Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).canvasColor.withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        facilityImageUrl,
                        width: 80,
                        height: 55,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 55,
                            color: Colors.grey[300],
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 55,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facilityName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            facilityDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                formatDateWithSuffix(selectedDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Booking Details
              _buildSectionHeader(context, "Your Booking"),
              const SizedBox(height: 4),
              _buildEditableRow(
                dialogContext,
                "Date",
                formatDateWithSuffix(selectedDate),
                Icons.calendar_month,
                "change",
              ),
              _buildEditableRow(
                dialogContext,
                "Slot",
                selectedTimeSlot.replaceAll('\n - \n', ' to '),
                Icons.lock_clock,
                "change",
              ),
              _buildEditableRow(
                dialogContext,
                "Court",
                selectedCourt,
                Icons.sports,
                "",
              ),
              const SizedBox(height: 6),

              // Participants
              _buildSectionHeader(context, "Participants Details"),
              const SizedBox(height: 4),
              _buildPriceRow(
                  "Member participants", totalmemberparticipants.toString()),
              if (totalGuestPlayers > 0)
                _buildPriceRow(
                    "Guest participants", totalGuestPlayers.toString()),
              if (totalChildMembers > 0)
                _buildPriceRow(
                    "Child Member participants", totalChildMembers.toString()),
              if (totalGuestPlayers > 0)
                _buildPriceRow("Guest Levy per Facility", "200"),
              const Divider(height: 8),
              _buildPriceRow("Total to be Paid", "Ksh. $total", isTotal: true),
              const SizedBox(height: 8),

              // Policy
              const Text(
                "Cancellation Policy: You can cancel anytime. Court empty 15min after booking time is available for others.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Payments can also be made at the club reception.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Confirm Button
              InkWell(
                onTap: () async {
                  final navContext = Navigator.of(dialogContext).context;
                  Navigator.of(dialogContext).pop();
                  if (totalGuestPlayers > 0) {
                    await _showGuestLevyDialog(
                      navContext,
                      ref,
                      total,
                      selectedDate,
                      selectedTimeSlot,
                      selectedFacility,
                      selectedCourt,
                      facilityName,
                    );
                  } else {
                    await _submitBooking(
                      navContext,
                      ref,
                      selectedDate,
                      selectedTimeSlot,
                      selectedFacility,
                      selectedCourt,
                      facilityName,
                    );
                  }
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007BFF), Color(0xFF00BFFF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Book Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showGuestLevyDialog(
  BuildContext context,
  WidgetRef ref,
  int total,
  DateTime selectedDate,
  String selectedTimeSlot,
  String selectedFacility,
  String selectedCourt,
  String facilityName,
) async {
  bool paymentConfirmed = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Guest Levy Required',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF00A651).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('Total Due',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('KES $total',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00A651))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A guest levy is required for this booking. Pay now via M-Pesa or pay later at the club reception.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Pay Later'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.payment_rounded,
              color: Colors.white, size: 16),
          label: const Text('Pay Now',
              style: TextStyle(color: Colors.white)),
          onPressed: () async {
            Navigator.of(ctx).pop();
            final paid = await showPaymentSelectorSheet(
              context,
              ref,
              amount: total,
              accountRef: 'GuestLevy',
              description: 'Guest Levy Payment',
              title: 'Guest Levy',
            );
            paymentConfirmed = paid == true;
          },
        ),
      ],
    ),
  );

  await _submitBooking(
    context,
    ref,
    selectedDate,
    selectedTimeSlot,
    selectedFacility,
    selectedCourt,
    facilityName,
    paymentConfirmed: paymentConfirmed,
  );
}

/// Standalone pay-only dialog — called from the bookings list card.
Future<void> showPayGuestLevyDialog(
  BuildContext context,
  WidgetRef ref,
  String bookingId,
  int guestLevy,
) async {
  final paid = await showPaymentSelectorSheet(
    context,
    ref,
    amount: guestLevy,
    accountRef: 'GuestLevy',
    description: 'Guest Levy Payment',
    title: 'Guest Levy',
    onSuccess: (_) async {
      await FirebaseFirestore.instance
          .collection('bookings_collection')
          .doc(bookingId)
          .update({'reaction.isPaid': true});
    },
  );
  if (paid == true) {
    Fluttertoast.showToast(
      msg: 'Payment confirmed! Your booking is now marked as paid.',
      backgroundColor: const Color(0xFF00A651),
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}

Widget _buildSectionHeader(BuildContext context, String title) {
  return Row(
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    ],
  );
}

Widget _buildEditableRow(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  String editLabel,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
      ),
      Padding(
        padding: EdgeInsets.only(left: 3.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12.sp,
                    color: Colors.grey[800],
                  ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: Theme.of(context).primaryColorDark,
              ),
              onPressed: Navigator.of(context).pop,
              child: Text(
                editLabel,
                style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black : Colors.grey[700],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 20.w),
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15.sp : 12.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _submitBooking(
  BuildContext context,
  WidgetRef ref,
  DateTime selectedDate,
  String? selectedTimeSlot,
  String selectedFacility,
  String selectedCourt,
  String facilityName, {
  bool paymentConfirmed = false,
  VoidCallback? onBookAnother,
}) async {
  final participantCounts = ref.read(participantCountsProvider.notifier).state;
  final participantsDetails = {
    'members': participantCounts['Member'] ?? 0,
    'guests': participantCounts['Guest'] ?? 0,
    'child_Member': participantCounts['Child Member'] ?? 0,
  };

  if (selectedTimeSlot == null) {
    Fluttertoast.showToast(msg: 'No time slot selected.');
    return;
  }

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    Fluttertoast.showToast(msg: 'User not authenticated.');
    return;
  }

  // parse your time slot
  DateTime selectedSlot;
  try {
    final raw = selectedTimeSlot.split('\n')[0].trim();
    if (raw.contains('-')) {
      final parts = raw.split('-');
      final startStr = parts[0].trim();
      selectedSlot = DateFormat('HH:mm').parseStrict(startStr);
    } else {
      final normalized = raw
          .replaceAllMapped(
              RegExp(r'(\d)([APap])'), (m) => '${m[1]} ${m[2]!.toUpperCase()}')
          .replaceAll('.', '');
      selectedSlot = DateFormat('h:mm a').parseStrict(normalized);
    }
  } catch (e) {
    Fluttertoast.showToast(msg: 'Error parsing time slot.');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final userDoc =
      await firestore.collection('users_members').doc(currentUser.uid).get();
  final memNumber = userDoc.data()?['mem_Number'] as String? ?? 'Member';

  final datePart = DateFormat('yyyy-MM-dd').format(selectedDate);
  final uniqueDocId = '${selectedFacility}_'
      '${selectedCourt}_'
      '${datePart}_'
      '${selectedSlot.hour}_'
      '${selectedSlot.minute}';

  try {
    final dayStart =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    await firestore.runTransaction((tx) async {
      final docRef =
          firestore.collection('bookings_collection').doc(uniqueDocId);
      final snapshot = await tx.get(docRef);
      if (snapshot.exists) {
        throw FirebaseException(
          plugin: 'firestore',
          code: 'already-booked',
          message:
              'This time slot is already booked. Please choose another slot.',
        );
      }

      // Per-day limit check inside the transaction (atomic)
      final existingSnap = await firestore
          .collection('bookings_collection')
          .where('user_Id', isEqualTo: currentUser.uid)
          .where('facility_Id', isEqualTo: selectedFacility)
          .where('booking_Date', isEqualTo: Timestamp.fromDate(dayStart))
          .where('reaction.status', isNotEqualTo: 'Cancelled')
          .where('facility_Type', isEqualTo: 'Sports')
          .count()
          .get();
      if ((existingSnap.count ?? 0) >= 2) {
        throw FirebaseException(
          plugin: 'firestore',
          code: 'limit-reached',
          message: 'You have reached the maximum of 2 bookings for this facility today.',
        );
      }
      tx.set(docRef, {
        'facility_Id': selectedFacility,
        'date_Booked': Timestamp.now(),
        'court_No': selectedCourt,
        'facility_Type': 'Sports',
        'booking_Id': uniqueDocId,
        'booking_Date': Timestamp.fromDate(
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
        ),
        'start_Time': Timestamp.fromDate(DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedSlot.hour,
          selectedSlot.minute,
        )),
        'end_Time': Timestamp.fromDate(DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedSlot.hour + 1,
          selectedSlot.minute,
        )),
        'user_Id': currentUser.uid,
        'Participants_Details': participantsDetails,
        'no_of_Attendees':
            participantCounts.values.fold(0, (sum, n) => sum + n).toString(),
        'reaction': {
          'reaction_Id': '',
          'reaction_Date': Timestamp.now(),
          'status': 'Confirmed',
          'isPaid': paymentConfirmed,
          'reacted_By': currentUser.uid,
        },
        'mem_Number': memNumber,
        'interested_Members': [],
      });
    });

    // On success, send AT notifications then show dialog
    try {
      ref.read(selectedTimeSlotProvider.notifier).state = [];

      // Fetch facility name for the notification message
      final slotStr = selectedTimeSlot.replaceAll('\n - \n', ' - ');
      final dateStr = DateFormat('EEE d MMM').format(selectedDate);
      final phone = userDoc.data()?['phone_Number']?.toString() ?? '';

      if (phone.isNotEmpty) {
        final userName = userDoc.data()?['f_Name']?.toString() ?? 'Member';
        final guestLevy = (participantCounts['Guest'] ?? 0) * 200;
        AfricasTalkingService.sendSportsBookingConfirmation(
          phone: phone,
          userName: userName,
          facilityName: facilityName,
          courtNo: selectedCourt,
          date: dateStr,
          timeSlot: slotStr,
          amountDue: guestLevy > 0 ? guestLevy : null,
        ).catchError((_) {});
        AfricasTalkingService.sendSportsBookingConfirmation(
          phone: phone,
          userName: userName,
          facilityName: facilityName,
          courtNo: selectedCourt,
          date: dateStr,
          timeSlot: slotStr,
          amountDue: guestLevy > 0 ? guestLevy : null,
          channel: ATChannel.whatsapp,
        ).catchError((_) {});
      }

      final successMsg = paymentConfirmed
          ? 'Booking confirmed & payment received!\nReceipt and booking confirmation sent to your email and WhatsApp.'
          : 'Your booking has been confirmed!\nA copy of the booking details has been shared to your WhatsApp and email.';

      await GeneralDialog(
        context,
        ref,
        isSuccess: true,
        isSports: true,
        message: successMsg,
        onBookAnother: onBookAnother,
      );
    } catch (e) {
      // on failure, show error dialog the same way:
      await GeneralDialog(
        context,
        ref,
        isSuccess: false,
        isSports: true,
        message: e.toString(),
      );
    }
  } catch (e, st) {
    if (e is FirebaseException && e.code == 'already-booked') {
      Fluttertoast.showToast(
        msg: e.message ?? 'This slot is already booked.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } else if (e is FirebaseException && e.code == 'limit-reached') {
      Fluttertoast.showToast(
        msg: e.message ?? 'Booking limit reached.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Booking failed, please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint('Unknown booking error: $e\n$st');
    }
  }
}

Future<void> submitMultiSlotBooking(
  BuildContext context,
  WidgetRef ref,
  DateTime selectedDate,
  List<String> selectedSlots,
  String selectedFacility,
  String selectedCourt,
  String noOfAttendees,
  Map<String, int> participantCounts, {
  bool paymentConfirmed = false,
  VoidCallback? onBookAnother,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    Fluttertoast.showToast(msg: 'User not authenticated.');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final participantsDetails = {
    'members': participantCounts['Member'] ?? 0,
    'guests': participantCounts['Guest'] ?? 0,
    'child_Member': participantCounts['Child Member'] ?? 0,
  };
  final totalGuestPlayers = participantCounts['Guest'] ?? 0;
  final guestLevy = totalGuestPlayers * 200;

  // If there are guests, show levy payment sheet first
  if (guestLevy > 0 && context.mounted) {
    bool? proceedWithMpesa;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Guest Levy Required',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00A651).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00A651).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Total Due',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('KES $guestLevy',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00A651))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A guest levy is required for this booking. Pay now via M-Pesa or pay later at the club reception.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Payments can also be made at the club reception.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              proceedWithMpesa = false;
              Navigator.of(ctx).pop();
            },
            child: const Text('Pay Later'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.payment_rounded,
                color: Colors.white, size: 16),
            label: const Text('Pay Now',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              proceedWithMpesa = true;
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
    if (proceedWithMpesa == true && context.mounted) {
      final paid = await showPaymentSelectorSheet(
        context,
        ref,
        amount: guestLevy,
        accountRef: 'GuestLevy',
        description: 'Guest Levy Payment',
        title: 'Guest Levy',
      );
      paymentConfirmed = paid == true;
    }
    // proceedWithMpesa == false → Pay Later → paymentConfirmed stays false, booking proceeds
  }

  // Parse all slots and build booking docs
  final dayStart =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final userDoc = await firestore
      .collection('users_members')
      .doc(currentUser.uid)
      .get();
  final memNumber = userDoc.data()?['mem_Number'] as String? ?? 'Member';
  final datePart = DateFormat('yyyy-MM-dd').format(selectedDate);

  final List<Map<String, dynamic>> bookingDocs = [];
  for (final slot in selectedSlots) {
    DateTime parsedSlot;
    try {
      final raw = slot.split('\n')[0].trim();
      if (raw.contains('-')) {
        parsedSlot =
            DateFormat('HH:mm').parseStrict(raw.split('-')[0].trim());
      } else {
        final normalized = raw
            .replaceAllMapped(
                RegExp(r'(\d)([APap])'),
                (m) => '${m[1]} ${m[2]!.toUpperCase()}')
            .replaceAll('.', '');
        parsedSlot = DateFormat('h:mm a').parseStrict(normalized);
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'Error parsing slot: $slot');
      return;
    }
    final docId = '${selectedFacility}_${selectedCourt}_'
        '${datePart}_${parsedSlot.hour}_${parsedSlot.minute}';
    bookingDocs.add({
      'docId': docId,
      'start': DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, parsedSlot.hour, parsedSlot.minute),
      'end': DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, parsedSlot.hour + 1, parsedSlot.minute),
    });
  }

  // Check daily limit BEFORE the transaction (count() not supported inside transactions)
  final existingSnap = await firestore
      .collection('bookings_collection')
      .where('user_Id', isEqualTo: currentUser.uid)
      .where('facility_Id', isEqualTo: selectedFacility)
      .where('booking_Date', isEqualTo: Timestamp.fromDate(dayStart))
      .where('reaction.status', isNotEqualTo: 'Cancelled')
      .where('facility_Type', isEqualTo: 'Sports')
      .count()
      .get();
  final existing = existingSnap.count ?? 0;
  if (existing + bookingDocs.length > 2) {
    Fluttertoast.showToast(
      msg: 'You can only have 2 bookings for this facility per day. You already have $existing.',
      backgroundColor: Colors.red,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
    return;
  }

  try {
    await firestore.runTransaction((tx) async {
      // ALL reads first
      final docRefs = bookingDocs.map((b) => firestore
          .collection('bookings_collection')
          .doc(b['docId'] as String)).toList();
      final snaps = await Future.wait(docRefs.map((r) => tx.get(r)));
      for (int i = 0; i < snaps.length; i++) {
        if (snaps[i].exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'already-booked',
            message: 'Slot ${(bookingDocs[i]['start'] as DateTime).hour}:00 is already booked.',
          );
        }
      }
      // ALL writes after
      for (int i = 0; i < bookingDocs.length; i++) {
        final b = bookingDocs[i];
        tx.set(docRefs[i], {
          'facility_Id': selectedFacility,
          'date_Booked': Timestamp.now(),
          'court_No': selectedCourt,
          'facility_Type': 'Sports',
          'booking_Id': b['docId'],
          'booking_Date': Timestamp.fromDate(dayStart),
          'start_Time': Timestamp.fromDate(b['start'] as DateTime),
          'end_Time': Timestamp.fromDate(b['end'] as DateTime),
          'user_Id': currentUser.uid,
          'Participants_Details': participantsDetails,
          'no_of_Attendees': noOfAttendees,
          'reaction': {
            'reaction_Id': '',
            'reaction_Date': Timestamp.now(),
            'status': 'Confirmed',
            'isPaid': paymentConfirmed,
            'reacted_By': currentUser.uid,
          },
          'mem_Number': memNumber,
          'interested_Members': [],
        });
      }
    });

    // Reset slots
    ref.read(selectedTimeSlotProvider.notifier).state = [];

    // Fire-and-forget notifications
    final phone = userDoc.data()?['phone_Number']?.toString() ?? '';
    if (phone.isNotEmpty) {
      final facilityDoc = await firestore
          .collection('Facilities')
          .doc(selectedFacility)
          .get();
      final facilityName =
          facilityDoc.data()?['facility_Name'] ?? 'Facility';
      final userName = userDoc.data()?['f_Name']?.toString() ?? 'Member';
      final dateStr = DateFormat('EEE d MMM').format(selectedDate);
      final guestLevy = (participantCounts['Guest'] ?? 0) * 200;
      for (final b in bookingDocs) {
        final slotStr =
            '${DateFormat('h:mm a').format(b['start'] as DateTime)} – '
            '${DateFormat('h:mm a').format(b['end'] as DateTime)}';
        AfricasTalkingService.sendSportsBookingConfirmation(
          phone: phone,
          userName: userName,
          facilityName: facilityName,
          courtNo: selectedCourt,
          date: dateStr,
          timeSlot: slotStr,
          amountDue: guestLevy > 0 ? guestLevy : null,
        ).catchError((_) {});
        AfricasTalkingService.sendSportsBookingConfirmation(
          phone: phone,
          userName: userName,
          facilityName: facilityName,
          courtNo: selectedCourt,
          date: dateStr,
          timeSlot: slotStr,
          amountDue: guestLevy > 0 ? guestLevy : null,
          channel: ATChannel.whatsapp,
        ).catchError((_) {});
      }
    }

    if (context.mounted) {
      final msg = selectedSlots.length > 1
          ? '${selectedSlots.length} slots confirmed!\nA copy has been shared to your WhatsApp and email.'
          : 'Your booking has been confirmed!\nA copy has been shared to your WhatsApp and email.';
      await GeneralDialog(context, ref,
          isSuccess: true, isSports: true, message: msg, onBookAnother: onBookAnother);
    }
  } catch (e) {
    if (e is FirebaseException && e.code == 'already-booked') {
      Fluttertoast.showToast(
          msg: e.message ?? 'A slot is already booked.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG);
    } else if (e is FirebaseException && e.code == 'limit-reached') {
      Fluttertoast.showToast(
          msg: e.message ?? 'Booking limit reached.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG);
    } else {
      Fluttertoast.showToast(
          msg: 'Booking failed. Please try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white);
      debugPrint('Booking error: $e');
    }
    if (context.mounted) {
      await GeneralDialog(context, ref,
          isSuccess: false,
          isSports: true,
          message: 'Sorry, we couldn\'t complete your booking.\nPlease try again.');
    }
  }
}

Future<Object?> GeneralDialog(
  BuildContext context,
  WidgetRef ref, {
  required bool isSuccess,
  required bool isSports,
  required String message,
  double blurSigma = 5.0,
  VoidCallback? onBookAnother,
}) {
  final asset = isSuccess
      ? 'assets/images/common/success.json'
      : 'assets/images/common/error.json';
  final title = isSuccess ? 'Booking Confirmed!' : 'Booking Failed';
  final titleColor = isSuccess ? Colors.green[700]! : Colors.red[700]!;

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Booking Confirmation',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (c, anim, sec, child) =>
        FadeTransition(opacity: anim, child: child),
    pageBuilder: (c, a1, a2) {
      return Stack(
        children: [
          // blur the background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: const SizedBox.expand(),
          ),
          // the dialog itself
          Center(
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                        repeat: false,
                        animate: true,
                        asset,
                        height: 100,
                        width: 100),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    isSuccess
                        ? isSports
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(c).pop();
                                      context.go('/');
                                    },
                                    child: const Text('Home'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(c).pop();
                                      onBookAnother?.call();
                                    },
                                    child: const Text('Book Another'),
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  Navigator.of(c).pop();
                                },
                                child: const Text('Close'),
                              )
                        : ElevatedButton(
                            onPressed: () => Navigator.of(c).pop(),
                            child: const Text('Try again'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
