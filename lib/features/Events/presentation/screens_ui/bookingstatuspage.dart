import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/mpesa_service.dart';
import 'package:nrbgymkhana/features/Events/presentation/providers/ticketnotifier.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BookingConfirmationDialog extends ConsumerWidget {
  final DocumentSnapshot event;
  final bool isFree;
  final int basePrice;

  const BookingConfirmationDialog({
    super.key,
    required this.event,
    required this.isFree,
    required this.basePrice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quantities = ref.watch(ticketQuantitiesProvider);
    final ticketCategories = event.data() is Map<String, dynamic>
        ? (event.data() as Map<String, dynamic>)['ticketCategories']
                as List<dynamic>? ??
            []
        : [];

    final total = calculateTotal(
      ticketCategories: ticketCategories.cast<Map<String, dynamic>>(),
      quantities: quantities,
      basePrice: basePrice,
      isFree: isFree,
    );

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 5.h,
              margin: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isFree)
                  Chip(
                    side: BorderSide.none,
                    label: const Text('FREE'),
                    backgroundColor: Colors.green,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            SizedBox(height: 20.h),

            // Ticket Quantities
            if (ticketCategories.isNotEmpty)
              _buildTicketSummary(ticketCategories.cast<Map<String, dynamic>>(),
                  quantities, theme)
            else
              _buildDefaultTicketSummary(quantities, basePrice, theme),

            SizedBox(height: 20.h),

            // Total
            _buildTotalSummary(total, theme, isFree),

            SizedBox(height: 30.h),

            // Action Buttons
            _buildActionButtons(
              context: context,
              ref: ref,
              total: total,
              isFree: isFree,
              eventId: event.id,
              onSuccess: () =>
                  _showSuccessAnimation(context, ref, event.id, event.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSummary(List<Map<String, dynamic>> ticketCategories,
      Map<String, int> quantities, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Tickets',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        ...ticketCategories.map((category) {
          final name = category['name'] as String?;
          final price = category['price'] as int?;
          final quantity = quantities[name ?? ''] ?? 0;

          if (quantity <= 0) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$name × $quantity',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'KSH ${price! * quantity}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDefaultTicketSummary(
      Map<String, int> quantities, int basePrice, ThemeData theme) {
    final quantity = quantities['default'] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'General Admission × $quantity',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'KSH ${basePrice * quantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalSummary(int total, ThemeData theme, bool isFree) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            isFree ? 'FREE' : 'KSH $total',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isFree ? Colors.green : AppKolors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required WidgetRef ref,
    required int total,
    required bool isFree,
    required VoidCallback onSuccess,
    required String eventId,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide.none,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () => isFree
                ? _handleBooking(
                    context,
                    ref,
                    isFree,
                    () => _showSuccessAnimation(context, ref, event.id, event.id),
                  )
                : _handlePaidBooking(
                    context,
                    ref,
                    total,
                    () => _showSuccessAnimation(context, ref, event.id, event.id),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isFree ? Colors.green : Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(isFree ? 'Confirm Booking' : 'Proceed to Payment',
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // For paid events: collect M-Pesa payment first, then confirm booking
  Future<void> _handlePaidBooking(
    BuildContext context,
    WidgetRef ref,
    int total,
    VoidCallback onSuccess,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users_members')
        .doc(currentUser.uid)
        .get();
    final userPhone = (userDoc.data()?['phone_Number'] ?? '').toString();
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventMpesaSheet(
        initialPhone: userPhone,
        amount: total,
        onPaymentConfirmed: (checkoutId) => _handleBooking(
          context,
          ref,
          false,
          onSuccess,
          checkoutId: checkoutId,
        ),
      ),
    );
  }

  Future<void> _handleBooking(
    BuildContext context,
    WidgetRef ref,
    bool isFree,
    VoidCallback onSuccess, {
    String? checkoutId,
  }) async {
    late BuildContext dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const BookingProcessingDialog();
      },
    );

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final nowStamp = Timestamp.now();
      // Deterministic ID prevents duplicate bookings from double-taps
      final bookingDocRef = FirebaseFirestore.instance
          .collection('events_collection')
          .doc(event.id)
          .collection('bookings')
          .doc(userId);

      final eventDocRef = FirebaseFirestore.instance
          .collection('events_collection')
          .doc(event.id);

      final quantities = ref.read(ticketQuantitiesProvider);
      int newTicketsCount = quantities.values.fold(0, (sum, q) => sum + q);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final freshEventSnapshot = await transaction.get(eventDocRef);
        final bookingSnapshot = await transaction.get(bookingDocRef);
        if (bookingSnapshot.exists) {
          throw Exception('You have already booked this event.');
        }

        final eventData = freshEventSnapshot.data() ?? {};

        final currentTicketsSold = (eventData['ticketsSold'] ?? 0) as int;
        final ticketsTarget = (eventData['target_No'] ?? 0) as int;

        if (currentTicketsSold + newTicketsCount > ticketsTarget) {
          throw Exception('Booking exceeds available tickets.');
        }

        final bookingData = {
          'booked_By': userId,
          'booking_Date': nowStamp,
          'status': isFree ? 'Confirmed' : 'Confirmed',
          'total_Amount': isFree
              ? 0
              : calculateTotal(
                  ticketCategories: (eventData['ticketCategories']
                          ?.cast<Map<String, dynamic>>() ??
                      []),
                  quantities: quantities,
                  basePrice: basePrice,
                  isFree: isFree,
                ),
          'is_Free': isFree,
          'tickets': quantities,
          'booking_Id': bookingDocRef.id,
          if (checkoutId != null) 'payment_Id': checkoutId,
        };

        transaction.set(bookingDocRef, bookingData);
        transaction.update(eventDocRef, {
          'ticketsSold': currentTicketsSold + newTicketsCount,
        });
      });

      final bookingId = bookingDocRef.id; // ✅ Capture booking ID
      Navigator.of(dialogContext).pop();
      onSuccess();

      // Navigate directly after success
      _showSuccessAnimation(context, ref, event.id, bookingId);
    } catch (e) {
      Navigator.of(dialogContext).pop();
      final msg = e.toString().replaceAll('Exception: ', '');
      _showErrorDialog(context, msg);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: Navigator.of(context).pop, child: const Text("OK")),
        ],
      ),
    );
  }

  void _showSuccessAnimation(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    String bookingId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SuccessAnimation(
        onDismiss: () {
          Navigator.pop(ctx);
          ref.read(ticketQuantitiesProvider.notifier).resetAll();
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
        eventId: eventId,
        bookingId: bookingId,
      ),
    );
  }
}

