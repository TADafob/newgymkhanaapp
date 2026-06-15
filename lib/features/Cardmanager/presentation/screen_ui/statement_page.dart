import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/statement_pdf_generator.dart';
import 'package:nrbgymkhana/features/Profile/domain/entities/profile_data.dart';
import 'package:nrbgymkhana/features/Profile/presentation/providers/profile_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

bool _isCredit(String? type) => (type ?? '').toLowerCase() == 'top up';

// ── Providers ─────────────────────────────────────────────────────────────────

final statementFromProvider = StateProvider<DateTime?>((ref) => null);
final statementToProvider = StateProvider<DateTime?>((ref) => null);
final statementLoadingProvider = StateProvider<bool>((ref) => false);

// ── Bottom sheet entry point ──────────────────────────────────────────────────

Future<void> showCardStatementSheet(BuildContext context, WidgetRef ref) {
  // Reset date range each time the sheet opens
  ref.read(statementFromProvider.notifier).state = null;
  ref.read(statementToProvider.notifier).state = null;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: const _StatementSheet(),
    ),
  );
}

class _StatementSheet extends ConsumerWidget {
  const _StatementSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final from = ref.watch(statementFromProvider);
    final to = ref.watch(statementToProvider);
    final isLoading = ref.watch(statementLoadingProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1E33) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppKolors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: AppKolors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card Statement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppKolors.textPrimary,
                        )),
                    Text('Select a date range to generate',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : AppKolors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick range chips
            _QuickRangeChips(isDark: isDark),
            const SizedBox(height: 16),

            // From / To pickers
            Row(
              children: [
                Expanded(
                  child: _DatePickerTile(
                    label: 'From',
                    date: from,
                    isDark: isDark,
                    onTap: () => _pickDate(context, ref, isFrom: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerTile(
                    label: 'To',
                    date: to,
                    isDark: isDark,
                    onTap: () => _pickDate(context, ref, isFrom: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (from != null && to != null && !isLoading)
                    ? () => _generate(context, ref, uid)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKolors.primary,
                  disabledBackgroundColor:
                      isDark ? Colors.white12 : Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white),
                label: Text(
                  isLoading ? 'Generating...' : 'Generate Statement',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref,
      {required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (ref.read(statementFromProvider) ?? now)
          : (ref.read(statementToProvider) ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: ColorScheme.light(primary: AppKolors.primary)),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (isFrom) {
      ref.read(statementFromProvider.notifier).state = picked;
    } else {
      ref.read(statementToProvider.notifier).state = picked;
    }
  }

  Future<void> _generate(
      BuildContext context, WidgetRef ref, String uid) async {
    final from = ref.read(statementFromProvider)!;
    final to = ref.read(statementToProvider)!;

    if (to.isBefore(from)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('"To" date must be after "From" date'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    ref.read(statementLoadingProvider.notifier).state = true;
    try {
      final toEndOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      final snap = await FirebaseFirestore.instance
          .collection('members_cards')
          .doc(uid)
          .collection('card_Transactions')
          .orderBy('trans_Date', descending: false)
          .where('trans_Date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('trans_Date',
              isLessThanOrEqualTo: Timestamp.fromDate(toEndOfDay))
          .get();

      final transactions = snap.docs.map((d) => d.data()).toList();
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.fetchProfile(uid);
      final balDoc = await FirebaseFirestore.instance
          .collection('members_cards')
          .doc(uid)
          .get();
      final balance = (balDoc.data()?['card_Balance'] ?? 0.0) as num;

      if (!context.mounted) return;
      Navigator.of(context).pop(); // close sheet
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StatementPreviewPage(
          profile: profile,
          transactions: transactions,
          from: from,
          to: toEndOfDay,
          currentBalance: balance.toDouble(),
        ),
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      ref.read(statementLoadingProvider.notifier).state = false;
    }
  }
}
class StatementPage extends ConsumerWidget {
  const StatementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final profileAsync = ref.watch(profileProvider(uid));
    final from = ref.watch(statementFromProvider);
    final to = ref.watch(statementToProvider);
    final isLoading = ref.watch(statementLoadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member info card
                  profileAsync.when(
                    data: (p) => _MemberCard(profile: p, isDark: isDark),
                    loading: () => const _MemberCardSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Date range section
                  _SectionLabel(label: 'SELECT DATE RANGE', isDark: isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerTile(
                          label: 'From',
                          date: from,
                          isDark: isDark,
                          onTap: () => _pickDate(context, ref, isFrom: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerTile(
                          label: 'To',
                          date: to,
                          isDark: isDark,
                          onTap: () => _pickDate(context, ref, isFrom: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick range chips
                  _SectionLabel(label: 'QUICK SELECT', isDark: isDark),
                  const SizedBox(height: 10),
                  _QuickRangeChips(isDark: isDark),

                  const SizedBox(height: 32),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: (from != null && to != null && !isLoading)
                          ? () => _generate(context, ref, uid)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppKolors.primary,
                        disabledBackgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white),
                      label: Text(
                        isLoading ? 'Generating...' : 'Generate Statement',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppKolors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppKolors.primary.withOpacity(0.18)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppKolors.primary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The statement will be generated as a PDF and can be saved or shared. It includes all card transactions within the selected period.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : AppKolors.textSecondary,
                              height: 1.5,
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0693e3), Color(0xFF07d8c3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Statement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Generate your transaction history',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref,
      {required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (ref.read(statementFromProvider) ?? now)
          : (ref.read(statementToProvider) ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppKolors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (isFrom) {
      ref.read(statementFromProvider.notifier).state = picked;
    } else {
      ref.read(statementToProvider.notifier).state = picked;
    }
  }

  Future<void> _generate(
      BuildContext context, WidgetRef ref, String uid) async {
    final from = ref.read(statementFromProvider)!;
    final to = ref.read(statementToProvider)!;

    // Validate range
    if (to.isBefore(from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('"To" date must be after "From" date'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    ref.read(statementLoadingProvider.notifier).state = true;

    try {
      // Fetch transactions
      final toEndOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      final snap = await FirebaseFirestore.instance
          .collection('members_cards')
          .doc(uid)
          .collection('card_Transactions')
          .orderBy('trans_Date', descending: false)
          .where('trans_Date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('trans_Date',
              isLessThanOrEqualTo: Timestamp.fromDate(toEndOfDay))
          .get();

      final transactions = snap.docs.map((d) => d.data()).toList();
      debugPrint('[StatementPage] Fetched ${transactions.length} transactions');

      // Fetch profile
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.fetchProfile(uid);
      debugPrint(
          '[StatementPage] Profile fetched: username=${profile.username}, email=${profile.email}, phone=${profile.phone}');

      // Fetch balance
      final balDoc = await FirebaseFirestore.instance
          .collection('members_cards')
          .doc(uid)
          .get();
      final balance = (balDoc.data()?['card_Balance'] ?? 0.0) as num;
      debugPrint('[StatementPage] Balance fetched: $balance');

      if (!context.mounted) return;

      debugPrint(
          '[StatementPage] Navigating to preview with ${transactions.length} transactions');

      // Navigate to preview
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StatementPreviewPage(
          profile: profile,
          transactions: transactions,
          from: from,
          to: toEndOfDay,
          currentBalance: balance.toDouble(),
        ),
      ));
    } catch (e, stackTrace) {
      debugPrint('[StatementPage] ERROR generating statement: $e');
      debugPrint('[StatementPage] Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      ref.read(statementLoadingProvider.notifier).state = false;
    }
  }
}

// ── Quick Range Chips ─────────────────────────────────────────────────────────

class _QuickRangeChips extends ConsumerWidget {
  final bool isDark;
  const _QuickRangeChips({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final ranges = [
      ('This Month', DateTime(now.year, now.month, 1), now),
      (
        'Last Month',
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 0)
      ),
      ('Last 3 Months', DateTime(now.year, now.month - 3, 1), now),
      ('This Year', DateTime(now.year, 1, 1), now),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ranges.map((r) {
        return GestureDetector(
          onTap: () {
            ref.read(statementFromProvider.notifier).state = r.$2;
            ref.read(statementToProvider.notifier).state = r.$3;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Text(
              r.$1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppKolors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Member Card ───────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final Profile profile;
  final bool isDark;
  const _MemberCard({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppKolors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.username
                    .trim()
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join(),
                style: const TextStyle(
                  color: AppKolors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.username,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppKolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Member',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00C853),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCardSkeleton extends StatelessWidget {
  const _MemberCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

// ── Date Picker Tile ──────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isDark;
  final VoidCallback onTap;
  const _DatePickerTile(
      {required this.label,
      required this.date,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: date != null
                ? AppKolors.primary.withOpacity(0.4)
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: date != null ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: date != null
                  ? AppKolors.primary
                  : (isDark ? Colors.white38 : Colors.grey.shade400),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date!)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? (isDark ? Colors.white : AppKolors.textPrimary)
                          : (isDark ? Colors.white30 : Colors.grey.shade400),
                    ),
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

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? Colors.white38 : AppKolors.textSecondary,
      ),
    );
  }
}

// ── Statement Preview Page ────────────────────────────────────────────────────

class StatementPreviewPage extends StatefulWidget {
  final Profile profile;
  final List<Map<String, dynamic>> transactions;
  final DateTime from;
  final DateTime to;
  final double currentBalance;

  const StatementPreviewPage({
    super.key,
    required this.profile,
    required this.transactions,
    required this.from,
    required this.to,
    required this.currentBalance,
  });

  @override
  State<StatementPreviewPage> createState() => _StatementPreviewPageState();
}

class _StatementPreviewPageState extends State<StatementPreviewPage> {
  Uint8List? _pdfBytes;
  bool _generating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buildPdf();
  }

  Future<void> _buildPdf() async {
    try {
      debugPrint('[StatementPreviewPage] Starting PDF build');
      final bytes = await StatementPdfGenerator.generate(
        profile: widget.profile,
        transactions: widget.transactions,
        from: widget.from,
        to: widget.to,
        currentBalance: widget.currentBalance,
      );
      debugPrint(
          '[StatementPreviewPage] PDF generation successful, size: ${bytes.length} bytes');
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _generating = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[StatementPreviewPage] ERROR generating PDF: $e');
      debugPrint('[StatementPreviewPage] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _generating = false;
        });
      }
    }
  }

  Future<void> _share() async {
    if (_pdfBytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/NRB_Gymkhana_Statement_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(_pdfBytes!);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Nairobi Gymkhana Card Statement');
  }

  Future<void> _saveToDevice() async {
    if (_pdfBytes == null) return;
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not access device storage'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final fileName =
          'NRB_Gymkhana_Statement_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(_pdfBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved to ${file.path}'),
          backgroundColor: const Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(file.path),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          // Header
          Container(
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statement Preview',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${dateFmt.format(widget.from)}  →  ${dateFmt.format(widget.to)}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (!_generating && _pdfBytes != null) ...[
                      _HeaderAction(icon: Icons.share_rounded, onTap: _share),
                      const SizedBox(width: 8),
                      _HeaderAction(
                          icon: Icons.download_rounded, onTap: _saveToDevice),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Summary strip
          if (!_generating && _pdfBytes != null)
            Container(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(
                    label: 'Transactions',
                    value: '${widget.transactions.length}',
                    color: const Color(0xFF0693e3),
                    isDark: isDark,
                  ),
                  _SummaryChip(
                    label: 'Credits',
                    value:
                        'KES ${NumberFormat('#,##0').format(widget.transactions.where((t) => _isCredit(t['trans_Type']?.toString())).fold(0.0, (s, t) => s + (t['trans_Amount'] as num? ?? 0).toDouble()))}',
                    color: const Color(0xFF00C853),
                    isDark: isDark,
                  ),
                  _SummaryChip(
                    label: 'Debits',
                    value:
                        'KES ${NumberFormat('#,##0').format(widget.transactions.where((t) => !_isCredit(t['trans_Type']?.toString())).fold(0.0, (s, t) => s + (t['trans_Amount'] as num? ?? 0).toDouble()))}',
                    color: const Color(0xFFFF5252),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

          // PDF viewer / loading / error
          Expanded(
            child: _generating
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Building your statement...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : PdfPreview(
                        build: (_) async => _pdfBytes!,
                        allowPrinting: true,
                        allowSharing: false,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        pdfFileName: 'NRB_Gymkhana_Statement.pdf',
                        actions: const [],
                      ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

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
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _SummaryChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.grey.shade500)),
      ],
    );
  }
}
