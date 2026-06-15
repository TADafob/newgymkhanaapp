import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Profile/domain/entities/profile_data.dart';
import 'package:nrbgymkhana/features/Profile/presentation/providers/profile_provider.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final profileAsync = ref.watch(profileProvider(uid));

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF0F4F8),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => _AccountInfoBody(profile: profile),
      ),
    );
  }
}

class _AccountInfoBody extends StatelessWidget {
  final Profile profile;
  const _AccountInfoBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = profile.username.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final spouse = (profile.connectees['Spouse'] ?? []).join(', ');
    final children = (profile.connectees['Children'] ?? []).join(', ');

    return CustomScrollView(
      slivers: [
        // ── Hero Header ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroHeader(
            initials: initials,
            name: profile.username,
            isDark: isDark,
          ),
        ),

        // ── Personal Info ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _InfoSection(
            title: 'Personal Information',
            icon: Icons.person_rounded,
            isDark: isDark,
            fields: [
              _InfoField(
                icon: Icons.badge_outlined,
                label: 'Full Name',
                value: profile.username,
              ),
              _InfoField(
                icon: Icons.wc_rounded,
                label: 'Gender',
                value: profile.gender,
              ),
              _InfoField(
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: profile.dob,
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Contact Info ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _InfoSection(
            title: 'Contact Details',
            icon: Icons.contact_mail_rounded,
            isDark: isDark,
            fields: [
              _InfoField(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: profile.email,
                copyable: true,
              ),
              _InfoField(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: profile.phone,
                copyable: true,
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Family / Connectees ──────────────────────────────────────
        if (spouse.isNotEmpty || children.isNotEmpty)
          SliverToBoxAdapter(
            child: _InfoSection(
              title: 'Family & Connectees',
              icon: Icons.people_rounded,
              isDark: isDark,
              fields: [
                if (spouse.isNotEmpty)
                  _InfoField(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Spouse',
                    value: spouse,
                  ),
                if (children.isNotEmpty)
                  _InfoField(
                    icon: Icons.child_care_rounded,
                    label: 'Children',
                    value: children,
                  ),
              ],
            ),
          ),

        // ── Note ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppKolors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppKolors.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppKolors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To update your information, please contact the club administration.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppKolors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String initials;
  final String name;
  final bool isDark;
  const _HeroHeader(
      {required this.initials, required this.name, required this.isDark});

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
            // Bubbles
            Positioned(top: -30, right: -20, child: _Bubble(100, 0.07)),
            Positioned(top: 20, right: 70, child: _Bubble(55, 0.05)),
            Positioned(bottom: 20, left: -20, child: _Bubble(70, 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                children: [
                  // Back button row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Avatar + name
                  Container(
                    width: 80,
                    height: 80,
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
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Nairobi Gymkhana Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
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

// ── Info Section ──────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoField> fields;
  final bool isDark;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.fields,
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
            padding: const EdgeInsets.only(left: 4, bottom: 10, top: 20),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppKolors.primary),
                const SizedBox(width: 7),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : AppKolors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
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
                for (int i = 0; i < fields.length; i++) ...[
                  _InfoRow(field: fields[i], isDark: isDark),
                  if (i < fields.length - 1)
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

class _InfoField {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });
}

class _InfoRow extends StatelessWidget {
  final _InfoField field;
  final bool isDark;
  const _InfoRow({required this.field, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isEmpty = field.value.trim().isEmpty || field.value == 'N/A';

    return Padding(
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
            child: Icon(field.icon, color: AppKolors.primary, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : AppKolors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEmpty ? '—' : field.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEmpty
                        ? (isDark ? Colors.white24 : Colors.grey.shade400)
                        : (isDark ? Colors.white : AppKolors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (field.copyable && !isEmpty)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: field.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${field.label} copied'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppKolors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.copy_rounded,
                    size: 15, color: AppKolors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
