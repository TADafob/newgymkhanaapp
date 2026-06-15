// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class EventDetailsPage extends ConsumerStatefulWidget {
//   final DocumentSnapshot event;
//   const EventDetailsPage({super.key, required this.event});

//   @override
//   ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
// }

// class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
//   bool _isBooking = false;

//   @override
//   Widget build(BuildContext c) {
//     final ticketQuantities = ref.watch(ticketQuantitiesProvider);
//     final totalTickets = ticketQuantities.values.fold(0, (sum, qty) => sum + qty);
//     final data = widget.event.data() as Map<String, dynamic>;
//     final ticketsSold = data['ticketsSold'] as int? ?? 0;
//     final target = data['target_No'] as int? ?? 0;
//     final dateTs = data['date'] as Timestamp?;
//     final dateTime = dateTs?.toDate() ?? DateTime.now();

//     final isPast = dateTime.isBefore(DateTime.now());
//     final fullyBooked = ticketsSold >= target;

//     final isButtonEnabled = totalTickets > 0 && !fullyBooked && !isPast && !_isBooking;

//     return Scaffold(
//       appBar: AppBar(title: Text(data['title'] ?? 'Event')),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // ... Your existing UI here

//             ElevatedButton(
//               onPressed: isButtonEnabled
//                   ? () async {
//                       setState(() => _isBooking = true);

//                       // simulate booking process or open dialog
//                       await showModalBottomSheet(
//                         context: c,
//                         isScrollControlled: true,
//                         backgroundColor: Colors.transparent,
//                         builder: (_) => BookingConfirmationDialog(
//                           event: widget.event,
//                           isFree: data['isFree'] as bool? ?? false,
//                           basePrice: data['price'] as int? ?? 0,
//                         ),
//                       );

//                       setState(() => _isBooking = false);
//                     }
//                   : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isButtonEnabled ? AppKolors.accent3 : Colors.grey,
//                 minimumSize: Size(double.infinity, 50.h),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               child: _isBooking
//                   ? SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                     )
//                   : Text(
//                       'Book Tickets',
//                       style: TextStyle(fontSize: 18.sp, color: Colors.white),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
