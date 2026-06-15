import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Events/presentation/providers/ticketnotifier.dart';
import 'package:nrbgymkhana/features/Events/presentation/screens_ui/bookingstatuspage.dart';
import 'package:nrbgymkhana/features/Events/presentation/widgets/ticketsection.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  final DocumentSnapshot event;
  const EventDetailsPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final ticketQuantities = ref.watch(ticketQuantitiesProvider);
    final totalTickets =
        ticketQuantities.values.fold(0, (sum, qty) => sum + qty);
    final data = widget.event.data() as Map<String, dynamic>;
    final imageUrl = data['image_Url'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final dateTs = data['date'] as Timestamp?;
    final dateTime = dateTs?.toDate() ?? DateTime.now();
    final tickets =
        (data['ticketCategories'] as List? ?? []).cast<Map<String, dynamic>>();
    final isFree = data['isFree'] as bool? ?? false;
    final basePrice = data['price'] as int? ?? 0;
    final target = data['target_No'] as int? ?? 0;
    final ticketsSold = data['ticketsSold'] as int? ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isPast = dateTime.isBefore(DateTime.now());
    final fullyBooked = ticketsSold >= target;
    final isButtonEnabled = !fullyBooked && !isPast && !_isBooking;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, imageUrl, isDark),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(title, location, isDark),
                      SizedBox(height: 20.h),
                      _buildDateTimeSection(dateTime, isDark),
                      SizedBox(height: 24.h),
                      _buildProgressSection(ticketsSold, target, isDark),
                      SizedBox(height: 28.h),
                      _buildAboutSection(description, isDark),
                      SizedBox(height: 28.h),
                      _buildTicketsSection(tickets, isFree, basePrice, isDark),
                      SizedBox(height: 28.h),
                      _buildBookButton(
                        isButtonEnabled,
                        isPast,
                        fullyBooked,
                        totalTickets,
                        context,
                        data,
                      ),
                      SizedBox(height: 100.h),
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

  Widget _buildSliverAppBar(
      BuildContext context, String imageUrl, bool isDark) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: widget.event.id,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(String title, String location, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Icon(Icons.location_on, size: 18.sp, color: AppKolors.primary),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(DateTime dateTime, bool isDark) {
    final fmtDate = DateFormat('EEEE, MMMM d, yyyy').format(dateTime);
    final fmtTime = DateFormat('h:mm a').format(dateTime);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppKolors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.calendar_today,
                size: 20.sp, color: AppKolors.primary),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmtDate,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  fmtTime,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(int ticketsSold, int target, bool isDark) {
    final percentage =
        target > 0 ? (ticketsSold / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tickets Sold',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '$ticketsSold / $target',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppKolors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8.h,
              backgroundColor:
                  isDark ? Colors.white10 : Colors.black.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppKolors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String description, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Event',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          description,
          style: TextStyle(
            fontSize: 13.sp,
            height: 1.7,
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsSection(
    List<Map<String, dynamic>> tickets,
    bool isFree,
    int basePrice,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Tickets',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          child: TicketSection(
            categories: tickets,
            isFree: isFree,
            basePrice: basePrice,
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton(
    bool isButtonEnabled,
    bool isPast,
    bool fullyBooked,
    int totalTickets,
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    String buttonText;
    if (isPast) {
      buttonText = 'Event Ended';
    } else if (fullyBooked) {
      buttonText = 'Fully Booked';
    } else {
      buttonText = 'Book Now';
    }

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isButtonEnabled
            ? () async {
                if (totalTickets == 0) {
                  Fluttertoast.showToast(
                    msg: 'Please select at least one ticket',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: AppKolors.accent3,
                    textColor: Colors.white,
                    fontSize: 14.sp,
                  );
                  return;
                }

                setState(() => _isBooking = true);

                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BookingConfirmationDialog(
                    event: widget.event,
                    isFree: data['isFree'] as bool? ?? false,
                    basePrice: data['price'] as int? ?? 0,
                  ),
                );

                setState(() => _isBooking = false);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonEnabled
              ? AppKolors.primary
              : Colors.grey.withOpacity(0.5),
          disabledBackgroundColor: Colors.grey.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: isButtonEnabled ? 6 : 0,
          shadowColor: AppKolors.primary.withOpacity(0.4),
        ),
        child: _isBooking
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
