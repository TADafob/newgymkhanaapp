import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkNotifier extends StateNotifier<Set<String>> {
  BookmarkNotifier() : super({}) {
    _loadBookmarks();
  }

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _loadBookmarks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users_members')
        .doc(user.uid)
        .collection('bookmarks')
        .get();

    final eventIds = snapshot.docs.map((doc) => doc.id).toSet();
    state = eventIds;
  }

  void toggleBookmark(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bookmarkRef = _firestore
        .collection('users_members')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(eventId);

    final isBookmarked = state.contains(eventId);

    if (isBookmarked) {
      await bookmarkRef.delete();
      state = {...state}..remove(eventId);
    } else {
      await bookmarkRef.set({'timestamp': FieldValue.serverTimestamp()});
      state = {...state}..add(eventId);
    }
  }

  bool isBookmarked(String eventId) {
    return state.contains(eventId);
  }
}

final bookmarkProvider = StateNotifierProvider<BookmarkNotifier, Set<String>>(
  (ref) => BookmarkNotifier(),
);
