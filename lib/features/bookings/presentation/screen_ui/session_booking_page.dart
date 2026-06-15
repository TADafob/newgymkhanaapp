import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/africas_talking_service.dart';
import 'package:nrbgymkhana/core/utils/payment_selector_sheet.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/sheetexitmessage.dart';

// ── Providers specific to session booking ────────────────────────────────────
final sessionCourtProvider = StateProvider<String?>((ref) => null);
final sessionDateProvider = StateProvider<DateTime?>((ref) => null);
final sessionFromTimeProvider = StateProvider<TimeOfDay?>((ref) => null);
final sessionToTimeProvider = StateProvider<TimeOfDay?>((ref) => null);

// ── Main Page ─────────────────────────────────────────────────────────────────
class SessionBookingPage extends ConsumerStatefulWidget {
  final String facilityName;
  final String imageUrl;
  final String facilityDocId;

  const SessionBookingPage({
    super.key,
    required this.facilityName,
    required this.imageUrl,
    required this.facilityDocId,
  });

  @override
  ConsumerState<SessionBookingPage> createState() => _SessionBookingPageState();
}

class _SessionBookingPageState extends ConsumerState<SessionBookingPage> {
  final _pageController = PageController();
  int _step = 0;

  static const _stepLabels = ['Court & Date', 'Players', 'Time', 'Confirm'];

