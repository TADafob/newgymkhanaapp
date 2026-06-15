// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/features/Events/presentation/providers/ticketnotifier.dart';
// import 'package:nrbgymkhana/features/Events/presentation/screens_ui/bookingstatuspage.dart';

// class EventDetailsPage extends ConsumerStatefulWidget {
//   final DocumentSnapshot event;

//   const EventDetailsPage({super.key, required this.event});

//   @override
//   ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
// }

// class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {

//  Widget _buildTicketSection(BuildContext context, WidgetRef ref) {
//   final eventData = widget.event.data() as Map<String, dynamic>? ?? {};
//   final ticketCategories = eventData['ticketCategories'] as List? ?? [];
//   final isFree = eventData['isFree'] ?? false;
//   final price = eventData['price'] ?? 0;

//   final quantities = ref.watch(ticketQuantitiesProvider);
  
//   final total = ticketCategories.fold(
//     0,
//     (sum, category) {
//       final name = category['name'] as String?;
//       final categoryPrice = category['price'] as int? ?? 0;
//       final quantity = quantities[name ?? ''] ?? 0;
//       return sum + (quantity * categoryPrice);
//     },
//   );

//   if (ticketCategories.isNotEmpty) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: ticketCategories.length,
//       itemBuilder: (context, index) {
//         final category = ticketCategories[index] as Map<String, dynamic>;
//         final categoryName = category['name'] ?? '';
//         final categoryPrice = category['price'] ?? 0;
//         final maxTickets = category['maxTickets'] ?? 100;

//         return TicketCategory(
//           name: categoryName,
//           price: categoryPrice,
//           maxTickets: maxTickets,
//         );
//       },
//     );
//   } else {
//   final quantity = quantities['default'] ?? 1;
//   return Column(
//     children: [
//       // Always show quantity controls, even for free events
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text('Quantity'),
//           Row(
//             children: [
//               IconButton(
//                 onPressed: () => ref.read(ticketQuantitiesProvider.notifier).decrement('default'),
//                 icon: Icon(Icons.remove),
//               ),
//               Text('$quantity'),
//               IconButton(
//                 onPressed: () => ref.read(ticketQuantitiesProvider.notifier).increment('default'),
//                 icon: Icon(Icons.add),
//               ),
//             ],
//           ),
//         ],
//       ),
//       // Show total price (still displays 'Free' for free events)
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text('Total Price'),
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Text(
//               isFree ? 'Free' : 'KES ${price * quantity}',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isFree ? Colors.green : Colors.red,
//                 fontSize: 14.sp,
//               ),
//             ),
//           ),
//         ],
//       ),
//     ],
//   );
// }
// }

//   @override
//   Widget build(BuildContext context) {
//     final imageUrl = widget.event.get('image_Url') ?? 
//       'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png ';
    
//     final eventDate = (widget.event.get('date') as Timestamp?)?.toDate() ?? DateTime.now();
//     final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(eventDate);
//     final formattedTime = DateFormat('h:mm a').format(eventDate);

//     final eventData = widget.event.data() as Map<String, dynamic>? ?? {};
//     final targetNo = eventData['target_No'] as int? ?? 0;

//     return FutureBuilder<QuerySnapshot>(
//       future: FirebaseFirestore.instance
//         .collection('events_collection')
//         .doc(widget.event.id)
//         .collection('bookings')
//         .get(),
//       builder: (context, snapshot) {
//         int ticketsSold = 0;
//         if (snapshot.hasData) {
//           for (final doc in snapshot.data!.docs) {
//             final raw = doc.get('tickets');
//             if (raw is Map) {
//               ticketsSold += raw.values.whereType<int>().fold(0, (sum, v) => sum + v);
//             }
//           }
//         }
//         final isFullyBooked = targetNo > 0 && ticketsSold >= targetNo;

//         return  SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Hero(
//                   tag: widget.event.id,
//                   child: Container(
//                     height: 250.h,
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         fit: BoxFit.cover,
//                         image: NetworkImage(imageUrl),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.all(20.w),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.event.get('title') ?? 'Event Title',
//                         style: TextStyle(
//                           fontSize: 24.sp,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 10.h),
//                       Row(
//   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   crossAxisAlignment: CrossAxisAlignment.start,
//   children: [
//     // ← Left column: date + location
//     Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.calendar_today, color: AppKolors.primary, size: 18),
//             SizedBox(width: 8.w),
//             Text(formattedDate, style: TextStyle(color: AppKolors.secondary)),
//           ],
//         ),
//         SizedBox(height: 8.h),
//         Row(
//           children: [
//             Icon(Icons.location_on, color: AppKolors.primary, size: 18),
//             SizedBox(width: 8.w),
//             Text(
//               widget.event.get('location') ?? 'Location not specified',
//               style: TextStyle(color: AppKolors.secondary),
//             ),
//           ],
//         ),
//       ],
//     ),

//     // → Right column: time on top, then booking stats
//     FutureBuilder<QuerySnapshot>(
//       future: FirebaseFirestore.instance
//           .collection('events_collection')
//           .doc(widget.event.id)
//           .collection('bookings')
//           .get(),
//       builder: (context, snap) {
//         // loading & error handling omitted for brevity…
//         if (snap.connectionState != ConnectionState.done) {
//           return const SizedBox(
//             width: 100, height: 40,
//             child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
//           );
//         }
//         final docs = snap.data?.docs ?? [];
//         final peopleBooked = docs.length;
//         var ticketsSold = 0;
//         for (final doc in docs) {
//           final raw = doc.get('tickets');
//           if (raw is Map) {
//             ticketsSold += raw.values
//                 .whereType<int>()
//                 .fold(0, (sum, v) => sum + v);
//           }
//         }
//         final target = (widget.event.data() as Map<String, dynamic>)['target_No'] as int? ?? 0;
//         final isNear = target - 10;
//         final getColor = ticketsSold >= target
//             ? AppKolors.accent3
//             : ticketsSold >= isNear
//                 ? AppKolors.accent3
//                 : AppKolors.accent;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             // 1) The time row
//             Row(
//               children: [
//                 Icon(Icons.access_time, color: AppKolors.primary, size: 18),
//                 SizedBox(width: 8.w),
//                 Text('From: $formattedTime', style: TextStyle(color: AppKolors.secondary)),
//               ],
//             ),
//             SizedBox(height: 8.h),
//             // 2) Booking stats
//             Text(
//               '$peopleBooked People Booked',
//               style: TextStyle(
//                 color: AppKolors.secondary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 4.h),
//             Text(
//               '($ticketsSold/$target tickets)',
//               style: TextStyle(
//                 color: getColor,
//                 fontSize: 12.sp,
//               ),
//             ),
//           ],
//         );
//       },
//     ),
//   ],
// ),


              
//                   SizedBox(height: 20.h),
//                   Text(
//                     'About Event',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.bold,
//                       color: AppKolors.blackness,
//                     ),
//                   ),
//                   SizedBox(height: 10.h),
//                   Text(
//                     widget.event.get('description') ?? 'No description available',
//                     style: TextStyle(fontSize: 12.sp, height: 1.5),
//                   ),
//                   SizedBox(height: 30.h),
//                   Text(
//                     'Tickets',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.bold,
//                       color: AppKolors.blackness,
//                     ),
//                   ),
//                   SizedBox(height: 15.h),
//                   Card(
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.all(16.w),
//                       child: _buildTicketSection(context, ref),
//                     ),
//                   ),
//                   SizedBox(height: 30.h),
//                   ElevatedButton(
//                     onPressed: isFullyBooked
//                         ? null
//                         : () async {
//                             final eventData = widget.event.data() as Map<String, dynamic>? ?? {};
//                             final isFree = eventData['isFree'] ?? false;
//                             final price = eventData['price'] ?? 0;

//                             showModalBottomSheet(
//                               context: context,
//                               isScrollControlled: true,
//                               backgroundColor: Colors.transparent,
//                               builder: (context) => BookingConfirmationDialog(
//                                 event: widget.event,
//                                 isFree: isFree,
//                                 basePrice: price,
//                               ),
//                             );
//                           },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppKolors.accent3,
//                       minimumSize: Size(double.infinity, 50.h),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       isFullyBooked ? 'Fully Booked' : 'Book Tickets',
//                       style: TextStyle(fontSize: 18.sp, color: Colors.white),
//                     ),
//                   ),
//                 ],

//               ),
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }
// }

