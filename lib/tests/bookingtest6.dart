// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:date_picker_timeline/date_picker_timeline.dart';
// import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';

// class BookingPage extends ConsumerWidget {
//   const BookingPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final selectedDate = ref.watch(selectedDateProvider);
//     final selectedCourt = ref.watch(selectedCourtProvider);
//     final selectedFacility = ref.watch(selectedFacilityProvider);
//     final firestore = FirebaseFirestore.instance;
//     final userId = FirebaseAuth.instance.currentUser!.uid;

//     List<String> timeSlots = List.generate(14, (index) {
//       final startHour = 7 + index;
//       final startTime = DateTime(0, 0, 0, startHour);
//       final endTime = startTime.add(const Duration(hours: 1));
//       return '${DateFormat('h:mm a').format(startTime)}\n - \n${DateFormat('h:mm a').format(endTime)}';
//     });

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Select Date and Time Slot"),
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
//               selectionColor: Colors.blue,
//               selectedTextColor: Colors.white,
//               onDateChange: (date) {
//                 ref.read(selectedDateProvider.notifier).state = date;
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
//                     decoration: BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.green
//                     ),
//                   ),
//                   SizedBox(width: 10,),
//                   Text('Available',style: TextStyle(fontSize: 12),)
//                 ],),
//                 Row(children: [
//                   Container(
//                     height: 10,
//                     width: 10,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.yellow
//                     ),
//                   ),
//                   SizedBox(width: 10,),
//                   Text('Reserved', style: TextStyle(fontSize: 12),)
//                 ],),
//                 Row(children: [
//                   Container(
//                     height: 10,
//                     width: 10,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.red
//                     ),
//                   ),
//                   SizedBox(width: 10,),
//                   Text('Booked', style: TextStyle(fontSize: 12),)
//                 ],),
//                 Row(children: [
//                   Container(
//                     height: 10,
//                     width: 10,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.rectangle,
//                       color: Colors.grey
//                     ),
//                   ),
//                   SizedBox(width: 10,),
//                   Text('Blocked', style: TextStyle(fontSize: 12),)
//                 ],)
//               ],
//             ),
//           ),
//           SizedBox(height: 10,),
//           // Time Slot Selection Grid
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: firestore
//                   .collection('bookings_collection')
//                   .where('booking_Date', isEqualTo: Timestamp.fromDate(selectedDate!))
//                   .where('facility_Id', isEqualTo: selectedFacility)
//                   .where('court_No', isEqualTo: selectedCourt)
//                   .where('reaction.status', isNotEqualTo: 'Cancelled')
//                   .where('facility_Type', isEqualTo: 'Sports') // Only slot-based bookings
//                   .snapshots(),

//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 final allBookings = snapshot.data!.docs;
//                 final userBookings = allBookings.where((doc) => doc['user_Id'] == userId).toList();
//                 final bool isBookingLimitReached = userBookings.length >= 2;

//                 Map<String, String> slotStatus = {};
//                 for (var doc in allBookings) {
//                   DateTime startTime = (doc['start_Time'] as Timestamp).toDate();
//                   String timeSlot = '${DateFormat('h:mm a').format(startTime)}\n - \n${DateFormat('h:mm a').format(startTime.add(const Duration(hours: 1)))}';
//                   String status = doc['reaction']['status'];
//                   slotStatus[timeSlot] = status;
//                 }

//                 return GridView.builder(
//                   padding: const EdgeInsets.all(20),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                   ),
//                   itemCount: timeSlots.length,
//                   itemBuilder: (context, index) {
//   String timeSlot = timeSlots[index];
//   Color color = Colors.green;
//   bool isClickable = true;

//   final now = DateTime.now();
//   final dateLimit = now.add(const Duration(hours: 48));
//   final selectedDateTime = DateTime(
//     selectedDate.year,
//     selectedDate.month,
//     selectedDate.day,
//   );

//   // Check if the selectedDate exceeds the 48-hour limit
//   if (selectedDateTime.isAfter(dateLimit)) {
//     isClickable = false;
//     color = Colors.grey;
//   }

//   // Slot status from Firebase
//   if (slotStatus.containsKey(timeSlot)) {
//     if (slotStatus[timeSlot] == 'Confirmed') {
//       color = Colors.red;
//       isClickable = false;
//     } else if (slotStatus[timeSlot] == 'Unconfirmed') {
//       color = Colors.yellow;
//       isClickable = false;
//     }
//   }

//   // Limit user bookings
//   if (!slotStatus.containsKey(timeSlot) && isBookingLimitReached) {
//     isClickable = false;
//     color = Colors.grey;
//   }

