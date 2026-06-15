import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/common/widgets/dateformat.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyTicketsPage extends StatelessWidget {
  final String userId;

  const MyTicketsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('bookings')
          .where('booked_By', isEqualTo: userId)
          .snapshots(),
      builder: (context, bookingSnapshot) {
        if (bookingSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppKolors.primary));
        }

        if (bookingSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red.withOpacity(0.5)),
                SizedBox(height: 12.h),
                Text('Error loading tickets', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
              ],
            ),
          );
        }

        final bookings = bookingSnapshot.data?.docs ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppKolors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.airplane_ticket_outlined, size: 48.sp, color: AppKolors.primary),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No Tickets Yet',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Book an event to get your tickets',
                  style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          );
        }

        // Aggregate total tickets across all bookings
        int grandTotal = 0;
        for (final doc in bookings) {
          final booking = doc.data() as Map<String, dynamic>;
          final ticketsMap = (booking['tickets'] as Map<String, dynamic>?) ?? {};
          grandTotal += ticketsMap.entries.fold<int>(0, (sum, entry) {
            final v = entry.value;
            if (v is num) return sum + v.toInt();
            if (v is Map && v['count'] is num) return sum + (v['count'] as num).toInt();
            return sum;
          });
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          children: [
            // ── Summary Banner ──────────────────────────────────
            _SummaryBanner(totalTickets: grandTotal, totalEvents: bookings.length, isDark: isDark),
            SizedBox(height: 24.h),
            Text(
              'Your Tickets',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
            ),
            SizedBox(height: 12.h),
            ...bookings.map((doc) {
              final booking = doc.data() as Map<String, dynamic>;
              final ticketsMap = (booking['tickets'] as Map<String, dynamic>?) ?? {};
              int totalTickets = ticketsMap.entries.fold<int>(0, (sum, entry) {
                final v = entry.value;
                if (v is num) return sum + v.toInt();
                if (v is Map && v['count'] is num) return sum + (v['count'] as num).toInt();
                return sum;
              });

              final eventRef = doc.reference.parent.parent!;
              final orderId = doc.id;
              final eventId = eventRef.id;

              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: FutureBuilder<DocumentSnapshot>(
                  future: eventRef.get(),
                  builder: (context, eventSnap) {
                    if (!eventSnap.hasData) return const SizedBox.shrink();
                    final eventData = eventSnap.data!.data() as Map<String, dynamic>;
                    return TicketCard(
                      eventTitle: eventData['title'] ?? 'Unknown',
                      dateTime: (eventData['date'] as Timestamp?)?.toDate(),
                      orderId: orderId,
                      bookingId: orderId,
                      eventId: eventId,
                      totalTickets: totalTickets,
                      ticketsMap: ticketsMap,
                      imageUrl: eventData['image_Url'] ?? '',
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Summary Banner ─────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final int totalTickets;
  final int totalEvents;
  final bool isDark;

  const _SummaryBanner({required this.totalTickets, required this.totalEvents, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppKolors.primary, AppKolors.primaryDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: AppKolors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.airplane_ticket_rounded, color: Colors.white, size: 40),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Tickets',
                style: TextStyle(fontSize: 12.sp, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              Text(
                '$totalTickets',
                style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  '$totalEvents',
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  totalEvents == 1 ? 'Event' : 'Events',
                  style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket Card ────────────────────────────────────────────────────────────────
class TicketCard extends StatelessWidget {
  final String eventTitle;
  final DateTime? dateTime;
  final int totalTickets;
  final Map<String, dynamic> ticketsMap;
  final String orderId;
  final String bookingId;
  final String eventId;
  final String imageUrl;

  const TicketCard({
    super.key,
    required this.eventTitle,
    required this.totalTickets,
    required this.ticketsMap,
    required this.dateTime,
    required this.orderId,
    required this.bookingId,
    required this.eventId,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Top: Ticket Count Hero ───────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 20.w),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppKolors.primary, AppKolors.primaryDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big ticket count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalTickets',
                      style: TextStyle(
                        fontSize: 56.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      totalTickets == 1 ? 'TICKET' : 'TICKETS',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Breakdown chips
                if (ticketsMap.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: ticketsMap.entries.map((e) {
                      final qty = e.value is num
                          ? (e.value as num).toInt()
                          : (e.value is Map ? (e.value['count'] as num?)?.toInt() ?? 0 : 0);
                      if (qty == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '$qty × ${e.key}',
                            style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // ── Perforated Divider ───────────────────────────────
          _PerforatedDivider(isDark: isDark, cardColor: cardColor),

          // ── Bottom: Event Info + QR ──────────────────────────
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Code
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: QrImageView(
                    data: orderId,
                    version: QrVersions.auto,
                    size: 64.w,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                SizedBox(width: 14.w),
                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event thumbnail + title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.network(
                                imageUrl,
                                width: 40.w,
                                height: 40.w,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          if (imageUrl.isNotEmpty) SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              eventTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11.sp, color: AppKolors.primary),
                          SizedBox(width: 4.w),
                          Text(
                            dateTime != null ? formatDateWithSuffix(dateTime!) : 'TBD',
                            style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '#${orderId.substring(0, orderId.length > 10 ? 10 : orderId.length).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        height: 36.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppKolors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            elevation: 0,
                          ),
                          onPressed: () => context.goNamed(
                            'Ticket',
                            pathParameters: {'eventId': eventId, 'orderId': bookingId},
                          ),
                          child: Text(
                            'View Ticket',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Perforated Divider ─────────────────────────────────────────────────────────
class _PerforatedDivider extends StatelessWidget {
  final bool isDark;
  final Color cardColor;

  const _PerforatedDivider({required this.isDark, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8);
    return SizedBox(
      height: 24.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            thickness: 1,
            indent: 20.w,
            endIndent: 20.w,
          ),
          // Left notch
          Positioned(
            left: 0,
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            ),
          ),
          // Right notch
          Positioned(
            right: 0,
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