// class TicketCategory extends ConsumerWidget {
//   final String name;
//   final int price;
//   final int maxTickets;

//   const TicketCategory({
//     super.key,
//     required this.name,
//     required this.price,
//     required this.maxTickets,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     final quantity = ref.watch(ticketQuantitiesProvider.select((state) => state[name] ?? 0));
//     final notifier = ref.read(ticketQuantitiesProvider.notifier);

//     final totalPrice = quantity * price;

//     return Padding(
//       padding: const EdgeInsets.all(10.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title & Price
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 name,
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: AppKolors.blackness,
//                 ),
//               ),
//               if (quantity > 0)
//                 Chip(
//                   side: BorderSide(
//                     color: theme.colorScheme.primaryContainer,
//                     width: 1.5,
//                   ),
//                   elevation: 0,
//                   backgroundColor: theme.colorScheme.primaryContainer,
//                   label: Text(
//                     'KSH $totalPrice',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: theme.colorScheme.onPrimaryContainer,
//                     ),
//                   ),
//                 ),
//             ],
//           ),

//           // Price per ticket
//           Row(
//             children: [
//               Text(
//                 'KSH $price per ticket',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.hintColor,
//                 ),
//               ),
//             ],
//           ),

//           // Quantity Controls
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Quantity:',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Row(
//                 children: [
//                   IconButton(
//                     onPressed: () => notifier.decrement(name),
//                     icon: Icon(Icons.remove),
//                     color: theme.colorScheme.primary,
//                   ),
//                   Text('$quantity'),
//                   IconButton(
//                     onPressed: () => notifier.increment(name),
//                     icon: Icon(Icons.add),
//                     color: theme.colorScheme.primary,
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           // Max tickets warning
//           if (quantity == maxTickets)
//             Padding(
//               padding: const EdgeInsets.only(top: 8.0),
//               child: Text(
//                 'Maximum $maxTickets tickets allowed.',
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: theme.colorScheme.error,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
