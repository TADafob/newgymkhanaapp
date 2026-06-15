import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:intl/intl.dart' as intl;

String formatTime(DateTime time) {
  return intl.DateFormat('hh:mm a').format(time);
}

class BookingsCard extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final String dateBooked;
  final DateTime dateCheck;
  final String time;
  final String timeCheck;
  final String facilityType;
  final String? courtNo;
  final VoidCallback onCancel;
  final VoidCallback onraiseIssue;
  final VoidCallback ondetails;
  final VoidCallback? onPayNow;
  final VoidCallback? onRebook;
  final int guestLevy;
  final bool isPaid;

  const BookingsCard({
    super.key,
    required this.id,
    required this.title,
    required this.status,
    required this.dateBooked,
    required this.time,
    required this.dateCheck,
    required this.timeCheck,
    required this.facilityType,
    this.courtNo,
    required this.onCancel,
    required this.onraiseIssue,
    required this.ondetails,
    this.onPayNow,
    this.onRebook,
    this.guestLevy = 0,
    this.isPaid = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isClub = facilityType == 'Club';
    final isBanda = facilityType == 'Bandas';
    final isClubLike = isClub || isBanda;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDateOnly =
        DateTime(dateCheck.year, dateCheck.month, dateCheck.day);

    String timelineText;
    Color timelineColor;

    if (isClubLike) {
      if (bookingDateOnly.isAfter(today)) {
        timelineText = 'Upcoming';
        timelineColor = Colors.orange;
      } else if (bookingDateOnly.isAtSameMomentAs(today)) {
        timelineText = 'Ongoing';
        timelineColor = Colors.green.shade500;
      } else {
        timelineText = 'Past';
        timelineColor = Colors.red.shade400;
      }
    } else {
      try {
        final parsedTime = intl.DateFormat('hh:mm a').parse(timeCheck);
        final bookingStart = DateTime(dateCheck.year, dateCheck.month,
            dateCheck.day, parsedTime.hour, parsedTime.minute);
        final bookingEnd = bookingStart.add(const Duration(hours: 1));
        if (now.isBefore(bookingStart)) {
          timelineText = 'Upcoming';
          timelineColor = Colors.orange;
        } else if (now.isBefore(bookingEnd)) {
          timelineText = 'Ongoing';
          timelineColor = Colors.green.shade500;
        } else {
          timelineText = 'Past';
          timelineColor = Colors.red.shade400;
        }
      } catch (_) {
        timelineText = 'Unknown';
        timelineColor = Colors.grey;
      }
    }

    final confirmColor = status == 'Confirmed'
        ? Colors.green.shade500
        : status == 'Unconfirmed'
            ? Colors.orange
            : Colors.red.shade400;
    final confirmText = status == 'Unconfirmed' ? 'Pending' : status;
    final accentColor = isClubLike ? AppKolors.primary : AppKolors.accent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Gradient header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isClubLike
                      ? [AppKolors.dark, AppKolors.darkCard]
                      : [const Color(0xFF054a5e), const Color(0xFF07b8a6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isClubLike
                          ? (isBanda ? Icons.outdoor_grill_outlined : Icons.stadium_outlined)
                          : Icons.sports_cricket_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isClubLike
                              ? (isBanda ? 'Banda Booking' : 'Club Booking')
                              : (courtNo != null && courtNo!.isNotEmpty
                                  ? 'Court No. $courtNo'
                                  : 'Sports Facility'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(confirmText, confirmColor),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  // Info row
                  Row(
                    children: [
                      _infoItem(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: isClubLike ? 'Dates' : 'Date',
                        value: dateBooked,
                        color: accentColor,
                      ),
                      if (!isClubLike) ...[
                        const SizedBox(width: 20),
                        _infoItem(
                          context,
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: time,
                          color: accentColor,
                        ),
                      ],
                      const Spacer(),
                      _statusChip(timelineText, timelineColor),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(
                      height: 1,
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.35)),
                  const SizedBox(height: 12),

                  // Action buttons
                  if (onRebook != null)
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: onRebook,
                            icon: const Icon(Icons.replay_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Rebook',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: AppKolors.accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: ondetails,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'View Details',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (!isPaid && guestLevy > 0)
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: onCancel,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              backgroundColor: Colors.red.withValues(alpha: 0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.red.shade200, width: 1),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextButton(
                            onPressed: onPayNow,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              backgroundColor: Colors.amber.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Pay KSH $guestLevy',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextButton(
                            onPressed: ondetails,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Two buttons: Cancel | View Details
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: onCancel,
                            icon: Icon(Icons.cancel_outlined,
                                size: 16, color: Colors.red.shade400),
                            label: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Colors.red.shade200, width: 1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: ondetails,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 16, color: Colors.white),
                            label: const Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
