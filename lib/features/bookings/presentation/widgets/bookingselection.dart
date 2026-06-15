import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';

// ── Providers ──
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final fromTimeProvider = StateProvider<TimeOfDay?>((ref) => null);
final toTimeProvider = StateProvider<TimeOfDay?>((ref) => null);
final selectedCourtProvider = StateProvider<String>((ref) => 'Court 1');
final selectedFacilityProvider = StateProvider<String>((ref) => '');
final selectedTimeSlotProvider = StateProvider<List<String>>((ref) => []);
final participantCountsProvider = StateProvider<Map<String, int>>((ref) => {
      'Member': 0,
      'Child Member': 0,
      'Guest': 0,
    });

final courtImagesProvider = FutureProvider<List<String>>((ref) async {
  final facilityId = ref.watch(selectedFacilityProvider);
  final courtName = ref.watch(selectedCourtProvider).toLowerCase();
  final snap = await FirebaseFirestore.instance
      .collection('Facilities')
      .doc(facilityId)
      .collection('courts')
      .doc(courtName)
      .get();
  if (!snap.exists) return [];
  final raw = snap.data()?['images'];
  return raw is List ? raw.whereType<String>().toList() : [];
}, dependencies: [selectedFacilityProvider, selectedCourtProvider]);

// ── Main Widget ──
class SportBookingSheet extends ConsumerStatefulWidget {
  final String facilityName;
  final String imageUrl;
  final int numberOfCourts;
  final VoidCallback? onClose;

  const SportBookingSheet({
    super.key,
    required this.facilityName,
    required this.imageUrl,
    required this.numberOfCourts,
    this.onClose,
  });

  @override
  ConsumerState<SportBookingSheet> createState() => _SportBookingSheetState();
}

class _SportBookingSheetState extends ConsumerState<SportBookingSheet>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _stepAnim;
  int _currentPage = 0;

  // Step 1 errors
  String? _dateError;
  String? _participantError;

  // Step 2 scroll
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stepAnim.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    setState(() {
      _dateError = null;
      _participantError = null;
    });

    final date = ref.read(selectedDateProvider);
    final counts = ref.read(participantCountsProvider);
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    bool hasError = false;
    if (total == 0) {
      _participantError = 'Select at least one participant.';
      hasError = true;
    }
    if (hasError) {
      setState(() {});
      return;
    }

    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _currentPage = 1);
  }

  void _goToStep1() {
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _currentPage = 0);
  }

  Future<void> _requestBooking() async {
    final selectedDate = ref.read(selectedDateProvider);
    final selectedSlots = ref.read(selectedTimeSlotProvider);
    if (selectedSlots.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select at least one time slot.');
      return;
    }
    final selectedFacility = ref.read(selectedFacilityProvider);
    final selectedCourt = ref.read(selectedCourtProvider);
    final counts = ref.read(participantCountsProvider);
    await submitMultiSlotBooking(
      context,
      ref,
      selectedDate,
      selectedSlots,
      selectedFacility,
      selectedCourt,
      counts.values.fold<int>(0, (p, e) => p + e).toString(),
      counts,
      onBookAnother: _goToStep2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header: step indicator + close button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
          child: Row(
            children: [
              Expanded(child: _StepIndicator(currentStep: _currentPage)),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose,
                splashRadius: 20,
              ),
            ],
          ),
        ),
        Flexible(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Step1(
                facilityName: widget.facilityName,
                imageUrl: widget.imageUrl,
                numberOfCourts: widget.numberOfCourts,
                dateError: _dateError,
                participantError: _participantError,
              ),
              Step2(scrollController: _scrollController),
            ],
          ),
        ),
        _StickyButton(
          currentPage: _currentPage,
          onStep1: _goToStep2,
          onStep2: _requestBooking,
          onBack: _goToStep1,
        ),
      ],
    );
  }
}

