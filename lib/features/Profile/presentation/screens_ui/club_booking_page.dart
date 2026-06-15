import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/sheetexitmessage.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';

class ClubBookingPage extends ConsumerStatefulWidget {
  final String facilityName;
  final String imageUrl;

  const ClubBookingPage({
    super.key,
    required this.facilityName,
    required this.imageUrl,
  });

  @override
  ConsumerState<ClubBookingPage> createState() => _ClubBookingPageState();
}

class _ClubBookingPageState extends ConsumerState<ClubBookingPage> {
  final _pageController = PageController();
  final _scrollController = ScrollController();
  int _step = 0;
  String? _dateError;
  String? _guestError;

  static const _stepLabels = ['Date', 'Attendants', 'Time Slot', 'Confirm'];

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

  void _validateDateAndNext() {
    final date = ref.read(selectedClubDateProvider);
    if (date == null) {
      setState(() => _dateError = 'Please select a date.');
      return;
    }
    ref.read(selectedClubFacilityProvider.notifier).state =
        widget.facilityName; // Store facility
    setState(() => _dateError = null);
    _goTo(1);
  }

  void _validateGuestsAndNext() {
    final count = ref.read(clubGuestCountProvider);
    if (count == 0) {
      setState(() => _guestError = 'Select at least 1 guest.');
      return;
    }
    setState(() => _guestError = null);
    _goTo(2);
  }

  void _validateSlotAndNext() {
    final slot = ref.read(selectedClubTimeSlotProvider);
    if (slot == null) {
      Fluttertoast.showToast(msg: 'Please select a time slot.');
      return;
    }
    _goTo(3);
  }

  Future<void> _requestBooking() async {
    final date = ref.read(selectedClubDateProvider);
    final slot = ref.read(selectedClubTimeSlotProvider);
    if (slot == null || date == null) {
      Fluttertoast.showToast(msg: 'Please select a valid time slot.');
      return;
    }
    // Use existing sports confirmation dialog, adapt for club
    await showConfirmationDialog(
      context,
      ref,
      date,
      slot,
      ref.read(selectedClubFacilityProvider),
      'N/A', // No courts for club
      ref.read(clubGuestCountProvider).toString(),
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
        ),
        body: Column(
          children: [
            _ProgressBar(step: _step, labels: _stepLabels),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 0: Date Selection
                  _Step0Club(
                    facilityName: widget.facilityName,
                    imageUrl: widget.imageUrl,
                    dateError: _dateError,
                  ),
                  // Step 1: Guests
                  _Step1Guests(guestError: _guestError),
                  // Step 2: Time Slot
                  _Step2ClubTime(scrollController: _scrollController),
                  // Step 3: Confirm
                  _Step4ConfirmClub(
                    facilityName: widget.facilityName,
                    imageUrl: widget.imageUrl,
                    onEditDate: () => _goTo(0),
                    onEditGuests: () => _goTo(1),
                    onEditSlot: () => _goTo(2),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: _BottomCtaClub(
            step: _step,
            onStep0: _validateDateAndNext,
            onStep1: _validateGuestsAndNext,
            onStep2: _validateSlotAndNext,
            onStep3: _requestBooking,
            onBack: () => _goTo(_step - 1),
          ),
        ),
      ),
    );
  }
}

// ── Progress Bar (copied from sports) ──
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

// ── Step 0: Facility + Date ──
class _Step0Club extends ConsumerWidget {
  final String facilityName;
  final String imageUrl;
  final String? dateError;

  const _Step0Club({
    required this.facilityName,
    required this.imageUrl,
    this.dateError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final facilityId = ref.watch(selectedClubFacilityProvider);
    final unavailableDatesAsync =
        ref.watch(clubUnavailableDatesProvider(facilityId));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility image
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
                    child:
                        Icon(Icons.image, size: 48, color: cs.onSurfaceVariant),
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
                          cs.surface.withOpacity(0.85),
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
          // Date picker with unavailable
          Text('Select Date',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          unavailableDatesAsync.when(
            data: (unavailable) => DatePicker(
              DateTime.now(),
              height: 80,
              initialSelectedDate:
                  ref.watch(selectedClubDateProvider) ?? DateTime.now(),
              selectionColor: cs.primary,
              selectedTextColor: cs.onPrimary,
              deactivatedColor: cs.outlineVariant,
              daysCount: 30,
              monthTextStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.primary.withOpacity(0.8)),
              dayTextStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              dateTextStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              inactiveDates: unavailable,
              onDateChange: (date) {
                ref.read(selectedClubDateProvider.notifier).state = date;
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                Text('Error loading dates', style: TextStyle(color: cs.error)),
          ),
          if (dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(dateError!,
                  style: TextStyle(fontSize: 12, color: cs.error)),
            ),
        ],
      ),
    );
  }
}

