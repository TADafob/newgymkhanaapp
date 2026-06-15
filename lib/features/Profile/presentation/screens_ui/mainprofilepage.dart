import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Profile/presentation/providers/historyprovider.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/accountdetials.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/change_password_page.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/payment_methods_page.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/appsettings.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/contactpage.dart';
import 'package:nrbgymkhana/features/app_auths/presentation/providers/auth_provider.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/allbookingspage.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final reportCountAsync = ref.watch(reportCountProvider);
    final upcomingAsync = ref.watch(upcomingBookingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppKolors.primary,
      onRefresh: () async {
        ref.invalidate(userStreamProvider);
        ref.invalidate(userDataProvider);
        ref.invalidate(reportCountProvider);
        ref.invalidate(upcomingBookingsProvider);
      },
      child: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeroHeader(userAsync: userAsync, isDark: isDark),
          ),

          // ── Stat Cards ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                    _StatCard(
                      label: 'Upcoming\nBookings',
                      icon: Icons.calendar_month_rounded,
                      color: AppKolors.primary,
                      valueAsync: upcomingAsync,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BookingsOverviewPage())),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Active\nSubs',
                      icon: Icons.card_membership_rounded,
                      color: AppKolors.accent,
                      valueAsync: userDataAsync.whenData((d) => d.activeSubscriptions),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Reported\nIssues',
                      icon: Icons.report_rounded,
                      color: const Color(0xFFef4444),
                      valueAsync: reportCountAsync,
                    ),
                ],
              ),
            ),
          ),

          // ── Account Section ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _MenuSection(
              title: 'Account',
              isDark: isDark,
              items: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Account Information',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EditProfilePage())),
                ),
                _MenuItem(
                  icon: Icons.payment_rounded,
                  label: 'Payment Methods',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PaymentMethodsPage())),
                ),
                _MenuItem(
                  icon: Icons.lock_reset_rounded,
                  label: 'Change Password',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Preferences Section ──────────────────────────────────
          SliverToBoxAdapter(
            child: _MenuSection(
              title: 'Preferences',
              isDark: isDark,
              items: [
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'App Settings',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AppSettingsPage())),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Support Section ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _MenuSection(
              title: 'Support',
              isDark: isDark,
              items: [
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: "FAQ's",
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ContactSupportPage())),
                ),
                _MenuItem(
                  icon: Icons.support_agent_rounded,
                  label: 'Contact Support',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ContactSupportPage())),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Support Contact Card ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SupportBanner(isDark: isDark),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Sign Out ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SignOutButton(ref: ref),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 100,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _ProfileHeroHeader extends StatelessWidget {
  final AsyncValue userAsync;
  final bool isDark;
  const _ProfileHeroHeader({required this.userAsync, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppKolors.primary, AppKolors.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D0693e3),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Bubble decorations
            Positioned(
              top: -30, right: -20,
              child: _Bubble(100, 0.07),
            ),
            Positioned(
              top: 20, right: 70,
              child: _Bubble(55, 0.05),
            ),
            Positioned(
              bottom: 30, left: -20,
              child: _Bubble(80, 0.06),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: userAsync.when(
                data: (doc) {
                  final data = (doc.data() as Map<String, dynamic>?) ?? {};
                  final firstName = data['f_Name'] as String? ?? '';
                  final lastName = data['l_Name'] as String? ?? '';
                  final fullName = '$firstName $lastName'.trim();
                  final memType = data['mem_Type'] as String? ?? 'Member';
                  final memNo = data['mem_Number'] as String? ?? '';
                  final email = data['email'] as String? ?? '';
                  final initials = [
                    if (firstName.isNotEmpty) firstName[0],
                    if (lastName.isNotEmpty) lastName[0],
                  ].join().toUpperCase();

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            initials.isEmpty ? 'M' : initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? 'Member' : fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _HeaderChip(label: '$memType Member'),
                                if (memNo.isNotEmpty)
                                  _HeaderChip(label: '# $memNo'),
                              ],
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.mail_outline_rounded,
                                      size: 13,
                                      color: Colors.white.withValues(alpha: 0.7)),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 72),
                error: (_, __) => const SizedBox.shrink(),
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

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble(this.size, this.opacity);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final AsyncValue<int> valueAsync;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.valueAsync,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = valueAsync.maybeWhen(data: (v) => '$v', orElse: () => '—');

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1E33) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : AppKolors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu Section ──────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final bool isDark;

  const _MenuSection({
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : AppKolors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D1E33) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _MenuTile(item: items[i], isDark: isDark),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.withValues(alpha: 0.12),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final bool isDark;
  const _MenuTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppKolors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppKolors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppKolors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Support Banner ────────────────────────────────────────────────────────────
class _SupportBanner extends StatelessWidget {
  final bool isDark;
  const _SupportBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppKolors.primary.withValues(alpha: 0.12),
            AppKolors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppKolors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppKolors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.headset_mic_rounded,
                color: AppKolors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppKolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '0708 042 394  ·  Techsupport@nairobigymkhana.com',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : AppKolors.textSecondary,
                    height: 1.4,
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

// ── Sign Out Button ───────────────────────────────────────────────────────────
class _SignOutButton extends StatelessWidget {
  final WidgetRef ref;
  const _SignOutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmSignOut(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFef4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFef4444).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFef4444), size: 20),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Color(0xFFef4444),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppKolors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(signOutUseCaseProvider).call();
            },
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Color(0xFFef4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