// ── Step Indicator ──
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _labels = ['Details', 'Pick Slot'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
      child: Row(
        children: [
          _step(0, currentStep),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color:
                    currentStep >= 1 ? AppKolors.primary : Colors.grey.shade200,
              ),
            ),
          ),
          _step(1, currentStep),
        ],
      ),
    );
  }

  Widget _step(int step, int current) {
    final done = current > step;
    final active = current == step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? AppKolors.primary : Colors.grey.shade200,
            border: Border.all(
              color: active ? AppKolors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _labels[step],
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppKolors.primary : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ── Step 1: Court + Date ──
class Step1 extends ConsumerStatefulWidget {
  final String facilityName;
  final String imageUrl;
  final int numberOfCourts;
  final String? dateError;

  const Step1({
    super.key,
    required this.facilityName,
    required this.imageUrl,
    required this.numberOfCourts,
    this.dateError,
    // ignore legacy param
    String? participantError,
  });

  @override
  ConsumerState<Step1> createState() => _Step1State();
}

class _Step1State extends ConsumerState<Step1> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final imagesAsync = ref.watch(courtImagesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              child: imagesAsync.when(
                data: (images) {
                  final list = images.isNotEmpty ? images : [widget.imageUrl];
                  return CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      autoPlay: list.length > 1,
                      autoPlayInterval: const Duration(seconds: 8),
                      enlargeCenterPage: true,
                      enableInfiniteScroll: list.length > 1,
                    ),
                    items: list
                        .map((url) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(url,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: cs.surfaceContainerHighest,
                                      child: Icon(Icons.broken_image,
                                          color: cs.onSurfaceVariant))),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Court chips
          Text('Select Court',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.numberOfCourts, (i) {
              final name = 'Court ${i + 1}';
              final selected = ref.watch(selectedCourtProvider) == name;
              return GestureDetector(
                onTap: () =>
                    ref.read(selectedCourtProvider.notifier).state = name,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? cs.primary : cs.outlineVariant,
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: cs.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_tennis,
                          size: 14,
                          color: selected ? cs.onPrimary : cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Date strip
          Text('Select Date',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          DatePicker(
            DateTime.now(),
            height: 80,
            initialSelectedDate:
                ref.watch(selectedDateProvider) ?? DateTime.now(),
            selectionColor: cs.primary,
            selectedTextColor: cs.onPrimary,
            deactivatedColor: cs.outlineVariant,
            daysCount: 7,
            monthTextStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.primary.withValues(alpha: 0.8)),
            dayTextStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            dateTextStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            inactiveDates: _deactivatedDates(),
            onDateChange: (date) {
              final limit = DateTime.now().add(const Duration(hours: 48));
              if (date.isBefore(limit)) {
                ref.read(selectedDateProvider.notifier).state = date;
                ref.read(selectedTimeSlotProvider.notifier).state = [];
              } else {
                Fluttertoast.showToast(
                    msg: 'Bookings are only made 48 hours prior.');
              }
            },
          ),
          if (widget.dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(widget.dateError!,
                  style: TextStyle(fontSize: 12, color: cs.error)),
            ),
        ],
      ),
    );
  }
}

// ── Step 1b: Participants (standalone) ──
class Step1Participants extends ConsumerWidget {
  final String? participantError;
  const Step1Participants({super.key, this.participantError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final counts = ref.watch(participantCountsProvider);
    final keys = counts.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text('Who\'s Playing?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Add at least one participant to continue.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          if (participantError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(participantError!,
                  style: TextStyle(fontSize: 12, color: cs.error)),
            ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: keys.asMap().entries.map((entry) {
                final i = entry.key;
                final type = entry.value;
                final count = counts[type] ?? 0;
                final isLast = i == keys.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              type == 'Guest'
                                  ? Icons.person_outline
                                  : type == 'Child Member'
                                      ? Icons.child_care
                                      : Icons.badge_outlined,
                              size: 20,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(type,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface)),
                                if (type == 'Guest')
                                  Text('Ksh 200 levy per guest',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          _CounterBtn(
                            icon: Icons.remove,
                            onTap: () {
                              if (count > 0) {
                                final m = Map<String, int>.from(
                                    ref.read(participantCountsProvider));
                                m[type] = count - 1;
                                ref
                                    .read(participantCountsProvider.notifier)
                                    .state = m;
                              }
                            },
                          ),
                          SizedBox(
                            width: 36,
                            child: Text('$count',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: count > 0
                                        ? cs.primary
                                        : cs.onSurfaceVariant)),
                          ),
                          _CounterBtn(
                            icon: Icons.add,
                            onTap: () {
                              final m = Map<String, int>.from(
                                  ref.read(participantCountsProvider));
                              m[type] = count + 1;
                              ref
                                  .read(participantCountsProvider.notifier)
                                  .state = m;
                            },
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                          height: 1,
                          indent: 74,
                          endIndent: 20,
                          color: cs.outlineVariant),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Total pill
          Builder(builder: (context) {
            final total = counts.values.fold<int>(0, (a, b) => a + b);
            if (total == 0) return const SizedBox.shrink();
            return Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$total participant${total == 1 ? '' : 's'} selected',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppKolors.primary.withValues(alpha: 0.08),
          border: Border.all(color: AppKolors.primary.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: AppKolors.primary),
      ),
    );
  }
}

// ── Step 2 ──
class Step2 extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const Step2({super.key, required this.scrollController});

  @override
  ConsumerState<Step2> createState() => _Step2State();
}

class _Step2State extends ConsumerState<Step2> {
  bool _isGridView = true;

  List<String> get _timeSlots => List.generate(15, (i) {
        final start = DateTime(0, 0, 0, 7 + i);
        final end = start.add(const Duration(hours: 1));
        return '${DateFormat('h:mm a').format(start)}\n - \n${DateFormat('h:mm a').format(end)}';
      });

  Future<void> _showHoverCard(
      BuildContext context, Map<String, dynamic> data) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bookingUserId = data['userId'] ?? data['user_Id'] as String;
    final userDoc = await FirebaseFirestore.instance
        .collection('users_members')
        .doc(bookingUserId)
        .get();
    final memNumber = userDoc.data()?['mem_Number'] ?? 'Member';
    final isMe = bookingUserId == currentUser?.uid;
    final status = data['status'] as String;

    String displayText;
    if (status == 'Unconfirmed') {
      displayText = isMe
          ? 'Pending Confirmation\n(blocked for you)'
          : 'Pending Confirmation\n(blocked for $memNumber)';
    } else if (status == 'Confirmed') {
      displayText = isMe
          ? 'Booking Confirmed\nreserved for you'
          : 'Booking Confirmed\nreserved for $memNumber';
    } else {
      displayText = status;
    }

    final interested = data['interested_Members'] as List<dynamic>? ?? [];
    final alreadyInterested =
        currentUser != null && interested.contains(currentUser.uid);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (status == 'Unconfirmed'
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.1),
                ),
                child: Icon(
                  status == 'Unconfirmed'
                      ? Icons.hourglass_top_rounded
                      : Icons.event_busy,
                  color: status == 'Unconfirmed'
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                status == 'Unconfirmed' ? 'Slot Pending' : 'Slot Booked',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppKolors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppKolors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (isMe)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppKolors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: AppKolors.primary),
                      const SizedBox(width: 6),
                      Text('Your booking',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppKolors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: alreadyInterested
                        ? null
                        : () {
                            _showInterest(
                                context, data['booking_Id'] as String);
                            Navigator.of(context).pop();
                          },
                    icon: Icon(
                        alreadyInterested
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        size: 18),
                    label: Text(alreadyInterested
                        ? 'Notified when free'
                        : 'Notify me if free'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyInterested
                          ? Colors.grey.shade200
                          : AppKolors.primary,
                      foregroundColor:
                          alreadyInterested ? Colors.black54 : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInterest(BuildContext context, String bookingId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final ref = FirebaseFirestore.instance
          .collection('bookings_collection')
          .doc(bookingId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final interested =
            snap.data()?['interested_Members'] as List<dynamic>? ?? [];
        if (!interested.contains(currentUser.uid)) {
          interested.add(currentUser.uid);
          tx.update(ref, {'interested_Members': interested});
        }
      });
      Fluttertoast.showToast(
          msg: 'Interest shown; you\'ll be notified when available.');
    } catch (_) {
      Fluttertoast.showToast(msg: 'Failed to show interest.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedFacility = ref.watch(selectedFacilityProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to continue.'));
    }

    return Column(
      children: [
        // Legend + view toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              _legend('Available', const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              _legend('Pending', const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _legend('Booked', const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              _legend('N/A', Colors.grey.shade400),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isGridView = !_isGridView),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppKolors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppKolors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    size: 18,
                    color: AppKolors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<int>(
            future: FirebaseFirestore.instance
                .collection('bookings_collection')
                .where('user_Id', isEqualTo: currentUser.uid)
                .where('facility_Id', isEqualTo: selectedFacility)
                .where('booking_Date',
                    isEqualTo:
                        Timestamp.fromDate(selectedDate ?? DateTime.now()))
                .where('reaction.status', isNotEqualTo: 'Cancelled')
                .where('facility_Type', isEqualTo: 'Sports')
                .count()
                .get()
                .then((s) => s.count ?? 0),
            builder: (context, countSnap) {
              final alreadyBooked = countSnap.data ?? 0;
              final slotsRemaining = (2 - alreadyBooked).clamp(0, 2);
              final limitReached = slotsRemaining == 0;
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings_collection')
                    .where('booking_Date',
                        isEqualTo:
                            Timestamp.fromDate(selectedDate ?? DateTime.now()))
                    .where('facility_Id', isEqualTo: selectedFacility)
                    .where('court_No',
                        isEqualTo: ref.watch(selectedCourtProvider))
                    .where('reaction.status', isNotEqualTo: 'Cancelled')
                    .where('facility_Type', isEqualTo: 'Sports')
                    .snapshots(),
                builder: (context, snap) {
                  final allBookings = snap.data?.docs ?? [];
                  final Map<String, Map<String, dynamic>> slotData = {};
                  for (final doc in allBookings) {
                    try {
                      final start = (doc['start_Time'] as Timestamp).toDate();
                      final slot =
                          '${DateFormat('h:mm a').format(start)}\n - \n${DateFormat('h:mm a').format(start.add(const Duration(hours: 1)))}';
                      slotData[slot] = {
                        'status': doc['reaction']['status'],
                        'userId': doc['user_Id'],
                        'booking_Id': doc['booking_Id'],
                        'interested_Members': doc['interested_Members'] ?? [],
                      };
                    } catch (_) {}
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isGridView
                        ? _buildGrid(context, selectedDate, slotData,
                            limitReached, slotsRemaining)
                        : _buildList(context, selectedDate, slotData,
                            limitReached, slotsRemaining),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── shared slot state resolver ──
  Map<String, dynamic> _resolveSlot(
    int i,
    DateTime? selectedDate,
    Map<String, Map<String, dynamic>> slotData,
    bool limitReached,
    List<String> selectedSlots,
  ) {
    final slot = _timeSlots[i];
    final now = DateTime.now();
    final base = selectedDate ?? now;
    final slotStart = DateTime(base.year, base.month, base.day, 7 + i);
    final slotEnd = slotStart.add(const Duration(hours: 1));
    final windowEnd = now.add(const Duration(hours: 48));
    final isSelected = selectedSlots.contains(slot);

    String slotState = 'available';
    if (slotEnd.isBefore(now) || slotStart.isAfter(windowEnd)) {
      slotState = 'unavailable';
    }
    if (slotData.containsKey(slot)) {
      final s = slotData[slot]!['status'] as String;
      if (s == 'Confirmed') {
        slotState = 'booked';
      } else if (s == 'Unconfirmed') slotState = 'pending';
    }
    // block available slots only if limit reached AND not already selected
    if (limitReached && slotState == 'available' && !isSelected) {
      slotState = 'unavailable';
    }

    Color stateColor;
    Color stateBg;
    String stateLabel;
    IconData stateIcon;
    switch (slotState) {
      case 'booked':
        stateColor = const Color(0xFFEF4444);
        stateBg = const Color(0xFFFEF2F2);
        stateLabel = 'Booked';
        stateIcon = Icons.event_busy;
        break;
      case 'pending':
        stateColor = const Color(0xFFF59E0B);
        stateBg = const Color(0xFFFFFBEB);
        stateLabel = 'Pending';
        stateIcon = Icons.hourglass_top_rounded;
        break;
      case 'unavailable':
        stateColor = Colors.grey.shade400;
        stateBg = Colors.grey.shade50;
        stateLabel = 'N/A';
        stateIcon = Icons.block_rounded;
        break;
      default:
        stateColor = const Color(0xFF16A34A);
        stateBg = const Color(0xFFF0FDF4);
        stateLabel = 'Available';
        stateIcon = Icons.check_circle_outline_rounded;
    }

    return {
      'slot': slot,
      'slotState': slotState,
      'isSelected': isSelected,
      'slotStart': slotStart,
      'slotEnd': slotEnd,
      'stateColor': stateColor,
      'stateBg': stateBg,
      'stateLabel': stateLabel,
      'stateIcon': stateIcon,
      'clickable': slotState == 'available' || isSelected,
    };
  }

  // ── List view ──
  Widget _buildList(
    BuildContext context,
    DateTime? selectedDate,
    Map<String, Map<String, dynamic>> slotData,
    bool limitReached,
    int slotsRemaining,
  ) {
    final selectedSlots = ref.watch(selectedTimeSlotProvider);
    return ListView.builder(
      key: const ValueKey('list'),
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      itemCount: _timeSlots.length,
      itemBuilder: (context, i) {
        final r = _resolveSlot(
            i, selectedDate, slotData, limitReached, selectedSlots);
        final slot = r['slot'] as String;
        final slotStart = r['slotStart'] as DateTime;
        final slotEnd = r['slotEnd'] as DateTime;
        final stateColor = r['stateColor'] as Color;
        final stateBg = r['stateBg'] as Color;
        final stateLabel = r['stateLabel'] as String;
        final stateIcon = r['stateIcon'] as IconData;
        final clickable = r['clickable'] as bool;
        final isSelected = r['isSelected'] as bool;
        final startLabel = DateFormat('h:mm a').format(slotStart);
        final endLabel = DateFormat('h:mm a').format(slotEnd);

        return GestureDetector(
          onTap: () {
            if (!clickable && slotData.containsKey(slot)) {
              _showHoverCard(context, slotData[slot]!);
            } else if (clickable) {
              final current =
                  List<String>.from(ref.read(selectedTimeSlotProvider));
              if (isSelected) {
                current.remove(slot);
                ref.read(selectedTimeSlotProvider.notifier).state = current;
              } else if (current.length < slotsRemaining) {
                current.add(slot);
                ref.read(selectedTimeSlotProvider.notifier).state = current;
              } else {
                Fluttertoast.showToast(
                    msg:
                        'You can only select $slotsRemaining more slot${slotsRemaining == 1 ? '' : 's'}',
                    backgroundColor: Colors.orange,
                    textColor: Colors.white);
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(vertical: 4.h),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppKolors.primary
                  : (clickable ? Colors.white : stateBg),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppKolors.primary
                    : (clickable
                        ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                        : stateColor.withValues(alpha: 0.3)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppKolors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : [
                      const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1))
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : stateColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(stateIcon,
                      size: 20, color: isSelected ? Colors.white : stateColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$startLabel – $endLabel',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? Colors.white : AppKolors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 hour session',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppKolors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : stateColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSelected ? 'Selected' : stateLabel,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : stateColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Grid view ──
  Widget _buildGrid(
    BuildContext context,
    DateTime? selectedDate,
    Map<String, Map<String, dynamic>> slotData,
    bool limitReached,
    int slotsRemaining,
  ) {
    final selectedSlots = ref.watch(selectedTimeSlotProvider);
    return GridView.builder(
      key: const ValueKey('grid'),
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 1,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, i) {
        final r = _resolveSlot(
            i, selectedDate, slotData, limitReached, selectedSlots);
        final slot = r['slot'] as String;
        final slotStart = r['slotStart'] as DateTime;
        final slotEnd = r['slotEnd'] as DateTime;
        final stateColor = r['stateColor'] as Color;
        final stateBg = r['stateBg'] as Color;
        final stateIcon = r['stateIcon'] as IconData;
        final clickable = r['clickable'] as bool;
        final isSelected = r['isSelected'] as bool;
        final startLabel = DateFormat('h:mm a').format(slotStart);
        final endLabel = DateFormat('h:mm a').format(slotEnd);

        return GestureDetector(
          onTap: () {
            if (!clickable && slotData.containsKey(slot)) {
              _showHoverCard(context, slotData[slot]!);
            } else if (clickable) {
              final current =
                  List<String>.from(ref.read(selectedTimeSlotProvider));
              if (isSelected) {
                current.remove(slot);
                ref.read(selectedTimeSlotProvider.notifier).state = current;
              } else if (current.length < slotsRemaining) {
                current.add(slot);
                ref.read(selectedTimeSlotProvider.notifier).state = current;
              } else {
                Fluttertoast.showToast(
                    msg:
                        'You can only select $slotsRemaining more slot${slotsRemaining == 1 ? '' : 's'}',
                    backgroundColor: Colors.orange,
                    textColor: Colors.white);
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppKolors.primary
                  : (clickable ? const Color(0xFFF0FDF4) : stateBg),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppKolors.primary
                    : (clickable
                        ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                        : stateColor.withValues(alpha: 0.3)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppKolors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : [
                      const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: Offset(0, 1))
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stateIcon,
                  size: 18,
                  color: isSelected ? Colors.white : stateColor,
                ),
                const SizedBox(height: 6),
                Text(
                  startLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppKolors.textPrimary,
                  ),
                ),
                Text(
                  endLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppKolors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legend(String label, Color color) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: AppKolors.textSecondary)),
        ],
      );
}

// ── Sticky CTA Button ──
class _StickyButton extends ConsumerWidget {
  final int currentPage;
  final VoidCallback onStep1;
  final VoidCallback onStep2;
  final VoidCallback onBack;

  const _StickyButton({
    required this.currentPage,
    required this.onStep1,
    required this.onStep2,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 12),
      child: Row(
        children: [
          if (currentPage == 1) ...[
            GestureDetector(
              onTap: onBack,
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
            const Spacer(),
          ],
          if (currentPage == 0)
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKolors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 4,
                  ),
                  onPressed: onStep1,
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppKolors.background,
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKolors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: onStep2,
                icon: const Icon(Icons.check_circle_outline,
                    size: 18, color: Colors.white),
                label: Builder(builder: (context) {
                  final slots = ref.watch(selectedTimeSlotProvider);
                  final count = slots.length;
                  return Text(
                    count == 0
                        ? 'Request Booking'
                        : 'Book $count Slot${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppKolors.background,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helpers ──
List<DateTime> _deactivatedDates() {
  final now = DateTime.now();
  final limit = now.add(const Duration(hours: 48));
  return List.generate(30, (i) => now.add(Duration(days: i)))
      .where((d) => d.isAfter(limit))
      .toList();
}
