import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:nrbgymkhana/core/utils/mpesa_service.dart';

enum _PayState { idle, waiting, success, failure }

/// Shows a beautiful M-Pesa STK-push bottom sheet.
///
/// [amount]       – KES amount to charge
/// [accountRef]   – Daraja account reference (e.g. "GuestLevy", "WalletTopUp")
/// [description]  – Short description sent to Daraja
/// [title]        – Sheet header title
/// [onSuccess]    – Called after confirmed payment (Firestore callback received)
///
/// Returns `true` if payment succeeded, `false`/`null` otherwise.
Future<bool?> showMpesaPaymentSheet(
  BuildContext context, {
  required int amount,
  required String accountRef,
  String description = 'Payment',
  String title = 'M-Pesa Payment',
  String? initialPhone,
  Future<void> Function(Map<String, dynamic> callbackData)? onSuccess,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MpesaSheet(
      amount: amount,
      accountRef: accountRef,
      description: description,
      title: title,
      initialPhone: initialPhone,
      onSuccess: onSuccess,
    ),
  );
}

class _MpesaSheet extends StatefulWidget {
  final int amount;
  final String accountRef;
  final String description;
  final String title;
  final String? initialPhone;
  final Future<void> Function(Map<String, dynamic>)? onSuccess;

  const _MpesaSheet({
    required this.amount,
    required this.accountRef,
    required this.description,
    required this.title,
    this.initialPhone,
    this.onSuccess,
  });

  @override
  State<_MpesaSheet> createState() => _MpesaSheetState();
}

class _MpesaSheetState extends State<_MpesaSheet>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  _PayState _state = _PayState.idle;
  String _statusMsg = '';
  String _errorMsg = '';

  late AnimationController _pulseCtrl;
  StreamSubscription<DocumentSnapshot>? _callbackSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      // Phone already known — pre-fill and auto-fire STK push after first frame
      _phoneCtrl.text = widget.initialPhone!;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _pay(); });
    } else {
      _prefillPhone();
    }
  }

  Future<void> _prefillPhone() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users_members')
        .doc(uid)
        .get();
    final phone = doc.data()?['phone_Number']?.toString() ?? '';
    if (mounted) _phoneCtrl.text = phone;
  }

  @override
  void dispose() {
    _callbackSub?.cancel();
    _pulseCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMsg = 'Please enter your M-Pesa number.');
      return;
    }
    setState(() {
      _state = _PayState.waiting;
      _statusMsg = 'Sending M-Pesa prompt…';
      _errorMsg = '';
    });

    try {
      final result = await MpesaService.stkPush(
        phone: phone,
        amount: widget.amount,
        accountRef: widget.accountRef,
        description: widget.description,
      );

      final checkoutId = result['CheckoutRequestID'] as String?;
      if (checkoutId == null) throw Exception('No CheckoutRequestID returned.');

      if (!mounted) return;
      setState(() => _statusMsg = 'Enter your M-Pesa PIN on your phone…');

      // 90-second timeout timer — cancels the subscription if no callback arrives
      final timeout = Future.delayed(const Duration(seconds: 90));

      final docRef = FirebaseFirestore.instance
          .collection('mpesa_callbacks')
          .doc(checkoutId);

      _callbackSub = docRef.snapshots().listen(
        (snap) async {
          if (!snap.exists) return; // still waiting
          await _callbackSub?.cancel();
          _callbackSub = null;

          final data = snap.data()!;
          final resultCode = data['resultCode'];
          final paid = resultCode == 0;

          if (!mounted) return;
          if (paid) {
            await widget.onSuccess?.call(data);
            if (!mounted) return;
            setState(() {
              _state = _PayState.success;
              _statusMsg = data['mpesaReceiptNumber'] != null
                  ? 'Receipt: ${data['mpesaReceiptNumber']}'
                  : 'Payment confirmed!';
            });
          } else {
            // Map common Safaricom result codes to friendly messages
            final msg = _friendlyError(resultCode, data['resultDesc']);
            if (!mounted) return;
            setState(() {
              _state = _PayState.failure;
              _errorMsg = msg;
            });
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _state = _PayState.failure;
            _errorMsg = 'Connection error. Please try again.';
          });
        },
      );

      // Wait for timeout; if sub is still active by then, it means no callback came
      await timeout;
      if (_callbackSub != null) {
        await _callbackSub?.cancel();
        _callbackSub = null;
        if (!mounted) return;
        setState(() {
          _state = _PayState.failure;
          _errorMsg = 'No response from M-Pesa (90s). Please try again.';
        });
      }
    } catch (e) {
      await _callbackSub?.cancel();
      _callbackSub = null;
      if (!mounted) return;
      setState(() {
        _state = _PayState.failure;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Cancel the pending STK push and go back to idle
  Future<void> _cancelWaiting() async {
    await _callbackSub?.cancel();
    _callbackSub = null;
    if (!mounted) return;
    setState(() {
      _state = _PayState.idle;
      _statusMsg = '';
      _errorMsg = '';
    });
  }

  void _retry() {
    _callbackSub?.cancel();
    _callbackSub = null;
    setState(() {
      _state = _PayState.idle;
      _errorMsg = '';
      _statusMsg = '';
    });
  }

  /// Maps Safaricom result codes to human-readable messages
  String _friendlyError(dynamic code, String? desc) {
    switch (code) {
      case 1032:
        return 'You cancelled the M-Pesa prompt. Tap "Try Again" to retry.';
      case 1037:
        return 'M-Pesa request timed out on your phone. Please try again.';
      case 1:
        return 'Insufficient M-Pesa balance. Please top up and try again.';
      case 2001:
        return 'Wrong M-Pesa PIN entered. Please try again.';
      default:
        return desc ?? 'Payment failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 8,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _buildBody(cs, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, bool isDark) {
    switch (_state) {
      case _PayState.idle:
        return _IdleView(
          key: const ValueKey('idle'),
          cs: cs,
          isDark: isDark,
          amount: widget.amount,
          title: widget.title,
          phoneCtrl: _phoneCtrl,
          phoneFocus: _phoneFocus,
          errorMsg: _errorMsg,
          onPay: _pay,
          onCancel: () => Navigator.of(context).pop(false),
        );
      case _PayState.waiting:
        return _WaitingView(
          key: const ValueKey('waiting'),
          cs: cs,
          isDark: isDark,
          amount: widget.amount,
          statusMsg: _statusMsg,
          pulseCtrl: _pulseCtrl,
          onCancel: _cancelWaiting,
        );
      case _PayState.success:
        return _ResultView(
          key: const ValueKey('success'),
          cs: cs,
          isDark: isDark,
          isSuccess: true,
          amount: widget.amount,
          subtitle: _statusMsg,
          onDone: () => Navigator.of(context).pop(true),
        );
      case _PayState.failure:
        return _ResultView(
          key: const ValueKey('failure'),
          cs: cs,
          isDark: isDark,
          isSuccess: false,
          amount: widget.amount,
          subtitle: _errorMsg,
          onDone: () => Navigator.of(context).pop(false),
          onRetry: _retry,
        );
    }
  }
}

// ── Idle (input) view ─────────────────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final int amount;
  final String title;
  final TextEditingController phoneCtrl;
  final FocusNode phoneFocus;
  final String errorMsg;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  const _IdleView({
    super.key,
    required this.cs,
    required this.isDark,
    required this.amount,
    required this.title,
    required this.phoneCtrl,
    required this.phoneFocus,
    required this.errorMsg,
    required this.onPay,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // M-Pesa logo row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00A651).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: Color(0xFF00A651), size: 26),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                Text('Lipa na M-Pesa',
                    style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF00A651),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Amount chip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00A651), Color(0xFF007A3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A651).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text('Amount Due',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                'KES ${_fmt(amount)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phone field
        AnimatedBuilder(
          animation: phoneFocus,
          builder: (_, __) {
            final focused = phoneFocus.hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: focused
                      ? const Color(0xFF00A651)
                      : cs.outlineVariant,
                  width: focused ? 2 : 1,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00A651).withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.phone_android_rounded,
                      color: Color(0xFF00A651), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      focusNode: phoneFocus,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d\+]'))
                      ],
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '07XX XXX XXX',
                        hintStyle: TextStyle(
                            color: cs.onSurface.withOpacity(0.3),
                            fontSize: 15),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        labelText: 'M-Pesa Number',
                        labelStyle: TextStyle(
                            color: focused
                                ? const Color(0xFF00A651)
                                : cs.onSurfaceVariant,
                            fontSize: 12),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            );
          },
        ),

        if (errorMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(errorMsg,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Pay button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A651), Color(0xFF007A3D)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A651).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 18),
              label: Text(
                'Pay KES ${_fmt(amount)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              onPressed: onPay,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        ),
      ],
    );
  }
}

