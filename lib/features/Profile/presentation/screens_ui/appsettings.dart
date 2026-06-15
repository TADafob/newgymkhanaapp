import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/common/sharedpreff/localstorage.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSettingsPage extends ConsumerStatefulWidget {
  const AppSettingsPage({super.key});

  @override
  _AppSettingsPageState createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends ConsumerState<AppSettingsPage> {
  bool? _notificationsEnabled;
  bool _bookingReminders = true;
  bool _newsAlerts = true;
  bool _promotionalAlerts = false;
  bool _smsEnabled = true;
  bool _whatsappEnabled = false;
  String _appVersion = '';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadAppVersion();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final notifEnabled = await LocalStorage.getNotificationsEnabled();

    // Load SMS / WhatsApp from Firestore (source of truth for the monitor)
    bool sms = true;
    bool whatsapp = false;
    final uid = _uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users_members')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      sms = data['smsNotificationsEnabled'] as bool? ?? true;
      whatsapp = data['whatsappNotificationsEnabled'] as bool? ?? false;
    }

    setState(() {
      _notificationsEnabled = notifEnabled ?? false;
      _bookingReminders = prefs.getBool('booking_reminders') ?? true;
      _newsAlerts = prefs.getBool('news_alerts') ?? true;
      _promotionalAlerts = prefs.getBool('promotional_alerts') ?? false;
      _smsEnabled = sms;
      _whatsappEnabled = whatsapp;
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    } catch (_) {
      setState(() => _appVersion = '1.0.0');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    await LocalStorage.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);

    final uid = _uid;
    if (value) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && uid != null) {
        await FirebaseFirestore.instance
            .collection('users_members')
            .doc(uid)
            .update({'fcm_Token': token, 'notificationsEnabled': true});
      }
    } else {
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users_members')
            .doc(uid)
            .update({'fcm_Token': FieldValue.delete(), 'notificationsEnabled': false});
      }
    }
  }

  Future<void> _toggleFirestorePref(String field, bool value) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users_members')
        .doc(uid)
        .update({field: value});
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_notificationsEnabled == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? AppKolors.darkBackground : AppKolors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Appearance ──────────────────────────────────────
                _SectionLabel(label: 'APPEARANCE', isDark: isDark),
                const SizedBox(height: 8),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _ThemeSelector(
                      themeMode: themeMode,
                      isDark: isDark,
                      onChanged: (mode) =>
                          ref.read(themeProvider.notifier).setTheme(mode),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Notifications ────────────────────────────────────
                _SectionLabel(label: 'NOTIFICATIONS', isDark: isDark),
                const SizedBox(height: 8),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _SwitchTile(
                      icon: Icons.notifications_active_outlined,
                      iconColor: AppKolors.primary,
                      title: 'Push Notifications',
                      subtitle: 'Receive alerts on this device',
                      value: _notificationsEnabled!,
                      isDark: isDark,
                      onChanged: _toggleNotifications,
                    ),
                    _divider(isDark),
                    _SwitchTile(
                      icon: Icons.event_available_outlined,
                      iconColor: const Color(0xFF10b981),
                      title: 'Booking Reminders',
                      subtitle: 'Alerts before your bookings',
                      value: _bookingReminders,
                      isDark: isDark,
                      enabled: _notificationsEnabled!,
                      onChanged: (v) {
                        setState(() => _bookingReminders = v);
                        _setPref('booking_reminders', v);
                      },
                    ),
                    _divider(isDark),
                    _SwitchTile(
                      icon: Icons.newspaper_outlined,
                      iconColor: AppKolors.accent,
                      title: 'News & Announcements',
                      subtitle: 'Club news and updates',
                      value: _newsAlerts,
                      isDark: isDark,
                      enabled: _notificationsEnabled!,
                      onChanged: (v) {
                        setState(() => _newsAlerts = v);
                        _setPref('news_alerts', v);
                      },
                    ),
                    _divider(isDark),
                    _SwitchTile(
                      icon: Icons.local_offer_outlined,
                      iconColor: const Color(0xFFf59e0b),
                      title: 'Promotions & Offers',
                      subtitle: 'Special deals and events',
                      value: _promotionalAlerts,
                      isDark: isDark,
                      enabled: _notificationsEnabled!,
                      onChanged: (v) {
                        setState(() => _promotionalAlerts = v);
                        _setPref('promotional_alerts', v);
                      },
                    ),
                    _divider(isDark),
                    _SwitchTile(
                      icon: Icons.sms_outlined,
                      iconColor: const Color(0xFF10b981),
                      title: 'SMS Notifications',
                      subtitle: 'Receive transaction alerts via SMS',
                      value: _smsEnabled,
                      isDark: isDark,
                      onChanged: (v) {
                        setState(() => _smsEnabled = v);
                        _toggleFirestorePref('smsNotificationsEnabled', v);
                      },
                    ),
                    _divider(isDark),
                    _SwitchTile(
                      icon: Icons.chat_outlined,
                      iconColor: const Color(0xFF25D366),
                      title: 'WhatsApp Notifications',
                      subtitle: 'Receive transaction alerts via WhatsApp',
                      value: _whatsappEnabled,
                      isDark: isDark,
                      onChanged: (v) {
                        setState(() => _whatsappEnabled = v);
                        _toggleFirestorePref('whatsappNotificationsEnabled', v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── About ────────────────────────────────────────────
                _SectionLabel(label: 'ABOUT', isDark: isDark),
                const SizedBox(height: 8),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _InfoTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppKolors.primary,
                      title: 'App Version',
                      trailing: _appVersion,
                      isDark: isDark,
                    ),
                    _divider(isDark),
                    _TapTile(
                      icon: Icons.description_outlined,
                      iconColor: AppKolors.textSecondary,
                      title: 'Terms & Conditions',
                      isDark: isDark,
                      onTap: () => _launchUrl('https://nairobigymkhana.com/terms'),
                    ),
                    _divider(isDark),
                    _TapTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppKolors.textSecondary,
                      title: 'Privacy Policy',
                      isDark: isDark,
                      onTap: () => _launchUrl('https://nairobigymkhana.com/privacy'),
                    ),
                    _divider(isDark),
                    _TapTile(
                      icon: Icons.rate_review_outlined,
                      iconColor: const Color(0xFFf59e0b),
                      title: 'Rate the App',
                      isDark: isDark,
                      onTap: () => _launchUrl('https://play.google.com/store'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Data & Storage ───────────────────────────────────
                _SectionLabel(label: 'DATA & STORAGE', isDark: isDark),
                const SizedBox(height: 8),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _TapTile(
                      icon: Icons.cleaning_services_outlined,
                      iconColor: const Color(0xFFef4444),
                      title: 'Clear Cache',
                      isDark: isDark,
                      onTap: () => _clearCache(context),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      backgroundColor: isDark ? AppKolors.darkSurface : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppKolors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
        title: Text(
          'App Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppKolors.textPrimary,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppKolors.primary.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 56,
        endIndent: 16,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.withValues(alpha: 0.12),
      );

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Cache',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This will clear locally cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppKolors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(
                    color: Color(0xFFef4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? Colors.white38 : AppKolors.textSecondary,
          ),
        ),
      );
}

// ── Settings Card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
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
        child: Column(children: children),
      );
}

