// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
// import 'package:nrbgymkhana/features/common/widgets/dateformat.dart';
// import 'package:intl/intl.dart';

// Future<void> showConfirmationDialog(
//   BuildContext context,
//   WidgetRef ref,
//   DateTime selectedDate,
//   String selectedTimeSlot,
//   String selectedFacility,
//   String selectedCourt,
//   String noOfAttendees,
// ) async {
//   final firestore = FirebaseFirestore.instance;

//   // Fetch facility details
//   String facilityName = '';
//   String facilityImageUrl = '';
//   String facilityDescription = '';
//   try {
//     final facilityQuery = await firestore
//         .collection('Facilities')
//         .where('facility_Id', isEqualTo: selectedFacility)
//         .get();

//     if (facilityQuery.docs.isNotEmpty) {
//       final doc = facilityQuery.docs.first;
//       facilityName = doc['facility_Name'] ?? 'Unknown Facility';
//       facilityImageUrl = doc['image'] ?? '';
//       facilityDescription = doc['description'] ?? 'Sports Facility at the club';
//     } else {
//       Fluttertoast.showToast(msg: 'Facility not found.');
//       return;
//     }
//   } catch (e) {
//     Fluttertoast.showToast(msg: 'Failed to retrieve facility details.');
//     return;
//   }

//   // Price calculation (demo values)

//   final totalparticipantCounts =
//       ref.read(participantCountsProvider.notifier).state;
//   final totalmemberparticipants = totalparticipantCounts['Member'] ?? 0;
//   final totalGuestPlayers = totalparticipantCounts['Guest'] ?? 0;
//   final totalChildMembers = totalparticipantCounts['Child Member'] ?? 0;

//   int total = totalGuestPlayers * 200;
//   // Show animated dialog
//   await showGeneralDialog(
//     context: context,
//     barrierLabel: "Confirm Booking",
//     barrierDismissible: true,
//     transitionDuration: const Duration(milliseconds: 400),
//     transitionBuilder: (context, animation, secondaryAnimation, child) {
//       return ScaleTransition(
//         scale: CurvedAnimation(
//           parent: animation,
//           curve: Curves.easeOutBack,
//         ),
//         child: child,
//       );
//     },
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         insetPadding: EdgeInsets.symmetric(
//           horizontal: MediaQuery.of(context).size.width * 0.07,
//           vertical: 10,
//         ),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Theme.of(context).cardColor.withValues(alpha: 0.95),
//                 Theme.of(context).cardColor.withValues(alpha: 0.85),
//               ],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//               )
//             ],
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Header with Close Button
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back),
//                       onPressed: Navigator.of(context).pop,
//                     ),
//                     Expanded(
//                       child: Text(
//                         'Request Booking',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: Navigator.of(context).pop,
//                     ),
//                   ],
//                 ),
//                 const Divider(),

//                 // Facility Card
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     color: Theme.of(context).canvasColor.withValues(alpha: 0.05),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.05),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       )
//                     ],
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 2,
//                     horizontal: 16,
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Facility Image
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           facilityImageUrl,
//                           width: 100,
//                           height: 68,
//                           fit: BoxFit.cover,
//                           loadingBuilder: (context, child, loadingProgress) {
//                             if (loadingProgress == null) return child;
//                             return Container(
//                               width: 100,
//                               height: 68,
//                               color: Colors.grey[300],
//                             );
//                           },
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               width: 100,
//                               height: 68,
//                               color: Colors.grey[300],
//                               child: const Icon(Icons.image),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       // Facility Info
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               facilityName,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleMedium
//                                   ?.copyWith(fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               facilityDescription,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: Theme.of(context).textTheme.bodySmall,
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 const Icon(Icons.calendar_month, size: 16),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   formatDateWithSuffix(selectedDate),
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodySmall
//                                       ?.copyWith(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Booking Details
//                 _buildSectionHeader(context, "Your Booking"),
//                 const SizedBox(height: 10),
//                 _buildEditableRow(
//                   context,
//                   "Date",
//                   formatDateWithSuffix(selectedDate),
//                   Icons.calendar_month,
//                   "change",
//                 ),
//                 _buildEditableRow(
//                   context,
//                   "Slot",
//                   selectedTimeSlot.replaceAll('\n - \n', ' to '),	
//                   Icons.lock_clock,
//                   "change",
//                 ),
//                 _buildEditableRow(
//                   context,
//                   "Court",
//                   selectedCourt,
//                   Icons.sports,
//                   "",
//                 ),
//                 const SizedBox(height: 10),

