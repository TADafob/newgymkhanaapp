import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// for GoRouter if needed

// Providers
final selectedMonthProvider = StateProvider<int?>((_) => null);
final selectedYearProvider = StateProvider<int?>((_) => null);

// Model
class Notice {
  final String id;
  final String title;
  final String author;
  final DateTime date;
  final String details;
  final List<String> tags;
  final List<String>? imageUrls;
  final String? videoUrl;
  final IconData icon;
  final int likeCount;
  final int dislikeCount;
  final String? currentUserReaction;

  Notice({
    required this.id,
    required this.title,
    required this.author,
    required this.date,
    required this.details,
    required this.tags,
    this.imageUrls,
    this.videoUrl,
    required this.icon,
    required this.likeCount,
    required this.dislikeCount,
    this.currentUserReaction,
  });

  Notice copyWith({
    int? likeCount,
    int? dislikeCount,
    String? currentUserReaction,
  }) {
    return Notice(
      id: id,
      title: title,
      author: author,
      date: date,
      details: details,
      tags: tags,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      icon: icon,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
    );
  }

  static Future<Notice> fromDoc(DocumentSnapshot doc,
      [String? currentUserId]) async {
    final data = doc.data()! as Map<String, dynamic>;

    String? userReaction;
    if (currentUserId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('notices')
          .doc(doc.id)
          .collection('reactions')
          .doc(currentUserId)
          .get();
      if (userDoc.exists) {
        userReaction = userDoc.data()!['type'] as String?;
      }
    }

    final metaSnap = await FirebaseFirestore.instance
        .collection('notices')
        .doc(doc.id)
        .collection('reactions')
        .doc('meta')
        .get();
    final meta = metaSnap.data() ?? <String, dynamic>{};

    return Notice(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      date: (data['date_Added'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data['details'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      icon: Icons.campaign,
      likeCount: meta['likeCount'] as int? ?? 0,
      dislikeCount: meta['dislikeCount'] as int? ?? 0,
      currentUserReaction: userReaction,
    );
  }
}

// Service
class ReactionService {
  final _notices = FirebaseFirestore.instance.collection('notices');

  DocumentReference getReactionRef(String noticeId, String userId) =>
      _notices.doc(noticeId).collection('reactions').doc(userId);

  DocumentReference getMetaRef(String noticeId) =>
      _notices.doc(noticeId).collection('reactions').doc('meta');

  Future<void> toggleReaction(
      String noticeId, String userId, String type) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final userRef = getReactionRef(noticeId, userId);
      final metaRef = getMetaRef(noticeId);

      final userSnap = await tx.get(userRef);
      final metaSnap = await tx.get(metaRef);
      final meta = (metaSnap.data() as Map<String, dynamic>?) ?? {};
      int likes = meta['likeCount'] ?? 0;
      int dislikes = meta['dislikeCount'] ?? 0;
      final existing = userSnap.exists
          ? (userSnap.data()! as Map<String, dynamic>)['type'] as String?
          : null;

      if (existing == type) {
        tx.delete(userRef);
        if (type == 'like') {
          likes--;
        } else {
          dislikes--;
        }
      } else {
        tx.set(userRef, {'type': type});
        if (existing == 'like') likes--;
        if (existing == 'dislike') dislikes--;
        if (type == 'like') {
          likes++;
        } else {
          dislikes++;
        }
      }

      tx.set(
        metaRef,
        {'likeCount': likes, 'dislikeCount': dislikes},
        SetOptions(merge: true),
      );
    });
  }
}

final reactionServiceProvider =
    Provider<ReactionService>((ref) => ReactionService());

// Providers
final noticeListProvider = StreamProvider<List<Notice>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);

  Query query = FirebaseFirestore.instance.collection('notices');

  if (year != null) {
    final start = DateTime(year, month ?? 1, 1);
    final end =
        month != null ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);
    query = query
        .where('date_Added', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date_Added', isLessThan: Timestamp.fromDate(end));
  }

  query = query.orderBy('date_Added', descending: true);

  return query.snapshots().asyncMap(
      (snap) => Future.wait(snap.docs.map((d) => Notice.fromDoc(d, uid))));
});

final noticeReactionsProvider =
    StreamProvider.family<Map<String, String>, String>((ref, noticeId) {
  return FirebaseFirestore.instance
      .collection('notices')
      .doc(noticeId)
      .collection('reactions')
      .snapshots()
      .map((snap) => {
            for (var doc in snap.docs)
              if (doc.id != 'meta') doc.id: doc.data()['type'] as String
          });
});

final noticeMetaProvider =
    StreamProvider.family<Map<String, int>, String>((ref, noticeId) {
  return FirebaseFirestore.instance
      .collection('notices')
      .doc(noticeId)
      .collection('reactions')
      .doc('meta')
      .snapshots()
      .map((doc) {
    final d = doc.data() ?? {};
    return {
      'likeCount': d['likeCount'] as int? ?? 0,
      'dislikeCount': d['dislikeCount'] as int? ?? 0,
    };
  });
});

final userReactionProvider =
    StreamProvider.family<String?, String>((ref, noticeId) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return FirebaseFirestore.instance
      .collection('notices')
      .doc(noticeId)
      .collection('reactions')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? doc.data()!['type'] as String? : null);
});

// Helpers
Map<String, List<Notice>> groupByMonth(List<Notice> notices) {
  final map = <String, List<Notice>>{};
  for (var n in notices) {
    final monthName = _monthName(n.date.month);
    final key = '$monthName ${n.date.year}';
    map.putIfAbsent(key, () => []).add(n);
  }
  return map;
}

String _monthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return names[month - 1];
}

int _monthIndex(String name) {
  const names = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };
  return names[name] ?? 1;
}

Color _tagColor(String tag) {
  switch (tag.toLowerCase()) {
    case 'important':
      return Colors.red;
    case 'gym':
      return Colors.purple;
    case 'payments':
      return Colors.orange;
    case 'events':
      return Colors.blue;
    case 'updates':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
