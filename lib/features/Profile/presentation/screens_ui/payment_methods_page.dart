import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Profile/data/models/payment_method.dart';
import 'package:nrbgymkhana/features/Profile/presentation/providers/payment_methods_provider.dart';

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroHeader(isDark: isDark)),
          SliverToBoxAdapter(
            child: methodsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (methods) => _MethodsList(
                methods: methods,
                isDark: isDark,
                ref: ref,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 70),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(context, ref),
          backgroundColor: AppKolors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add Method',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final bool isDark;
  const _HeroHeader({required this.isDark});

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
              color: Color(0x4D0693e3), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(top: -30, right: -20, child: _Bubble(100, 0.07)),
            Positioned(top: 20, right: 70, child: _Bubble(55, 0.05)),
            Positioned(bottom: 20, left: -20, child: _Bubble(70, 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Methods',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your saved payment options',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
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

// ── Methods List ──────────────────────────────────────────────────────────────
class _MethodsList extends StatelessWidget {
  final List<PaymentMethod> methods;
  final bool isDark;
  final WidgetRef ref;
  const _MethodsList(
      {required this.methods, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppKolors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment_rounded,
                  size: 48, color: AppKolors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'No payment methods yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppKolors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Method" to save your first\npayment option',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : AppKolors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'SAVED METHODS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? Colors.white38 : AppKolors.textSecondary,
              ),
            ),
          ),
          ...methods.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MethodCard(
                  method: m,
                  isDark: isDark,
                  onSetDefault: () => setDefaultPaymentMethod(m.id),
                  onDelete: () => _confirmDelete(context, m),
                ),
              )),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PaymentMethod m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Method',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove ${m.label} (${m.identifier})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppKolors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deletePaymentMethod(m.id);
            },
            child: const Text('Remove',
                style: TextStyle(
                    color: Color(0xFFef4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Method Card ───────────────────────────────────────────────────────────────
class _MethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isDark;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _MethodCard({
    required this.method,
    required this.isDark,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _methodConfig(method.type);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: method.isDefault
            ? Border.all(color: cfg.color.withValues(alpha: 0.5), width: 1.5)
            : Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: method.isDefault
                ? cfg.color.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(cfg.imagePath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppKolors.textPrimary,
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cfg.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cfg.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.identifier,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : AppKolors.textSecondary,
                      letterSpacing: method.type == 'card' ? 1.5 : 0,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: isDark ? Colors.white38 : Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'default') onSetDefault();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(children: [
                      Icon(Icons.star_rounded,
                          size: 18, color: AppKolors.primary),
                      SizedBox(width: 10),
                      Text('Set as Default'),
                    ]),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: Color(0xFFef4444)),
                    SizedBox(width: 10),
                    Text('Remove',
                        style: TextStyle(color: Color(0xFFef4444))),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Method Bottom Sheet ───────────────────────────────────────────────────
void _showAddSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddMethodSheet(ref: ref),
  );
}

class _AddMethodSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddMethodSheet({required this.ref});

  @override
  ConsumerState<_AddMethodSheet> createState() => _AddMethodSheetState();
}

class _AddMethodSheetState extends ConsumerState<_AddMethodSheet> {
  String _selectedType = 'mpesa';
  final _controller = TextEditingController();
  bool _setAsDefault = false;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  static const _types = [
    {'type': 'mpesa', 'label': 'M-Pesa'},
    {'type': 'airtel', 'label': 'Airtel Money'},
    {'type': 'card', 'label': 'Debit / Credit Card'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _inputLabel {
    if (_selectedType == 'card') return 'Card Number';
    return 'Phone Number';
  }

  String get _inputHint {
    if (_selectedType == 'card') return '1234 5678 9012 3456';
    return '07XX XXX XXX';
  }

  TextInputType get _keyboardType {
    return TextInputType.number;
  }

  List<TextInputFormatter> get _formatters {
    if (_selectedType == 'card') return [_CardNumberFormatter()];
    return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)];
  }

  String _maskIdentifier(String raw) {
    if (_selectedType == 'card') {
      final digits = raw.replaceAll(' ', '');
      if (digits.length >= 4) {
        return '**** **** **** ${digits.substring(digits.length - 4)}';
      }
      return raw;
    }
    // phone — show last 4 digits
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 4) {
      return '${clean.substring(0, clean.length - 4).replaceAll(RegExp(r'\d'), '*')}${clean.substring(clean.length - 4)}';
    }
    return raw;
  }

  String _labelFor(String type) =>
      _types.firstWhere((t) => t['type'] == type)['label']!;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final methods = ref.read(paymentMethodsProvider).valueOrNull ?? [];
      final isFirst = methods.isEmpty;
      await addPaymentMethod(PaymentMethod(
        id: '',
        type: _selectedType,
        label: _labelFor(_selectedType),
        identifier: _maskIdentifier(_controller.text),
        isDefault: isFirst || _setAsDefault,
      ));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cfg = _methodConfig(_selectedType);

    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1E33) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white24
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppKolors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Type selector
              Row(
                children: _types.map((t) {
                  final selected = _selectedType == t['type'];
                  final tCfg = _methodConfig(t['type']!);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = t['type']!;
                          _controller.clear();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? tCfg.color.withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? tCfg.color.withValues(alpha: 0.5)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.grey.shade200),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              tCfg.imagePath,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t['label']!.split(' ').first,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? tCfg.color
                                    : (isDark
                                        ? Colors.white54
                                        : AppKolors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Input field
              Text(
                _inputLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppKolors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                keyboardType: _keyboardType,
                inputFormatters: _formatters,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppKolors.textPrimary,
                  letterSpacing: _selectedType == 'card' ? 2 : 0,
                ),
                decoration: InputDecoration(
                  hintText: _inputHint,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      cfg.imagePath,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: cfg.color, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFef4444)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFef4444), width: 1.5),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a ${_inputLabel.toLowerCase()}';
                  }
                  if (_selectedType != 'card') {
                    final digits = v.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 9) return 'Enter a valid phone number';
                  } else {
                    final digits = v.replaceAll(' ', '');
                    if (digits.length < 13) return 'Enter a valid card number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Set as default toggle
              GestureDetector(
                onTap: () => setState(() => _setAsDefault = !_setAsDefault),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _setAsDefault
                            ? AppKolors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _setAsDefault
                              ? AppKolors.primary
                              : (isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400),
                          width: 1.5,
                        ),
                      ),
                      child: _setAsDefault
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Set as default payment method',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : AppKolors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKolors.primary,
                    disabledBackgroundColor:
                        AppKolors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Method',
                          style: TextStyle(
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
      ),
    );
  }
}

// ── Card Number Formatter ─────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(' ', '');
    if (digits.length > 16) return old;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

// ── Method Config ─────────────────────────────────────────────────────────────
class _MethodCfg {
  final Color color;
  final String imagePath;
  const _MethodCfg(this.color, this.imagePath);
}

_MethodCfg _methodConfig(String type) {
  switch (type) {
    case 'mpesa':
      return const _MethodCfg(
          Color(0xFF00A651), 'assets/images/rechargescreen/MpesaLogo.png');
    case 'airtel':
      return const _MethodCfg(
          Color(0xFFE40000), 'assets/images/rechargescreen/airtelLogo.png');
    case 'card':
    default:
      return const _MethodCfg(
          AppKolors.primary, 'assets/images/rechargescreen/mastercardLogo.png');
  }
}
