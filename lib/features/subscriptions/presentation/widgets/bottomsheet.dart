import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/mpesa_service.dart';
import 'package:nrbgymkhana/core/utils/payment_selector_sheet.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/screen_ui/subspage.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);
final priceProvider = StateProvider<String>((ref) {
  final facility = ref.watch(selectedFacilityProvider);
  if (facility == 'Individual Member') return 'Ksh. 4,000';
  if (facility == 'Member & Spouse') return 'Ksh. 8,000';
  if (facility == 'Junior\n Member') return 'Ksh. 4,000';
  return 'Ksh. 18,500';
});

// ── Price table ───────────────────────────────────────────────────────────────
const _gymPrices = {
  'Individual Member': [
    'Ksh. 4,000',
    'Ksh. 10,000',
    'Ksh. 18,000',
    'Ksh. 32,000'
  ],
  'Member & Spouse': [
    'Ksh. 8,000',
    'Ksh. 20,000',
    'Ksh. 27,000',
    'Ksh. 45,000'
  ],
  'Junior\n Member': ['Ksh. 4,000', 'Ksh. 10,000', 'N/A', 'Ksh. 22,500'],
};

const _gymPlans = [
  {
    'key': 'Individual Member',
    'label': 'Individual',
    'icon': Icons.person_rounded
  },
  {
    'key': 'Member & Spouse',
    'label': 'Member & Spouse',
    'icon': Icons.people_rounded
  },
  {
    'key': 'Junior\n Member',
    'label': 'Junior',
    'icon': Icons.child_care_rounded
  },
];

const _durations = ['Monthly', 'Quarterly', 'Semi-Annual', 'Annual'];
const _durationDays = [31, 120, 180, 0]; // 0 = end of year

// ── Bottom sheet entry ────────────────────────────────────────────────────────
class PurchaseOptionsBottomSheet extends ConsumerStatefulWidget {
  final String category;
  const PurchaseOptionsBottomSheet({super.key, required this.category});

  @override
  ConsumerState<PurchaseOptionsBottomSheet> createState() =>
      _PurchaseOptionsBottomSheetState();
}

