import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/clubbooking.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/sports_booking_page.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/session_booking_page.dart';

import 'package:nrbgymkhana/features/bookings/presentation/widgets/sheetexitmessage.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/banda_booking_page.dart';

class BookingsCatPage extends ConsumerStatefulWidget {
  final String category;
  const BookingsCatPage({super.key, required this.category});

  @override
  ConsumerState<BookingsCatPage> createState() => _BookingsCatPageState();
}

class _BookingsCatPageState extends ConsumerState<BookingsCatPage> {
  bool _isGridView = false;

  bool get _isClub => widget.category == 'Clubs';
  bool get _isBanda => widget.category == 'Bandas';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppKolors.background,
      child: Column(
        children: [
          _HeroHeader(isClub: _isClub, isBanda: _isBanda),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Facilities')
                  .where('facility_Type',
                      isEqualTo:
                          _isBanda ? 'Bandas' : (_isClub ? 'Club' : 'Sports'))
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final facilitiesData = snapshot.data?.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'title': data['facility_Name'],
                        'facility_Id': data['facility_Id'] ?? doc.id,
                        'docid': doc.id,
                        'courts': data['courts'],
                        'images': (data['images'] as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .where((url) =>
                                    url.isNotEmpty &&
                                    Uri.tryParse(url)?.hasAbsolutePath == true)
                                .toList() ??
                            [],
                        'imageurl': data['image'] != null &&
                                Uri.tryParse(data['image'])?.hasAbsolutePath ==
                                    true
                            ? data['image']
                            : '',
                        'isActive': data['isActive'],
                        'booking_Mode': data['booking_Mode'] ?? 'slot',
                      };
                    }).toList() ??
                    [];

