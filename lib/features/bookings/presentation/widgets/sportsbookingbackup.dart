// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:date_picker_timeline/date_picker_timeline.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
// import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
// import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';

// class BookingPage extends ConsumerWidget {
//   const BookingPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final selectedDate = ref.watch(selectedDateProvider);
//     final selectedCourt = ref.watch(selectedCourtProvider);
//     final selectedFacility = ref.watch(selectedFacilityProvider);
//     final noofattendees =
//         ref.read(participantCountsProvider.notifier).state;

//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) {
//       Fluttertoast.showToast(
//         msg: 'User not logged in.',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//       return Scaffold(
//         body: nodatawidget(
//           title: 'User not logged in. Please sign in to continue.',
//         ),
//       );
//     }
//     final firestore = FirebaseFirestore.instance;
//     final userId = currentUser.uid;

//     // Generate the list of time slots from 7:00 AM to 8:00 PM.
//     List<String> timeSlots = List.generate(15, (index) {
//       final startHour = 7 + index;
//       final startTime = DateTime(0, 0, 0, startHour);
//       final endTime = startTime.add(const Duration(hours: 1));
//       return '${DateFormat('h:mm a').format(startTime)}\n - \n${DateFormat('h:mm a').format(endTime)}';
//     });
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Select Date and Time Slot", style: TextStyle(fontSize: 20.w),),
//       ),
//       body: Column(
//         children: [
//           // Date Picker
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: DatePicker(
//               DateTime.now(),
//               height: 100,
//               initialSelectedDate: selectedDate ?? DateTime.now(),
//               selectionColor: AppKolors.secondary,
//               selectedTextColor: AppKolors.background,
//               deactivatedColor: AppKolors.accent3,
//               inactiveDates: _generateDeactivatedDates(),
//               onDateChange: (date) {
//                 final now = DateTime.now();
//                 final dateLimit = now.add(const Duration(hours: 48));
//                 // Only allow selecting dates before the 48-hour threshold.
//                 if (date.isBefore(dateLimit)) {
//                   ref.read(selectedDateProvider.notifier).state = date;
//                   // Clear previously selected time slot when date changes.
//                   ref.read(selectedTimeSlotProvider.notifier).state = null;
//                 } else {
//                   Fluttertoast.showToast(
//                     msg: 'You can only select dates within the next 48 hours.',
//                     toastLength: Toast.LENGTH_SHORT,
//                     gravity: ToastGravity.BOTTOM,
//                   );
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 30),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(children: [
//                   Container(
//                     height: 10,
//                     width: 10,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.lightBlueAccent,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   const Text('Available', style: TextStyle(fontSize: 12)),
//                 ]),
//                 Row(children: [
//                   Container(
//                     height: 10,
//                     width: 10,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.yellow,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   const Text('Pending', style: TextStyle(fontSize: 12)),
//                 ]),
//                 Row(children: [
//                   Container(
//                     height: 10,
//                     width: 10,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.red,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   const Text('Booked', style: TextStyle(fontSize: 12)),
//                 ]),
//                 Row(children: [
//                   Container(
//                     height: 10,
//                     width: 10,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   const Text('Blocked', style: TextStyle(fontSize: 12)),
//                 ])
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           // Time Slot Selection Grid
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: firestore
//                   .collection('bookings_collection')
//                   .where('booking_Date',
//                       isEqualTo: Timestamp.fromDate(
//                           selectedDate ?? DateTime.now()))
//                   .where('facility_Id', isEqualTo: selectedFacility)
//                   .where('court_No', isEqualTo: selectedCourt)
//                   .where('reaction.status', isNotEqualTo: 'Cancelled')
//                   .where('facility_Type',
//                       isEqualTo: 'Sports') // Only slot-based bookings
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                       child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(
//                       child: Text('Error: ${snapshot.error}'));
//                 }

//                 final allBookings = snapshot.data?.docs ?? [];
//                   final userBookings = allBookings.where((doc) => doc['user_Id'] == userId).toList();
//                   final bool isBookingLimitReached = userBookings.length >= 2;

//                   // Instead of Map<String, String>, we store booking details
//                   Map<String, Map<String, dynamic>> slotBookingData = {};
//                   for (var doc in allBookings) {
//                     try {
//                       DateTime startTime = (doc['start_Time'] as Timestamp).toDate();
//                       String timeSlot =
//                           '${DateFormat('h:mm a').format(startTime)}\n - \n${DateFormat('h:mm a').format(startTime.add(const Duration(hours: 1)))}';
//                       String status = doc['reaction']['status'];
//                       slotBookingData[timeSlot] = {
//                         'status': status,
//                         'userId': doc['user_Id'],
//                         'mem_Number': doc['mem_Number'] ?? 'Member',
//                         // <-- Added booking_Id so that _showinterestbutton receives it
//                         'booking_Id': doc['booking_Id'],
//                         'interested_Members': doc['interested_Members'] ?? [],
//                       };
//                     } catch (e) {
//                       debugPrint('Error parsing booking document: $e');
//                     }
//                   }

//                 return GridView.builder(
//                   padding: const EdgeInsets.all(20),
//                   gridDelegate:
//                       const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                   ),
//                   itemCount: timeSlots.length,
//                   itemBuilder: (context, index) {
//                     String timeSlot = timeSlots[index];
//                     Color color = Colors.lightBlueAccent;
//                     bool isClickable = true;
//                     final now = DateTime.now();

//                     // Build the complete DateTime for this slot using the selected date and the hour (7 + index).
//                     final slotDateTime = DateTime(
//                       (selectedDate ?? DateTime.now()).year,
//                       (selectedDate ?? DateTime.now()).month,
//                       (selectedDate ?? DateTime.now()).day,
//                       7 + index,
//                       0,
//                     );

//                     // Disable the slot if it's either in the past OR beyond the allowed 48 hours.
//                     if (slotDateTime.isBefore(now) ||
//                         slotDateTime.isAfter(
//                             now.add(const Duration(hours: 48)))) {
//                       isClickable = false;
//                       color = Colors.grey;
//                     }

//                     // Update appearance based on the booking details fetched from Firebase.
//                     if (slotBookingData.containsKey(timeSlot)) {
//                       final bookingData = slotBookingData[timeSlot]!;
//                       if (bookingData['status'] == 'Confirmed') {
//                         color = Colors.red;
//                         isClickable = false;
//                       } else if (bookingData['status'] == 'Unconfirmed') {
//                         color = Colors.yellow;
//                         isClickable = false;
//                       }
//                     }

//                     // If there is no booking for this slot and the user reached the limit,
//                     // disable the slot.
//                     if (!slotBookingData.containsKey(timeSlot) &&
//                         isBookingLimitReached) {
//                       isClickable = false;
//                       color = Colors.grey;
//                     }

//                     return GestureDetector(
//                       onTap: () {
//                         // If the slot is inactive because of a booking,
//                         // show the hover card with booking details.
//                         if (!isClickable &&
//                             slotBookingData.containsKey(timeSlot)) {
//                           _showHoverCard(
//                               context, slotBookingData[timeSlot]!);
//                         } else if (isClickable) {
//                           // Otherwise, allow the user to select the slot.
//                           ref
//                               .read(selectedTimeSlotProvider.notifier)
//                               .state = timeSlot;
//                         }
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color:
//                               ref.watch(selectedTimeSlotProvider) ==
//                                       timeSlot
//                                   ? Colors.pink
//                                   : color,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Center(
//                           child: Text(
//                             timeSlot,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: isClickable
//                                   ? Colors.white
//                                   : Colors.black,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           // Booking Request Button
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                   backgroundColor: AppKolors.secondary,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10))),
//               onPressed: () async {
//                 if (ref.watch(selectedTimeSlotProvider) == null ||
//                     selectedDate == null) {
//                   Fluttertoast.showToast(
//                     msg: 'Please select a valid time slot.',
//                     toastLength: Toast.LENGTH_SHORT,
//                     gravity: ToastGravity.BOTTOM,
//                   );
//                   return;
//                 }

