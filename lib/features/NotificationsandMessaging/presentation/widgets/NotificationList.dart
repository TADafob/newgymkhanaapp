import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/presentation/screens_ui/notif_details.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/data/notifications_model.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';

class NotificationList extends ConsumerWidget {
  const NotificationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view notifications."));
    }

    return StreamBuilder<QuerySnapshot>(
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

        final notifications =
            docs.where((d) => d.data() is Map<String, dynamic>).map((doc) {
          return NotificationModel.fromFirestore(
              doc.id, doc.data()! as Map<String, dynamic>);
        }).toList();

        final grouped = _groupByDate(notifications);

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: grouped.entries.expand<Widget>((entry) {
            return [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ...entry.value.map((notif) => _buildDismissible(context, notif)),
            ];
          }).toList(),
        );
      },
    );
  }

  Widget _buildDismissible(BuildContext context, NotificationModel notif) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notif.id),
      background: _swipeBackground(Alignment.centerLeft, Icons.delete),
      secondaryBackground:
          _swipeBackground(Alignment.centerRight, Icons.delete),
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
                      child: const Text('Delete')),
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
      child: Column(
        children: [
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Icon(notif.icon, color: notif.iconColor),
              title: Text(
                notif.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(notif.body,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: notif.isNew
                  ? const Icon(Icons.circle, color: Colors.red, size: 12)
                  : null,
              onTap: () async {
                // mark as read
                if (notif.isNew) {
                  await FirebaseFirestore.instance
                      .collection('notifications_collection')
                      .doc(notif.id)
                      .update({'isNew': false});
                }
                // go to detail
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => NotificationDetailPage(notification: notif),
                ));
              },
            ),
          ),
          Divider(
            indent: 20,
            endIndent: 20,
            color: isDark
                ? AppKolors.darkDivider
                : AppKolors.containerPrimary.withValues(alpha: 0.4),
            thickness: 0.5,
          ),
        ],
      ),
    );
  }

  Widget _swipeBackground(Alignment align, IconData icon) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.redAccent,
      child: Icon(icon, color: Colors.white),
    );
  }

  Map<String, List<NotificationModel>> _groupByDate(
      List<NotificationModel> list) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<NotificationModel>> map = {};

    for (var n in list) {
      String key;
      if (_isSameDay(n.dateTime, today)) {
        key = 'Today';
      } else if (_isSameDay(n.dateTime, yesterday)) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMM d, yyyy').format(n.dateTime);
      }
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