// ── Step 1: Guests Counter ──
class _Step1Guests extends ConsumerWidget {
  final String? guestError;
  const _Step1Guests({this.guestError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final count = ref.watch(clubGuestCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, size: 24, color: cs.primary),
              const SizedBox(width: 12),
              Text('Number of Guests',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select number of attendants/guests.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          if (guestError != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(guestError!,
                    style: TextStyle(fontSize: 13, color: cs.error))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 32, color: cs.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guests',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      Text('Ksh 200 levy per guest over quota if applicable',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                _CounterBtn(
                  icon: Icons.remove,
                  onTap: count > 0
                      ? () => ref.read(clubGuestCountProvider.notifier).state--
                      : null,
                ),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text('$count',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cs.primary)),
                ),
                _CounterBtn(
                  icon: Icons.add,
                  onTap: () =>
                      ref.read(clubGuestCountProvider.notifier).state++,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              onTap != null ? cs.primary.withOpacity(0.1) : cs.outlineVariant,
        ),
        child: Icon(icon,
            size: 20, color: onTap != null ? cs.primary : cs.onSurfaceVariant),
      ),
    );
  }
}

// ── Step 2: Time Slots (like sports Step2) ──
class _Step2ClubTime extends ConsumerWidget {
  final ScrollController scrollController;
  const _Step2ClubTime({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final date = ref.watch(selectedClubDateProvider);
    final facilityId = ref.watch(selectedClubFacilityProvider);
    final slotsAsync = date != null
        ? ref.watch(clubTimeSlotsProvider((facilityId, date)))
        : null;

    if (date == null) {
      return const Center(child: Text('Please select date first'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _legend('Available', const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              _legend('Booked', const Color(0xFFEF4444)),
            ],
          ),
        ),
        Expanded(
          child: slotsAsync?.when(
                data: (slots) => GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: slots.length,
                  itemBuilder: (context, i) {
                    final entries = slots.entries.toList();
                    final slot = entries[i].key;
                    final status = entries[i].value;
                    final isAvailable = status == 'available';
                    final isSelected =
                        ref.watch(selectedClubTimeSlotProvider) == slot;
                    final color = isSelected
                        ? cs.primary
                        : (isAvailable
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFEF4444));

                    return GestureDetector(
                      onTap: isAvailable
                          ? () => ref
                              .read(selectedClubTimeSlotProvider.notifier)
                              .state = slot
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary
                              : (isAvailable
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            slot,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? cs.onPrimary : color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Error loading slots')),
              ) ??
              const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      );
}

// ── Step 4: Confirm (adapted from sports) ──
class _Step4ConfirmClub extends ConsumerWidget {
  final String facilityName;
  final String imageUrl;
  final VoidCallback onEditDate;
  final VoidCallback onEditGuests;
  final VoidCallback onEditSlot;

  const _Step4ConfirmClub({
    required this.facilityName,
    required this.imageUrl,
    required this.onEditDate,
    required this.onEditGuests,
    required this.onEditSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final date = ref.watch(selectedClubDateProvider);
    final slot = ref.watch(selectedClubTimeSlotProvider);
    final guests = ref.watch(clubGuestCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.image,
                            size: 48, color: cs.onSurfaceVariant))),
                Positioned.fill(
                    child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                      Colors.transparent,
                      cs.surface.withOpacity(0.85)
                    ])))),
                Positioned(
                    bottom: 12,
                    left: 16,
                    child: Text(facilityName,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Details card
          Container(
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionHeader(cs, Icons.event_note_outlined, 'Booking Details'),
              _row(
                  cs,
                  Icons.calendar_today_outlined,
                  'Date',
                  date != null
                      ? DateFormat('EEEE, d MMMM yyyy').format(date)
                      : '—',
                  onEditDate),
              const Divider(
                  height: 1,
                  indent: 46,
                  endIndent: 16,
                  color: Color(0xFFEBEBF0)),
              _row(cs, Icons.access_time_outlined, 'Time',
                  slot?.replaceAll('\n - \n', ' – ') ?? '—', onEditSlot),
              const Divider(
                  height: 1,
                  indent: 46,
                  endIndent: 16,
                  color: Color(0xFFEBEBF0)),
              _row(cs, Icons.group_outlined, 'Guests', guests.toString(),
                  onEditGuests),
            ]),
          ),
          const SizedBox(height: 20),
          // Policy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'Bookings can be cancelled 48hrs prior. Contact club for confirmation.',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, IconData icon, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant))
        ]),
      );

  Widget _row(ColorScheme cs, IconData icon, String label, String value,
          VoidCallback onEdit) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface))),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ...[
            const SizedBox(width: 8),
            GestureDetector(
                onTap: onEdit,
                child: Text('edit',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)))
          ],
        ]),
      );
}

// ── Bottom CTA (adapted) ──
class _BottomCtaClub extends ConsumerWidget {
  final int step;
  final VoidCallback onStep0;
  final VoidCallback onStep1;
  final VoidCallback onStep2;
  final Future<void> Function() onStep3;
  final VoidCallback onBack;

  const _BottomCtaClub({
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
    final labels = ['Continue', 'Continue', 'Review', 'Confirm Booking'];
    final VoidCallback? action = step == 0
        ? onStep0
        : step == 1
            ? onStep1
            : step == 2
                ? onStep2
                : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          if (step > 0)
            GestureDetector(
              onTap: onBack,
              child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.surfaceContainerHighest),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 20, color: cs.onSurface)),
            ),
          if (step > 0) const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                    elevation: 0),
                onPressed: step == 3 ? () => onStep3() : action,
                child: Text(labels[step],
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
