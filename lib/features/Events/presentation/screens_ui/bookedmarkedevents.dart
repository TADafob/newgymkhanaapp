import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Events/presentation/widgets/trendingevents.dart';

class BookmarkedEventsPage extends ConsumerWidget {
  const BookmarkedEventsPage({super.key});

  Stream<List<String>> getUserBookmarkedEventIds(String userId) {
    return FirebaseFirestore.instance
        .collection('users_members')
        .doc(userId)
        .collection('bookmarks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<List<DocumentSnapshot>> fetchBookmarkedEvents(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < eventIds.length; i += 10) {
      chunks.add(eventIds.sublist(i, i + 10 > eventIds.length ? eventIds.length : i + 10));
    }

    final allDocs = <DocumentSnapshot>[];

    for (final chunk in chunks) {
      final snapshot = await FirebaseFirestore.instance
          .collection('events_collection')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      allDocs.addAll(snapshot.docs);
    }

    return allDocs;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
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
              child: Icon(
                Icons.bookmark_outline,
                size: 48.sp,
                color: AppKolors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Sign in to view bookmarks',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please log in to save your favorite events',
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<String>>(
      stream: getUserBookmarkedEventIds(userId),
      builder: (context, bookmarkSnap) {
        if (bookmarkSnap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppKolors.primary),
          );
        }

        if (!bookmarkSnap.hasData || bookmarkSnap.data!.isEmpty) {
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
                  child: Icon(
                    Icons.bookmark_outline,
                    size: 48.sp,
                    color: AppKolors.primary,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No Bookmarks Yet',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Bookmark events to save them for later',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }

        final eventIds = bookmarkSnap.data!;

        return FutureBuilder<List<DocumentSnapshot>>(
          future: fetchBookmarkedEvents(eventIds),
          builder: (context, eventSnap) {
            if (eventSnap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: AppKolors.primary),
              );
            }

            final events = eventSnap.data ?? [];

            if (events.isEmpty) {
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
                      child: Icon(
                        Icons.bookmark_outline,
                        size: 48.sp,
                        color: AppKolors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No Bookmarks Yet',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16.w),
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemCount: events.length,
              itemBuilder: (ctx, i) {
                final ev = events[i].data() as Map<String, dynamic>;
                final data = events[i];
                final id = events[i].id;

                return TrendingEventCard(
                  eventId: id,
                  imageUrl: ev['image_Url'] ??
                      'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png',
                  title: ev['title'] ?? '',
                  location: ev['location'] ?? '',
                  date: ev['date'] ?? '',
                  price: ev['price']?.toString() ?? '',
                  isFree: ev['isFree'] ?? false,
                  onTapped: () =>
                      context.go('/the-wall/Events-thewall/event-details', extra: data),
                  status: ev['status'],
                );
              },
            );
          },
        );
      },
    );
  }
}