                return responsiveLayout(
                  smallScreen: _buildContent(context, facilitiesData),
                  mediumScreen: Center(
                    child: SizedBox(
                      width: 400,
                      child: _buildContent(context, facilitiesData),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, List<Map<String, dynamic>> facilitiesData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Text(
                'Select a Facility',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppKolors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppKolors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${facilitiesData.length} available',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppKolors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ── View toggle ──
              GestureDetector(
                onTap: () => setState(() => _isGridView = !_isGridView),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppKolors.dark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppKolors.dark.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    size: 18,
                    color: AppKolors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Animated view switch ──
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isGridView
                  ? _buildGrid(facilitiesData)
                  : _buildList(facilitiesData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> facilitiesData) {
    return GridView.builder(
      key: const ValueKey('grid'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: facilitiesData.length,
      itemBuilder: (context, index) {
        final facility = facilitiesData[index];
        final bool isActive = facility['isActive'] == true;
        return _FacilityCard(
          facility: facility,
          isActive: isActive,
          isClub: _isClub,
          onTap: () => _handleTap(facility, isActive),
        );
      },
    );
  }

  Widget _buildList(List<Map<String, dynamic>> facilitiesData) {
    return ListView.separated(
      key: const ValueKey('list'),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: facilitiesData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final facility = facilitiesData[index];
        final bool isActive = facility['isActive'] == true;
        return _FacilityListTile(
          facility: facility,
          isActive: isActive,
          isClub: _isClub,
          onTap: () => _handleTap(facility, isActive),
        );
      },
    );
  }

  void _handleTap(Map<String, dynamic> facility, bool isActive) {
    if (!isActive) return;
    ref.read(selectedFacilityProvider.notifier).state =
        facility['facility_Id'] ?? '';
    final image = facility['imageurl'] ?? '';
    final images = facility['images'] ?? [];
    final facilityTitle = facility['title'] ?? '';

    if (_isBanda) {
      showBandaBookingBottomSheet(context, ref, facilityTitle, image);
    } else if (_isClub) {
      ref.read(selectedFacilityProvider.notifier).state =
          facility['facility_Id'] ?? '';
      showDatePickerBottomSheet(
        context,
        ref,
        image,
        List<String>.from(images),
        facilityTitle,
      );
    } else {
      final container = ProviderScope.containerOf(context, listen: false);
      final bookingMode = facility['booking_Mode'] as String? ?? 'slot';
      final facilityDocId = facility['docid'] as String? ?? facility['facility_Id'] ?? '';
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => ProviderScope(
                overrides: [
                  selectedFacilityProvider
                      .overrideWith((ref) => facilityDocId),
                ],
                child: bookingMode == 'session'
                    ? SessionBookingPage(
                        facilityName: facilityTitle,
                        imageUrl: image,
                        facilityDocId: facilityDocId,
                      )
                    : SportsBookingPage(
                        facilityName: facilityTitle,
                        imageUrl: image,
                        numberOfCourts: _parseCourts(facility['courts']),
                      ),
              ),
            ),
          )
          .whenComplete(() => resetBookingForm(container));
    }
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final bool isClub;
  final bool isBanda;
  const _HeroHeader({required this.isClub, this.isBanda = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0693e3), Color(0xFF057ab8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppKolors.accent.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isBanda
                          ? Icons.outdoor_grill_outlined
                          : isClub
                              ? Icons.stadium_outlined
                              : Icons.sports_tennis_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBanda
                            ? 'Banda Facilities'
                            : isClub
                                ? 'Club Facilities'
                                : 'Sports Facilities',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap a facility to book',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
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

// ── Facility Card ──────────────────────────────────────────────────────────────
class _FacilityCard extends StatelessWidget {
  final Map<String, dynamic> facility;
  final bool isActive;
  final bool isClub;
  final VoidCallback onTap;

  const _FacilityCard({
    required this.facility,
    required this.isActive,
    required this.isClub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = facility['imageurl'] ?? '';
    final title = facility['title'] ?? '';
    final statusLabel = isClub
        ? (isActive ? 'Available' : 'Blocked')
        : (isActive ? 'Slots Open' : 'Unavailable');
    final statusColor =
        isActive ? const Color(0xFF16A34A) : Colors.red.shade400;

    return Opacity(
      opacity: isActive ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Status badge top-right
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Title + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppKolors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppKolors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppKolors.border,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 36, color: AppKolors.textSecondary),
        ),
      );
}

// ── Facility List Tile ─────────────────────────────────────────────────────────
class _FacilityListTile extends StatelessWidget {
  final Map<String, dynamic> facility;
  final bool isActive;
  final bool isClub;
  final VoidCallback onTap;

  const _FacilityListTile({
    required this.facility,
    required this.isActive,
    required this.isClub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = facility['imageurl'] ?? '';
    final title = facility['title'] ?? '';
    final statusLabel = isClub
        ? (isActive ? 'Available' : 'Blocked')
        : (isActive ? 'Slots Open' : 'Unavailable');
    final statusColor =
        isActive ? const Color(0xFF16A34A) : Colors.red.shade400;

    return Opacity(
      opacity: isActive ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                // Thumbnail
                SizedBox(
                  width: 90,
                  height: 90,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppKolors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppKolors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppKolors.border,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 28, color: AppKolors.textSecondary),
        ),
      );
}

void showBandaBookingBottomSheet(
  BuildContext context,
  WidgetRef ref,
  String facilityName,
  String imageUrl,
) {
  final container = ProviderScope.containerOf(context, listen: false);
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    useRootNavigator: true,
    builder: (ctx) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          showExitConfirmationDialog(ctx).then((cancel) {
            if (cancel!) {
              Navigator.of(ctx).pop();
              _showCancelledToast(context);
            }
          });
        },
        child: Stack(
          children: [
            Consumer(
              builder: (context, ref, child) {
                return BandaBookingPage();
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () async {
                  final cancel = await showExitConfirmationDialog(ctx);
                  if (cancel!) {
                    Navigator.of(ctx).pop();
                    _showCancelledToast(context);
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    resetBookingForm(container);
  });
}

void _showCancelledToast(BuildContext context) {
  Fluttertoast.showToast(
    msg: 'Booking process canceled. Your changes were not saved.',
    backgroundColor: Colors.orange,
    textColor: Colors.white,
  );
}

void resetClubForm(ProviderContainer container) {
  container.read(selectedClubDateProvider.notifier).state = null;
  container.read(selectedClubFacilityProvider.notifier).state = '';
  container.read(clubGuestCountProvider.notifier).state = 0;
  container.read(selectedClubTimeSlotProvider.notifier).state = null;
}

int _parseCourts(dynamic courts) {
  if (courts is int) return courts;
  if (courts is List) return courts.length;
  return 1;
}

void resetBookingForm(ProviderContainer container) {
  container.read(selectedDateProvider.notifier).state = DateTime.now();
  container.read(selectedCourtProvider.notifier).state = 'Court 1';
  container.read(participantCountsProvider.notifier).state = {
    'Member': 0,
    'Child Member': 0,
    'Guest': 0,
  };
  container.read(selectedDateToProvider.notifier).state = null;
  container.read(selectedFromDateProvider.notifier).state = null;
  container.read(selectedTimeFromProvider.notifier).state = null;
  container.read(selectedNoOfAttendeesProvider.notifier).state = '';
  container.read(selectedTimeToProvider.notifier).state = null;
}