//   return GestureDetector(
//     onTap: isClickable
//         ? () {
//             ref.read(selectedTimeSlotProvider.notifier).state = timeSlot;
//           }
//         : null,
//     child: Container(
//       decoration: BoxDecoration(
//         color: ref.watch(selectedTimeSlotProvider) == timeSlot ? Colors.pink : color,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Center(
//         child: Text(
//           timeSlot,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: isClickable ? Colors.white : Colors.black,
//           ),
//         ),
//       ),
//     ),
//   );
// },

//                 );
//               },
//             ),
//           ),
//           // Booking Request Button
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               onPressed: () async {
//                 if (ref.watch(selectedTimeSlotProvider) == null) {
//                   Fluttertoast.showToast(
//                     msg: 'Please select a date and time slot.',
//                     toastLength: Toast.LENGTH_SHORT,
//                     gravity: ToastGravity.BOTTOM,
//                   );
//                   return;
//                 }

//                 final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
//                 await _showConfirmationDialog(
//                   context,
//                   ref,
//                   selectedDate,
//                   selectedTimeSlot!,
//                   selectedFacility,
//                   selectedCourt,
//                 );
//               },
//               child: const Text("Request Booking"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//  Future<void> _showConfirmationDialog(
//   BuildContext context,
//   WidgetRef ref,
//   DateTime selectedDate,
//   String selectedTimeSlot,
//   String selectedFacility,
//   String selectedCourt,
// ) async {
//   final firestore = FirebaseFirestore.instance;

//   // Fetch the facility name based on facility_Id
//   String facilityName = '';
//   try {
//     final facilityQuery = await firestore
//         .collection('Facilities')
//         .where('facility_Id', isEqualTo: selectedFacility)
//         .get();

//     if (facilityQuery.docs.isNotEmpty) {
//       facilityName = facilityQuery.docs.first['facility_Name'];
//     } else {
//       Fluttertoast.showToast(
//         msg: 'Facility not found.',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//       return;
//     }
//   } catch (e) {
//     Fluttertoast.showToast(
//       msg: 'Failed to retrieve facility name.',
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//     );
//     return;
//   }

//   // Show confirmation dialog
//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text('Confirm Booking'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Facility: $facilityName'),
//             Text('Court: $selectedCourt'),
//             Text('Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
//             Text('Time Slot: ${selectedTimeSlot.replaceAll("\n - \n", " - ")}'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.of(context).pop();
//               await _submitBooking(
//                 context,
//                 ref,
//                 selectedDate,
//                 selectedTimeSlot,
//                 selectedFacility,
//                 selectedCourt,
//               );
//             },
//             child: const Text('Confirm'),
//           ),
//         ],
//       );
//     },
//   );
// }


//   Future<void> _submitBooking(
//     BuildContext context,
//     WidgetRef ref,
//     DateTime selectedDate,
//     String? selectedTimeSlot,
//     String selectedFacility,
//     String selectedCourt,
//   ) async {


//     final participantCounts = ref.read(participantCountsProvider.notifier).state;
//     final participantsDetails = {
//     'members': participantCounts['Member'] ?? 0,
//     'guests': participantCounts['Guest'] ?? 0,
//     'child_Member': participantCounts['Child Member'] ?? 0,
//   };

//     try {
//       if (selectedTimeSlot == null) return;

//       final firestore = FirebaseFirestore.instance;
//       final userId = FirebaseAuth.instance.currentUser!.uid;
//       final bookingId = firestore.collection('bookings_collection').doc().id;
//       final DateTime selectedSlot = DateFormat('h:mm a').parse(selectedTimeSlot.split('\n')[0]);

//       await firestore.collection('bookings_collection').doc(bookingId).set({
//         'facility_Id': selectedFacility,
//         'date_Booked': Timestamp.now(),
//         'court_No': selectedCourt,
//         'facility_Type': 'Sports',
//         'booking_Id': bookingId,
//         'booking_Date': Timestamp.fromDate(selectedDate),
//         'start_Time': Timestamp.fromDate(
//           DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedSlot.hour, selectedSlot.minute),
//         ),
//         'end_Time': Timestamp.fromDate(
//           DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedSlot.hour + 1, selectedSlot.minute),
//         ),
//         'user_Id': userId,
//         'Participants_Details': participantsDetails,
//         'no_of_Attendees': participantCounts.values.reduce((a, b) => a + b).toString(),
//         'reaction': {
//           'reaction_Id': '',
//           'reaction_Date': '',
//           'status': 'Unconfirmed',
//           'isPaid': false,
//           'reacted_By': '',
//         },
//       });

//       Fluttertoast.showToast(
//         msg: 'Booking Requested Successfully',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.green,
//         textColor: Colors.white,
//       );

//       ref.read(selectedTimeSlotProvider.notifier).state = null;
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Booking request failed, please try again.',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     }
//   }
// }
