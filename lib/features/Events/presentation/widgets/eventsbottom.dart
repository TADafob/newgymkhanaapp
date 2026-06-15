// lib/features/Events/presentation/widgets/event_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Events/presentation/providers/bookmarkprovider.dart';

class EventCard extends StatelessWidget {
  final String eventId;
  final String imageUrl;
  final String title;
  final String location;
  final dynamic date; // Timestamp, DateTime or ISO string
  final String price;
  final String status;
  final bool isFree;

  const EventCard({
    super.key,
    required this.eventId,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.date,
    required this.price,
    required this.status,
    this.isFree = false,
  });

  DateTime? get _parsedDate {
    if (date is Timestamp) return (date as Timestamp).toDate();
    if (date is DateTime) return date as DateTime;
    if (date is String) {
      try {
        return DateTime.parse(date as String);
      } catch (_) {}
    }
    return null;
  }

  String get _month =>
      _parsedDate != null ? DateFormat('MMM').format(_parsedDate!) : '--';
  String get _day =>
      _parsedDate != null ? DateFormat('dd').format(_parsedDate!) : '--';

  bool get _isFree => isFree || price == '0' || price.toLowerCase() == 'free';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.w,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // 1) Background image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholder: (_, __) => Container(color: Colors.grey[800]),
                errorWidget: (_, __, ___) => const Icon(Icons.error, size: 48),
              ),
            ),

            // 2) Gradient overlay
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                    ],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
            ),

            // 3) Date badge
            Positioned(
              top: 12,
              left: 12,
              child: _DateBadge(day: _day, month: _month),
            ),

            // 4) Bookmark button (isolated rebuild)
            Positioned(
              top: 12,
              right: 12,
              child: _BookmarkButton(eventId),
            ),

            // 5) Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _BottomInfo(
                  title: title,
                  location: location,
                  eventId: eventId,
                  isFree: _isFree,
                  price: _isFree ? 'Free' : price,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String day, month;
  const _DateBadge({required this.day, required this.month});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppKolors.secondary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(day,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppKolors.background,
                )),
            Text(month,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppKolors.background,
                )),
          ],
        ),
      );
}

class _BottomInfo extends StatelessWidget {
  final String title, location, price, eventId;
  final bool isFree;

  const _BottomInfo({
    required this.title,
    required this.location,
    required this.eventId,
    required this.isFree,
    required this.price,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on,
                  size: 14.sp, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.9))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Attendee count
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events_collection')
                      .doc(eventId)
                      .collection('bookings')
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(width: 60, height: 20);
                    }
                    final total = snap.data?.docs.length ?? 0;
                    final display = total > 50 ? '50+' : total.toString();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_alt,
                            size: 16, color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(display,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14)),
                      ],
                    );
                  },
                ),
              ),

              // Price / Free badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFree
                      ? Colors.greenAccent.withValues(alpha: 0.8)
                      : AppKolors.accent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFree ? 'Free' : (price.startsWith('From') ? price : 'Ksh. $price'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      );
}

class _BookmarkButton extends ConsumerWidget {
  final String eventId;
  const _BookmarkButton(this.eventId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // only rebuild when this event’s bookmark state changes
    final isBookmarked = ref.watch(
      bookmarkProvider.select((list) => list.contains(eventId)),
    );

    return GestureDetector(
      onTap: () => ref.read(bookmarkProvider.notifier).toggleBookmark(eventId),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppKolors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isBookmarked ? Icons.favorite : Icons.favorite_border,
          color: AppKolors.accent3,
          size: 20,
        ),
      ),
    );
  }
}
