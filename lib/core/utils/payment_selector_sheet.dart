import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/mpesa_payment_sheet.dart';
import 'package:nrbgymkhana/features/Profile/data/models/payment_method.dart';
import 'package:nrbgymkhana/features/Profile/presentation/providers/payment_methods_provider.dart';

/// Shows a bottom sheet listing the user's saved payment methods (default first).
/// Taps through to the appropriate payment flow.
/// Returns `true` if payment succeeded, `false`/`null` otherwise.
Future<bool?> showPaymentSelectorSheet(
  BuildContext context,
  WidgetRef ref, {
  required int amount,
  required String accountRef,
  String description = 'Payment',
  String title = 'Payment',
  Future<void> Function(Map<String, dynamic> callbackData)? onSuccess,
}) async {
  final methods = ref.read(paymentMethodsProvider).valueOrNull ?? [];

  // No saved methods → fall back directly to M-Pesa sheet
  if (methods.isEmpty) {
    return showMpesaPaymentSheet(
      context,
      amount: amount,
      accountRef: accountRef,
      description: description,
      title: title,
      onSuccess: onSuccess,
    );
  }

  // Default method is first (provider orders by isDefault desc)
  final defaultMethod = methods.firstWhere(
    (m) => m.isDefault,
    orElse: () => methods.first,
  );

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSelectorSheet(
      methods: methods,
      defaultMethod: defaultMethod,
      amount: amount,
      accountRef: accountRef,
      description: description,
      title: title,
      onSuccess: onSuccess,
    ),
  );
}

class _PaymentSelectorSheet extends StatefulWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod defaultMethod;
  final int amount;
  final String accountRef;
  final String description;
  final String title;
  final Future<void> Function(Map<String, dynamic>)? onSuccess;

  const _PaymentSelectorSheet({
    required this.methods,
    required this.defaultMethod,
    required this.amount,
    required this.accountRef,
    required this.description,
    required this.title,
    this.onSuccess,
  });

  @override
  State<_PaymentSelectorSheet> createState() => _PaymentSelectorSheetState();
}

class _PaymentSelectorSheetState extends State<_PaymentSelectorSheet> {
  late PaymentMethod _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.defaultMethod;
  }

  Future<void> _proceed() async {
    if (_selected.type == 'mpesa') {
      // M-Pesa sheet uses useRootNavigator:true so it overlays the selector.
      // After it completes, pop the selector with the result.
      final result = await showMpesaPaymentSheet(
        context,
        amount: widget.amount,
        accountRef: widget.accountRef,
        description: widget.description,
        title: widget.title,
        onSuccess: widget.onSuccess,
      );
      if (context.mounted) Navigator.of(context).pop(result);
    } else if (_selected.type == 'airtel') {
      Navigator.of(context).pop(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Airtel Money payment coming soon.')),
        );
      }
    } else {
      Navigator.of(context).pop(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card payment coming soon.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1E33) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pay KES ${_fmt(widget.amount)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppKolors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a payment method',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : AppKolors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ...widget.methods.map((m) => _MethodTile(
                  method: m,
                  isSelected: _selected.id == m.id,
                  isDark: isDark,
                  onTap: () => setState(() => _selected = m),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKolors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Pay with ${_selected.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _cfgFor(method.type);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? cfg.color.withValues(alpha: 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cfg.color.withValues(alpha: 0.6) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(cfg.imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppKolors.textPrimary,
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cfg.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: cfg.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.identifier,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppKolors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? cfg.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? cfg.color : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cfg {
  final Color color;
  final String imagePath;
  const _Cfg(this.color, this.imagePath);
}

_Cfg _cfgFor(String type) {
  switch (type) {
    case 'mpesa':
      return const _Cfg(
          Color(0xFF00A651), 'assets/images/rechargescreen/MpesaLogo.png');
    case 'airtel':
      return const _Cfg(
          Color(0xFFE40000), 'assets/images/rechargescreen/airtelLogo.png');
    case 'card':
    default:
      return const _Cfg(
          AppKolors.primary, 'assets/images/rechargescreen/mastercardLogo.png');
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
