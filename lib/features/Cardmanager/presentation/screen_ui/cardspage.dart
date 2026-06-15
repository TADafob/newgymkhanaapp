import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/statement_page.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/topuppage.dart';

final selectedFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'All');

final cardThemeProvider =
    StateProvider<bool>((ref) => false); // false=grey, true=blue

bool _isCredit(String? type) => (type ?? '').toLowerCase() == 'top up';

final transactionsStreamProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  final filter = ref.watch(selectedFilterProvider);

  return FirebaseFirestore.instance
      .collection('members_cards')
      .doc(user.uid)
      .collection('card_Transactions')
      .orderBy('trans_Date', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) {
    if (filter == 'In') {
      return snap.docs
          .where((d) => _isCredit((d.data())['trans_Type'] as String?))
          .toList();
    }
    if (filter == 'Out') {
      return snap.docs
          .where((d) => !_isCredit((d.data())['trans_Type'] as String?))
          .toList();
    }
    return snap.docs;
  });
});

final cardBalanceProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('members_cards')
      .doc(user.uid)
      .snapshots();
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class CardsPage extends ConsumerWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: const _CardsHeader()),
          SliverToBoxAdapter(child: const _FilterTabs()),
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final txAsync = ref.watch(transactionsStreamProvider);
                return txAsync.when(
                  data: (docs) {
                    if (docs.isEmpty) return const _EmptyState();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final ts =
                            (data['trans_Date'] as Timestamp?)?.toDate() ??
                                DateTime.now();
                        final showHeader = i == 0 ||
                            !_isSameDay(
                              ts,
                              (docs[i - 1].data()
                                          as Map<String, dynamic>)['trans_Date']
                                      ?.toDate() ??
                                  DateTime.now(),
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader) _DateHeader(date: ts),
                            _TransactionTile(data: data),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('Error: $e')),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86),
        child: Consumer(
          builder: (context, ref, _) => FloatingActionButton.extended(
            onPressed: () => showTopUpDialog(context, ref),
            backgroundColor: AppKolors.accent,
            elevation: 4,
            icon: const Icon(Icons.add_card_rounded, color: Colors.white),
            label: const Text('Top Up',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _CardsHeader extends ConsumerWidget {
  const _CardsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(cardBalanceProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0693e3), Color(0xFF07d8c3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nav row
              Row(
                children: [
                  _GlassButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  const Text(
                    'My Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _GlassButton(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const StatementPage()),
                        ),
                        child: const Icon(Icons.description_outlined,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, _) {
                          final isBlue = ref.watch(cardThemeProvider);
                          return _GlassButton(
                            onTap: () => ref
                                .read(cardThemeProvider.notifier)
                                .state = !isBlue,
                            child: Icon(
                              isBlue
                                  ? Icons.style_rounded
                                  : Icons.style_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final isBlue = ref.watch(cardThemeProvider);
                  return _GymkhanaCard(
                      balanceAsync: balanceAsync, isBlue: isBlue);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gymkhana Card ────────────────────────────────────────────────────────────

class _GymkhanaCard extends StatelessWidget {
  final AsyncValue<DocumentSnapshot> balanceAsync;
  final bool isBlue;
  const _GymkhanaCard({required this.balanceAsync, required this.isBlue});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Base
              isBlue
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0A1628),
                            Color(0xFF0693e3),
                            Color(0xFF07d8c3)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.6, 1.0],
                        ),
                      ),
                    )
                  : Container(color: const Color(0xFF888888)),

              // 2. Small stripe near top
              Positioned(
                top: 36,
                left: 0,
                width: 300,
                height: 10,
                child: Container(
                  color: isBlue
                      ? Colors.white.withOpacity(0.12)
                      : const Color.fromARGB(130, 241, 236, 236),
                ),
              ),

              // 3. Bigger stripe near bottom
              Positioned(
                bottom: 20,
                left: 0,
                width: 300,
                height: 60,
                child: Container(
                  color: isBlue
                      ? Colors.white.withOpacity(0.08)
                      : const Color.fromARGB(130, 241, 236, 236),
                ),
              ),

              // 4. Faded logo watermark
              Positioned.fill(
                child: Opacity(
                  opacity: 0.13,
                  child: Image.asset(
                    'assets/images/rechargescreen/lionCard.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 5. MEMBER strip on the right
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 48,
                child: Container(
                  color: isBlue ? Colors.white.withOpacity(0.15) : Colors.grey,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'MEMBER',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 6. Card content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 44, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _LogoMark(),
                          const Spacer(),
                          Icon(Icons.wifi_rounded,
                              color: isBlue
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFF3B3020).withOpacity(0.45),
                              size: 20),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          4,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Row(
                              children: List.generate(
                                4,
                                (_) => Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(right: 3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isBlue
                                        ? Colors.white.withOpacity(0.5)
                                        : const Color(0xFF3B3020)
                                            .withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          color: isBlue
                              ? Colors.white.withOpacity(0.65)
                              : const Color(0xFF3B3020).withOpacity(0.5),
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      balanceAsync.when(
                        data: (doc) {
                          final d = doc.data() as Map<String, dynamic>? ?? {};
                          final bal = d['card_Balance'] ?? 0.0;
                          return Text(
                            'KES ${NumberFormat('#,##0.00').format(bal)}',
                            style: TextStyle(
                              color: isBlue
                                  ? Colors.white
                                  : const Color(0xFF1a1208),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 28,
                          width: 110,
                          child: Center(
                            child: LinearProgressIndicator(
                              color: Color(0xFF3B82F6),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                        error: (_, __) => Text('---',
                            style: TextStyle(
                                color: isBlue
                                    ? Colors.white
                                    : const Color(0xFF1a1208),
                                fontSize: 20)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/common/logo3.png',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 3),
        const Text(
          'NAIROBI GYMKHANA',
          style: TextStyle(
            color: Color(0xFF3B3020),
            fontSize: 6,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ─── Glass Button ─────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Filter Tabs ──────────────────────────────────────────────────────────────

class _FilterTabs extends ConsumerWidget {
  const _FilterTabs();

  static const _filters = [
    ('All', 'All', AppKolors.primary, Icons.list_rounded),
    ('In', 'Credit', Color(0xFF00C853), Icons.south_west_rounded),
    ('Out', 'Debit', Color(0xFFFF5252), Icons.north_east_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppKolors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: _filters.map((f) {
                final key = f.$1;
                final label = f.$2;
                final color = f.$3;
                final icon = f.$4;
                final isSelected = selected == key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(selectedFilterProvider.notifier).state = key,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(isDark ? 0.2 : 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: color.withOpacity(0.4), width: 1.2)
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 15,
                            color: isSelected
                                ? color
                                : (isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? color
                                  : (isDark
                                      ? Colors.white38
                                      : Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Header ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TransactionTile({required this.data});

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t == 'top up') return Icons.add_card_rounded;
    if (t.contains('bar')) return Icons.local_bar_rounded;
    if (t.contains('facility') || t.contains('sport')) {
      return Icons.sports_tennis_rounded;
    }
    if (t.contains('event')) return Icons.event_rounded;
    if (t.contains('restaurant') ||
        t.contains('food') ||
        t.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (t.contains('guest')) return Icons.group_rounded;
    if (t.contains('subscription') || t.contains('member')) {
      return Icons.card_membership_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  String _labelForType(String type) {
    final t = type.toLowerCase();
    if (t == 'top up') return 'Top Up';
    if (t.contains('bar')) return 'Bar';
    if (t.contains('facility')) return 'Facility';
    if (t.contains('event')) return 'Event';
    if (t.contains('restaurant') ||
        t.contains('food') ||
        t.contains('dining')) {
      return 'Dining';
    }
    if (t.contains('guest')) return 'Guest Levy';
    if (t.contains('subscription') || t.contains('member')) return 'Membership';
    return type;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCredit = _isCredit(data['trans_Type'] as String?);
    final rawType = (data['trans_Type'] as String? ?? '').trim();
    final amount = data['trans_Amount'] ?? 0.0;
    final description = (data['trans_Descr'] as String? ?? '').trim();
    final rcptNo = (data['trans_Id'] as String? ?? '').trim();
    final waiter = (data['waiter'] as String? ?? '').trim();
    final item = (data['item'] as String? ?? '').trim();
    final paymentMethod = (data['payment_method'] as String? ?? '').trim();
    final memName = (data['mem_Name'] as String? ?? '').trim();
    final timestamp =
        (data['trans_Date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeStr = DateFormat('h:mm a').format(timestamp);
    final txColor =
        isCredit ? const Color(0xFF00C853) : const Color(0xFFFF5252);
    final typeLabel = _labelForType(rawType);
    final icon = _iconForType(rawType);

    final subtitleParts = <String>[];
    if (item.isNotEmpty) subtitleParts.add(item);
    if (waiter.isNotEmpty) subtitleParts.add('Waiter: $waiter');
    if (paymentMethod.isNotEmpty) subtitleParts.add(paymentMethod);
    if (memName.isNotEmpty) subtitleParts.add(memName);
    final subtitle = subtitleParts.join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: txColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: txColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: txColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCredit ? 'Card $typeLabel' : '$typeLabel Payment',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: txColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppKolors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (rcptNo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.receipt_outlined,
                            size: 11,
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          'Rcpt #$rcptNo',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${isCredit ? "+" : "−"}KES ${NumberFormat('#,##0').format(amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: txColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 48,
                color: isDark ? Colors.white24 : Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
