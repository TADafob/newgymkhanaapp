// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
// import 'package:intl/intl.dart';

// class NotificationsPage extends StatelessWidget {
//   const NotificationsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Column(
//           children: [
//             CommonTopContainer(title: 'NOTIFICATIONS', Image_url: 'assets/images/common/calendar.png', titleposition: 130,),
//             SizedBox(height: 10,),
//             TabBar(
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                 dividerColor: Colors.transparent,
//                 labelColor: AppKolors.secondary,
//                 unselectedLabelColor: Colors.black,
//                 labelStyle: const TextStyle(fontSize: 18),
//                 unselectedLabelStyle: const TextStyle(fontSize: 14),
//                 indicator: UnderlineTabIndicator(
//                   borderRadius: BorderRadius.circular(120),
//                   borderSide: const BorderSide(
//                     color: AppKolors.accent3,
//                     width: 3,
//                   ),
//                   insets: const EdgeInsets.symmetric(horizontal: 16.0),
//                 ),
//               tabs: [
//                 Tab(text: 'Notifications'),
//                 Tab(text: 'Messages'),
//               ],
//             ),
//             const Expanded(
//               child: TabBarView(
//                 children: [
//                   NotificationList(),
//                   MessagesList(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class NotificationList extends ConsumerWidget {
//   const NotificationList({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final notifications = ref.watch(notificationsProvider);

//     Map<String, List<Map<String, dynamic>>> groupedNotifications = groupByDate(notifications);

//     return ListView(
//       padding: const EdgeInsets.all(8.0),
//       children: groupedNotifications.entries.map((entry) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
//               child: Text(
//                 entry.key,
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ...entry.value.map((notification) {
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 4.0),
//                 child: ListTile(
//                   leading: const Icon(
//                     Icons.notifications,
//                     color: Colors.blueAccent,
//                   ),
//                   title: Text(
//                     notification['title'],
//                     style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(notification['description'], style: const TextStyle(color: Colors.black87)),
//                       const SizedBox(height: 4),
//                       Text(notification['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
//                     ],
//                   ),
//                   trailing: const Icon(Icons.circle, color: Colors.lightBlueAccent, size: 12),
//                 ),
//               );
//             }),
//           ],
//         );
//       }).toList(),
//     );
//   }
// }

// Map<String, List<Map<String, dynamic>>> groupByDate(List<Map<String, dynamic>> notifications) {
//   final today = DateTime.now();
//   final yesterday = today.subtract(const Duration(days: 1));

//   Map<String, List<Map<String, dynamic>>> grouped = {
//     'Today': [],
//     'Yesterday': [],
//     'Older': [],
//   };

//   for (var notification in notifications) {
//     DateTime date = notification['date'];
//     if (isSameDay(date, today)) {
//       grouped['Today']!.add(notification);
//     } else if (isSameDay(date, yesterday)) {
//       grouped['Yesterday']!.add(notification);
//     } else {
//       grouped['Older']!.add(notification);
//     }
//   }

//   return grouped;
// }

// bool isSameDay(DateTime date1, DateTime date2) {
//   return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
// }

// // --------------------- MESSAGES SECTION ---------------------


// class MessagesList extends ConsumerWidget {
//   const MessagesList({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final messagesAsync = ref.watch(messagesProvider);

//     return Scaffold(
//       body: messagesAsync.when(
//         data: (messages) {
//           if (messages.isEmpty) {
//             return const Center(child: Text("No messages yet!", style: TextStyle(color: Colors.grey)));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(8.0),
//             itemCount: messages.length,
//             itemBuilder: (context, index) {
//               final message = messages[index];

//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 6.0),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     radius: 25,
//                     backgroundImage: NetworkImage(message['profilePic']),
//                   ),
//                   title: Text(
//                     message['sender'],
//                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
//                   ),
//                   subtitle: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           message['snippet'],
//                           style: const TextStyle(color: Colors.black87),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                       Text(
//                         formatTime(message['date']),
//                         style: const TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                   trailing: message['unreadCount'] > 0
//                       ? CircleAvatar(
//                           radius: 12,
//                           backgroundColor: Colors.red,
//                           child: Text(
//                             message['unreadCount'].toString(),
//                             style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                           ),
//                         )
//                       : const SizedBox.shrink(),
//                 ),
//               );
//             },
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) => Center(child: Text("Error loading messages: $error")),
//       ),

