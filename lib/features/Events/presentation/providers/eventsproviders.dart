import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final allEventsProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('events_collection')
      .orderBy('date', descending: false)
      .snapshots();
});

final upcomingEventsProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final now = DateTime.now();
  return ref.watch(allEventsProvider.stream).map((snapshot) {
    return snapshot.docs.where((doc) {
      final ts = doc.data()['date'];
      if (ts is Timestamp) {
        final eventDate = ts.toDate();
        return eventDate.isAfter(now) || eventDate.isAtSameMomentAs(now);
      }
      return false;
    }).toList();
  });
});

final pastEventsProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final now = DateTime.now();
  return ref.watch(allEventsProvider.stream).map((snapshot) {
    return snapshot.docs.where((doc) {
      final ts = doc.data()['date'];
      if (ts is Timestamp) {
        return ts.toDate().isBefore(now);
      }
      return false;
    }).toList();
  });
});

/// Holds the state of a booking attempt.
class BookingState {
  final bool isLoading;
  final String? error;
  final bool success;

  const BookingState._({this.isLoading = false, this.error, this.success = false});
  const BookingState.idle()   : this._();
  const BookingState.loading(): this._(isLoading: true);
  const BookingState.error(String e): this._(error: e);
  const BookingState.done(): this._(success: true);
}

/// Parameters needed to book.
class BookingParams {
  final String eventId;
  final Map<String,int> tickets;
  final bool isFree;
  final int basePrice;

  BookingParams({
    required this.eventId,
    required this.tickets,
    required this.isFree,
    required this.basePrice,
  });
}

/// The notifier which runs the Firestore call.
class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier(): super(const BookingState.idle());

  Future<void> book(BookingParams p) async {
    state = const BookingState.loading();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final now    = Timestamp.now();
      final docRef = FirebaseFirestore.instance
          .collection('events_collection')
          .doc(p.eventId)
          .collection('bookings')
          .doc(); // auto‑ID

      final totalAmount = p.isFree
        ? 0
        : p.tickets.entries.fold<int>(0, (sum,e) => sum + e.value * p.basePrice);

      final data = {
        'booked_By'     : userId,
        'booking_Date'  : now,
        'status'        : 'Pending',
        'total_Amount'  : totalAmount,
        'is_Free'       : p.isFree,
        'tickets'       : p.tickets,
        'booking_Id'    : docRef.id,
      };

      await docRef.set(data);

      state = const BookingState.done();
    } catch (e) {
      state = BookingState.error(e.toString());
    }
  }
}

/// Provider for our booking notifier.
final bookingProvider = StateNotifierProvider.autoDispose<
    BookingNotifier, BookingState>((ref) => BookingNotifier());