// Booking processing dialog
class BookingProcessingDialog extends StatelessWidget {
  const BookingProcessingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Processing your booking..."),
          ],
        ),
      ),
    );
  }
}

// Success animation
class SuccessAnimation extends StatefulWidget {
  final VoidCallback onDismiss;
  final String eventId;
  final String bookingId;

  const SuccessAnimation({
    super.key,
    required this.onDismiss,
    required this.eventId,
    required this.bookingId,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 300.w,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Lottie.asset(
                  'assets/images/common/success.json',
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Booking Confirmed!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your email for confirmation details and tickets information',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.goNamed(
                        'Ticket',
                        pathParameters: {
                          'eventId': widget.eventId,
                          'orderId': widget.bookingId,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      padding:
                          EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      'View Tickets',
                      style: TextStyle(color: AppKolors.background),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      padding:
                          EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(color: AppKolors.background),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// M-Pesa payment sheet for paid events
class _EventMpesaSheet extends StatefulWidget {
  final String initialPhone;
  final int amount;
  final void Function(String checkoutId) onPaymentConfirmed;

  const _EventMpesaSheet({
    required this.initialPhone,
    required this.amount,
    required this.onPaymentConfirmed,
  });

  @override
  State<_EventMpesaSheet> createState() => _EventMpesaSheetState();
}

class _EventMpesaSheetState extends State<_EventMpesaSheet> {
  late final TextEditingController _phoneCtrl;
  bool _loading = false;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter your M-Pesa number.');
      return;
    }
    setState(() {
      _loading = true;
      _statusMsg = 'Sending M-Pesa prompt...';
    });
    try {
      final stkResult = await MpesaService.stkPush(
        phone: phone,
        amount: widget.amount,
        accountRef: 'EventTicket',
        description: 'Event Ticket Payment',
      );
      final checkoutId = stkResult['CheckoutRequestID'] as String?;
      if (checkoutId == null) throw Exception('No CheckoutRequestID returned.');

      setState(() => _statusMsg = 'Prompt sent! Enter your M-Pesa PIN...');

      final callbackDoc = FirebaseFirestore.instance
          .collection('mpesa_callbacks')
          .doc(checkoutId);

      await for (final snap in callbackDoc.snapshots().timeout(
            const Duration(seconds: 90),
            onTimeout: (sink) => sink.close(),
          )) {
        if (!snap.exists) continue;
        final resultCode = snap.data()?['resultCode'];
        if (!mounted) return;
        if (resultCode == 0) {
          Navigator.of(context).pop();
          widget.onPaymentConfirmed(checkoutId);
        } else {
          setState(() { _loading = false; _statusMsg = ''; });
          Fluttertoast.showToast(
            msg: snap.data()?['resultDesc'] ?? 'Payment cancelled.',
            backgroundColor: Colors.red,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() { _loading = false; _statusMsg = ''; });
      Fluttertoast.showToast(
        msg: 'Payment timed out. Please try again.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _statusMsg = ''; });
      Fluttertoast.showToast(
        msg: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Pay KSH ${widget.amount}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'M-Pesa Number',
              hintText: '07XXXXXXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_android_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)),
                        const SizedBox(width: 12),
                        Text(_statusMsg,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ],
                    )
                  : const Text('Pay Now',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper: Calculate total
int calculateTotal({
  required List<Map<String, dynamic>> ticketCategories,
  required Map<String, int> quantities,
  required int basePrice,
  required bool isFree,
}) {
  if (isFree) return 0;

  if (ticketCategories.isNotEmpty) {
    return ticketCategories.fold<int>(0, (sum, category) {
      final name = category['name'] as String?;
      final price = category['price'] as int?;
      final quantity = quantities[name ?? ''] ?? 0;
      return sum + (price ?? 0) * quantity;
    });
  } else {
    final quantity = quantities['default'] ?? 1;
    return basePrice * quantity;
  }
}

// Helper: Format date
String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('dd MMMM yyyy');
  return formatter.format(date);
}
