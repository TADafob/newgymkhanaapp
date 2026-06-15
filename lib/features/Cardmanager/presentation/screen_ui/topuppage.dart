import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/mpesa_payment_sheet.dart';
import 'package:nrbgymkhana/features/Profile/data/models/payment_method.dart';
import 'package:nrbgymkhana/features/Profile/presentation/providers/payment_methods_provider.dart';

Future<void> showTopUpDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: const _TopUpDialog(),
    ),
  );
}

enum _Step { amount, confirm, methodPicker }

class _TopUpDialog extends ConsumerStatefulWidget {
  const _TopUpDialog();
  @override
  ConsumerState<_TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends ConsumerState<_TopUpDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  int _amount = 0;
  _Step _step = _Step.amount;
  // which step to return to from method picker
  _Step _pickerReturnStep = _Step.amount;
  PaymentMethod? _selectedMethod;

  static const _chips = [500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _amount = int.tryParse(_ctrl.text) ?? 0));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  PaymentMethod? _resolveMethod(List<PaymentMethod> methods) =>
      _selectedMethod ??
      (methods.isEmpty
          ? null
          : methods.firstWhere((m) => m.isDefault, orElse: () => methods.first));

  void _openMethodPicker(_Step returnTo) =>
      setState(() { _pickerReturnStep = returnTo; _step = _Step.methodPicker; });

  Future<void> _pay(PaymentMethod? method) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Navigator.of(context).pop(); // close dialog; mpesa sheet overlays on root

    await showMpesaPaymentSheet(
      context,
      amount: _amount,
      accountRef: 'WalletTopUp',
      description: 'Wallet Top Up',
      title: 'Top Up Wallet',
      initialPhone: method?.identifier,
      onSuccess: (data) async {
        if (uid == null) return;
        final receiptNo = data['mpesaReceiptNumber'] as String? ?? '';
        final batch = FirebaseFirestore.instance.batch();
        final cardRef = FirebaseFirestore.instance
            .collection('users_members')
            .doc(uid)
            .collection('card_transactions')
            .doc();
        batch.set(cardRef, {
          'trans_Type': 'Top Up',
          'trans_Amount': _amount,
          'trans_Descr': 'Wallet Top Up',
          'trans_Id': receiptNo,
          'trans_Date': Timestamp.now(),
        });
        batch.update(
          FirebaseFirestore.instance.collection('users_members').doc(uid),
          {'wallet_Balance': FieldValue.increment(_amount)},
        );
        await batch.commit();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppKolors.darkSurface : Colors.white;
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? [];
    final method = _resolveMethod(methods);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, 12))],
        ),
        // clip so AnimatedSwitcher children don't overflow rounded corners
        clipBehavior: Clip.hardEdge,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) {
            final offset = (child.key == ValueKey(_Step.amount))
                ? const Offset(-1, 0)
                : const Offset(1, 0);
            return SlideTransition(
              position: Tween(begin: offset, end: Offset.zero).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: switch (_step) {
            _Step.amount => _AmountStep(
                key: const ValueKey(_Step.amount),
                ctrl: _ctrl,
                focus: _focus,
                amount: _amount,
                chips: _chips,
                method: method,
                isDark: isDark,
                onChip: (v) { _ctrl.text = v.toString(); setState(() => _amount = v); },
                onNext: () => setState(() => _step = _Step.confirm),
                onChangeMethod: () => _openMethodPicker(_Step.amount),
                onClose: () => Navigator.of(context).pop(),
              ),
            _Step.confirm => _ConfirmStep(
                key: const ValueKey(_Step.confirm),
                amount: _amount,
                method: method,
                isDark: isDark,
                onBack: () => setState(() => _step = _Step.amount),
                onChangeMethod: () => _openMethodPicker(_Step.confirm),
                onPay: () => _pay(method),
                onClose: () => Navigator.of(context).pop(),
              ),
            _Step.methodPicker => _MethodPickerStep(
                key: const ValueKey(_Step.methodPicker),
                methods: methods,
                selected: method,
                isDark: isDark,
                onSelect: (m) => setState(() {
                  _selectedMethod = m;
                  _step = _pickerReturnStep;
                }),
                onBack: () => setState(() => _step = _pickerReturnStep),
              ),
          },
        ),
      ),
    );
  }
}

// ── Step 1: Amount entry ──────────────────────────────────────────────────────

