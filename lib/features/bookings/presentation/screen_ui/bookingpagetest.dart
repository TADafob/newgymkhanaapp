// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
// import 'package:nrbgymkhana/features/bookings/presentation/widgets/sportsbookingpage.dart';

// class BookingsCatPage extends ConsumerWidget {
//   final String category;
//   const BookingsCatPage({super.key, required this.category});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       body: FutureBuilder<QuerySnapshot>(
//         future: FirebaseFirestore.instance
//           .collection('Facilities')
//           .where(
//             'facility_Type',
//             isEqualTo: category == 'Clubs' ? 'Club' : 'Sports',
//           )
//           .get(),
//         builder: (ctx, snap) {
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snap.hasError) {
//             return Center(child: Text('Error: ${snap.error}'));
//           }

//           final facilities = snap.data!.docs.map((doc) {
//             final d = doc.data()! as Map<String, dynamic>;
//             return {
//               'facility_Id': d['facility_Id']   as String? ?? '',
//               'title':        d['facility_Name'] as String? ?? '',
//               'imageurl':     d['image']         as String? ?? '',
//               'courts':       d['courts']        as int?    ?? 1,
//               'isActive':     d['isActive']      as bool?   ?? false,
//             };
//           }).toList();

//           return GridView.builder(
//             padding: const EdgeInsets.all(14),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//               childAspectRatio: 0.8,
//             ),
//             itemCount: facilities.length,
//             itemBuilder: (ctx, i) {
//               final f = facilities[i];
//               final isActive = f['isActive'] as bool;

//               return Opacity(
//                 opacity: isActive ? 1 : 0.5,
//                 child: IgnorePointer(
//                   ignoring: !isActive,
//                   child: GestureDetector(
//                     onTap: () {
//                       final facilityId   = f['facility_Id'] as String;
//                       final facilityName = f['title']       as String;
//                       final imageUrl     = f['imageurl']    as String;
//                       final courtsCount  = f['courts']      as int;

//                       _showBookingBottomSheet(
//                         context,
//                         facilityName,
//                         imageUrl,
//                         courtsCount,
//                         facilityId: facilityId,
//                       );
//                     },
//                     child: Card(
//                       clipBehavior: Clip.antiAlias,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         children: [
//                           Expanded(
//                             child: Stack(
//                               fit: StackFit.expand,
//                               children: [
//                                 if (f['imageurl'] != '')
//                                   Image.network(f['imageurl'] as String,
//                                       fit: BoxFit.cover)
//                                 else
//                                   Container(color: Colors.grey),
//                                 Positioned(
//                                   left: 0, right: 0, bottom: 0,
//                                   child: Container(
//                                     color: Colors.black45,
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 4, horizontal: 6),
//                                     child: Text(
//                                       f['title'] as String,
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                       overflow: TextOverflow.ellipsis,
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             width: double.infinity,
//                             color: Colors.white.withValues(alpha: 0.2),
//                             padding: const EdgeInsets.symmetric(
//                                 vertical: 6, horizontal: 6),
//                             child: Center(
//                               child: Text(
//                                 isActive ? 'Available' : 'Unavailable',
//                                 style: TextStyle(
//                                   color: isActive
//                                       ? Colors.green.withValues(alpha: 0.7)
//                                       : Colors.red,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _showBookingBottomSheet(
//     BuildContext context,
//     String facilityName,
//     String imageUrl,
//     int numberOfCourts, {
//     required String facilityId,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (_) {
//         return ProviderScope(
//           overrides: [
//             // CORRECT OVERRIDE: pin the facility provider to this ID
//             selectedFacilityProvider.overrideWithProvider(
//               StateProvider<String>((_) => facilityId),
//             ),
//           ],
//           child: Consumer(builder: (ctx, ref, _) {
//             return BookingsportsForm(
//               facilityName: facilityName,
//               imageUrl: imageUrl,
//               numberOfCourts: numberOfCourts,
//               onBookingConfirmed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => BookingPage()),
//                 );
//               },
//             );
//           }),
//         );
//       },
//     ).whenComplete(() {
//       final container = ProviderScope.containerOf(context, listen: false);
//       container.read(selectedDateProvider.notifier).state = null;
//       container.read(selectedCourtProvider.notifier).state = 'Court 1';
//       container.read(participantCountsProvider.notifier).state = {
//         'Member': 0,
//         'Child Member': 0,
//         'Guest': 0,
//       };
//     });
//   }
// }