// ── Waiting view ──────────────────────────────────────────────────────────────
class _WaitingView extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final int amount;
  final String statusMsg;
  final AnimationController pulseCtrl;
  final VoidCallback onCancel;

  const _WaitingView({
    super.key,
    required this.cs,
    required this.isDark,
    required this.amount,
    required this.statusMsg,
    required this.pulseCtrl,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing phone icon
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, child) => Transform.scale(
              scale: 0.92 + 0.08 * pulseCtrl.value,
              child: child,
            ),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A651).withOpacity(0.12),
                border: Border.all(
                    color: const Color(0xFF00A651).withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: Color(0xFF00A651), size: 44),
            ),
          ),
          const SizedBox(height: 24),
          Text('Waiting for Payment',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(statusMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.5)),
          const SizedBox(height: 20),
          _DotsIndicator(color: const Color(0xFF00A651)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00A651).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF00A651).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF00A651), size: 16),
                const SizedBox(width: 8),
                Text('KES ${_fmt(amount)} will be deducted',
                    style: const TextStyle(
                        color: Color(0xFF00A651),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onCancel,
            icon: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
            label: Text('Cancel',
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Result view ───────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final bool isSuccess;
  final int amount;
  final String subtitle;
  final VoidCallback onDone;
  final VoidCallback? onRetry;

  const _ResultView({
    super.key,
    required this.cs,
    required this.isDark,
    required this.isSuccess,
    required this.amount,
    required this.subtitle,
    required this.onDone,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF00A651) : Colors.red.shade600;
    final asset = isSuccess
        ? 'assets/images/common/success.json'
        : 'assets/images/common/error.json';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(asset,
              height: 110, width: 110, repeat: false, animate: true),
          const SizedBox(height: 12),
          Text(
            isSuccess ? 'Payment Successful!' : 'Payment Failed',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 8),
          if (isSuccess)
            Text('KES ${_fmt(amount)} paid',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onDone,
              child: Text(isSuccess ? 'Done' : 'Close',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
              child: Text('Try Again',
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated dots ─────────────────────────────────────────────────────────────
class _DotsIndicator extends StatefulWidget {
  final Color color;
  const _DotsIndicator({required this.color});

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (1 - (2 * t - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.4 + 0.6 * scale),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

String _fmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
