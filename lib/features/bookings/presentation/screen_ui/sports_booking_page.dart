import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/sheetexitmessage.dart';

class SportsBookingPage extends ConsumerStatefulWidget {
  final String facilityName;
  final String imageUrl;
  final int numberOfCourts;

  const SportsBookingPage({
    super.key,
    required this.facilityName,
    required this.imageUrl,
    required this.numberOfCourts,
  });

  @override
  ConsumerState<SportsBookingPage> createState() => _SportsBookingPageState();
}

class _SportsBookingPageState extends ConsumerState<SportsBookingPage> {
  final _pageController = PageController();
  final _scrollController = ScrollController();
  int _step = 0;

  String? _dateError;
  String? _participantError;

  static const _stepLabels = [
    'Court & Date',
    'Players',
    'Time Slot',
    'Confirm'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_step > 0) {
      _goTo(_step - 1);
      return false;
    }
    final cancel = await showExitConfirmationDialog(context);
    if (cancel == true) {
      _showCancelledToast();
      return true;
    }
    return false;
  }

  void _goTo(int step) {
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _step = step);
  }

  // Step 0 → 1: validate date
  void _validateDateAndNext() {
    final date = ref.read(selectedDateProvider);
    setState(() => _dateError = null);
    _goTo(1);
  }

  // Step 1 → 2: validate participants
  void _validateParticipantsAndNext() {
    final counts = ref.read(participantCountsProvider);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      setState(() => _participantError = 'Select at least one participant.');
      return;
    }
    setState(() => _participantError = null);
    _goTo(2);
  }

  // Step 2 → 3: validate slot
  void _validateSlotAndNext() {
    final slots = ref.read(selectedTimeSlotProvider);
    if (slots.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select at least one time slot.');
      return;
    }
    _goTo(3);
  }

  Future<void> _requestBooking() async {
    final selectedDate = ref.read(selectedDateProvider);
    final selectedSlots = ref.read(selectedTimeSlotProvider);
    if (selectedSlots.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select a valid time slot.');
      return;
    }
    final counts = ref.read(participantCountsProvider);
    await submitMultiSlotBooking(
      context,
      ref,
      selectedDate,
      selectedSlots,
      ref.read(selectedFacilityProvider),
      ref.read(selectedCourtProvider),
      counts.values.fold<int>(0, (p, e) => p + e).toString(),
      counts,
    );
  }

  void _showCancelledToast() {
    Fluttertoast.showToast(
      msg: 'Booking process canceled. Your changes were not saved.',
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cs.onSurface),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            widget.facilityName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.close, size: 20, color: cs.onSurface),
              onPressed: () async {
                final confirmed = await showExitConfirmationDialog(context);
                if (confirmed == true && context.mounted) {
                  _showCancelledToast();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _ProgressBar(step: _step, labels: _stepLabels),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 0: Court + Date
                  Step1(
                    facilityName: widget.facilityName,
                    imageUrl: widget.imageUrl,
                    numberOfCourts: widget.numberOfCourts,
                    dateError: _dateError,
                  ),
                  // Step 1: Participants
                  Step1Participants(participantError: _participantError),
                  // Step 2: Time Slot
                  Step2(scrollController: _scrollController),
                  // Step 3: Confirm
                  _Step4Confirm(
                    facilityName: widget.facilityName,
                    imageUrl: widget.imageUrl,
                    onEditCourtDate: () => _goTo(0),
                    onEditParticipants: () => _goTo(1),
                    onEditSlot: () => _goTo(2),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: _BottomCta(
            step: _step,
            onStep0: _validateDateAndNext,
            onStep1: _validateParticipantsAndNext,
            onStep2: _validateSlotAndNext,
            onStep3: _requestBooking,
            onBack: () => _goTo(_step - 1),
          ),
        ),
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int step;
  final List<String> labels;
  const _ProgressBar({required this.step, required this.labels});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final lineStep = i ~/ 2;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: step > lineStep ? cs.primary : cs.outlineVariant,
                ),
              ),
            );
          }
          final s = i ~/ 2;
          final done = step > s;
          final active = step == s;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done || active ? cs.primary : cs.surfaceContainerHighest,
                ),
                child: Center(
                  child: done
                      ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                      : Text(
                          '${s + 1}',
                          style: TextStyle(
                            color: active ? cs.onPrimary : cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                labels[s],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Step 4: Confirm ───────────────────────────────────────────────────────────
class _Step4Confirm extends ConsumerWidget {
  final String facilityName;
  final String imageUrl;
  final VoidCallback onEditCourtDate;
  final VoidCallback onEditParticipants;
  final VoidCallback onEditSlot;

  const _Step4Confirm({
    required this.facilityName,
    required this.imageUrl,
    required this.onEditCourtDate,
    required this.onEditParticipants,
    required this.onEditSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final date = ref.watch(selectedDateProvider);
    final slots = ref.watch(selectedTimeSlotProvider);
    final slotDisplay = slots.isEmpty
        ? '—'
        : slots.map((s) => s.replaceAll('\n - \n', ' – ')).join(',  ');
    final court = ref.watch(selectedCourtProvider);
    final counts = ref.watch(participantCountsProvider);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final guestCount = counts['Guest'] ?? 0;
    final guestLevy = guestCount * 200;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility image header
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.sports_tennis,
                        size: 48, color: cs.onSurfaceVariant),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          cs.surface.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Text(
                    facilityName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Booking details card
          _card(cs, [
            _sectionHeader(cs, Icons.event_note_outlined, 'Booking Details'),
            _row(cs, Icons.calendar_today_outlined, 'Date',
                date != null ? _formatDate(date) : '—', onEditCourtDate),
            _divider(cs),
            _row(cs, Icons.sports_tennis_outlined, 'Court', court,
                onEditCourtDate),
            _divider(cs),
            _row(
              cs,
              Icons.access_time_outlined,
              'Time Slot',
              slotDisplay,
              onEditSlot,
            ),
          ]),
          const SizedBox(height: 14),

          // Participants card
          _card(cs, [
            _sectionHeader(cs, Icons.group_outlined, 'Participants'),
            ...counts.entries.where((e) => e.value > 0).map((e) {
              final icon = e.key == 'Guest'
                  ? Icons.person_outline
                  : e.key == 'Child Member'
                      ? Icons.child_care
                      : Icons.badge_outlined;
              return Column(children: [
                _row(cs, icon, e.key, '${e.value}', onEditParticipants),
                if (e.key != counts.entries.where((x) => x.value > 0).last.key)
                  _divider(cs),
              ]);
            }),
            _divider(cs),
            _row(cs, Icons.people_outline, 'Total', '$total', null),
          ]),

          // Charges card (only if guest levy applies)
          if (guestLevy > 0) ...[
            const SizedBox(height: 14),
            _card(cs, [
              _sectionHeader(cs, Icons.receipt_long_outlined, 'Charges'),
              _row(cs, Icons.person_outline, 'Guest Levy',
                  'Ksh $guestLevy ($guestCount × 200)', null),
              _divider(cs),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 18, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Total Due',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                    ),
                    Text(
                      'Ksh $guestLevy',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.primary),
                    ),
                  ],
                ),
              ),
            ]),
          ],

          const SizedBox(height: 14),
          // Policy note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Court empty 15 min after booking time becomes available for others. You can cancel anytime.',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ColorScheme cs, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _sectionHeader(ColorScheme cs, IconData icon, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
          ],
        ),
      );

  Widget _row(ColorScheme cs, IconData icon, String label, String value,
      VoidCallback? onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          if (onEdit != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onEdit,
              child: Text('edit',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) =>
      Divider(height: 1, indent: 46, endIndent: 16, color: cs.outlineVariant);

  String _formatDate(DateTime d) =>
      '${_ordinal(d.day)} ${_months[d.month - 1]} ${d.year}  •  ${DateFormat('EEEE').format(d)}';

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
}

// ── Bottom CTA ────────────────────────────────────────────────────────────────
class _BottomCta extends ConsumerWidget {
  final int step;
  final VoidCallback onStep0;
  final VoidCallback onStep1;
  final VoidCallback onStep2;
  final AsyncCallback onStep3;
  final VoidCallback onBack;

  const _BottomCta({
    required this.step,
    required this.onStep0,
    required this.onStep1,
    required this.onStep2,
    required this.onStep3,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final slots = ref.watch(selectedTimeSlotProvider);

    final labels = ['Continue', 'Continue', 'Review Booking', 'Confirm & Book'];
    final VoidCallback? action = step == 0
        ? onStep0
        : step == 1
            ? onStep1
            : step == 2
                ? (slots.isNotEmpty ? onStep2 : null)
                : null; // step 3 uses async

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          if (step > 0) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest,
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 18, color: cs.onSurface),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: step == 3 ? onStep3 : action,
                  child: Text(
                    labels[step],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef AsyncCallback = Future<void> Function();