//                 // Price Breakdown
//                 _buildSectionHeader(context, "Participants Details"),
//                 const SizedBox(height: 10),
//                 _buildPriceRow("Member participants", totalmemberparticipants.toString()),
//                 totalGuestPlayers > 0
//                     ? _buildPriceRow("Guest participants", totalGuestPlayers.toString())
//                     : const SizedBox.shrink(),
//                 totalChildMembers > 0
//                     ? _buildPriceRow("Child Member participants", totalChildMembers.toString())
//                     : const SizedBox.shrink(),
//                 totalGuestPlayers > 0
//                     ? _buildPriceRow("Guest Levy per Facility", "200")
//                     : const SizedBox.shrink(),
//                 const Divider(),
//                 _buildPriceRow("Total to be Paid", "Ksh. $total", isTotal: true),
//                 const SizedBox(height: 20),

//                 // Cancellation Policy
//                 const Text(
//                   "Cancellation Policy\n"
//                   "You can cancel the booking at any time. if court is empty within 15 minutes of booking time then the court can be used by anyone.",
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 13,
//                     fontStyle: FontStyle.italic,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),

//                 // Confirm Button
//                 InkWell(
//                   onTap: () async {
//                     Navigator.of(context).pop();
//                     await _submitBooking(
//                       context,
//                       ref,
//                       selectedDate,
//                       selectedTimeSlot,
//                       selectedFacility,
//                       selectedCourt,
//                     );
//                   },
//                   child: Container(
//                     height: 50,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF007BFF), Color(0xFF00BFFF)],
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.blue.withValues(alpha: 0.4),
//                           blurRadius: 8,
//                           offset: const Offset(0, 4),
//                         )
//                       ],
//                     ),
//                     alignment: Alignment.center,
//                     child: const Text(
//                       "Confirm & Request",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//      },
//      );
// }

// // Helper Widgets

// Widget _buildSectionHeader(BuildContext context, String title, ) {
//   return Row(
//     children: [
//       Text(
//         title,
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//           color: Theme.of(context).primaryColorDark,
//         ),
//       ),
//     ],
//   );
// }