//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showSendMessageDialog(context, ref),
//         backgroundColor: Colors.blueAccent,
//         child: const Icon(Icons.message, color: Colors.white),
//       ),
//     );
//   }

//   void _showSendMessageDialog(BuildContext context, WidgetRef ref) {
//     final TextEditingController receiverController = TextEditingController();
//     final TextEditingController messageController = TextEditingController();
//     final sendingId = FirebaseAuth.instance.currentUser!.uid;
    
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Send Message"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: receiverController,
//                 decoration: const InputDecoration(labelText: "Receiver ID"),
//               ),
//               TextField(
//                 controller: messageController,
//                 decoration: const InputDecoration(labelText: "Message"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 final senderId = sendingId; // Replace with logged-in user ID
//                 final receiverId = receiverController.text.trim();
//                 final text = messageController.text.trim();
                
//                 if (receiverId.isNotEmpty && text.isNotEmpty) {
//                   ref.read(sendMessageProvider)(senderId, receiverId, text);
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text("Send"),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// // Format timestamp
// String formatTime(DateTime date) {
//   DateTime now = DateTime.now();
//   if (isSameDay(date, now)) {
//     return DateFormat('h:mm a').format(date);
//   } else if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
//     return 'Yesterday';
//   } else {
//     return DateFormat('MMM d').format(date);
//   }
// }

// // bool isSameDay(DateTime date1, DateTime date2) {
// //   return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
// // }


// // --------------------- PROVIDERS ---------------------

// final notificationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
//   return [
//     {
//       'title': 'XRP is up',
//       'description': 'XRP is up by 7.03% to 0.5691 USDT in the last 24 hours',
//       'time': '12:19 AM',
//       'date': DateTime.now(),
//     },
//     {
//       'title': 'SOL is up',
//       'description': 'SOL is up by 7.02% to 155.5 USDT in the last 24 hours',
//       'time': 'May 6, 2024',
//       'date': DateTime.now().subtract(const Duration(days: 1)),
//     },
//     {
//       'title': 'ZERO/USDT is live!',
//       'description': 'Trade ZERO/USDT now',
//       'time': 'May 6, 2024',
//       'date': DateTime.now().subtract(const Duration(days: 1)),
//     },
//     {
//       'title': 'BTC market update',
//       'description': 'BTC is above 64,000 USDT',
//       'time': 'May 4, 2024',
//       'date': DateTime(2024, 5, 4),
//     },
//   ];
// });

// // final messagesProvider = Provider<List<Map<String, dynamic>>>((ref) {
// //   return [
// //     {
// //       'sender': 'Alice Johnson',
// //       'profilePic': 'https://randomuser.me/api/portraits/women/44.jpg',
// //       'snippet': 'Hey, are we still meeting later today?',
// //       'unreadCount': 3,
// //       'date': DateTime.now(),
// //     },
// //     {
// //       'sender': 'John Doe',
// //       'profilePic': 'https://randomuser.me/api/portraits/men/46.jpg',
// //       'snippet': 'Got it! I will check the details and get back to you.',
// //       'unreadCount': 0,
// //       'date': DateTime.now().subtract(const Duration(hours: 4)),
// //     },
// //     {
// //       'sender': 'Mark Smith',
// //       'profilePic': 'https://randomuser.me/api/portraits/men/47.jpg',
// //       'snippet': 'Check out this new update, it\'s really cool!',
// //       'unreadCount': 2,
// //       'date': DateTime.now().subtract(const Duration(days: 1)),
// //     },
// //     {
// //       'sender': 'Hon Treasuerer',
// //       'profilePic': 'https://randomuser.me/api/portraits/men/48.jpg',
// //       'snippet': 'Check out this new update, it\'s really cool!',
// //       'unreadCount': 2,
// //       'date': DateTime.now().subtract(const Duration(days: 2)),
// //     },
// //     {
// //       'sender': 'Reception',
// //       'profilePic': 'https://randomuser.me/api/portraits/men/49.jpg',
// //       'snippet': 'Check out this new update, it\'s really cool!',
// //       'unreadCount': 2,
// //       'date': DateTime.now().subtract(const Duration(days: 3)),
// //     },
// //   ];
// // });

