import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class BookingDetailsPage extends StatefulWidget {
  final String requestNumber;
  final String facilityName;
  final String date;
  final String timeSlot;
  final String numberOfPeople;
  final String? imageUrl;
  final String? status;
  final String? courtNo;
  final VoidCallback? onCancel;
  final VoidCallback? onRebook;
  final VoidCallback? onPayNow;

  const BookingDetailsPage({
    super.key,
    required this.requestNumber,
    required this.facilityName,
    required this.date,
    required this.timeSlot,
    required this.numberOfPeople,
    required this.imageUrl,
    this.status,
    this.courtNo,
    this.onCancel,
    this.onRebook,
    this.onPayNow,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _showQr = false;

  // ── Derived helpers ──────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (widget.status) {
      case 'Confirmed':
        return const Color(0xFF22C55E);
      case 'Cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case 'Confirmed':
        return 'Confirmed';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case 'Confirmed':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  // ── Share ────────────────────────────────────────────────────────────────────
  Future<void> _share() async {
    final bytes = await _screenshotController.capture(pixelRatio: 2.0);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/booking_${widget.requestNumber}.png').create();
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📅 My booking at ${widget.facilityName} on ${widget.date}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: CustomScrollView(
          slivers: [
            // ── Step 1: Hero SliverAppBar ──────────────────────────────────────
            _buildHeroAppBar(context),

            // ── Steps 3–5 will be added here ──────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  _buildQrSection(),
                  const SizedBox(height: 200), // placeholder — will be replaced
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero SliverAppBar ────────────────────────────────────────────────────────
  SliverAppBar _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: AppKolors.dark,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
              onPressed: _share,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.facilityName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.courtNo != null) ...[
              const SizedBox(height: 2),
              Text(
                'Court ${widget.courtNo}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.imageUrl ??
                  'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppKolors.dark),
            ),
            // Gradient overlay for readability
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            // Status badge top-right
            Positioned(
              top: 60,
              right: 16,
              child: _StatusBadge(
                label: _statusLabel,
                color: _statusColor,
                icon: _statusIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── QR / Confirmation Code Section ───────────────────────────────────────────────────────────────
  Widget _buildQrSection() {
    // Encode key booking info into the QR payload
    final qrData =
        'BOOKING:${widget.requestNumber}|FACILITY:${widget.facilityName}|DATE:${widget.date}|TIME:${widget.timeSlot}|ATTENDEES:${widget.numberOfPeople}|STATUS:${widget.status ?? 'Pending'}';

    // Short human-readable confirmation code (first 8 chars uppercased)
    final confirmCode = widget.requestNumber.length >= 8
        ? widget.requestNumber.substring(0, 8).toUpperCase()
        : widget.requestNumber.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppKolors.dark.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header with toggle ───────────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppKolors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: AppKolors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Confirmation Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppKolors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                // Toggle pill: Code | QR
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppKolors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToggleTab(
                        label: 'Code',
                        selected: !_showQr,
                        onTap: () => setState(() => _showQr = false),
                      ),
                      _ToggleTab(
                        label: 'QR',
                        selected: _showQr,
                        onTap: () => setState(() => _showQr = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppKolors.border.withValues(alpha: 0.6)),

          // ── Content area ───────────────────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _showQr
                ? _buildQrView(qrData)
                : _buildCodeView(confirmCode),
          ),

          const SizedBox(height: 20),

          // ── Footer note ───────────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: AppKolors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Present this code or QR at the facility for entry verification.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppKolors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(String data) {
    return Padding(
      key: const ValueKey('qr'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppKolors.border),
            boxShadow: [
              BoxShadow(
                color: AppKolors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: 180,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppKolors.dark,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppKolors.dark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeView(String code) {
    return Padding(
      key: const ValueKey('code'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        children: [
          // Dashed code display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppKolors.primary.withValues(alpha: 0.06),
                  AppKolors.accent.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppKolors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _formatCode(code),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppKolors.dark,
                    letterSpacing: 8,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirmation Code',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppKolors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Copy button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Confirmation code copied!'),
                    backgroundColor: AppKolors.accent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppKolors.primary,
                side: BorderSide(
                    color: AppKolors.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Inserts a space every 4 chars for readability e.g. ABCD EF12
  String _formatCode(String code) {
    final clean = code.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  // ── Details Card ───────────────────────────────────────────────────────────────────
  Widget _buildDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppKolors.dark.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ───────────────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppKolors.dark, AppKolors.darkCard],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Booking Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                // Booking ID chip — tap to copy
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.requestNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Booking ID copied!'),
                        backgroundColor: AppKolors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppKolors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppKolors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#${widget.requestNumber.length > 8 ? widget.requestNumber.substring(0, 8) : widget.requestNumber}',
                          style: const TextStyle(
                            color: AppKolors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded,
                            color: AppKolors.accent, size: 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Detail rows ───────────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.stadium_rounded,
                  iconColor: AppKolors.primary,
                  label: 'Facility',
                  value: widget.courtNo != null
                      ? '${widget.facilityName} • Court ${widget.courtNo}'
                      : widget.facilityName,
                ),
                _divider(),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  label: 'Date',
                  value: widget.date,
                ),
                _divider(),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  label: 'Time Slot',
                  value: widget.timeSlot,
                ),
                _divider(),
                _DetailRow(
                  icon: Icons.people_alt_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: 'Attendees',
                  value: widget.numberOfPeople,
                ),
                _divider(),
                _DetailRow(
                  icon: _statusIcon,
                  iconColor: _statusColor,
                  label: 'Status',
                  value: _statusLabel,
                  valueColor: _statusColor,
                  valueBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Divider(
            height: 1,
            thickness: 1,
            color: AppKolors.border.withValues(alpha: 0.6)),
      );

  // ── Status Banner (below hero) ───────────────────────────────────────────────
  Widget _buildStatusBanner() {
    if (widget.status == 'Confirmed') return const SizedBox.shrink();
    final isCancel = widget.status == 'Cancelled';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon, color: _statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCancel
                  ? 'This booking has been cancelled.'
                  : 'Your booking is pending confirmation. For assistance call 0708042394.',
              style: TextStyle(
                fontSize: 13,
                color: _statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Status Badge ────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
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
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppKolors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        valueBold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? AppKolors.textPrimary,
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

// ── Toggle Tab (Code | QR pill) ──────────────────────────────────────────────
class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppKolors.dark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppKolors.dark.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppKolors.textSecondary,
          ),
        ),
      ),
    );
  }
}
