// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
// import 'package:intl/intl.dart';
// import 'package:nrbgymkhana/tests/test.dart';

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

// class NotificationList extends StatelessWidget {
//   const NotificationList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return const Center(child: Text("Please log in to view notifications."));
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('notifications_collection')
//           .where('userId', isEqualTo: user.uid) // Filter notifications by user ID
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text("No notifications yet."));
//         }

//         final notifications = snapshot.data!.docs.map((doc) {
//           final data = doc.data() as Map<String, dynamic>;

//           // Handle 'date' as a Firestore Timestamp
//           final timestamp = data['date'] as Timestamp;
//           final date = timestamp.toDate(); // Convert Timestamp to DateTime
//           final formattedTime = DateFormat('hh:mm a').format(date);

//           return {
//             'id': doc.id,
//             'title': data['title'] ?? '',
//             'description': data['description'] ?? '',
//             'time': formattedTime,
//             'date': date,
//             'isNew': data['isNew'] ?? false,
//           };
//         }).toList();

//         // Group notifications by date
//         final groupedNotifications = groupByDate(notifications);

//         return ListView(
//           padding: const EdgeInsets.all(8.0),
//           children: groupedNotifications.entries.map((entry) {
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
//                   child: Text(
//                     entry.key,
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 ...entry.value.map((notification) {
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 4.0),
//                     child: ListTile(
//                       leading: const Icon(
//                         Icons.notifications,
//                         color: Colors.blueAccent,
//                       ),
//                       title: Text(
//                         notification['title'],
//                         style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(notification['description'], style: const TextStyle(color: Colors.black87)),
//                           const SizedBox(height: 4),
//                           Text(notification['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
//                         ],
//                       ),
//                       trailing: notification['isNew']
//                           ? const Icon(Icons.circle, color: Colors.red, size: 12)
//                           : const SizedBox.shrink(),
//                       onTap: () {
//                         // Mark notification as read
//                         FirebaseFirestore.instance
//                             .collection('notifications_collection')
//                             .doc(notification['id'])
//                             .update({'isNew': false});
//                       },
//                     ),
//                   );
//                 }),
//               ],
//             );
//           }).toList(),
//         );
//       },
//     );
//   }

//   // Helper function to group notifications by date
//   Map<String, List<Map<String, dynamic>>> groupByDate(List<Map<String, dynamic>> notifications) {
//     final today = DateTime.now();
//     final yesterday = today.subtract(const Duration(days: 1));

//     Map<String, List<Map<String, dynamic>>> grouped = {
//       'Today': [],
//       'Yesterday': [],
//       'Older': [],
//     };

//     for (var notification in notifications) {
//       DateTime date = notification['date'];
//       if (isSameDay(date, today)) {
//         grouped['Today']!.add(notification);
//       } else if (isSameDay(date, yesterday)) {
//         grouped['Yesterday']!.add(notification);
//       } else {
//         grouped['Older']!.add(notification);
//       }
//     }

//     return grouped;
//   }

//   // Helper function to check if two dates are on the same day
//   bool isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
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

//               return MessageCard(message: message);
//             },
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) => Center(child: Text("Error loading messages: $error")),
//       ),
//       floatingActionButton: FloatingActionButton(
//         shape: const CircleBorder(),
//         onPressed: () => _showSendMessageBottomSheet(context, ref),
//         backgroundColor: Colors.blueAccent,
//         child: const Icon(Icons.message, color: Colors.white),
//       ),
//     );
//   }
// }

// class MessageCard extends StatelessWidget {
//   final Map<String, dynamic> message;

//   const MessageCard({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       margin: const EdgeInsets.symmetric(vertical: 6.0),
//       child: ListTile(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ChatScreen(
//                 chatId: message['chatId'],
//                 senderName: message['sender'],
//                 profilePic: message['profilePic'],
//                 receiverId: message['receiverId'],
//               ),
//             ),
//           );
//         },
//         leading: CircleAvatar(
//           radius: 25,
//           backgroundImage: NetworkImage(message['profilePic']),
//         ),
//         title: Text(
//           message['sender'],
//           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
//         ),
//         subtitle: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 message['snippet'],
//                 style: const TextStyle(color: Colors.black87, fontSize: 12),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1,
//               ),
//             ),
//             Text(
//               formatTime(message['date']),
//               style: const TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//           ],
//         ),
//         trailing: message['unreadCount'] > 0
//             ? CircleAvatar(
//                 radius: 12,
//                 backgroundColor: Colors.red,
//                 child: Text(
//                   message['unreadCount'].toString(),
//                   style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                 ),
//               )
//             : const SizedBox.shrink(),
//       ),
//     );
//   }
// }

// void _showSendMessageBottomSheet(BuildContext context, WidgetRef ref) {

//   final firestore = FirebaseFirestore.instance;
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//   showModalBottomSheet(
//     showDragHandle: true,
//     isDismissible: true,
//     useSafeArea: true,
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//     ),
//     builder: (context) {
//       TextEditingController searchController = TextEditingController();
//       ValueNotifier<String> searchQueryNotifier = ValueNotifier<String>('');