// final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
// //final senderId = FirebaseAuth.instance.currentUser!.uid;

// // Fetch chat list for a specific user
// final messagesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
//   final firestore = ref.watch(firestoreProvider);
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid; // Get logged-in user ID

//   return firestore
//       .collection("chats_collection")
//       .where("users", arrayContains: currentUserId) // Get chats where user is a participant
//       .orderBy("lastMessageTime", descending: true)
//       .snapshots()
//       .asyncMap((snapshot) async {
//     List<Map<String, dynamic>> messages = [];

//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       String senderId = data['lastsenderId'] ?? '';
//       List<dynamic> participants = data['users'] ?? [];

//       // Determine the receiver ID (the other person in the chat)
//       String receiverId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');

//       String displayedUserId = senderId == currentUserId ? receiverId : senderId;

//       if (displayedUserId.isEmpty) continue; // Skip if we can't determine the other user

//       print('Fetching user details for ID: $displayedUserId');

//       // Fetch the other participant's details from 'users_members'
//       var userDoc = await firestore.collection('users_members').doc(displayedUserId).get();
//       String displayedName = userDoc.exists ? userDoc['f_Name'] ?? 'Unknown' : 'Unknown';
//       String profilePic = userDoc.exists ? userDoc['avatar_Url'] ?? "https://via.placeholder.com/50" : "https://via.placeholder.com/50";

//       messages.add({
//         'chatId': doc.id,
//         'sender': displayedName, // Show the correct name
//         'profilePic': profilePic,
//         'snippet': data['lastMessage'] ?? "",
//         'unreadCount': (data['unreadCount'][currentUserId] ?? 0), // Show unread count
//         'date': (data['lastMessageTime'] as Timestamp).toDate(),
//       });
//     }

//     return messages;
//   });
// });




// // Function to send a new message
// final sendMessageProvider = Provider((ref) {
//   final firestore = ref.watch(firestoreProvider);

//   return (String senderId, String receiverId, String text) async {
//     final chatRef = firestore.collection("chats_collection");
    
//     // Find existing chat or create a new one
//     final existingChat = await chatRef
//         .where("users_members", arrayContains: senderId)
//         .get();
    
//     DocumentReference chatDoc;
//     if (existingChat.docs.isNotEmpty) {
//       chatDoc = existingChat.docs.first.reference; // Use existing chat
//     } else {
//       chatDoc = await chatRef.add({
//         "users": [senderId, receiverId],
//         "lastMessage": text,
//         "lastMessageTime": FieldValue.serverTimestamp(),
//         "unreadCount": {receiverId: 1, senderId: 0},
//         "lastsenderId": senderId
//       });
//     }

//     // Add new message to the messages subcollection
//     await chatDoc.collection("messages").add({
//       "senderId": senderId,
//       "receiverId": receiverId,
//       "text": text,
//       "timestamp": FieldValue.serverTimestamp(),
//       "status": {senderId: "sent", receiverId: "delivered"},
//     });

//     // Update chat last message
//     await chatDoc.update({
//       "lastMessage": text,
//       "lastMessageTime": FieldValue.serverTimestamp(),
//       "unreadCount.$receiverId": FieldValue.increment(1),
//     });
//   };
// });
