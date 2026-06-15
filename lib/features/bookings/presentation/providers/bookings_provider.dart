import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/features/app_auths/presentation/providers/auth_provider.dart';
import 'package:nrbgymkhana/features/bookings/data/models/bookingmodel.dart';

// StreamProvider to fetch bookings for the current user with optimization
final bookingsProvider = StreamProvider<List<Booking>>((ref) {
  final currentUser = ref.watch(authStateChangesProvider).value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  // Optimized query: only fetch non-cancelled bookings from today onwards
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return FirebaseFirestore.instance
      .collection('bookings_collection')
      .where('user_Id', isEqualTo: currentUser.uid)
      .where('start_Time', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
      .orderBy('start_Time', descending: false)
      .limit(50)
      .snapshots()
      .asyncMap((snapshot) async {
    final bookings = await Future.wait(
      snapshot.docs.map((doc) => Booking.fromFirestore(doc)),
    );
    return bookings;
  });
});

// ── Club Booking Providers ──
final selectedClubDateProvider = StateProvider<DateTime?>((ref) => null);
final clubGuestCountProvider = StateProvider<int>((ref) => 0);
final selectedClubTimeSlotProvider = StateProvider<String?>((ref) => null);
final selectedClubFacilityProvider = StateProvider<String>((ref) => '');

final clubUnavailableDatesProvider =
    FutureProvider.family<List<DateTime>, String>((ref, facilityId) async {
  final now = DateTime.now();
  final limit = now.add(const Duration(days: 90)); // Like sports lastDay

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings_collection')
      .where('facility_Id', isEqualTo: facilityId)
      .where('facility_Type', isEqualTo: 'Club')
      .where('booking_Date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .where('status', isNotEqualTo: 'Cancelled') // Assume status field
      .get();

  final dates = snapshot.docs
      .expand((doc) {
        final bookingDate =
            (doc['booking_Date'] as Timestamp?)?.toDate() ?? DateTime.now();
        return [bookingDate]; // One date per booking for club
      })
      .where((date) => !date.isBefore(now) && !date.isAfter(limit))
      .toList();

  return dates;
});

final clubTimeSlotsProvider =
    FutureProvider.family<Map<String, dynamic>, (String, DateTime)>(
        (ref, params) async {
  final (facilityId, selectedDate) = params;
  final now = DateTime.now();

  // Generate 8am-10pm slots (14 slots)
  final slots = <String, String>{};
  for (int hour = 8; hour < 22; hour++) {
    final start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour);
    final end = start.add(const Duration(hours: 1));
    final slotKey =
        '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}';

    // Check availability (simplified - query bookings overlapping this slot)
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings_collection')
        .where('facility_Id', isEqualTo: facilityId)
        .where('facility_Type', isEqualTo: 'Club')
        .where('booking_Date', isEqualTo: Timestamp.fromDate(selectedDate))
        .where('start_Time', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .where('end_Time', isGreaterThan: Timestamp.fromDate(start))
        .where('status', isNotEqualTo: 'Cancelled')
        .limit(1)
        .get();

    final isAvailable = snapshot.docs.isEmpty;
    slots[slotKey] = isAvailable ? 'available' : 'booked';
  }

  return slots;
});

class BookingsCardStateNotifier extends StateNotifier<Map<String, bool>> {
  BookingsCardStateNotifier() : super({});

  void toggleCard(String id) {
    state = {
      ...state,
      id: !(state[id] ?? false),
    };
  }

  void collapseOtherCards(String id) {
    state = {
      ...state.map((key, value) {
        return MapEntry(key, key == id ? !(state[key] ?? false) : false);
      }),
    };
  }
}

final bookingsCardProvider =
    StateNotifierProvider.autoDispose<BookingsCardNotifier, Map<String, bool>>(
        (ref) {
  return BookingsCardNotifier();
});

class BookingsCardNotifier extends StateNotifier<Map<String, bool>> {
  BookingsCardNotifier() : super({});

  void toggleCard(String id) {
    final wasOpen = state[id] ?? false;
    state = {
      for (final entry in state.entries) entry.key: false,
      id: !wasOpen,
    };
  }
}

final disabledDatesStateProvider = StateProvider<List<DateTime>>((ref) => []);

final disabledDatesProvider =
    FutureProvider.family<List<DateTime>, String>((ref, facilityId) async {
  final bookingsQuery = FirebaseFirestore.instance
      .collection('bookings_collection')
      .where('facility_Id', isEqualTo: facilityId)
      .get();

  final bookings = await bookingsQuery;

  if (bookings.docs.isEmpty) {
    return [];
  }

  final dates = bookings.docs.expand((doc) {
    final startDate = (doc['start_Time'] as Timestamp).toDate();
    final endDate = (doc['end_Time'] as Timestamp).toDate();
    return List.generate(
      endDate.difference(startDate).inDays + 1,
      (index) => startDate.add(Duration(days: index)),
    );
  }).toList();

  ref.read(disabledDatesStateProvider.notifier).state = dates;
  return dates;
});

Future<Map<String, dynamic>> fetchFacilities() async {
  final CollectionReference facilitiesRef =
      FirebaseFirestore.instance.collection('Facilities');
  QuerySnapshot querySnapshot = await facilitiesRef.get();
  Map<String, dynamic> facilityConfig = {};

  for (var doc in querySnapshot.docs) {
    var data = doc.data() as Map<String, dynamic>;
    final facilityName =
        (data['facility_Name'] as String?)?.toLowerCase() ?? '';

    facilityConfig[facilityName] = {
      'image': data['image'] ?? '',
      'description': data['description'] ?? 'No description available.',
      'courts': data.containsKey('courts') ? data['courts'] : 1,
      'images': data['images'] ?? [],
      'facility_Id': doc.id,
    };
  }

  return facilityConfig;
}

final allFacilitiesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await fetchFacilities();
});

final dateFromProvider = StateProvider<DateTime?>((ref) => null);
final dateToProvider = StateProvider<DateTime?>((ref) => null);
final selectedFromDateProvider = StateProvider<DateTime?>((ref) => null);
final selectedDateToProvider = StateProvider<DateTime?>((ref) => null);
final selectedTimeFromProvider = StateProvider<TimeOfDay?>((ref) => null);
final selectedTimeToProvider = StateProvider<TimeOfDay?>((ref) => null);
final selectedNoOfAttendeesProvider = StateProvider<String>((ref) => '');
final reasonForBookingProvider = StateProvider<String>((ref) => '');
final cateringProvider = StateProvider<String>((ref) => '');
final specialrequestsProvider = StateProvider<String>((ref) => '');

// Club booking — multi-date & time providers
final clubSelectedDatesProvider = StateProvider<List<DateTime>>((ref) => []);
final clubStartTimeProvider = StateProvider<TimeOfDay?>((ref) => null);
final clubEndTimeProvider = StateProvider<TimeOfDay?>((ref) => null);
final clubCatererTypeProvider = StateProvider<String>((ref) => ''); // 'internal_food', 'internal_drinks', 'external'
final clubCatererNameProvider = StateProvider<String>((ref) => '');
