import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Events/presentation/providers/eventsbookingsprov.dart';

class BookingStats extends ConsumerWidget {
  final String eventId;
  final String formattedTime;
  final int target;

  const BookingStats({
    super.key,
    required this.eventId,
    required this.formattedTime,
    required this.target,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingsProvider(eventId));

    return async.when(
      loading: () => const SizedBox(
        width: 100, height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Text('—', style: TextStyle(color: AppKolors.secondary)),
      data: (snap) {
        final docs = snap.docs;
        final people = docs.length;
        final sold = docs.fold<int>(
          0,
          (sum, doc) {
            final raw = doc.data()['tickets'];
            if (raw is Map<String, dynamic>) {
              return sum + raw.values.whereType<int>().fold(0, (s,v) => s+v);
            }
            return sum;
          },
        );

        final near = target - 10;
        final color = sold >= target
            ? AppKolors.accent3
            : sold >= near
                ? AppKolors.accent3
                : AppKolors.accent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                SizedBox(width: 8.w),
                Text('From: $formattedTime', style: TextStyle(color: AppKolors.secondary)),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '$people People Booked',
              style: TextStyle(color: AppKolors.secondary, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text('($sold/$target tickets)',
              style: TextStyle(color: color, fontSize: 12.sp),
            ),
          ],
        );
      },
    );
  }
}
