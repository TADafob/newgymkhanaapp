import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/common/widgets/dateformat.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';
import 'package:nrbgymkhana/features/subscriptions/data/model/subsmodel.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/screen_ui/all_subs_page.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/screen_ui/subs_cat.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/widgets/renew_subs_dialog.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/widgets/subscard.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final subscriptionsProvider =
    StreamProvider.family<List<Subscription>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('subscriptions_collection')
      .where('user_Id', isEqualTo: userId) // Filter by user ID
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final reaction = data['reaction'] as Map<String, dynamic>? ?? {};

      return Subscription(
        subsId: data['subs_Id'] ?? '',
        docId: doc.id,
        subsPlan: data['subs_Plan'] ?? 'Unknown Plan',
        subsCatId: data['subs_cat_Id'] ?? '',
        subsDate: (data['subs_Date'] as Timestamp).toDate(),
        amount: data['amount'] ?? 0,
        isPaid: reaction['isPaid'] ?? false, // Access from the `reaction` map
        status:
            reaction['status'] ?? 'Unknown', // Access from the `reaction` map
        userId: data['user_Id'] ?? '',
        expiryDate: (data['expiry_Date'] as Timestamp?)!.toDate(),
      );
    }).toList();
  });
});

// Fetch the main subscription categories from `subs_Category`
final subsMainCategoryProvider = StreamProvider<Map<String, String>>((ref) {
  return FirebaseFirestore.instance
      .collection('subs_Category')
      .snapshots()
      .map((snapshot) {
    return Map.fromEntries(
      snapshot.docs.map((doc) {
        final data = doc.data();
        return MapEntry(
          doc.id, // Use the document ID as the key
          data['subs_Name'] ??
              doc.id, // Fallback to document ID if name is missing
        );
      }),
    );
  });
});

// Fetch the subcategories from `Subs_sub_Category`
final subsCategoryProvider =
    StreamProvider<Map<String, Map<String, String>>>((ref) {
  return FirebaseFirestore.instance
      .collection('Subs_sub_Category')
      .snapshots()
      .map((snapshot) {
    return Map.fromEntries(
      snapshot.docs.map((doc) {
        final data = doc.data();
        return MapEntry(
          data['sub_cat_Id'] ?? '', // Use `sub_cat_Id` as the key
          {
            'name': data['name'] ?? 'Unknown Subcategory',
            'subs_Id': data['subs_Id'] ?? '', // Store `subs_Id` for linking
          },
        );
      }),
    );
  });
});



// ── SubsPage ──────────────────────────────────────────────────────────────────
class SubsPage extends ConsumerWidget {
  const SubsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userAsync = ref.watch(userStreamProvider);
    final subscriptionsAsync = ref.watch(subscriptionsProvider(userId));
    final subCategoriesAsync = ref.watch(subsCategoryProvider);
    final mainCategoriesAsync = ref.watch(subsMainCategoryProvider);

    return Scaffold(
      backgroundColor: AppKolors.background,
      body: RefreshIndicator(
        color: AppKolors.primary,
        onRefresh: () async => ref.invalidate(subscriptionsProvider(userId)),
        child: CustomScrollView(
          slivers: [
            // ── Hero header ──
            SliverToBoxAdapter(
              child: _SubsHeroHeader(userAsync: userAsync),
            ),
            // ── Section: New Subscription ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(text: 'Subscribe to a Plan'),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a membership category to get started',
                      style: TextStyle(fontSize: 13, color: AppKolors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryButton(
                            label: 'Gym',
                            subtitle: 'From Ksh 4,000',
                            icon: Icons.fitness_center_rounded,
                            gradient: const [Color(0xFF054a5e), Color(0xFF07b8a6)],
                            onTap: () => showPurchaseOptionsBottomSheet(context, ref, 'Gym'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CategoryButton(
                            label: 'Club',
                            subtitle: 'Ksh 18,500 / yr',
                            icon: Icons.card_membership_rounded,
                            gradient: const [Color(0xFF1a2e35), Color(0xFF2c4a5a)],
                            onTap: () {
                              ref.read(selectedFacilityProvider.notifier).state = 'Annual Membership';
                              showPurchaseOptionsBottomSheet(context, ref, 'Club');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Section: My Subscriptions ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel(text: 'My Subscriptions'),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AllSubscriptionsPage()),
                      ),
                      child: const Text('See all', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: subscriptionsAsync.when(
                data: (subs) => subCategoriesAsync.when(
                  data: (subCats) => mainCategoriesAsync.when(
                    data: (mainCats) {
                      if (subs.isEmpty) {
                        return SliverToBoxAdapter(
                          child: nodatawidget(title: 'No subscriptions yet'),
                        );
                      }
                      final active = subs.where((s) => s.expiryDate.isAfter(DateTime.now())).toList()
                        ..sort((a, b) => b.subsDate.compareTo(a.subsDate));
                      final display = active.isEmpty ? subs.take(3).toList() : active.take(3).toList();
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final sub = display[i];
                            final subCat = subCats[sub.subsCatId] ?? {};
                            final subCatName = subCat['name'] ?? '';
                            final mainCatId = subCat['subs_Id'] ?? '';
                            final mainCatName = mainCats[mainCatId] ?? '';
                            final isActive = sub.expiryDate.isAfter(DateTime.now());
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SubscriptionCard(
                                title: '${sub.subsPlan} ($subCatName)',
                                status: sub.status,
                                datePaid: formatDateWithSuffix(sub.subsDate),
                                amount: sub.amount.toString(),
                                substype: mainCatName,
                                isActive: isActive,
                                onRenew: !isActive && sub.docId.isNotEmpty
                                    ? () => showRenewSubsDialog(
                                          context,
                                          ref,
                                          subsDocId: sub.docId,
                                          title: '${sub.subsPlan} ($subCatName)',
                                          amount: sub.amount,
                                          subsCatId: sub.subsCatId,
                                          expiryDate: sub.expiryDate,
                                        )
                                    : null,
                              ),
                            );
                          },
                          childCount: display.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(child: PageShimmer(itemCount: 2)),
                    error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
                  ),
                  loading: () => const SliverToBoxAdapter(child: PageShimmer(itemCount: 2)),
                  error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
                ),
                loading: () => const SliverToBoxAdapter(child: PageShimmer(itemCount: 2)),
                error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _SubsHeroHeader extends StatelessWidget {
  final AsyncValue<DocumentSnapshot> userAsync;
  const _SubsHeroHeader({required this.userAsync});

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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Memberships',
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
                  userAsync.when(
                    data: (doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final name = '${data['f_Name'] ?? ''} ${data['l_Name'] ?? ''}'.trim();
                      final memType = data['mem_Type'] as String? ?? 'Member';
                      final memNo = data['mem_Number'] as String? ?? '';
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _HeaderChip(label: '$memType Member'),
                                    if (memNo.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      _HeaderChip(label: '# $memNo'),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 52),
                    error: (_, __) => const SizedBox.shrink(),
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

class _HeaderChip extends StatelessWidget {
  final String label;
  const _HeaderChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppKolors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── Category Button ───────────────────────────────────────────────────────────
class _CategoryButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _CategoryButton({
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
                  'Subscribe',
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
