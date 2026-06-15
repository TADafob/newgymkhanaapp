// lib/features/Events/presentation/widgets/trending_event_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Events/presentation/providers/bookmarkprovider.dart';

class TrendingEventCard extends StatelessWidget {
  final String eventId;
  final String imageUrl;
  final String title;
  final String location;
  final dynamic date; // Timestamp, DateTime, or ISO string
  final String price;
  final bool isFree;
  final String status;
  final VoidCallback onTapped;
  final bool isSingleEvent;

  const TrendingEventCard({
    super.key,
    required this.eventId,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.date,
    required this.price,
    required this.isFree,
    required this.status,
    required this.onTapped,
    this.isSingleEvent = false,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isSingleEvent ? 315.w : 280.w,
      child: GestureDetector(
        onTap: onTapped,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            _EventImage(imageUrl: imageUrl),
            const _GradientOverlay(),
            Positioned(
                top: 12, left: 12, child: _DateBadge(day: _day, month: _month)),
            Positioned(top: 12, right: 12, child: _BookmarkButton(eventId)),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _EventInfo(
                  eventId: eventId,
                  title: title,
                  location: location,
                  date: _parsedDate,
                  price: price,
                  isFree: isFree,
                )),
          ]),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  final String imageUrl;
  const _EventImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 160.h,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) => Container(color: Colors.grey[800]),
          errorWidget: (_, __, ___) => const Icon(Icons.error, size: 48),
        ),
      );
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7)),
        ),
      );
}

class _DateBadge extends StatelessWidget {
  final String day, month;
  const _DateBadge({required this.day, required this.month});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppKolors.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(day,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppKolors.background)),
          Text(month,
              style: TextStyle(fontSize: 12, color: AppKolors.background)),
        ]),
      );
}

class _BookmarkButton extends ConsumerWidget {
  final String eventId;
  const _BookmarkButton(this.eventId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      bookmarkProvider.select((list) => list.contains(eventId)),
    );

    return GestureDetector(
      onTap: () => ref.read(bookmarkProvider.notifier).toggleBookmark(eventId),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppKolors.primary.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isBookmarked ? Icons.favorite : Icons.favorite_border,
          color: AppKolors.accent3,
        ),
      ),
    );
  }
}

class _EventInfo extends StatelessWidget {
  final String eventId, title, location, price;
  final bool isFree;
  final DateTime? date;
  const _EventInfo({
    required this.eventId,
    required this.title,
    required this.location,
    required this.date,
    required this.price,
    required this.isFree,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.location_on,
                  size: 16, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(
                location,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
              )),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: _AttendeeAvatars(eventId: eventId)),
              _PriceBadge(isFree: isFree, price: price),
            ]),
          ],
        ),
      );
}

class _AttendeeAvatars extends StatelessWidget {
  final String eventId;
  const _AttendeeAvatars({required this.eventId});

  static const double _diam = 24.0, _ovlp = 12.0;

  Widget _avatar(String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (_, imgProv) =>
            CircleAvatar(radius: _diam / 2, backgroundImage: imgProv),
        placeholder: (_, __) => _genericAvatar(),
        errorWidget: (_, __, ___) => _genericAvatar(),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
      );
    }
    return _genericAvatar();
  }

  Widget _genericAvatar() => CircleAvatar(
        radius: _diam / 2,
        backgroundColor: Colors.grey[600],
        child: const Icon(Icons.person, size: 16, color: Colors.white),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events_collection')
          .doc(eventId)
          .collection('bookings')
          .snapshots(),
      builder: (ctx, bookingSnap) {
        if (bookingSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: _diam);
        }

        final allDocs = bookingSnap.data?.docs ?? [];
        final total = allDocs.length;
        if (total == 0) {
          return Row(children: [
            Icon(Icons.event_available,
                size: 16, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text('Be the first to book!',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
          ]);
        }

        // Extract member UIDs only — guests have no booked_By field
        final memberUids = allDocs
            .map((d) => (d.data() as Map<String, dynamic>?)?['booked_By'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final displayUids = memberUids.take(3).toList();

        // Build the avatar row, fetching member avatars only if any exist
        Widget buildAvatarRow(Map<String, String> avatarMap) {
          // Show up to 3 slots: member avatar or generic for guests
          final slotCount = displayUids.isNotEmpty ? displayUids.length : (total > 3 ? 3 : total);
          return SizedBox(
            height: _diam,
            width: (slotCount * _ovlp) + _diam + 40,
            child: Stack(clipBehavior: Clip.none, children: [
              for (var i = 0; i < slotCount; i++)
                Positioned(
                  left: i * _ovlp,
                  child: _avatar(displayUids.length > i ? avatarMap[displayUids[i]] : null),
                ),
              Positioned(
                left: (slotCount * _ovlp) + 16,
                top: 4,
                child: Text(
                  total > slotCount ? '+${total - slotCount} Attending' : 'Attending',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          );
        }

        // No member UIDs at all (all guests) — skip Firestore user query
        if (displayUids.isEmpty) return buildAvatarRow({});

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users_members')
              .where(FieldPath.documentId, whereIn: displayUids)
              .snapshots(),
          builder: (ctx2, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: _diam);
            }
            final avatarMap = <String, String>{
              for (var doc in userSnap.data?.docs ?? [])
                doc.id: (doc.data() as Map<String, dynamic>)['avatar_Url'] as String? ?? ''
            };
            return buildAvatarRow(avatarMap);
          },
        );
      },
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final bool isFree;
  final String price;
  const _PriceBadge({required this.isFree, required this.price});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isFree
              ? Colors.greenAccent.withValues(alpha: 0.8)
              : Colors.amber.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isFree ? 'Free' : (price.startsWith('From') ? price : 'Ksh. $price'),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
}