// Widget _buildEditableRow(
//   BuildContext context,
//   String label,
//   String value,
//   IconData icon,
//   String editLabel,
// ) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         label,
//         style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//           fontSize: 13.sp,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       Padding(
//         padding: EdgeInsets.only(left: 3.w),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               value,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 fontSize: 12.sp,
//                 color: Colors.grey[800],
//               ),
//             ),
//             TextButton(
//               style: TextButton.styleFrom(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 foregroundColor: Theme.of(context).primaryColorDark,
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text(editLabel, 
//                 style: TextStyle(
//                   color: Theme.of(context).primaryColorDark,
//                   fontSize: 12.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),),
//           ],
//         ),
//       ),
//     ],
//   );
// }

// Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
//   return Padding(
//     padding:  EdgeInsets.symmetric(vertical: 4.h),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             color: isTotal ? Colors.black : Colors.grey[700],
//             fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         Padding(
//           padding: EdgeInsets.only(right: 20.w),
//           child: Text(
//             value,
//             style: TextStyle(
//               fontSize: isTotal ? 15.sp : 12.sp,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//               color: isTotal ? Colors.green : null,
//             ),
//           ),
//         ),
//       ],
//     ),
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
//     final participantCounts =
//         ref.read(participantCountsProvider.notifier).state;
//     final participantsDetails = {
//       'members': participantCounts['Member'] ?? 0,
//       'guests': participantCounts['Guest'] ?? 0,
//       'child_Member': participantCounts['Child Member'] ?? 0,
//     };

//     try {
//       if (selectedTimeSlot == null) {
//         Fluttertoast.showToast(
//           msg: 'No time slot selected.',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//         );
//         return;
//       }

//       final firestore = FirebaseFirestore.instance;
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) {
//         Fluttertoast.showToast(
//           msg: 'User not authenticated.',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//         );
//         return;
//       }
//       final userId = currentUser.uid;

//       // Parse the start time from the time slot string.
//       DateTime selectedSlot;
//       try {
//         selectedSlot = DateFormat('h:mm a')
//             .parse(selectedTimeSlot.split('\n')[0]);
//       } catch (e) {
//         Fluttertoast.showToast(
//           msg: 'Error parsing time slot. Please try a different slot.',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//         );
//         return;
//       }

//       final userDoc = await firestore.collection('users_members').doc(userId).get();
//       final memNumber = userDoc.exists ? userDoc.data()!['mem_Number'] ?? 'Member' : 'Member';
//       // Create a unique document ID for the booking based on facility, court, date, and time slot.
//       String datePart = DateFormat('yyyy-MM-dd').format(selectedDate);
//       String uniqueDocId =
//           '${selectedFacility}_${selectedCourt}_${datePart}_${selectedSlot.hour}_${selectedSlot.minute}';

//       // Run a transaction to ensure that the slot is booked only once.
//       await firestore.runTransaction((transaction) async {
//         DocumentReference bookingDocRef =
//             firestore.collection('bookings_collection').doc(uniqueDocId);
//         DocumentSnapshot snapshot = await transaction.get(bookingDocRef);

//         if (snapshot.exists) {
//           // If the booking for this slot exists, abort by throwing an exception.
//           throw Exception(
//               'This time slot is already booked. Please choose another slot.');
//         } else {
//           // Prepare new booking data.
//           final newBookingData = {
//             'facility_Id': selectedFacility,
//             'date_Booked': Timestamp.now(),
//             'court_No': selectedCourt,
//             'facility_Type': 'Sports',
//             'booking_Id': uniqueDocId,
//             'booking_Date': Timestamp.fromDate(selectedDate),
//             'start_Time': Timestamp.fromDate(
//               DateTime(
//                 selectedDate.year,
//                 selectedDate.month,
//                 selectedDate.day,
//                 selectedSlot.hour,
//                 selectedSlot.minute,
//               ),
//             ),
//             'end_Time': Timestamp.fromDate(
//               DateTime(
//                 selectedDate.year,
//                 selectedDate.month,
//                 selectedDate.day,
//                 selectedSlot.hour + 1,
//                 selectedSlot.minute,
//               ),
//             ),
//             'user_Id': userId,
//             'Participants_Details': participantsDetails,
//             'no_of_Attendees': participantCounts.values
//                 .fold<int>(0, (prev, element) => prev + element)
//                 .toString(),
//             'reaction': {
//               'reaction_Id': '',
//               'reaction_Date': null,
//               'status': 'Unconfirmed',
//               'isPaid': false,
//               'reacted_By': '',
//             },
//             // Optionally store a member number if needed.
//             'interested_Members': [], 
//           };

//           // Create the booking using the transaction.
//           transaction.set(bookingDocRef, newBookingData);
//         }
//       }).then((_) {
//         Fluttertoast.showToast(
//           msg: 'Booking Requested Successfully',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//         );

//         ref.read(selectedTimeSlotProvider.notifier).state = null;
//       }).catchError((error) {
//         Fluttertoast.showToast(
//           msg: error.toString(),
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//         debugPrint('Booking submission transaction error: $error');
//       });
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Booking request failed, please try again.',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//       debugPrint('Booking submission error: $e');
//     }
//   }