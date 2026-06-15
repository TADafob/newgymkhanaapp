// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/features/Events/presentation/providers/eventsproviders.dart';

// class CancelleduserEvents extends ConsumerWidget {
//   const CancelleduserEvents({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final eventsAsync = ref.watch(eventsStreamProvider);
//     final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

//     return eventsAsync.when(
//       data: (events) {
//         // Filter events to show only those with the current user's uid and reaction 'Cancelled'
//         final cancelledEvents = events.docs.where((event) {
//           final bookings = event['bookings'] as List<dynamic>?;
//           if (bookings != null) {
//             return bookings.any((booking) =>
//                 booking['reaction'] == 'cancelled' && booking['booked_By'] == currentUserUid);
//           }
//           return false;
//         }).toList();

//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//           itemCount: cancelledEvents.length,
//           itemBuilder: (context, index) {
//             final event = cancelledEvents[index];

//             return ListTile(
//               title: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Stack(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Image.network(
//                           event['image_Url'] ?? 'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png',
//                           width: double.maxFinite,
//                           height: 200,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       Positioned(
//                         top: 120,
//                         left: 45,
//                         child: Transform(
//                           transform: Matrix4.rotationZ(-0.4), // Slightly slanted angle
//                           child: Container(
//                             height: 40,
//                             width: 250,
//                             decoration: BoxDecoration(color: AppKolors.accent3),
//                             child: Center(
//                               child: Text('Cancelled booking!',
//                                   style: TextStyle(color: AppKolors.background, fontSize: 20)),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Text(
//                     event['title'] ?? 'No title',
//                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     DateFormat('MMMM dd, yyyy').format((event['date_Added'] as Timestamp).toDate()),
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                 ],
//               ),
//               onTap: () {},
//             );
//           },
//         );
//       },
//       error: (error, stack) => Center(child: Text('Error: $error')),
//       loading: () => const Center(child: CircularProgressIndicator()),
//     );
//   }
// }