class _AmountStep extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final int amount;
  final List<int> chips;
  final PaymentMethod? method;
  final bool isDark;
  final ValueChanged<int> onChip;
  final VoidCallback onNext;
  final VoidCallback onChangeMethod;
  final VoidCallback onClose;

  const _AmountStep({
    super.key,
    required this.ctrl,
    required this.focus,
    required this.amount,
    required this.chips,
    required this.method,
    required this.isDark,
    required this.onChip,
    required this.onNext,
    required this.onChangeMethod,
    required this.onClose,
  });

  bool get _valid => amount >= 100;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.white38 : AppKolors.textSecondary;
    final subtle = isDark ? Colors.white10 : Colors.grey.shade100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(
            children: [
              Text('Top Up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppKolors.textPrimary,
                  )),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, size: 20, color: muted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Big centered amount
        GestureDetector(
          onTap: () => focus.requestFocus(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
            child: Column(
              children: [
                Text('KES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppKolors.primary,
                    )),
                const SizedBox(height: 2),
                // Invisible TextField drives input; Text widget shows the value
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 0,
                      child: TextField(
                        controller: ctrl,
                        focusNode: focus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 0, color: Colors.transparent),
                        decoration: const InputDecoration(border: InputBorder.none),
                        cursorColor: Colors.transparent,
                        cursorWidth: 0,
                      ),
                    ),
                    Text(
                      amount == 0 ? '0' : _fmt(amount),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: _valid
                            ? (isDark ? Colors.white : AppKolors.textPrimary)
                            : (amount > 0
                                ? Colors.red.shade400
                                : (isDark ? Colors.white12 : Colors.grey.shade300)),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: amount > 0 && amount < 100
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Minimum KES 100',
                              style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // Quick chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: chips.map((v) {
              final sel = amount == v;
              return GestureDetector(
                onTap: () => onChip(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppKolors.primary : subtle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    v >= 1000 ? '${v ~/ 1000}K' : '$v',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : muted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),

        // Payment method row + Next button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _MethodIcon(type: method?.type ?? 'mpesa'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method?.label ?? 'M-Pesa',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppKolors.textPrimary,
                        )),
                    Text(method?.identifier ?? 'Default',
                        style: TextStyle(fontSize: 11, color: muted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onChangeMethod,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppKolors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Change',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppKolors.primary,
                      )),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _valid ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKolors.primary,
                  disabledBackgroundColor: AppKolors.primary.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Next',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Confirmation summary ──────────────────────────────────────────────

class _ConfirmStep extends StatelessWidget {
  final int amount;
  final PaymentMethod? method;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onChangeMethod;
  final VoidCallback onPay;
  final VoidCallback onClose;

  const _ConfirmStep({
    super.key,
    required this.amount,
    required this.method,
    required this.isDark,
    required this.onBack,
    required this.onChangeMethod,
    required this.onPay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.white38 : AppKolors.textSecondary;
    final surface = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with back
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: muted),
              ),
              const SizedBox(width: 8),
              Text('Confirm Top Up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppKolors.textPrimary,
                  )),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, size: 20, color: muted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppKolors.primary, AppKolors.darkCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('You are topping up',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 6),
                Text('KES ${_fmt(amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary rows
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'To',
                  value: 'NRB Gymkhana Wallet',
                  isDark: isDark,
                  showDivider: true,
                ),
                _SummaryRow(
                  label: 'Via',
                  isDark: isDark,
                  showDivider: false,
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MethodIcon(type: method?.type ?? 'mpesa', size: 22),
                      const SizedBox(width: 6),
                      Text(
                        '${method?.label ?? 'M-Pesa'} · ${method?.identifier ?? ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppKolors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onChangeMethod,
                        child: Text('Change',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppKolors.primary,
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKolors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Pay KES ${_fmt(amount)}',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isDark;
  final bool showDivider;

  const _SummaryRow({
    required this.label,
    required this.isDark,
    required this.showDivider,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.white38 : AppKolors.textSecondary;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: muted)),
              const Spacer(),
              if (valueWidget != null) valueWidget!,
              if (value != null)
                Text(value!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppKolors.textPrimary,
                    )),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 16, endIndent: 16,
              color: isDark ? Colors.white10 : Colors.grey.shade200),
      ],
    );
  }
}

// ── Step 3: Inline method picker ──────────────────────────────────────────────

class _MethodPickerStep extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod? selected;
  final bool isDark;
  final ValueChanged<PaymentMethod> onSelect;
  final VoidCallback onBack;

  const _MethodPickerStep({
    super.key,
    required this.methods,
    required this.selected,
    required this.isDark,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.white38 : AppKolors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: muted),
              ),
              const SizedBox(width: 8),
              Text('Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppKolors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          if (methods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No saved methods found.',
                    style: TextStyle(fontSize: 13, color: muted)),
              ),
            )
          else
            ...methods.map((m) {
              final isSelected = selected?.id == m.id;
              final cfg = _cfgFor(m.type);
              return GestureDetector(
                onTap: () => onSelect(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cfg.color.withOpacity(0.08)
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? cfg.color.withOpacity(0.5) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: cfg.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(cfg.imagePath, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(m.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppKolors.textPrimary,
                                    )),
                                if (m.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cfg.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Default',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: cfg.color,
                                        )),
                                  ),
                                ],
                              ],
                            ),
                            Text(m.identifier,
                                style: TextStyle(fontSize: 11, color: muted)),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? cfg.color : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? cfg.color : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Shared widgets & helpers ──────────────────────────────────────────────────

class _MethodIcon extends StatelessWidget {
  final String type;
  final double size;
  const _MethodIcon({required this.type, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final cfg = _cfgFor(type);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.17),
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Image.asset(cfg.imagePath, fit: BoxFit.contain),
    );
  }
}

class _Cfg {
  final Color color;
  final String imagePath;
  const _Cfg(this.color, this.imagePath);
}

_Cfg _cfgFor(String type) => switch (type) {
      'mpesa' => const _Cfg(Color(0xFF00A651), 'assets/images/rechargescreen/MpesaLogo.png'),
      'airtel' => const _Cfg(Color(0xFFE40000), 'assets/images/rechargescreen/airtelLogo.png'),
      _ => const _Cfg(AppKolors.primary, 'assets/images/rechargescreen/mastercardLogo.png'),
    };

String _fmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