//       return StatefulBuilder(
//         builder: (context, setState) {
//           return Column(
//             children: [
//               // Search bar
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TextField(
//                   controller: searchController,
//                   onChanged: (value) {
//                     searchQueryNotifier.value = value.trim().toLowerCase();
//                   },
//                   decoration: InputDecoration(
//                     hintText: 'Search by name or member number',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//               ),
//               // User List
//               Expanded(
//                 child: ValueListenableBuilder<String>(
//                   valueListenable: searchQueryNotifier,
//                   builder: (context, searchQuery, child) {
//                     return FutureBuilder<QuerySnapshot>(
//                       future: firestore.collection('users_members').get(),
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         if (snapshot.hasError) {
//                           return Center(child: Text("Error: ${snapshot.error}"));
//                         }

//                         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                           return const Center(child: Text("No users found."));
//                         }

//                         // Filter users: exclude the current user and apply search filter
//                         final allUsers = snapshot.data!.docs;
//                         final filteredUsers = allUsers.where((user) {
//                           final memNumber = user['mem_Number'] ?? '';
//                           final fullName =
//                               '${user['f_Name'] ?? ''} ${user['l_Name'] ?? ''}'.toLowerCase();
//                           return user.id != currentUserId &&
//                               (memNumber.contains(searchQuery) || fullName.contains(searchQuery));
//                         }).toList();

//                         if (filteredUsers.isEmpty) {
//                           return const Center(child: Text("No matching users found."));
//                         }

//                         return ListView.builder(
//                           padding: const EdgeInsets.all(8.0),
//                           itemCount: filteredUsers.length,
//                           itemBuilder: (context, index) {
//                             final user = filteredUsers[index];
//                             final userId = user.id;
//                             final memNumber = user['mem_Number'] ?? '';
//                             final fullName =
//                                 '${user['f_Name'] ?? ''} ${user['l_Name'] ?? ''}';
//                             final profilePic = user['avatar_Url'] ?? 'https://via.placeholder.com/50';

//                             return ListTile(
//                               leading: CircleAvatar(
//                                 backgroundImage: NetworkImage(profilePic),
//                               ),
//                               title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                               subtitle: Text('Member Number: $memNumber'),
//                               onTap: () async {
//                                 Navigator.pop(context); // Close the bottom sheet
//                                 await _handleUserSelection(
//                                     context, ref, userId, fullName, profilePic);
//                               },
//                             );
//                           },
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }

// Future<void> _handleUserSelection(
//     BuildContext context, WidgetRef ref, String receiverId, String receiverName, String profilePic) async {
//   final senderId = FirebaseAuth.instance.currentUser!.uid;
//   final firestore = FirebaseFirestore.instance;

//   try {
//     // Fetch current user's profile picture
//     final currentUserDoc = await firestore.collection('users_members').doc(senderId).get();
//     final senderProfilePic = currentUserDoc.exists
//         ? currentUserDoc['avatar_Url'] ?? 'https://via.placeholder.com/50'
//         : 'https://via.placeholder.com/50';


//       print('Current user profile picture: $senderProfilePic');
//     // Check if a chat already exists between the sender and receiver
//     final chatQuery = await firestore
//         .collection('chats_collection')
//         .where('users', arrayContains: senderId)
//         .get();

//     String? chatId;
//     for (var doc in chatQuery.docs) {
//       final chatUsers = doc.data()['users'] as List<dynamic>;
//       if (chatUsers.contains(receiverId)) {
//         chatId = doc.id;
//         break;
//       }
//     }

//     if (chatId == null) {
//       // Create a new chat if it doesn't exist
//       final newChatDoc = await firestore.collection('chats_collection').add({
//         'users': [senderId, receiverId],
//         'lastMessageTime': FieldValue.serverTimestamp(),
//         'unreadCounts': {receiverId: 0, senderId: 0},
//       });
//       chatId = newChatDoc.id;
//     }

//     // Navigate to the ChatScreen
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ChatScreen(
//           chatId: chatId!,
//           senderName: receiverName,
//           profilePic: profilePic,
//           receiverId: receiverId,
//         ),
//       ),
//     );
//   } catch (error) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Error: ${error.toString()}")),
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

// final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// final messagesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
//   final firestore = ref.watch(firestoreProvider);
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//   return firestore
//       .collection("chats_collection")
//       .where("users", arrayContains: currentUserId)
//       .orderBy("lastMessageTime", descending: true)
//       .snapshots()
//       .asyncMap((snapshot) async {
//     List<Map<String, dynamic>> messages = [];

//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       String chatId = doc.id;

//       var latestMessageSnapshot = await firestore
//           .collection("chats_collection")
//           .doc(chatId)
//           .collection("messages")
//           .orderBy("timestamp") // Order in ascending order
//           .get();

//       if (latestMessageSnapshot.docs.isEmpty) continue;

//       var latestMessage = latestMessageSnapshot.docs.last.data();
//       String senderId = latestMessage['senderId'] ?? '';
//       String receiverId = latestMessage['receiverId'] ?? '';

//       String displayedUserId;
//       if (senderId == currentUserId && receiverId.isNotEmpty) {
//         displayedUserId = receiverId;
//       } else if (receiverId == currentUserId && senderId.isNotEmpty) {
//         displayedUserId = senderId;
//       } else {
//         print("Error: Invalid IDs - senderId=$senderId, receiverId=$receiverId");
//         continue;
//       }

//       var userDoc = await firestore.collection('users_members').doc(displayedUserId).get();
//       String displayedName = userDoc.exists ? '${userDoc['f_Name']} ${userDoc['l_Name']}': 'Unknown';
//       String profilePic = userDoc.exists ? userDoc['avatar_Url'] ?? "https://via.placeholder.com/50" : "https://via.placeholder.com/50";

//       messages.add({
//         'chatId': chatId,
//         'sender': displayedName,
//         'profilePic': profilePic,
//         'snippet': latestMessage['text'] ?? "",
//         'unreadCount': (data['unreadCounts'] != null && data['unreadCounts'][currentUserId] != null) 
//                         ? data['unreadCounts'][currentUserId] : 0, // Ensure unread count is not null
//         'date': (latestMessage['timestamp'] as Timestamp).toDate(),
//         'receiverId': displayedUserId,
//         'isRead': latestMessage['isRead'] ?? false, // Add isRead field
//       });
//     }

//     return messages;
//   });
// });

// void _showSendMessageDialog(BuildContext context, WidgetRef ref) {
//   final TextEditingController memNumberController = TextEditingController();
//   final TextEditingController messageController = TextEditingController();
//   final senderId = FirebaseAuth.instance.currentUser!.uid;

//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text("Send Message"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: memNumberController,
//               decoration: const InputDecoration(labelText: "Enter Member Number"),
//             ),
//             TextField(
//               controller: messageController,
//               decoration: const InputDecoration(labelText: "Message"),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final memNumber = memNumberController.text.trim();
//               final text = messageController.text.trim();

//               if (memNumber.isEmpty || text.isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text("Please fill in all fields")),
//                 );
//                 return;
//               }

//               final firestore = FirebaseFirestore.instance;

//               try {
//                 // Search for the user with the given `mem_Number`
//                 final userQuery = await firestore
//                     .collection('members_users')
//                     .where('mem_Number', isEqualTo: memNumber)
//                     .get();

//                 final otherUserQuery = await firestore
//                     .collection('members_users')
//                     .where('mem_Number', isEqualTo: senderId)
//                     .get();

//                 if (userQuery.docs.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("User not found")),
//                   );
//                   return;
//                 }

//                 // Get the receiver's details
//                 final userDoc = userQuery.docs.first;
//                 final currentuserDoc = otherUserQuery.docs.first;
//                 final receiverId = userDoc.id; // User document ID
//                 final receiverName = userDoc['f_Name'] ?? 'Unknown';
//                 final profilePic = userDoc['avatar_Url'] ?? 'https://via.placeholder.com/50';
//                 final senderProfilePic = currentuserDoc['avatar_Url'] ?? 'https://via.placeholder.com/50';

//                 // Check if a chat already exists between the sender and receiver
//                 final chatQuery = await firestore
//                     .collection('chats_collection')
//                     .where('users', arrayContains: senderId)
//                     .get();

//                 String? chatId;
//                 for (var doc in chatQuery.docs) {
//                   final chatUsers = doc.data()['users'] as List<dynamic>;
//                   if (chatUsers.contains(receiverId)) {
//                     chatId = doc.id;
//                     break;
//                   }
//                 }

//                 if (chatId == null) {
//                   // Create a new chat if it doesn't exist
//                   final newChatDoc = await firestore.collection('chats_collection').add({
//                     'users': [senderId, receiverId],
//                     'lastMessageTime': FieldValue.serverTimestamp(),
//                     'unreadCounts': {receiverId: 0, senderId: 0},
//                   });
//                   chatId = newChatDoc.id;
//                 }

//                 // Send the message
//                 await firestore
//                     .collection('chats_collection')
//                     .doc(chatId)
//                     .collection('messages')
//                     .add({
//                   'senderId': senderId,
//                   'receiverId': receiverId,
//                   'text': text,
//                   'timestamp': FieldValue.serverTimestamp(),
//                   'isRead': false,
//                 });

//                 // Update the last message time and unread count
//                 await firestore.collection('chats_collection').doc(chatId).update({
//                   'lastMessageTime': FieldValue.serverTimestamp(),
//                   'unreadCounts.$receiverId': FieldValue.increment(1),
//                 });

//                 Navigator.pop(context); // Close the dialog

//                 // Navigate to the ChatScreen
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => ChatScreen(
//                       chatId: chatId!,
//                       senderName: receiverName,
//                       profilePic: profilePic,
//                       receiverId: receiverId,
//                     ),
//                   ),
//                 );
//               } catch (error) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text("Error: ${error.toString()}")),
//                 );
//               }
//             },
//             child: const Text("Send"),
//           ),
//         ],
//       );
//     },
//   );
// }