  // courts loaded from Firestore
  List<Map<String, dynamic>> _courts = [];
  bool _loadingCourts = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    final doc = await FirebaseFirestore.instance
        .collection('Facilities')
        .doc(widget.facilityDocId)
        .get();
    final raw = doc.data()?['courts'];
    List<Map<String, dynamic>> courts = [];
    if (raw is List) {
      courts = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (raw is int) {
      courts = List.generate(
          raw, (i) => {'court_Name': 'Court ${i + 1}', 'capacity': null});
    }
    if (mounted) {
      setState(() {
        _courts = courts;
        _loadingCourts = false;
      });
      // auto-select first court
      if (courts.isNotEmpty) {
        ref.read(sessionCourtProvider.notifier).state =
            courts.first['court_Name'] as String? ?? 'Court 1';
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _step = step);
  }

  Future<bool> _onWillPop() async {
    if (_step > 0) {
      _goTo(_step - 1);
      return false;
    }
    final cancel = await showExitConfirmationDialog(context);
    if (cancel == true) {
      Fluttertoast.showToast(
        msg: 'Booking process canceled.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cs.onSurface),
            onPressed: () async {
              final should = await _onWillPop();
              if (should && context.mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            widget.facilityName,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.close, size: 20, color: cs.onSurface),
              onPressed: () async {
                final confirmed = await showExitConfirmationDialog(context);
                if (confirmed == true && context.mounted) {
                  Fluttertoast.showToast(
                    msg: 'Booking process canceled.',
                    backgroundColor: Colors.orange,
                    textColor: Colors.white,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: _loadingCourts
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _SessionProgressBar(step: _step, labels: _stepLabels),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StepCourtDate(
                          facilityName: widget.facilityName,
                          imageUrl: widget.imageUrl,
                          courts: _courts,
                        ),
                        Step1Participants(),
                        _StepTimeRange(
                          facilityDocId: widget.facilityDocId,
                        ),
                        _StepConfirm(
                          facilityName: widget.facilityName,
                          imageUrl: widget.imageUrl,
                          onEditCourtDate: () => _goTo(0),
                          onEditParticipants: () => _goTo(1),
                          onEditTime: () => _goTo(2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: _SessionBottomCta(
            step: _step,
            onBack: () => _goTo(_step - 1),
            onNext: _handleNext,
          ),
        ),
      ),
    );
  }

  void _handleNext() {
    switch (_step) {
      case 0:
        final court = ref.read(sessionCourtProvider);
        final date = ref.read(sessionDateProvider);
        if (court == null) {
          Fluttertoast.showToast(msg: 'Please select a court.');
          return;
        }
        if (date == null) {
          Fluttertoast.showToast(msg: 'Please select a date.');
          return;
        }
        _goTo(1);
        break;
      case 1:
        final counts = ref.read(participantCountsProvider);
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        if (total == 0) {
          Fluttertoast.showToast(msg: 'Select at least one participant.');
          return;
        }
        _goTo(2);
        break;
      case 2:
        final from = ref.read(sessionFromTimeProvider);
        final to = ref.read(sessionToTimeProvider);
        if (from == null || to == null) {
          Fluttertoast.showToast(msg: 'Please select start and end time.');
          return;
        }
        final fromMins = from.hour * 60 + from.minute;
        final toMins = to.hour * 60 + to.minute;
        if (toMins <= fromMins) {
          Fluttertoast.showToast(msg: 'End time must be after start time.');
          return;
        }
        _goTo(3);
        break;
      case 3:
        _submitSessionBooking();
        break;
    }
  }

  Future<void> _submitSessionBooking() async {
    final court = ref.read(sessionCourtProvider);
    final date = ref.read(sessionDateProvider);
    final from = ref.read(sessionFromTimeProvider);
    final to = ref.read(sessionToTimeProvider);
    final counts = ref.read(participantCountsProvider);

    if (court == null || date == null || from == null || to == null) {
      Fluttertoast.showToast(msg: 'Please complete all steps.');
      return;
    }

    final startDt =
        DateTime(date.year, date.month, date.day, from.hour, from.minute);
    final endDt = DateTime(date.year, date.month, date.day, to.hour, to.minute);
    final dayStart = DateTime(date.year, date.month, date.day);

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      Fluttertoast.showToast(msg: 'User not authenticated.');
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final userDoc =
        await firestore.collection('users_members').doc(firebaseUser.uid).get();
    final memNumber = userDoc.data()?['mem_Number'] as String? ?? 'Member';
    final phone = userDoc.data()?['phone_Number']?.toString() ?? '';
    final userName = userDoc.data()?['f_Name']?.toString() ?? 'Member';

    final guestCount = counts['Guest'] ?? 0;
    final guestLevy = guestCount * 200;
    bool paymentConfirmed = false;

    if (guestLevy > 0 && mounted) {
      bool? payNow;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Guest Levy Required',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00A651).withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  const Text('Total Due',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('KES $guestLevy',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00A651))),
                ]),
              ),
              const SizedBox(height: 12),
              const Text(
                'A guest levy is required. Pay now via M-Pesa or pay later at reception.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                payNow = false;
                Navigator.of(ctx).pop();
              },
              child: const Text('Pay Later'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                payNow = true;
                Navigator.of(ctx).pop();
              },
              child:
                  const Text('Pay Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (payNow == true && mounted) {
        final paid = await showPaymentSelectorSheet(
          context,
          ref,
          amount: guestLevy,
          accountRef: 'GuestLevy',
          description: 'Guest Levy Payment',
          title: 'Guest Levy',
        );
        paymentConfirmed = paid == true;
      }
    }

    final datePart = DateFormat('yyyy-MM-dd').format(date);
    final docId =
        '${widget.facilityDocId}_${court}_${datePart}_${from.hour}_${from.minute}';
    final participantsDetails = {
      'members': counts['Member'] ?? 0,
      'guests': guestCount,
      'child_Member': counts['Child Member'] ?? 0,
    };
    final totalAttendees =
        counts.values.fold<int>(0, (a, b) => a + b).toString();

    try {
      await firestore.runTransaction((tx) async {
        final docRef = firestore.collection('bookings_collection').doc(docId);
        final snap = await tx.get(docRef);
        if (snap.exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'already-booked',
            message: 'This time slot is already booked.',
          );
        }
        tx.set(docRef, {
          'facility_Id': widget.facilityDocId,
          'booking_Id': docId,
          'court_No': court,
          'facility_Type': 'Sports',
          'booking_Mode': 'session',
          'booking_Date': Timestamp.fromDate(dayStart),
          'start_Time': Timestamp.fromDate(startDt),
          'end_Time': Timestamp.fromDate(endDt),
          'date_Booked': Timestamp.now(),
          'user_Id': firebaseUser.uid,
          'Participants_Details': participantsDetails,
          'no_of_Attendees': totalAttendees,
          'mem_Number': memNumber,
          'reaction': {
            'reaction_Id': '',
            'reaction_Date': Timestamp.now(),
            'status': 'Confirmed',
            'isPaid': paymentConfirmed,
            'reacted_By': firebaseUser.uid,
          },
          'interested_Members': [],
        });
      });

      ref.read(sessionCourtProvider.notifier).state = null;
      ref.read(sessionDateProvider.notifier).state = null;
      ref.read(sessionFromTimeProvider.notifier).state = null;
      ref.read(sessionToTimeProvider.notifier).state = null;
      ref.read(participantCountsProvider.notifier).state = {
        'Member': 0,
        'Child Member': 0,
        'Guest': 0
      };

      if (phone.isNotEmpty) {
        final slotStr = '${from.format(context)} – ${to.format(context)}';
        final dateStr = DateFormat('EEE d MMM').format(date);
        AfricasTalkingService.sendSportsBookingConfirmation(
          phone: phone,
          userName: userName,
          facilityName: widget.facilityName,
          courtNo: court,
          date: dateStr,
          timeSlot: slotStr,
          amountDue: guestLevy > 0 ? guestLevy : null,
        ).catchError((_) {});
        AfricasTalkingService.sendSportsBookingConfirmation(
          phone: phone,
          userName: userName,
          facilityName: widget.facilityName,
          courtNo: court,
          date: dateStr,
          timeSlot: slotStr,
          amountDue: guestLevy > 0 ? guestLevy : null,
          channel: ATChannel.whatsapp,
        ).catchError((_) {});
      }

      if (mounted) {
        await GeneralDialog(
          context,
          ref,
          isSuccess: true,
          isSports: true,
          message:
              'Your session has been confirmed!\nA copy has been shared to your WhatsApp and email.',
          onBookAnother: () => _goTo(0),
        );
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'already-booked') {
        Fluttertoast.showToast(
          msg: e.message ?? 'This slot is already booked.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Booking failed. Please try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        debugPrint('Session booking error: $e');
      }
      if (mounted) {
        await GeneralDialog(
          context,
          ref,
          isSuccess: false,
          isSports: true,
          message:
              'Sorry, we couldn\'t complete your booking.\nPlease try again.',
        );
      }
    }
  }
}

// ── Step 3: Confirm ───────────────────────────────────────────────────────────
class _StepConfirm extends ConsumerWidget {
  final String facilityName;
  final String imageUrl;
  final VoidCallback onEditCourtDate;
  final VoidCallback onEditParticipants;
  final VoidCallback onEditTime;

  const _StepConfirm({
    required this.facilityName,
    required this.imageUrl,
    required this.onEditCourtDate,
    required this.onEditParticipants,
    required this.onEditTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final court = ref.watch(sessionCourtProvider);
    final date = ref.watch(sessionDateProvider);
    final from = ref.watch(sessionFromTimeProvider);
    final to = ref.watch(sessionToTimeProvider);
    final counts = ref.watch(participantCountsProvider);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final guestCount = counts['Guest'] ?? 0;
    final guestLevy = guestCount * 200;
    final timeDisplay = (from != null && to != null)
        ? '${from.format(context)} – ${to.format(context)}'
        : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          child: Icon(Icons.sports,
                              size: 48, color: cs.onSurfaceVariant),
                        )),
                Positioned.fill(
                    child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        cs.surface.withValues(alpha: 0.85)
                      ],
                    ),
                  ),
                )),
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
          _card(cs, [
            _sectionHeader(cs, Icons.event_note_outlined, 'Booking Details'),
            _row(cs, Icons.calendar_today_outlined, 'Date',
                date != null ? _fmtDate(date) : '—', onEditCourtDate),
            _divider(cs),
            _row(cs, Icons.sports_tennis_outlined, 'Court', court ?? '—',
                onEditCourtDate),
            _divider(cs),
            _row(cs, Icons.access_time_outlined, 'Time', timeDisplay,
                onEditTime),
          ]),
          const SizedBox(height: 14),
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
                                color: cs.onSurface))),
                    Text('Ksh $guestLevy',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: cs.primary)),
                  ],
                ),
              ),
            ]),
          ],
          const SizedBox(height: 14),
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
                )),
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
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _sectionHeader(ColorScheme cs, IconData icon, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5)),
        ]),
      );

  Widget _row(ColorScheme cs, IconData icon, String label, String value,
          VoidCallback? onEdit) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface))),
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
        ]),
      );

  Widget _divider(ColorScheme cs) =>
      Divider(height: 1, indent: 46, endIndent: 16, color: cs.outlineVariant);

  String _fmtDate(DateTime d) {
    const months = [
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
    final suffix = _ordinal(d.day);
    return '$suffix ${months[d.month - 1]} ${d.year}  •  ${DateFormat('EEEE').format(d)}';
  }

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
}

