import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/appfonts.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/club_booking_page.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/booking_category.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/sports_booking_page.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';

class Facility {
  final String id;
  final String name;
  final String category;
  final String imagePath;
  final String description;
  final bool isAvailable;
  final List? imagePaths;
  final int? facilityQuota;

  Facility({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.description,
    required this.isAvailable,
    this.imagePaths,
    this.facilityQuota,
  });

  factory Facility.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawType = (data['facility_Type'] as String?)?.toLowerCase() ?? '';
    final rawName = (data['facility_Name'] as String?)?.toLowerCase() ?? '';
    final courts = (data['courts'] as num?)?.toInt();
    final grounds = (data['grounds'] as num?)?.toInt();
    final rooms = (data['rooms'] as num?)?.toInt();
    final isActive = data['isActive'] as bool? ?? true;

    final category = _mapToCategory(rawType, rawName);

    final isSports = category == 'Sports Facilities';
    final isGround = rawName.toLowerCase().contains('ground');

    return Facility(
      id: doc.id,
      name: data['facility_Name'] as String? ?? 'Unnamed Facility',
      category: category,
      imagePath: data['image'] as String? ?? '',
      description:
          data['description'] as String? ?? 'No description available.',
      isAvailable: isActive,
      facilityQuota: isSports
          ? courts
          : isGround
              ? grounds
              : rooms,
      imagePaths:
          (data['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  static String _mapToCategory(String type, String name) {
    if (type == 'bandas') return 'Bandas';
    if (type == 'club') {
      if (name.contains('court')) return 'Sports Facilities';
      if (name.contains('hall')) return 'Club Halls';
      if (name.contains('ground') ||
          name.contains('pitch') ||
          name.contains('field')) {
        return 'Grounds';
      }
      if (name.contains('banda')) return 'Bandas';
      if (name.contains('gym') ||
          name.contains('steam') ||
          name.contains('sauna')) {
        return 'Recreations';
      }
    }

    if (type.contains('sport')) return 'Sports Facilities';
    if (type.contains('hall')) return 'Halls';
    if (type.contains('ground')) return 'Grounds';
    if (type.contains('recreat')) return 'Recreations';
    return 'Other';
  }
}

final facilitiesStreamProvider = StreamProvider<List<Facility>>((ref) {
  return FirebaseFirestore.instance
      .collection('Facilities')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Facility.fromFirestore(d)).toList());
});

class ClubFacilitiesPage extends ConsumerStatefulWidget {
  const ClubFacilitiesPage({super.key});

  @override
  ConsumerState<ClubFacilitiesPage> createState() => _ClubFacilitiesPageState();
}

