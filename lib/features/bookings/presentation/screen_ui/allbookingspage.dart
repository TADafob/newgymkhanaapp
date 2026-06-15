import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/bookings/data/models/bookingmodel.dart';
import 'package:nrbgymkhana/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/booking_category.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/sports_booking_page.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/session_booking_page.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingdetails.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingscard.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/cancelsportsbookingwidget.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/dateformatterbookings.dart';
import 'package:nrbgymkhana/features/common/widgets/dateformat.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';

import 'reportbookingissue.dart';

class BookingsOverviewPage extends ConsumerWidget {
  const BookingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: AppKolors.background,
      body: Column(
        children: [
          // ── Step 1: Modern Hero Header ──────────────────────────
          _BookingsHeroHeader(bookingsAsync: bookingsAsync),

          // ── Steps 2–4: Pill Tabs + List ─────────────────────────
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // ── Step 2: Pill-style segmented tab bar ──────────
                  const _PillTabBar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: const [
                        FilteredBookingsList(filter: BookingFilter.all),
                        FilteredBookingsList(filter: BookingFilter.confirmed),
                        FilteredBookingsList(filter: BookingFilter.pending),
                        FilteredBookingsList(filter: BookingFilter.cancelled),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Hero Header Widget ─────────────────────────────────────────────────
class _BookingsHeroHeader extends StatelessWidget {
  final AsyncValue<List<Booking>> bookingsAsync;
  const _BookingsHeroHeader({required this.bookingsAsync});

  @override
  Widget build(BuildContext context) {
    final total = bookingsAsync.valueOrNull?.length ?? 0;
    final confirmed =
        bookingsAsync.valueOrNull?.where((b) => b.status == 'Confirmed').length ?? 0;
    final pending =
        bookingsAsync.valueOrNull?.where((b) => b.status == 'Unconfirmed').length ?? 0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppKolors.dark, AppKolors.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'My Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  _StatChip(label: 'Total', value: total, color: AppKolors.accent),
                  const SizedBox(width: 10),
                  _StatChip(
                      label: 'Confirmed',
                      value: confirmed,
                      color: Colors.green.shade400),
                  const SizedBox(width: 10),
                  _StatChip(
                      label: 'Pending',
                      value: pending,
                      color: Colors.orange.shade300),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Pill Tab Bar ───────────────────────────────────────────────────────
class _PillTabBar extends StatelessWidget {
  const _PillTabBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppKolors.border,
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: AppKolors.dark,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppKolors.dark.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppKolors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Pending'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
    );
  }
}

// ── Enum ───────────────────────────────────────────────────────────────────────
enum BookingFilter { all, confirmed, pending, cancelled }

// ── Filtered List ──────────────────────────────────────────────────────────────
class FilteredBookingsList extends ConsumerWidget {
  final BookingFilter filter;
  const FilteredBookingsList({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        List<Booking> filteredBookings = bookings.where((booking) {
          switch (filter) {
            case BookingFilter.confirmed:
              return booking.status == 'Confirmed';
            case BookingFilter.pending:
              return booking.status == 'Unconfirmed';
            case BookingFilter.cancelled:
              return booking.status == 'Cancelled';
            case BookingFilter.all:
            default:
              return true;
          }
        }).toList();

        if (filteredBookings.isEmpty) {
          return nodatawidget(title: 'No bookings found.');
        }

        filteredBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

        Map<String, List<Booking>> groupedBookings = {};
        for (var booking in filteredBookings) {
          final key = _getGroupKey(booking.bookingDate);
          groupedBookings.putIfAbsent(key, () => []).add(booking);
        }

        List<String> groupKeys = groupedBookings.keys.toList();
        groupKeys.sort((a, b) {
          if (a == 'Today') return -1;
          if (b == 'Today') return 1;
          DateTime da = DateFormat('MMMM yyyy').parse(a);
          DateTime db = DateFormat('MMMM yyyy').parse(b);
          return db.compareTo(da);
        });

        List<Widget> bookingWidgets = [];
        for (String group in groupKeys) {
          // ── Step 3: Styled group header ──────────────────────────
          bookingWidgets.add(_GroupHeader(label: group));
          for (var booking in groupedBookings[group]!) {
            bookingWidgets.add(
              BookingsCard(
                id: booking.bookingId,
                title: booking.facilityName,
                status: booking.status,
                dateBooked: (booking.facilityType == 'Club' || booking.facilityType == 'Bandas')
                    ? formatDateRangeWithSuffix(booking.startTime, booking.endTime)
                    : formatDateWithSuffix(booking.bookingDate),
                dateCheck: booking.startTime,
                timeCheck: formatTime(booking.startTime),
                time: formatHourRange(booking.startTime, booking.endTime),
                facilityType: booking.facilityType,
                courtNo: booking.court_No,
                isPaid: booking.isPaid,
                guestLevy: booking.guestCount * 200,
                onPayNow: (!booking.isPaid && booking.guestCount > 0)
                    ? () => showPayGuestLevyDialog(
                          context,
                          ref,
                          booking.bookingId,
                          booking.guestCount * 200,
                        )
                    : null,
                onRebook: (booking.status == 'Cancelled' ||
                        booking.startTime.isBefore(DateTime.now()))
                    ? () => _rebookBooking(context, booking)
                    : null,
                onCancel: () {
                  showCancelDialog(context: context, ref: ref, booking: booking);
                },
                onraiseIssue: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportIssueForm(
                        bookingId: booking.bookingId,
                        onSubmit: (stringNo) {},
                      ),
                    ),
                  );
                },
                ondetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingDetailsPage(
                        requestNumber: booking.bookingId,
                        facilityName: booking.facilityName,
                        date: (booking.facilityType == 'Club' || booking.facilityType == 'Bandas')
                            ? formatDateRangeWithSuffix(
                                booking.startTime, booking.endTime)
                            : formatDateWithSuffix(booking.bookingDate),
                        timeSlot:
                            '${formatTime(booking.startTime)} – ${formatTime(booking.endTime)}',
                        numberOfPeople: booking.noOfAttendees,
                        imageUrl: booking.imageUrl,
                        courtNo: booking.court_No,
                        status: booking.status,
                      ),
                    ),
                  );
                },
              ),
            );
          }
        }