// ── Progress Bar ──────────────────────────────────────────────────────────────
class _SessionProgressBar extends StatelessWidget {
  final int step;
  final List<String> labels;
  const _SessionProgressBar({required this.step, required this.labels});

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

// ── Step 0: Court + Date ──────────────────────────────────────────────────────
class _StepCourtDate extends ConsumerWidget {
  final String facilityName;
  final String imageUrl;
  final List<Map<String, dynamic>> courts;

  const _StepCourtDate({
    required this.facilityName,
    required this.imageUrl,
    required this.courts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedCourt = ref.watch(sessionCourtProvider);
    final selectedDate = ref.watch(sessionDateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.sports, size: 48, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Court selection
          Text('Select Court',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 10),
          if (courts.isEmpty)
            Text('No courts available.',
                style: TextStyle(color: cs.onSurfaceVariant))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: courts.map((c) {
                final name = c['court_Name'] as String? ?? 'Court';
                final isSelected = selectedCourt == name;
                return GestureDetector(
                  onTap: () =>
                      ref.read(sessionCourtProvider.notifier).state = name,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Date picker (no restriction — any future date)
          Text('Select Date',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                ref.read(sessionDateProvider.notifier).state = picked;
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedDate != null ? cs.primary : cs.outlineVariant,
                  width: selectedDate != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18,
                      color: selectedDate != null
                          ? cs.primary
                          : cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate != null
                        ? _formatDate(selectedDate)
                        : 'Tap to choose a date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedDate != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selectedDate != null
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
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
    final suffix = _ordinal(d.day);
    return '$suffix ${months[d.month - 1]} ${d.year}';
  }

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
}

// ── Step 2: Time Range ────────────────────────────────────────────────────────
class _StepTimeRange extends ConsumerStatefulWidget {
  final String facilityDocId;
  const _StepTimeRange({required this.facilityDocId});

  @override
  ConsumerState<_StepTimeRange> createState() => _StepTimeRangeState();
}

class _StepTimeRangeState extends ConsumerState<_StepTimeRange> {
  List<Map<String, dynamic>> _conflicts = [];
  bool _checking = false;

  Future<void> _checkAvailability() async {
    final date = ref.read(sessionDateProvider);
    final court = ref.read(sessionCourtProvider);
    final from = ref.read(sessionFromTimeProvider);
    final to = ref.read(sessionToTimeProvider);

    if (date == null || court == null || from == null || to == null) return;

    setState(() => _checking = true);

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final requestStart =
        DateTime(date.year, date.month, date.day, from.hour, from.minute);
    final requestEnd =
        DateTime(date.year, date.month, date.day, to.hour, to.minute);

    final snap = await FirebaseFirestore.instance
        .collection('bookings_collection')
        .where('facility_Id', isEqualTo: widget.facilityDocId)
        .where('court_No', isEqualTo: court)
        .where('start_Time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('start_Time', isLessThan: Timestamp.fromDate(dayEnd))
        .where('reaction.status', isNotEqualTo: 'Cancelled')
        .get();

    final conflicts = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final start = (doc['start_Time'] as Timestamp).toDate();
      final end = (doc['end_Time'] as Timestamp).toDate();
      // overlap: requestStart < end && requestEnd > start
      if (requestStart.isBefore(end) && requestEnd.isAfter(start)) {
        conflicts.add({
          'start': start,
          'end': end,
          'status': doc['reaction']['status'],
        });
      }
    }

    if (mounted)
      setState(() {
        _conflicts = conflicts;
        _checking = false;
      });
  }

  Future<void> _pickTime(bool isFrom) async {
    final cs = Theme.of(context).colorScheme;
    final current = isFrom
        ? ref.read(sessionFromTimeProvider)
        : ref.read(sessionToTimeProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (isFrom) {
      ref.read(sessionFromTimeProvider.notifier).state = picked;
    } else {
      ref.read(sessionToTimeProvider.notifier).state = picked;
    }
    // re-check whenever either time changes
    final from = isFrom ? picked : ref.read(sessionFromTimeProvider);
    final to = isFrom ? ref.read(sessionToTimeProvider) : picked;
    if (from != null && to != null) {
      await _checkAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final from = ref.watch(sessionFromTimeProvider);
    final to = ref.watch(sessionToTimeProvider);
    final date = ref.watch(sessionDateProvider);
    final court = ref.watch(sessionCourtProvider);

    final fromMins = from != null ? from.hour * 60 + from.minute : null;
    final toMins = to != null ? to.hour * 60 + to.minute : null;
    final durationMins =
        (fromMins != null && toMins != null && toMins > fromMins)
            ? toMins - fromMins
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary chip
          if (date != null && court != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$court  •  ${_fmtDate(date)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          Text('Select Time Range',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 12),

          // From / To pickers
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  label: 'Start Time',
                  time: from,
                  icon: Icons.play_circle_outline,
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeTile(
                  label: 'End Time',
                  time: to,
                  icon: Icons.stop_circle_outlined,
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),

          // Duration pill
          if (durationMins != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Duration: ${durationMins ~/ 60}h ${durationMins % 60 == 0 ? '' : '${durationMins % 60}m'}'
                      .trim(),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary),
                ),
              ),
            ),
          ],

          // Validation error
          if (fromMins != null && toMins != null && toMins <= fromMins) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.error_outline, size: 15, color: cs.error),
                const SizedBox(width: 6),
                Text('End time must be after start time.',
                    style: TextStyle(fontSize: 12, color: cs.error)),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Availability status
          Text('Availability',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 10),

          if (_checking)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (from == null || to == null)
            _statusTile(
              cs,
              Icons.access_time_outlined,
              'Select both times to check availability.',
              cs.onSurfaceVariant,
              cs.surfaceContainerHighest.withValues(alpha: 0.4),
            )
          else if (_conflicts.isEmpty &&
              durationMins != null &&
              durationMins > 0)
            _statusTile(
              cs,
              Icons.check_circle_outline,
              'This time slot is available!',
              const Color(0xFF16A34A),
              const Color(0xFFF0FDF4),
            )
          else if (_conflicts.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusTile(
                  cs,
                  Icons.event_busy,
                  'Conflicts with ${_conflicts.length} existing booking${_conflicts.length > 1 ? 's' : ''}:',
                  const Color(0xFFEF4444),
                  const Color(0xFFFEF2F2),
                ),
                const SizedBox(height: 8),
                ..._conflicts.map((c) {
                  final s = c['start'] as DateTime;
                  final e = c['end'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Icon(Icons.circle,
                            size: 6, color: const Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('h:mm a').format(s)} – ${DateFormat('h:mm a').format(e)}  (${c['status']})',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusTile(
      ColorScheme cs, IconData icon, String msg, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color))),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
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
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// ── Time Tile ─────────────────────────────────────────────────────────────────
class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasTime = time != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasTime
              ? cs.primary.withValues(alpha: 0.06)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTime ? cs.primary : cs.outlineVariant,
            width: hasTime ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 15,
                    color: hasTime ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasTime ? time!.format(context) : 'Tap to set',
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasTime ? FontWeight.w700 : FontWeight.w400,
                color: hasTime ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom CTA ────────────────────────────────────────────────────────────────
class _SessionBottomCta extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _SessionBottomCta({
    required this.step,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels = ['Continue', 'Continue', 'Review Booking', 'Confirm & Book'];

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
                  onPressed: onNext,
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