class _ClubFacilitiesPageState extends ConsumerState<ClubFacilitiesPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncFacilities = ref.watch(facilitiesStreamProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: asyncFacilities.when(
        loading: () => const PageShimmer(itemCount: 6),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (facilities) {
          final filteredFacilities = facilities.where((facility) {
            final nameLower = facility.name.toLowerCase();
            final queryLower = _searchQuery.toLowerCase();
            final categoryMatch = _selectedCategory == 'All' ||
                facility.category == _selectedCategory;
            return nameLower.contains(queryLower) && categoryMatch;
          }).toList();

          final categories = {'All', ...facilities.map((f) => f.category)};

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(facilitiesStreamProvider);
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: false,
                  backgroundColor:
                      isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Facilities',
                            style: AppFonts.headline2.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Explore all available facilities',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppKolors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 20),
                              hintText: 'Search facilities...',
                              hintStyle: TextStyle(
                                color: AppKolors.textSecondary,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF252525)
                                  : const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF252525)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view,
                                  size: 20,
                                  color: _isGridView
                                      ? AppKolors.primary
                                      : AppKolors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = true;
                                  });
                                },
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppKolors.textSecondary.withOpacity(0.2),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.list,
                                  size: 20,
                                  color: !_isGridView
                                      ? AppKolors.primary
                                      : AppKolors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppKolors.primary
                                    : isDark
                                        ? const Color(0xFF252525)
                                        : const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppKolors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                if (filteredFacilities.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppKolors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No facilities found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppKolors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Try selecting a different category'
                                : 'Try a different search term',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppKolors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isGridView)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return FacilityGridCard(
                            facility: filteredFacilities[index],
                          );
                        },
                        childCount: filteredFacilities.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
                      itemCount: filteredFacilities.length,
                      itemBuilder: (context, index) {
                        return FacilityListCard(
                          facility: filteredFacilities[index],
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FacilityGridCard extends StatelessWidget {
  final Facility facility;

  const FacilityGridCard({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilityDetailsPage(facility: facility),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                facility.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppKolors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.broken_image,
                    color: AppKolors.primary,
                    size: 40,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: facility.isAvailable
                      ? const Color(0xFF10b981)
                      : const Color(0xFFef4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  facility.isAvailable ? 'Open' : 'Closed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            facility.category,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (facility.facilityQuota != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${facility.facilityQuota} available',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FacilityListCard extends StatelessWidget {
  final Facility facility;

  const FacilityListCard({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilityDetailsPage(facility: facility),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.network(
                  facility.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppKolors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.broken_image,
                      color: AppKolors.primary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      facility.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppKolors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: facility.isAvailable
                                ? const Color(0xFF10b981).withOpacity(0.1)
                                : const Color(0xFFef4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            facility.isAvailable ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: facility.isAvailable
                                  ? const Color(0xFF10b981)
                                  : const Color(0xFFef4444),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (facility.facilityQuota != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${facility.facilityQuota} available',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppKolors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppKolors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FacilityDetailsPage extends ConsumerWidget {
  final Facility facility;

  const FacilityDetailsPage({super.key, required this.facility});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Image.network(
                    facility.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppKolors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.broken_image,
                        color: AppKolors.primary,
                        size: 80,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: facility.isAvailable
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFFef4444),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                facility.isAvailable ? 'Open' : 'Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                facility.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                Text(
                  'About',
                  style: AppFonts.headline2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  facility.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppKolors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                if (facility.facilityQuota != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppKolors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppKolors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: AppKolors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Availability',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppKolors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${facility.facilityQuota} slots available',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                facility.category != 'Club Halls' &&
                        facility.category != 'Sports Facilities' &&
                        facility.category != 'Grounds' &&
                        facility.category != 'Bandas'
                    ? Container()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if ((facility.category == 'Club Halls' ||
                                    facility.category == 'Grounds') &&
                                facility.isAvailable) {
                              final container = ProviderScope.containerOf(
                                  context,
                                  listen: false);
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => ProviderScope(
                                        overrides: [
                                          selectedFacilityProvider
                                              .overrideWith((r) => facility.id),
                                        ],
                                        child: ClubBookingPage(
                                          facilityName: facility.name,
                                          imageUrl: facility.imagePath,
                                        ),
                                      ),
                                    ),
                                  )
                                  .whenComplete(
                                      () => resetBookingForm(container));
                            } else if (facility.category == 'Bandas' &&
                                facility.isAvailable) {
                              ref
                                  .read(selectedFacilityProvider.notifier)
                                  .state = facility.id;
                              showBandaBookingBottomSheet(
                                context,
                                ref,
                                facility.name,
                                facility.imagePath,
                              );
                            } else if (facility.isAvailable != true) {
                              Fluttertoast.showToast(
                                msg:
                                    'Cannot book this facility, it is currently closed',
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                            } else {
                              final container = ProviderScope.containerOf(
                                  context,
                                  listen: false);
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => ProviderScope(
                                        overrides: [
                                          selectedFacilityProvider
                                              .overrideWith((r) => facility.id),
                                        ],
                                        child: SportsBookingPage(
                                          facilityName: facility.name,
                                          imageUrl: facility.imagePath,
                                          numberOfCourts:
                                              facility.facilityQuota ?? 1,
                                        ),
                                      ),
                                    ),
                                  )
                                  .whenComplete(
                                      () => resetBookingForm(container));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppKolors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Book Facility',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