        return RefreshIndicator(
          color: AppKolors.primary,
          onRefresh: () async => ref.invalidate(bookingsProvider),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                0, 8, 0, MediaQuery.of(context).padding.bottom + 80),
            children: bookingWidgets,
          ),
        );
      },
      loading: () => const PageShimmer(itemCount: 6),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  String _getGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(date.year, date.month, date.day);
    return bookingDay == today ? 'Today' : DateFormat('MMMM yyyy').format(date);
  }
}

// ── Step 3: Styled Group Header ────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final isToday = label == 'Today';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isToday
                  ? AppKolors.primary.withValues(alpha: 0.12)
                  : AppKolors.dark.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday
                    ? AppKolors.primary.withValues(alpha: 0.3)
                    : AppKolors.dark.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isToday ? Icons.today_rounded : Icons.calendar_month_outlined,
                  size: 13,
                  color: isToday ? AppKolors.primary : AppKolors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isToday ? AppKolors.primary : AppKolors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: AppKolors.border,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Utility function to format DateTime to a readable time string.
String formatTime(DateTime time) {
  return DateFormat('h:mm a').format(time);
}

Future<void> _rebookBooking(BuildContext context, Booking booking) async {
  final snap = await FirebaseFirestore.instance
      .collection('Facilities')
      .where('facility_Id', isEqualTo: booking.facilityId)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return;
  final data = snap.docs.first.data();
  final imageUrl = data['image'] as String? ?? '';
  final courts = data['courts'];
  final bookingMode = data['booking_Mode'] as String? ?? 'slot';
  final facilityDocId = snap.docs.first.id;
  if (!context.mounted) return;
  final container = ProviderScope.containerOf(context, listen: false);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProviderScope(
        overrides: [
          selectedFacilityProvider.overrideWith((r) => facilityDocId),
        ],
        child: bookingMode == 'session'
            ? SessionBookingPage(
                facilityName: booking.facilityName,
                imageUrl: imageUrl,
                facilityDocId: facilityDocId,
              )
            : SportsBookingPage(
                facilityName: booking.facilityName,
                imageUrl: imageUrl,
                numberOfCourts: courts is int ? courts : (courts is List ? courts.length : 1),
              ),
      ),
    ),
  ).whenComplete(() => resetBookingForm(container));
}