class _PurchaseOptionsBottomSheetState
    extends ConsumerState<PurchaseOptionsBottomSheet>
    with SingleTickerProviderStateMixin {
  // step 0 = pick plan (Gym only), step 1 = pick duration (Gym) / confirm (Club), step 2 = confirm (Gym)
  int _step = 0;
  final bool _loading = false;
  late final AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  bool get _isGym => widget.category == 'Gym';
  int get _totalSteps => _isGym ? 3 : 2;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    if (!_isGym) {
      Future.microtask(() {
        ref.read(selectedFacilityProvider.notifier).state = 'Annual Membership';
        ref.read(priceProvider.notifier).state = 'Ksh. 18,500';
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    _animCtrl.reverse().then((_) {
      setState(() => _step = step);
      _animCtrl.forward();
    });
  }

  void _next() => _goTo(_step + 1);
  void _back() => _goTo(_step - 1);

  Future<void> _submit() async {
    // Fetch user phone then open payment selector sheet
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final selectedTab = ref.read(selectedTabProvider);
    final price = ref.read(priceProvider);
    final selectedFacility = ref.read(selectedFacilityProvider);
    final amount = int.tryParse(price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    DateTime expiry;
    String subsId;
    String planLabel;
    if (_isGym) {
      final days = _durationDays[selectedTab];
      expiry = days == 0
          ? DateTime(DateTime.now().year, 12, 31, 23, 59, 59)
          : DateTime.now().add(Duration(days: days));
      subsId = [
        'Gym_Monthly',
        'Gym_Quarterly',
        'Gym_Semi',
        'Gym_Anual'
      ][selectedTab];
      planLabel = switch (selectedFacility) {
        'Individual Member' => 'Individual',
        'Junior\n Member' => 'Junior',
        _ => 'Couple',
      };
    } else {
      expiry = DateTime(DateTime.now().year, 12, 31, 23, 59, 59);
      subsId = 'Club_Membership';
      planLabel = 'Yearly Subs';
    }

    if (!mounted) return;
    final paid = await showPaymentSelectorSheet(
      context,
      ref,
      amount: amount,
      accountRef: 'SubsPayment',
      description: 'Subscription - $planLabel',
      title: 'Subscription Payment',
      onSuccess: (data) async {
        final checkoutId = data['CheckoutRequestID'] as String? ??
            data['mpesaReceiptNumber'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final subsRef = FirebaseFirestore.instance
            .collection('subscriptions_collection')
            .doc(checkoutId);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final existing = await tx.get(subsRef);
          if (existing.exists) return;
          tx.set(subsRef, {
            'amount': amount,
            'expiry_Date': Timestamp.fromDate(expiry),
            'reaction': {
              'isPaid': true,
              'reacted_By': '',
              'reaction_Date': Timestamp.fromDate(DateTime.now()),
              'reaction_Id': checkoutId,
              'status': 'Pending',
            },
            'subs_Date': Timestamp.fromDate(DateTime.now()),
            'subs_Id': 'Subs_${DateTime.now().millisecondsSinceEpoch}',
            'subs_Plan': planLabel,
            'subs_cat_Id': subsId,
            'user_Id': currentUser.uid,
          });
        });
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(paid == true);
  }

  void _showResult(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              success
                  ? Lottie.asset('assets/images/common/success.json',
                      height: 120)
                  : Lottie.asset('assets/images/common/failure.json',
                      height: 120),
              const SizedBox(height: 12),
              Text(
                success ? 'Subscription Added!' : 'Payment Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: success ? Colors.green.shade600 : Colors.red.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                success
                    ? 'Payment received. Your subscription is now pending admin approval.'
                    : 'Something went wrong. Please try again or contact support.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppKolors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        success ? Colors.green.shade600 : Colors.red.shade500,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (success) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SubsPage()),
                        (r) => r.isFirst,
                      );
                    }
                  },
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── drag handle ──
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // ── stepper indicator ──
            _StepIndicator(current: _step, total: _totalSteps),
            const SizedBox(height: 12),
            // ── scrollable step content ──
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildStep(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // ── action buttons ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: _buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_isGym) {
      if (_step == 0) return _StepPickPlan(ref: ref);
      if (_step == 1) return _StepPickDuration(ref: ref);
      return _StepConfirm(category: widget.category, ref: ref);
    } else {
      if (_step == 0) return _StepPickDuration(ref: ref, clubMode: true);
      return _StepConfirm(category: widget.category, ref: ref);
    }
  }

  Widget _buildActions() {
    final isLast = _step == _totalSteps - 1;
    return Row(
      children: [
        if (_step > 0) ...[
          _OutlineBtn(
            onTap: _back,
            child: const Icon(Icons.arrow_back_rounded,
                size: 20, color: AppKolors.dark),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _FilledBtn(
                  label: isLast ? 'Add Subscription' : 'Continue',
                  onTap: isLast ? _submit : _next,
                  color: isLast ? Colors.green.shade600 : AppKolors.primary,
                  trailing: isLast
                      ? const Icon(Icons.payment_rounded,
                          size: 18, color: Colors.white)
                      : const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                ),
        ),
      ],
    );
  }
}

// ── Slider data ───────────────────────────────────────────────────────────────
const _slides = [
  {
    'image': 'assets/images/common/09cfd9c280689c83e5d1401fb2e3905a.jpg',
    'title': 'World-Class Gym',
    'desc':
        'State-of-the-art equipment, steam room, sauna & swimming pool access.',
  },
  {
    'image': 'assets/images/common/576c731dfbc6a1414db519a8150472a2.jpg',
    'title': 'Club Facilities',
    'desc':
        'Full access to banda areas, sports courts, events & club activities.',
  },
  {
    'image': 'assets/images/common/10199859ab4bdf98cf51e5d94854eb91.jpg',
    'title': 'Family Memberships',
    'desc': 'Bring your spouse or junior members and enjoy together.',
  },
];

// ── Step 1 (Gym): Pick plan ───────────────────────────────────────────────────
class _StepPickPlan extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _StepPickPlan({required this.ref});

  @override
  ConsumerState<_StepPickPlan> createState() => _StepPickPlanState();
}

class _StepPickPlanState extends ConsumerState<_StepPickPlan> {
  final _pageCtrl = PageController();
  int _slideIndex = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedFacilityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Choose Your Plan',
          subtitle: 'Select the membership type that suits you',
        ),
        const SizedBox(height: 16),
        // ── Image slider ──
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _slideIndex = i),
              itemBuilder: (_, i) {
                final slide = _slides[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      slide['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppKolors.darkCard,
                        child: const Icon(Icons.image_rounded,
                            color: Colors.white38, size: 40),
                      ),
                    ),
                    // gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // text
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            slide['desc']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // dot indicators
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _slideIndex == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _slideIndex == i ? AppKolors.primary : AppKolors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // ── Plan grid ──
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: _gymPlans.map((p) {
            final key = p['key'] as String;
            final isSelected = selected == key;
            return GestureDetector(
              onTap: () {
                ref.read(selectedFacilityProvider.notifier).state = key;
                ref.read(priceProvider.notifier).state =
                    _gymPrices[key]![ref.read(selectedTabProvider)];
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppKolors.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppKolors.primary : AppKolors.border,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppKolors.primary.withValues(alpha: 0.12)
                            : AppKolors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        p['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? AppKolors.primary
                            : AppKolors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppKolors.primary
                            : AppKolors.textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      const Icon(Icons.check_circle_rounded,
                          size: 13, color: AppKolors.primary),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Step 2 (Gym) / Step 1 (Club): Pick duration ───────────────────────────────
class _StepPickDuration extends ConsumerWidget {
  final WidgetRef ref;
  final bool clubMode;
  const _StepPickDuration({required this.ref, this.clubMode = false});

  @override
  Widget build(BuildContext context, WidgetRef wRef) {
    final selectedTab = wRef.watch(selectedTabProvider);
    final facility = wRef.watch(selectedFacilityProvider);

    if (clubMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Annual Club Membership',
            subtitle: 'Full club access valid until 31 Dec',
          ),
          const SizedBox(height: 20),
          _PriceHighlight(
              price: 'Ksh. 18,500',
              period: 'Valid until 31 Dec ${DateTime.now().year}'),
          const SizedBox(height: 16),
          _FeatureList(features: const [
            'Full access to all club facilities',
            'Swimming pool access',
            'Banda areas',
            'Events & activities',
            'Gym access included',
          ]),
        ],
      );
    }

    final prices = _gymPrices[facility] ?? _gymPrices['Individual Member']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
            title: 'Choose Duration', subtitle: 'Pick a subscription period'),
        const SizedBox(height: 20),
        Row(
          children: List.generate(_durations.length, (i) {
            final isSelected = selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  wRef.read(selectedTabProvider.notifier).state = i;
                  wRef.read(priceProvider.notifier).state = prices[i];
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppKolors.primary : AppKolors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppKolors.primary : AppKolors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _durations[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppKolors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        _PriceHighlight(
          price: prices[selectedTab],
          period: _periodLabel(selectedTab),
        ),
        const SizedBox(height: 16),
        _FeatureList(features: const [
          'Unlimited gym access',
          'Steam & sauna access',
          'Towels provided',
          'Swimming pool access',
        ]),
      ],
    );
  }

  String _periodLabel(int tab) {
    final days = _durationDays[tab];
    if (days == 0) return 'Valid until 31 Dec ${DateTime.now().year}';
    final expiry = DateTime.now().add(Duration(days: days));
    return 'Valid until ${DateFormat('d MMM yyyy').format(expiry)}';
  }
}

// ── Step 3 (Gym) / Step 2 (Club): Confirm ────────────────────────────────────
class _StepConfirm extends ConsumerWidget {
  final String category;
  final WidgetRef ref;
  const _StepConfirm({required this.category, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef wRef) {
    final price = wRef.watch(priceProvider);
    final facility = wRef.watch(selectedFacilityProvider);
    final tab = wRef.watch(selectedTabProvider);
    final isGym = category == 'Gym';

    final planName = isGym
        ? '${facility.replaceAll('\n', '')} — ${_durations[tab]}'
        : 'Annual Club Membership';
    final days = isGym ? _durationDays[tab] : 0;
    final expiry = days == 0
        ? DateTime(DateTime.now().year, 12, 31)
        : DateTime.now().add(Duration(days: days));
    final expiryStr = DateFormat('d MMMM yyyy').format(expiry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
            title: 'Confirm Details',
            subtitle: 'Review before submitting your request'),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppKolors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppKolors.border),
          ),
          child: Column(
            children: [
              _ConfirmRow(label: 'Plan', value: planName),
              _Divider(),
              _ConfirmRow(label: 'Valid Until', value: expiryStr),
              _Divider(),
              _ConfirmRow(label: 'Amount', value: price, highlight: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your request will be reviewed by the Nairobi Gymkhana office. You will receive a notification once approved.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.amber.shade800, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done
                ? AppKolors.accent
                : active
                    ? AppKolors.primary
                    : AppKolors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppKolors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style:
                const TextStyle(fontSize: 13, color: AppKolors.textSecondary)),
      ],
    );
  }
}

class _PriceHighlight extends StatelessWidget {
  final String price;
  final String period;
  const _PriceHighlight({required this.price, required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppKolors.dark, AppKolors.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Amount',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(price,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Period',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(period,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final List<String> features;
  const _FeatureList({required this.features});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: features
          .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: AppKolors.accent),
                    const SizedBox(width: 10),
                    Text(f,
                        style: const TextStyle(
                            fontSize: 13, color: AppKolors.textPrimary)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _ConfirmRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppKolors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 13,
              fontWeight: FontWeight.w700,
              color: highlight ? AppKolors.primary : AppKolors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, indent: 16, endIndent: 16, color: AppKolors.border);
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Widget? trailing;
  const _FilledBtn(
      {required this.label,
      required this.onTap,
      required this.color,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _OutlineBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppKolors.border),
        ),
        child: Center(child: child),
      ),
    );
  }
}

String _getFormattedDate({int daysToAdd = 0}) {
  final target = daysToAdd == 0
      ? DateTime(DateTime.now().year, 12, 31)
      : DateTime.now().add(Duration(days: daysToAdd));
  return DateFormat('dd MMMM yyyy').format(target);
}

// ── M-Pesa Payment Sheet ──────────────────────────────────────────────────────
class _MpesaSheet extends StatefulWidget {
  final String initialPhone;
  final int amount;
  final String planLabel;
  final String subsId;
  final DateTime expiry;
  final String userId;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const _MpesaSheet({
    required this.initialPhone,
    required this.amount,
    required this.planLabel,
    required this.subsId,
    required this.expiry,
    required this.userId,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<_MpesaSheet> createState() => _MpesaSheetState();
}

class _MpesaSheetState extends State<_MpesaSheet> {
  late final TextEditingController _phoneCtrl;
  bool _loading = false;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter your M-Pesa number.');
      return;
    }
    setState(() {
      _loading = true;
      _statusMsg = 'Sending M-Pesa prompt...';
    });
    try {
      final stkResult = await MpesaService.stkPush(
        phone: phone,
        amount: widget.amount,
        accountRef: 'SubsPayment',
        description: 'Subscription - ${widget.planLabel}',
      );
      final checkoutId = stkResult['CheckoutRequestID'] as String?;
      if (checkoutId == null) throw Exception('No CheckoutRequestID returned.');

      setState(() => _statusMsg = 'Prompt sent! Enter your M-Pesa PIN...');

      final callbackDoc = FirebaseFirestore.instance
          .collection('mpesa_callbacks')
          .doc(checkoutId);

      await for (final snap in callbackDoc.snapshots().timeout(
            const Duration(seconds: 90),
            onTimeout: (sink) => sink.close(),
          )) {
        if (!snap.exists) continue;
        final resultCode = snap.data()?['resultCode'];
        if (!mounted) return;
        if (resultCode == 0) {
          // Payment successful — write subscription (idempotent on checkoutId)
          final subsRef = FirebaseFirestore.instance
              .collection('subscriptions_collection')
              .doc(checkoutId);
          await FirebaseFirestore.instance.runTransaction((tx) async {
            final existing = await tx.get(subsRef);
            if (existing.exists) return;
            tx.set(subsRef, {
              'amount': widget.amount,
              'expiry_Date': Timestamp.fromDate(widget.expiry),
              'reaction': {
                'isPaid': true,
                'reacted_By': '',
                'reaction_Date': Timestamp.fromDate(DateTime.now()),
                'reaction_Id': checkoutId,
                'status': 'Pending',
              },
              'subs_Date': Timestamp.fromDate(DateTime.now()),
              'subs_Id': 'Subs_${DateTime.now().millisecondsSinceEpoch}',
              'subs_Plan': widget.planLabel,
              'subs_cat_Id': widget.subsId,
              'user_Id': widget.userId,
            });
          });
          if (mounted) Navigator.of(context).pop();
          widget.onSuccess();
        } else {
          setState(() {
            _loading = false;
            _statusMsg = '';
          });
          Fluttertoast.showToast(
            msg: snap.data()?['resultDesc'] ?? 'Payment cancelled.',
            backgroundColor: Colors.red,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );
        }
        return;
      }

      // Timed out
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMsg = '';
      });
      Fluttertoast.showToast(
        msg: 'Payment timed out. Please try again.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMsg = '';
      });
      Fluttertoast.showToast(
        msg: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_android_rounded,
                          color: Color(0xFF4CAF50), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('M-Pesa Payment',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppKolors.textPrimary)),
                        Text('Lipa Na M-Pesa',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Amount card
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppKolors.dark, AppKolors.darkCard],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount to Pay',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            'KSH ${widget.amount}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Plan',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            widget.planLabel,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Phone field
                const Text('M-Pesa Number',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppKolors.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: '07XXXXXXXX',
                    prefixIcon: const Icon(Icons.phone_android_rounded,
                        color: AppKolors.primary),
                    filled: true,
                    fillColor: AppKolors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppKolors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppKolors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppKolors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Pay button
                SizedBox(
                  width: double.infinity,
                  child: _loading
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _statusMsg,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: _pay,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_rounded,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Pay Now',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
