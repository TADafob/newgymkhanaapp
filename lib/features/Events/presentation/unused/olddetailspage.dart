// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';

// final selectedTicketsProvider = StateProvider<int>((ref) => 1);
// final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'MPESA');

// class EventDetailsPage extends ConsumerWidget {
//   final QueryDocumentSnapshot<Map<String, dynamic>> event;

//   const EventDetailsPage({required this.event, super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final title = event['title'] ?? 'Event';
//     final imageUrl = event['image_Url'] ?? '';
//     final location = event['location'] ?? 'Not specified';
//     final date = event['date_Added'] != null
//         ? DateFormat('MMMM dd, yyyy').format((event['date_Added'] as Timestamp).toDate())
//         : 'Date unavailable';
//     final price = event['price'] ?? 0;
//     final isFree = event['isFree'] ?? false;

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(onPressed: () => context.go('/calendar'), icon: Icon(Icons.arrow_back)),
//         title: Text(title),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.network(
//               imageUrl,
//               width: double.infinity,
//               height: 200,
//               fit: BoxFit.cover,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Location: $location',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Date: $date',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Price: ${price == 0 ? "Free" : '\$${price.toString()}'}',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () => _showBookingPopup(context, ref, isFree),
//                     child: const Text('Book Tickets'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showBookingPopup(BuildContext context, WidgetRef ref, bool isFree) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Select Number of Tickets'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Consumer(
//                 builder: (context, ref, child) {
//                   final selectedTickets = ref.watch(selectedTicketsProvider);
//                   return DropdownButton<int>(
//                     value: selectedTickets,
//                     items: List.generate(
//                       10,
//                       (index) => DropdownMenuItem<int>(
//                         value: index + 1,
//                         child: Text('${index + 1} Tickets'),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       if (value != null) {
//                         ref.read(selectedTicketsProvider.notifier).state = value;
//                       }
//                     },
//                   );
//                 },
//               ),
//               if (!isFree)
//                 Consumer(
//                   builder: (context, ref, child) {
//                     final selectedPaymentMethod = ref.watch(selectedPaymentMethodProvider);
//                     return DropdownButton<String>(
//                       value: selectedPaymentMethod,
//                       items: const [
//                         DropdownMenuItem(value: 'MPESA', child: Text('MPESA')),
//                         DropdownMenuItem(value: 'Membership Card Points', child: Text('Redeem with Points')),
//                       ],
//                       onChanged: (value) {
//                         if (value != null) {
//                           ref.read(selectedPaymentMethodProvider.notifier).state = value;
//                         }
//                       },
//                     );
//                   },
//                 ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 final selectedTickets = ref.read(selectedTicketsProvider);
//                 final selectedPaymentMethod = ref.read(selectedPaymentMethodProvider);
//                 _bookTickets(context, ref, selectedTickets, selectedPaymentMethod);
//               },
//               child: const Text('Book'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _bookTickets(
//   BuildContext context,
//   WidgetRef ref,
//   int tickets,
//   String paymentMethod,
// ) async {
//   final userId = FirebaseAuth.instance.currentUser?.uid;
//   final bookingDate = Timestamp.now();
//   final bookingId = Random().nextInt(1000000).toString();
//   final isFree = event['isFree'] ?? false;
//   final isLimited = event['isLimited'] ?? false;
//   final price = event['price'] ?? 0;
//   final noofTickets = ref.read(selectedTicketsProvider);
//   final finalPrice = noofTickets * price;

//   try {
//     // Check if user already booked (for limited bookings)
//     if (isLimited) {
//       final eventDoc = await FirebaseFirestore.instance.collection('events_collection').doc(event.id).get();
//       final bookings = List<Map<String, dynamic>>.from(eventDoc['bookings'] ?? []);
//       final userAlreadyBooked = bookings.any((booking) => booking['booked_By'] == userId);

//       if (userAlreadyBooked) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('You can only book this event once.')),
//           );
//         });
//         return;
//       }
//     }

//     // Handle Membership Points Payment
//     if (!isFree && paymentMethod == 'Membership Card Points') {
//       final memberDoc = await FirebaseFirestore.instance.collection('members_cards').doc(userId).get();
//       final cardBalance = memberDoc['card_Balance'] ?? 0;

//       if (cardBalance < finalPrice) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Insufficient card balance.')),
//           );
//         });
//         return;
//       }

//       // Deduct card balance and log transaction
//       await FirebaseFirestore.instance.collection('members_cards').doc(userId).collection('card_Transactions').doc().update({
//             'trans_Amount': finalPrice,
//             'trans_Date': DateTime.now(),
//             'trans_Descr': event['title'],
//             'trans_Id': bookingId,
//             'trans_Type': 'redeem',
//       });
//     }

//     // Add booking to event document
//     await FirebaseFirestore.instance.collection('events_collection').doc(event.id).update({
//       'bookings': FieldValue.arrayUnion([
//         {
//           'booked_By': userId,
//           'booking_Date': bookingDate,
//           'no_of_Tickets': tickets,
//           'booking_id': bookingId,
//           'status': 'Pending',
//           'payment_Method': isFree ? 'Free' : paymentMethod,
//         },
//       ]),
//     });
//     Navigator.pop(context);

//     // Navigate to success page using GoRouter
//     context.go('/events-success');

//     // Show a success snackbar
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Booking successfully sent!')),
//       );
//     });
//   } catch (e) {
//     // Show error if there is an issue with booking
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error booking tickets: $e')),
//       );
//     });
//   }
// }
// }

