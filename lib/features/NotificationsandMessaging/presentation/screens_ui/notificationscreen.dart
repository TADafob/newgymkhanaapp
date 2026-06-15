import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/data/notifications_model.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/presentation/screens_ui/notif_details.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';

class NotificationsPage extends ConsumerWidget {
  final int initialTabIndex;
  const NotificationsPage({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppKolors.background,
      body: Column(
        children: [
          _NotifHeroHeader(isDark: isDark),
          Expanded(
            child: user == null
                ? const Center(child: Text('Please log in to view notifications.'))
                : _NotificationList(isDark: isDark),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _NotifHeroHeader extends StatelessWidget {
  final bool isDark;
  const _NotifHeroHeader({required this.isDark});

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
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your latest updates',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
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

// ── Notification List ─────────────────────────────────────────────────────────
class _NotificationList extends ConsumerStatefulWidget {
  final bool isDark;
  const _NotificationList({required this.isDark});

  @override
  ConsumerState<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<_NotificationList> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return RefreshIndicator(
      color: AppKolors.primary,
      onRefresh: () async => setState(() => _refreshKey++),
      child: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_refreshKey),
        stream: FirebaseFirestore.instance
            .collection('notifications_collection')
            .where('recipientId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const nodatawidget(title: 'You have no notifications yet');
        }

        final notifications = docs
            .where((d) => d.data() is Map<String, dynamic>)
            .map((doc) => NotificationModel.fromFirestore(
                doc.id, doc.data()! as Map<String, dynamic>))
            .toList();

        final unreadCount = notifications.where((n) => n.isNew).length;
        final grouped = _groupByDate(notifications);

        return Column(
          children: [
            // ── Unread badge row ──
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppKolors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppKolors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppKolors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$unreadCount unread',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppKolors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _markAllRead(user.uid),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                            fontSize: 12, color: AppKolors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            // ── List ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                children: grouped.entries.expand<Widget>((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark
                              ? Colors.white54
                              : AppKolors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...entry.value.map(
                        (n) => _NotifCard(notif: n, isDark: widget.isDark)),
                    const SizedBox(height: 4),
                  ];
                }).toList(),
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  Future<void> _markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('notifications_collection')
        .where('recipientId', isEqualTo: uid)
        .where('isNew', isEqualTo: true)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isNew': false});
    }
    await batch.commit();
  }

  Map<String, List<NotificationModel>> _groupByDate(
      List<NotificationModel> list) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<NotificationModel>> map = {};
    for (var n in list) {
      String key;
      if (_isSameDay(n.dateTime, today)) {
        key = 'TODAY';
      } else if (_isSameDay(n.dateTime, yesterday)) {
        key = 'YESTERDAY';
      } else {
        key = DateFormat('MMM d, yyyy').format(n.dateTime).toUpperCase();
      }
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Notification Card ─────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark;
  const _NotifCard({required this.notif, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      background: _swipeBg(Alignment.centerLeft),
      secondaryBackground: _swipeBg(Alignment.centerRight),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Notification?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection('notifications_collection')
            .doc(notif.id)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: GestureDetector(
        onTap: () async {
          if (notif.isNew) {
            await FirebaseFirestore.instance
                .collection('notifications_collection')
                .doc(notif.id)
                .update({'isNew': false});
          }
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => NotificationDetailPage(notification: notif),
          ));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: notif.isNew
                ? (isDark
                    ? AppKolors.primary.withValues(alpha: 0.12)
                    : AppKolors.primary.withValues(alpha: 0.05))
                : (isDark ? const Color(0xFF1D1E33) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: notif.isNew
                ? Border.all(
                    color: AppKolors.primary.withValues(alpha: 0.25), width: 1)
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.12),
                    width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notif.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(notif.icon, color: notif.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notif.isNew
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppKolors.textPrimary,
                              ),
                            ),
                          ),
                          if (notif.isNew)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppKolors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white60
                              : AppKolors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('hh:mm a').format(notif.dateTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white38
                              : AppKolors.textSecondary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
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

  Widget _swipeBg(Alignment align) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );
  }
}