//                 final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
//                 await showConfirmationDialog(
//                   context,
//                   ref,
//                   selectedDate,
//                   selectedTimeSlot!,
//                   selectedFacility,
//                   selectedCourt,
//                   noofattendees.values
//                       .fold<int>(
//                           0, (prev, element) => prev + element)
//                       .toString(),
//                 );
//               },
//               child: const Text(
//                 "Request Booking",
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: AppKolors.background),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // This function shows a small dialog that mimics a hover card.
// Future<void> _showHoverCard(
//     BuildContext context, Map<String, dynamic> bookingData) async {
//   final currentUser = FirebaseAuth.instance.currentUser;
//   final usersColl = FirebaseFirestore.instance.collection('users_members');

//   // Use either 'userId' or fallback to 'user_Id'
//   final bookingUserId = bookingData['userId'] ?? bookingData['user_Id'];

//   // Retrieve the document of the user who booked the slot.
//   final userDoc = await usersColl.doc(bookingUserId).get();
//   final memNumber = userDoc.data()?['mem_Number'] ?? 'Member';

//   bool isCurrentUser = bookingUserId == currentUser?.uid;
//   String status = bookingData['status'];
//   String displayText;

//   if (status == 'Unconfirmed') {
//     displayText = isCurrentUser
//         ? 'Pending Confirmation\n(blocked for you)'
//         : 'Pending Confirmation\n(blocked for $memNumber)';
//   } else if (status == 'Confirmed') {
//     displayText = isCurrentUser
//         ? 'Booking Confirmed\nreserved for you'
//         : 'Booking Confirmed\nreserved for $memNumber';
//   } else {
//     displayText = status;
//   }

