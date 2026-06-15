import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/africas_talking_service.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    try {
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentCtrl.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(_newCtrl.text.trim());

      // Fetch user data for notifications
      final doc = await FirebaseFirestore.instance
          .collection('users_members')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};
      final name = '${data['f_Name'] ?? ''} ${data['l_Name'] ?? ''}'.trim();
      final phone = data['phone'] as String? ?? '';
      final email = data['email'] as String? ?? user.email ?? '';
      final smsEnabled = data['smsNotificationsEnabled'] as bool? ?? true;
      final now = DateTime.now();

      // 1. In-app notification
      await FirebaseFirestore.instance
          .collection('notifications_collection')
          .add({
        'recipientId': user.uid,
        'type': 'security',
        'title': 'Password Changed',
        'description':
            'Your account password was successfully changed. If this wasn\'t you, contact support immediately.',
        'timestamp': Timestamp.fromDate(now),
        'isNew': true,
      });

      // 2. SMS
      if (smsEnabled && phone.isNotEmpty) {
        await AfricasTalkingService.sendPasswordChangeAlert(
          phone: phone,
          userName: name.isEmpty ? 'Member' : name,
          channel: ATChannel.sms,
        );
      }

      // 3. Email (via Africa's Talking or your email endpoint)
      if (email.isNotEmpty) {
        await AfricasTalkingService.sendPasswordChangeAlert(
          phone: email,
          userName: name.isEmpty ? 'Member' : name,
          channel: ATChannel.email,
        );
      }

      if (!mounted) return;

      // 4. In-app alert dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: Colors.green, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password Updated',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Your password has been changed successfully. A confirmation has been sent via SMS and email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done',
                  style: TextStyle(
                      color: AppKolors.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'wrong-password'
          ? 'Current password is incorrect.'
          : e.message ?? 'An error occurred.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppKolors.darkBackground : AppKolors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor:
                isDark ? AppKolors.darkSurface : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppKolors.textPrimary,
                  size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(
                'Change Password',
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
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                20, 24, 20, MediaQuery.of(context).padding.bottom + 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Security notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppKolors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppKolors.primary.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded,
                          color: AppKolors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You\'ll receive an SMS and email confirmation after changing your password.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : AppKolors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D1E33)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _PasswordField(
                          controller: _currentCtrl,
                          label: 'Current Password',
                          show: _showCurrent,
                          onToggle: () =>
                              setState(() => _showCurrent = !_showCurrent),
                          isDark: isDark,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter current password'
                              : null,
                        ),
                        _divider(isDark),
                        _PasswordField(
                          controller: _newCtrl,
                          label: 'New Password',
                          show: _showNew,
                          onToggle: () =>
                              setState(() => _showNew = !_showNew),
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter new password';
                            }
                            if (v.length < 8) {
                              return 'Minimum 8 characters';
                            }
                            if (v == _currentCtrl.text.trim()) {
                              return 'New password must differ from current';
                            }
                            return null;
                          },
                        ),
                        _divider(isDark),
                        _PasswordField(
                          controller: _confirmCtrl,
                          label: 'Confirm New Password',
                          show: _showConfirm,
                          onToggle: () =>
                              setState(() => _showConfirm = !_showConfirm),
                          isDark: isDark,
                          validator: (v) => v != _newCtrl.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppKolors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ]),
            ),
          ),
        ],
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
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final bool isDark;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.isDark,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        obscureText: !show,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppKolors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : AppKolors.textSecondary,
          ),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: AppKolors.primary, size: 18),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: isDark ? Colors.white38 : AppKolors.textSecondary,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