// ── Theme Selector ────────────────────────────────────────────────────────────
class _ThemeSelector extends StatelessWidget {
  final ThemeMode themeMode;
  final bool isDark;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeSelector(
      {required this.themeMode,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppKolors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_outlined,
                    color: AppKolors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                'App Theme',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppKolors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ThemeChip(
                label: 'System',
                icon: Icons.brightness_auto_rounded,
                mode: ThemeMode.system,
                selected: themeMode == ThemeMode.system,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.system),
              ),
              const SizedBox(width: 8),
              _ThemeChip(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                mode: ThemeMode.light,
                selected: themeMode == ThemeMode.light,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.light),
              ),
              const SizedBox(width: 8),
              _ThemeChip(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                mode: ThemeMode.dark,
                selected: themeMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _ThemeChip(
      {required this.label,
      required this.icon,
      required this.mode,
      required this.selected,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppKolors.primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppKolors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppKolors.primary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white54 : AppKolors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white54 : AppKolors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Switch Tile ───────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppKolors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : AppKolors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppKolors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;
  final bool isDark;
  const _InfoTile(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.trailing,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppKolors.textPrimary,
              ),
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : AppKolors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tap Tile ──────────────────────────────────────────────────────────────────
class _TapTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  const _TapTile(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
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