//   // Check if the current user has already shown interest.
//   List<dynamic> interestedMembers = bookingData['interested_Members'] ?? [];
//   bool alreadyInterested = currentUser != null && interestedMembers.contains(currentUser.uid);

//   showDialog(
//     context: context,
//     builder: (context) {
//       return Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: const EdgeInsets.all(50),
//         child: Container(
//           height: 140,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
//           ),
//           padding: const EdgeInsets.all(8),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 displayText,
//                 style: status == 'Unconfirmed'
//                     ? const TextStyle(fontSize: 14, color: AppKolors.accent3)
//                     : const TextStyle(fontSize: 14, color: AppKolors.accent2),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               // Disable the button if the user already showed interest.
//               isCurrentUser ? Text('This booking has been made Successfully by you', textAlign: TextAlign.center,) : Expanded(
//                 child: TextButton(
//                   onPressed: alreadyInterested
//                       ? null  // Disabled button
//                       : () {
//                           print('show interest button pressed under ${bookingData['booking_Id']}');
//                           _showinterestbutton(context, bookingData['booking_Id']);
//                           Navigator.of(context).pop();
//                         },
//                   style: TextButton.styleFrom(
//                     foregroundColor: alreadyInterested ? Colors.grey : Theme.of(context).primaryColorDark,
//                   ),
//                   child: Text(
//                     alreadyInterested ? 'Interest Already Shown, You\'ll be notified once the slot becomes available' : 'Show Interest',
//                   textAlign: TextAlign.center,),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }


// _showinterestbutton(context, bookingId) async {
//   final firestore = FirebaseFirestore.instance;
//   final currentUser = FirebaseAuth.instance.currentUser;

//   if (currentUser == null) {
//     Fluttertoast.showToast(
//       msg: 'User not logged in.',
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//     );
//     return;
//   }

//   try {
//     final bookingDocRef = firestore.collection('bookings_collection').doc(bookingId);

//     await firestore.runTransaction((transaction) async {
//       final snapshot = await transaction.get(bookingDocRef);

//       if (!snapshot.exists) {
//         throw Exception('Booking does not exist.');
//       }

//       List<dynamic> interestedMembers = snapshot.data()?['interested_Members'] ?? [];

//       if (!interestedMembers.contains(currentUser.uid)) {
//         interestedMembers.add(currentUser.uid);
//         transaction.update(bookingDocRef, {
//           'interested_Members': interestedMembers,
//         });
//       } else {
//         Fluttertoast.showToast(
//           msg: 'You have already shown interest.',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//         );
//       }
//     });

//     Fluttertoast.showToast(
//       msg: 'Interest shown successfully, a notification will be sent once the booking becomes available.',
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//     );
//   } catch (e) {
//     debugPrint('Error updating booking: $e');
//     Fluttertoast.showToast(
//       msg: 'Failed to show interest. Please try again.',
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//     );
//   }
// }
//   String formatDateWithSuffix(DateTime date) {
//     final day = date.day;
//     String suffix;
//     if (day >= 11 && day <= 13) {
//       suffix = 'th';
//     } else {
//       switch (day % 10) {
//         case 1:
//           suffix = 'st';
//           break;
//         case 2:
//           suffix = 'nd';
//           break;
//         case 3:
//           suffix = 'rd';
//           break;
//         default:
//           suffix = 'th';
//       }
//     }
//     return '${DateFormat('MMMM').format(date)} $day$suffix ${date.year}';
//   }
// }

// List<DateTime> _generateDeactivatedDates() {
//   final now = DateTime.now();
//   final dateLimit = now.add(const Duration(hours: 48));
//   final List<DateTime> deactivatedDates = [];

//   // Disable dates that fall beyond the 48-hour window.
//   for (int i = 0; i < 30; i++) {
//     final date = now.add(Duration(days: i));
//     if (date.isAfter(dateLimit)) {
//       deactivatedDates.add(date);
//     }
//   }

//   return deactivatedDates;
// }
