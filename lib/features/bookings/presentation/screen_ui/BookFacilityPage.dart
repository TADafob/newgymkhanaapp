import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/bookings/data/models/bookingmodel.dart';
import 'package:nrbgymkhana/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/allbookingspage.dart'
    as allbookings;
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingdetails.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingscard.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/cancelsportsbookingwidget.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/dateformatterbookings.dart';
import 'package:nrbgymkhana/features/common/widgets/dateformat.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';
import 'package:nrbgymkhana/features/common/widgets/sectionheader.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/reportbookingissue.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/booking_category.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/sports_booking_page.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/session_booking_page.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:intl/intl.dart';

class BookFacilityPage extends ConsumerWidget {
  const BookFacilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: responsiveLayout(
        smallScreen: _buildSmallScreen(context, ref),
        mediumScreen: _buildMediumScreen(context, ref),
      ),
    );
  }

  Widget _buildSmallScreen(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return ListView(
      children: [
        _BookingsHeroHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book a Facility',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppKolors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a facility category to get started',
                style: TextStyle(fontSize: 13, color: AppKolors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BookingCategoryButton(
                      label: 'Sports',
                      subtitle: 'Courts & fields',
                      icon: Icons.sports_tennis_rounded,
                      gradient: const [Color(0xFF054a5e), Color(0xFF07b8a6)],
                      onTap: () => GoRouter.of(context)
                          .go('/book-facility/book-category/Sports'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BookingCategoryButton(
                      label: 'Club',
                      subtitle: 'Hire club spaces',
                      icon: Icons.stadium_outlined,
                      gradient: const [Color(0xFF1a2e35), Color(0xFF2c4a5a)],
                      onTap: () => GoRouter.of(context)
                          .go('/book-facility/book-category/Clubs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BookingCategoryButton(
                label: 'Bandas',
                subtitle: 'Cook & dine spaces',
                icon: Icons.outdoor_grill_outlined,
                gradient: const [Color(0xFF5e3a1a), Color(0xFFb87333)],
                onTap: () => GoRouter.of(context)
                    .go('/book-facility/book-category/Bandas'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              SectionHeader(
                title: 'Upcoming Bookings',
                onSeeAll: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const allbookings.BookingsOverviewPage();
                  }));
                },
              ),
              bookingsAsync.when(
                data: (bookings) {
                  bookings = bookings.where((booking) {
                    if (booking.status == 'Cancelled') return false;
                    DateTime bookingDate = booking.bookingDate;
                    DateTime today = DateTime.now();
                    DateTime startOfToday =
                        DateTime(today.year, today.month, today.day);
                    DateTime startOfBookingDate = DateTime(
                        bookingDate.year, bookingDate.month, bookingDate.day);

                    return startOfBookingDate.isAfter(startOfToday) ||
                        startOfBookingDate.isAtSameMomentAs(startOfToday);
                  }).toList();

                  if (bookings.isEmpty) {
                    return nodatawidget(
                      title: 'All your active bookings will appear here',
                    );
                  }

                  bookings
                      .sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

                  Map<String, List<Booking>> groupedBookings = {};
                  for (var booking in bookings) {
                    String groupKey = _getFormattedDate(booking.bookingDate);
                    if (groupedBookings.containsKey(groupKey)) {
                      groupedBookings[groupKey]!.add(booking);
                    } else {
                      groupedBookings[groupKey] = [booking];
                    }
                  }

                  List<Widget> bookingWidgets = [];
                  groupedBookings.forEach((date, bookingsList) {
                    bookingWidgets.add(
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            child: Text(
                              date,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    );
                    for (var booking in bookingsList) {
                      bookingWidgets.add(
                        _BookingCardWrapper(
                          booking: booking,
                          context: context,
                          ref: ref,
                        ),
                      );
                    }
                  });

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(bookingsProvider);
                    },
                    child: Column(children: bookingWidgets),
                  );
                },
                loading: () => const PageShimmer(itemCount: 4),
                error: (error, stack) => Center(child: Text('Error: $error')),
              )
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  String _getFormattedDate(DateTime date) {
    DateTime today = DateTime.now();
    DateTime tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  Widget _buildMediumScreen(BuildContext context, WidgetRef ref) {
    return Center(
      child: SizedBox(
        width: 400,
        child: _buildSmallScreen(context, ref),
      ),
    );
  }
}

class _BookingCardWrapper extends StatelessWidget {
  final Booking booking;
  final BuildContext context;
  final WidgetRef ref;

  const _BookingCardWrapper({
    required this.booking,
    required this.context,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: BookingsCard(
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
            ? () async {
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
            : null,
        onCancel: () {
          showCancelDialog(
            context: context,
            ref: ref,
            booking: booking,
          );
        },
        onraiseIssue: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReportIssueForm(
                        bookingId: booking.bookingId,
                        onSubmit: (stringNo) {},
                      )));
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

// ── Bookings Hero Header ──────────────────────────────────────────────────────
class _BookingsHeroHeader extends StatelessWidget {
  const _BookingsHeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0693e3), Color(0xFF057ab8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppKolors.accent.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Reserve your spot today',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
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
}

// ── Booking Category Button ───────────────────────────────────────────────────
class _BookingCategoryButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _BookingCategoryButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Book now',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 13, color: Colors.white.withValues(alpha: 0.90)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
