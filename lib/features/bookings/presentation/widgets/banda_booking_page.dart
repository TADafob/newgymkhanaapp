import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/africas_talking_service.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';

class BandaBookingPage extends ConsumerStatefulWidget {
  const BandaBookingPage({super.key});
  @override
  _BandaBookingPageState createState() => _BandaBookingPageState();
}

class _BandaBookingPageState extends ConsumerState<BandaBookingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 state
  DateTime _selectedDay = DateTime.now();

  // Step 2 state (to be filled later)
  DateTime? _startTime;
  DateTime? _endTime;

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  String _getFacilityName(String facilityId) =>
      facilityId.toLowerCase().contains('banda') ? 'Pool area Banda' : 'Banda';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: nodatawidget(title: 'User not logged in. Please sign in to continue.'),
      );
    }

    final selectedFacility = ref.watch(selectedFacilityProvider);
    final facilityName = _getFacilityName(selectedFacility);

    return Scaffold(
      appBar: AppBar(
        title: Text('Book $facilityName', style: TextStyle(fontSize: 18.sp)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _StepIndicator(currentStep: _currentStep),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Step1(
            selectedDay: _selectedDay,
            facilityId: selectedFacility,
            onDayChanged: (d) => setState(() => _selectedDay = d),
            onContinue: () => _goToStep(1),
          ),
          _Step2(
            selectedDay: _selectedDay,
            facilityId: selectedFacility,
            startTime: _startTime,
            endTime: _endTime,
            onTimesChanged: (s, e) => setState(() {
              _startTime = s;
              _endTime = e;
            }),
            onBack: () => _goToStep(0),
            onContinue: () => _goToStep(2),
          ),
          _Step3(
            selectedDay: _selectedDay,
            facilityId: selectedFacility,
            facilityName: facilityName,
            startTime: _startTime,
            endTime: _endTime,
            onBack: () => _goToStep(1),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _labels = ['Pick Day', 'Pick Time', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color: currentStep > stepIndex
                    ? AppKolors.primary
                    : Colors.grey.shade200,
              ),
            );
          }
          final step = i ~/ 2;
          final done = currentStep > step;
          final active = currentStep == step;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? AppKolors.primary : Colors.grey.shade200,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: active ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _labels[step],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppKolors.primary : Colors.grey,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Step 1: Pick Day + Show Existing Bookings ──────────────────────────────────
class _Step1 extends ConsumerWidget {
  final DateTime selectedDay;
  final String facilityId;
  final ValueChanged<DateTime> onDayChanged;
  final VoidCallback onContinue;

  const _Step1({
    required this.selectedDay,
    required this.facilityId,
    required this.onDayChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayStart = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a Day',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppKolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Date picker tile
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDay,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppKolors.primary,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) onDayChanged(picked);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppKolors.secondary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          // coloured header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppKolors.secondary, AppKolors.primary],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Booking Date',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Tap to change',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // date body
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            color: Colors.white,
                            child: Row(
                              children: [
                                // day number badge
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppKolors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppKolors.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('d').format(selectedDay),
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w800,
                                          color: AppKolors.primary,
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM').format(selectedDay).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppKolors.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE').format(selectedDay),
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppKolors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('d MMMM yyyy').format(selectedDay),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppKolors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    color: AppKolors.secondary.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Existing bookings for selected day
                Text(
                  'Bookings on this day',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppKolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings_collection')
                      .where('facility_Id', isEqualTo: facilityId)
                      .where('facility_Type', isEqualTo: 'Bandas')
                      .where('start_Time',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
                      .where('start_Time', isLessThan: Timestamp.fromDate(dayEnd))
                      .orderBy('start_Time')
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = (snap.data?.docs ?? []).where((doc) {
                      final status =
                          (doc.data() as Map)['reaction']?['status'] as String? ?? '';
                      return status != 'Cancelled';
                    }).toList();

                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF16A34A), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'No bookings yet — day is fully open.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final start = (data['start_Time'] as Timestamp).toDate();
                        final end = (data['end_Time'] as Timestamp).toDate();
                        final status =
                            data['reaction']?['status'] as String? ?? 'Unknown';
                        final isMe = data['user_Id'] ==
                            FirebaseAuth.instance.currentUser?.uid;

                        final statusColor = status == 'Confirmed'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: statusColor, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppKolors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isMe ? 'Your booking' : status,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Continue button
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKolors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                elevation: 4,
              ),
              onPressed: onContinue,
              child: Text(
                'Continue — Pick Time',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Occasion helper ────────────────────────────────────────────────────────────
String deriveOccasion(DateTime end) {
  final h = end.hour + end.minute / 60.0;
  if (h <= 12) return 'Breakfast';   // ends by 12pm
  if (h <= 16) return 'Lunch';       // ends by 4pm
  return 'Dinner';                   // ends after 4pm (up to 10pm)
}

Color occasionColor(String occasion) {
  switch (occasion) {
    case 'Breakfast': return const Color(0xFFF59E0B);
    case 'Lunch':     return const Color(0xFF16A34A);
    default:          return const Color(0xFF6366F1); // Dinner
  }
}

IconData occasionIcon(String occasion) {
  switch (occasion) {
    case 'Breakfast': return Icons.wb_sunny_outlined;
    case 'Lunch':     return Icons.wb_cloudy_outlined;
    default:          return Icons.nights_stay_outlined;
  }
}

// ── Step 2: Pick Start & End Time ──────────────────────────────────────────────
class _Step2 extends StatefulWidget {
  final DateTime selectedDay;
  final String facilityId;
  final DateTime? startTime;
  final DateTime? endTime;
  final void Function(DateTime start, DateTime end) onTimesChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _Step2({
    required this.selectedDay,
    required this.facilityId,
    required this.startTime,
    required this.endTime,
    required this.onTimesChanged,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  late DateTime _start;
  late DateTime _end;
  Stream<List<Map<String, DateTime>>>? _slotsStream;

  Stream<List<Map<String, DateTime>>> _buildStream(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return FirebaseFirestore.instance
        .collection('bookings_collection')
        .where('facility_Id', isEqualTo: widget.facilityId)
        .where('facility_Type', isEqualTo: 'Bandas')
        .where('start_Time', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('start_Time', isLessThan: Timestamp.fromDate(dayEnd))
        .orderBy('start_Time')
        .snapshots()
        .map((snap) => snap.docs.where((doc) {
              final status =
                  doc.data()['reaction']?['status'] as String? ?? '';
              return status != 'Cancelled';
            }).map((doc) {
              final data = doc.data();
              return {
                'start': (data['start_Time'] as Timestamp).toDate(),
                'end': (data['end_Time'] as Timestamp).toDate(),
              };
            }).toList());
  }

  @override
  void initState() {
    super.initState();
    final d = widget.selectedDay;
    _start = widget.startTime ?? DateTime(d.year, d.month, d.day, 8, 0);
    _end   = widget.endTime   ?? DateTime(d.year, d.month, d.day, 10, 0);
    _slotsStream = _buildStream(d);
  }

  @override
  void didUpdateWidget(_Step2 old) {
    super.didUpdateWidget(old);
    if (widget.startTime != null && widget.startTime != old.startTime) {
      _start = widget.startTime!;
    }
    if (widget.endTime != null && widget.endTime != old.endTime) {
      _end = widget.endTime!;
    }
    if (widget.selectedDay != old.selectedDay) {
      _slotsStream = _buildStream(widget.selectedDay);
    }
  }

  bool _hasOverlap(List<Map<String, DateTime>> slots) => slots.any(
        (s) => _start.isBefore(s['end']!) && _end.isAfter(s['start']!),
      );

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppKolors.primary,
            onPrimary: Colors.white,
            onSurface: AppKolors.textPrimary,
            surface: Colors.white,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      ),
    );
    if (picked == null) return;
    final d = widget.selectedDay;
    final dt = DateTime(d.year, d.month, d.day, picked.hour, picked.minute);
    setState(() {
      if (isStart) {
        _start = dt;
        if (!_end.isAfter(_start)) {
          _end = _start.add(const Duration(hours: 2));
        }
      } else {
        _end = dt;
      }
    });
    widget.onTimesChanged(_start, _end);
  }

  @override
  Widget build(BuildContext context) {
    final duration = _end.difference(_start);
    final validDuration = duration.inMinutes > 0;
    final occasion = validDuration ? deriveOccasion(_end) : null;
    final oColor = occasion != null ? occasionColor(occasion) : Colors.grey;

    return StreamBuilder<List<Map<String, DateTime>>>(
      stream: _slotsStream,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final slots = snap.data ?? [];
        final hasOverlap = validDuration && _hasOverlap(slots);
        final canContinue = !loading && !hasOverlap && validDuration;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Selected day reminder
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppKolors.secondary, AppKolors.primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(widget.selectedDay),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM yyyy').format(widget.selectedDay),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Select Time',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppKolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Start / End pickers
                Row(
                  children: [
                    Expanded(child: _timeTile('Start Time', _start, () => _pickTime(isStart: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _timeTile('End Time', _end, () => _pickTime(isStart: false))),
                  ],
                ),
                const SizedBox(height: 16),

                // Duration + occasion chip
                if (validDuration) ...[
                  Row(
                    children: [
                      _infoChip(
                        '${(duration.inMinutes / 60).toStringAsFixed(1)} hrs',
                        Icons.timelapse,
                        AppKolors.secondary,
                      ),
                      const SizedBox(width: 10),
                      _infoChip(
                        occasion!,
                        occasionIcon(occasion),
                        oColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      _occasionHint(occasion),
                      style: TextStyle(fontSize: 11.sp, color: AppKolors.textSecondary),
                    ),
                  ),
                ],

                // End-time validation error
                if (!validDuration && _end.isBefore(_start)) ...[
                  const SizedBox(height: 10),
                  _alertBanner('End time must be after start time.', Colors.red),
                ],

                // Overlap warning
                if (validDuration && !loading && hasOverlap) ...[
                  const SizedBox(height: 14),
                  _alertBanner(
                    'Your selected time overlaps with an existing booking. Please adjust.',
                    Colors.orange,
                  ),
                ],

                // Existing bookings recap
                if (slots.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Booked slots on this day',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppKolors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...slots.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('h:mm a').format(s['start']!)} – ${DateFormat('h:mm a').format(s['end']!)}',
                          style: TextStyle(fontSize: 12.sp, color: AppKolors.textSecondary),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),

        // Back + Continue
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppKolors.secondary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppKolors.secondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canContinue
                          ? AppKolors.secondary
                          : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 4,
                    ),
                    onPressed: canContinue
                        ? widget.onContinue
                        : () => Fluttertoast.showToast(
                              msg: loading
                                  ? 'Checking availability...'
                                  : hasOverlap
                                      ? 'Please fix the time overlap before continuing.'
                                      : 'End time must be after start time.',
                              backgroundColor: Colors.orange,
                            ),
                    child: loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Continue — Confirm',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  },
  );
  }

  Widget _timeTile(String label, DateTime dt, VoidCallback onTap) {
    final isStart = label == 'Start Time';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppKolors.secondary.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isStart
                        ? [AppKolors.secondary, AppKolors.primary]
                        : [AppKolors.primary, AppKolors.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isStart ? Icons.login_rounded : Icons.logout_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              // time body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('h:mm').format(dt),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppKolors.textPrimary,
                        height: 1,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('a').format(dt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppKolors.primary,
                          ),
                        ),
                        Icon(Icons.access_time_rounded,
                            size: 14,
                            color: AppKolors.textSecondary.withValues(alpha: 0.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12.sp, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );

  Widget _alertBanner(String msg, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );

  String _occasionHint(String occasion) {
    switch (occasion) {
      case 'Breakfast': return 'Breakfast: ends by 12:00 PM';
      case 'Lunch':     return 'Lunch: ends between 12:00 PM – 4:00 PM';
      default:          return 'Dinner: ends after 4:00 PM';
    }
  }
}

// ── Step 3: Confirm & Book ─────────────────────────────────────────────────────
class _Step3 extends StatefulWidget {
  final DateTime selectedDay;
  final String facilityId;
  final String facilityName;
  final DateTime? startTime;
  final DateTime? endTime;
  final VoidCallback onBack;

  const _Step3({
    required this.selectedDay,
    required this.facilityId,
    required this.facilityName,
    required this.startTime,
    required this.endTime,
    required this.onBack,
  });

  @override
  State<_Step3> createState() => _Step3State();
}

class _Step3State extends State<_Step3> {
  bool _submitting = false;

  Future<void> _submit() async {
    final start = widget.startTime;
    final end = widget.endTime;
    if (start == null || end == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _submitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final datePart = DateFormat('yyyy-MM-dd').format(start);
      final bookingId =
          '${widget.facilityId}_${datePart}_${start.hour}_${start.minute}';
      final docRef = firestore.collection('bookings_collection').doc(bookingId);

      // Final overlap check inside transaction
      final dayStart = DateTime(start.year, start.month, start.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final existingSnap = await firestore
          .collection('bookings_collection')
          .where('facility_Id', isEqualTo: widget.facilityId)
          .where('facility_Type', isEqualTo: 'Bandas')
          .where('start_Time', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('start_Time', isLessThan: Timestamp.fromDate(dayEnd))
          .get();

      final hasOverlap = existingSnap.docs.any((doc) {
        final data = doc.data();
        final status = data['reaction']?['status'] as String? ?? '';
        if (status == 'Cancelled') return false;
        final eStart = (data['start_Time'] as Timestamp).toDate();
        final eEnd = (data['end_Time'] as Timestamp).toDate();
        return start.isBefore(eEnd) && end.isAfter(eStart);
      });

      if (hasOverlap) {
        Fluttertoast.showToast(
          msg: 'This slot was just booked by someone else. Please go back and pick a different time.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
        setState(() => _submitting = false);
        return;
      }

      await firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (snap.exists) throw Exception('already-booked');
        tx.set(docRef, {
          'booking_Id': bookingId,
          'user_Id': currentUser.uid,
          'facility_Id': widget.facilityId,
          'court_No': '',
          'no_of_Attendees': '',
          'occasion': deriveOccasion(end),
          'booking_Date': Timestamp.fromDate(dayStart),
          'start_Time': Timestamp.fromDate(start),
          'end_Time': Timestamp.fromDate(end),
          'facility_Type': 'Bandas',
          'reaction': {'status': 'Confirmed'},
          'interested_Members': [],
          'created_At': Timestamp.now(),
        });
      });

      if (mounted) {
        // Fire-and-forget SMS + WhatsApp
        final userDoc = await FirebaseFirestore.instance
            .collection('users_members')
            .doc(currentUser.uid)
            .get();
        final phone = userDoc.data()?['phone_Number']?.toString() ?? '';
        final userName = userDoc.data()?['f_Name']?.toString() ?? 'Member';
        if (phone.isNotEmpty) {
          final dateStr = DateFormat('EEE d MMM').format(start);
          final timeSlot =
              '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}';
          AfricasTalkingService.sendBandaBookingConfirmation(
            phone: phone,
            userName: userName,
            facilityName: widget.facilityName,
            date: dateStr,
            timeSlot: timeSlot,
          ).catchError((_) {});
          AfricasTalkingService.sendBandaBookingConfirmation(
            phone: phone,
            userName: userName,
            facilityName: widget.facilityName,
            date: dateStr,
            timeSlot: timeSlot,
            channel: ATChannel.whatsapp,
          ).catchError((_) {});
        }
        Fluttertoast.showToast(
          msg: 'Booking confirmed!',
          backgroundColor: Colors.green,
        );
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().contains('already-booked')
            ? 'Slot already taken. Please go back and pick another time.'
            : 'Failed to submit booking. Please try again.',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.startTime;
    final end = widget.endTime;
    if (start == null || end == null) {
      return const Center(child: Text('Missing time selection.'));
    }

    final occasion = deriveOccasion(end);
    final oColor = occasionColor(occasion);
    final duration = end.difference(start);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review your booking',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppKolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppKolors.primary.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _row(Icons.location_on_outlined, 'Facility', widget.facilityName, AppKolors.primary),
                      _divider(),
                      _row(Icons.calendar_today, 'Date',
                          DateFormat('EEEE, d MMMM yyyy').format(widget.selectedDay),
                          AppKolors.secondary),
                      _divider(),
                      _row(Icons.access_time, 'Time',
                          '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}',
                          AppKolors.secondary),
                      _divider(),
                      _row(Icons.timelapse, 'Duration',
                          '${(duration.inMinutes / 60).toStringAsFixed(1)} hours',
                          AppKolors.secondary),
                      _divider(),
                      _row(occasionIcon(occasion), 'Occasion', occasion, oColor),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'By confirming, your booking will be immediately reserved. '
                          'Cancellations must be made in advance.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Back + Confirm
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: _submitting ? null : widget.onBack,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppKolors.secondary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 18, color: AppKolors.secondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppKolors.secondary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 4,
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Confirm Booking',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 12.sp,
                    color: AppKolors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppKolors.textPrimary)),
          ],
        ),
      );

  Widget _divider() => Divider(
      height: 1, indent: 46, endIndent: 16, color: Colors.grey.shade100);
}
