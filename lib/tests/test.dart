// // ignore_for_file: library_private_types_in_public_api, unused_field

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:nrbgymkhana/tests/newtestlost.dart';

// class ChatScreen extends ConsumerStatefulWidget {
//   final String chatId;
//   final String senderName;
//   final String profilePic;
//   final String receiverId; // Add this parameter

//   const ChatScreen({
//     super.key,
//     required this.chatId,
//     required this.senderName,
//     required this.profilePic,
//     required this.receiverId,
//   });

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends ConsumerState<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   bool _isScreenActive = false;

//   @override
//   void initState() {
//     super.initState();
//     _isScreenActive = true;
//   }

//   @override
//   void dispose() {
//     _isScreenActive = false;
//     super.dispose();
//   }

//  void _sendMessage() {
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid;
//   final text = _messageController.text.trim();

//   if (text.isEmpty) return;

//   final chatDoc = FirebaseFirestore.instance.collection('chats_collection').doc(widget.chatId);

//   chatDoc.get().then((doc) {
//     if (doc.exists) {
//       var chatData = doc.data()!;
//       var unreadCounts = chatData['unreadCounts'];

//       // Initialize unread counts if not already present
//       if (unreadCounts == null) {
//         unreadCounts = {
//           currentUserId: 0,
//           widget.receiverId: 0,
//         };
//         chatDoc.update({'unreadCounts': unreadCounts});
//       }

//       // Add the message with correct senderId and receiverId
//       chatDoc.collection('messages').add({
//         'senderId': currentUserId, // Current user sending the message
//         'receiverId': widget.receiverId, // Receiver is the other user
//         'text': text,
//         'timestamp': Timestamp.now(),
//         'isRead': false,
//       });

//       // Increment unread count for the receiver
//       chatDoc.update({
//         'unreadCounts.${widget.receiverId}': FieldValue.increment(1),
//       });
//     }
//   });

//   _messageController.clear();
// }

//  @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Row(
//         children: [
//           CircleAvatar(
//             backgroundImage: NetworkImage(widget.profilePic), // Sender's profile pic
//           ),
//           const SizedBox(width: 10),
//           Text(widget.senderName),
//         ],
//       ),
//     ),
//     body: Column(
//       children: [
//         Expanded(
//           child: Consumer(
//             builder: (context, ref, child) {
//               final chatAsync = ref.watch(chatProvider(widget.chatId));
//               return chatAsync.when(
//                 data: (chat) {
//                   if (chat.isEmpty) {
//                     return const Center(
//                       child: Text(
//                         "No messages yet!",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     );
//                   }

//                   // Reset unread messages
//                   _markMessagesAsRead(chat);
                  

//                   return  ListView.builder(
//   padding: const EdgeInsets.all(8.0),
//   itemCount: chat.length,
//   itemBuilder: (context, index) {
//     final message = chat[index];
//     final isUserMessage = message['senderId'] == FirebaseAuth.instance.currentUser!.uid;
//     final profilePic = isUserMessage ? null : widget.profilePic;

//     // Convert timestamp to DateTime
//     DateTime messageDate = message['timestamp'].toDate();
//     String formattedDate = "${messageDate.day}-${messageDate.month}-${messageDate.year}";

//     // Track last displayed date
//     bool showDateHeader = false;
//     if (index == 0 || formattedDate != "${chat[index - 1]['timestamp'].toDate().day}-${chat[index - 1]['timestamp'].toDate().month}-${chat[index - 1]['timestamp'].toDate().year}") {
//       showDateHeader = true;
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         if (showDateHeader) // Display date separator only when needed
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: Text(
//               formattedDate,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//         Align(
//           alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               if (!isUserMessage) ...[
//                 CircleAvatar(
//                   radius: 15,
//                   backgroundImage: NetworkImage(profilePic ?? 'https://via.placeholder.com/50'),
//                 ),
//                 const SizedBox(width: 8),
//               ],
//               ConstrainedBox(
//                 constraints: BoxConstraints(
//                   maxWidth: MediaQuery.of(context).size.width * 0.7, // Limit width to 70% of screen
//                 ),
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   margin: const EdgeInsets.symmetric(vertical: 4),
//                   decoration: BoxDecoration(
//                     color: isUserMessage ? Colors.green[300] : Colors.grey[300],
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Text(message['text']),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: isUserMessage ? 10 : 43),
//           child: Row(
//             mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               Text(
//                 _formatTimestamp(message['timestamp']),
//                 style: const TextStyle(fontSize: 12, color: Colors.black54),
//               ),
//               if (isUserMessage) ...[
//                 const SizedBox(width: 5),
//                 Icon(
//                   Icons.done_all,
//                   size: 18,
//                   color: message['isRead'] ? Colors.blue : Colors.grey,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   },
// );


//                 },
//                 loading: () => const Center(child: CircularProgressIndicator()),
//                 error: (error, stack) =>
//                     Center(child: Text("Error loading messages: $error")),
//               );
//             },
//           ),
//         ),
//         // Message Input Area
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.image),
//                 onPressed: () => _showMediaOptions(context),
//               ),
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                     borderRadius: BorderRadius.circular(30)
//                   ),
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: const InputDecoration(
//                       border: OutlineInputBorder(borderSide: BorderSide.none),
//                       hintText: "Type a message"),
//                   ),
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.send),
//                 onPressed: _sendMessage,
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }


// void _markMessagesAsRead(List<dynamic> chat) {
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid;
//   final chatDoc = FirebaseFirestore.instance.collection('chats_collection').doc(widget.chatId);

//   chatDoc.update({
//     'unreadCounts.$currentUserId': 0,
//   });

//   for (var message in chat) {
//     if (message['receiverId'] == currentUserId && !message['isRead']) {
//       FirebaseFirestore.instance
//           .collection('chats_collection')
//           .doc(widget.chatId)
//           .collection('messages')
//           .doc(message['messageId']) // Use a proper message ID
//           .update({'isRead': true});
//     }
//   }
// }



// final chatProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
//   final firestore = ref.watch(firestoreProvider);

//   return firestore
//       .collection("chats_collection")
//       .doc(chatId)
//       .collection("messages")
//       .orderBy("timestamp")
//       .snapshots()
//       .map((snapshot) {
//         final currentUserId = FirebaseAuth.instance.currentUser!.uid;

//         // Update read status only for the current user
//         for (var doc in snapshot.docs) {
//           if (doc['receiverId'] == currentUserId && !doc['isRead']) {
//             doc.reference.update({'isRead': true});
//           }
//         }

//         return snapshot.docs.map((doc) => doc.data()).toList();
//       });
// });

// void _showMediaOptions(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     builder: (context) {
//       return SizedBox(
//         height: 200,
//         child: Column(
//           children: [
//             ListTile(
//               leading: Icon(Icons.photo),
//               title: Text('Photo'),
//               onTap: () {
//                 // Add logic for photo selection
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.videocam),
//               title: Text('Video'),
//               onTap: () {
//                 // Add logic for video selection
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.attach_file),
//               title: Text('File'),
//               onTap: () {
//                 // Add logic for file selection
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }
// void createNewChat(String chatId, String currentUserId, String receiverId) {
//   FirebaseFirestore.instance.collection('chats_collection').doc(chatId).set({
//     'users': [currentUserId, receiverId],
//     'unreadCounts': {
//       currentUserId: 0,
//       receiverId: 0,
//     },
//     'lastMessageTime': Timestamp.now(), // Or whenever you want to initialize it
//   });
// }
// }
// String _formatTimestamp(Timestamp timestamp) {
//   DateTime dateTime = timestamp.toDate();
//   return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
// }

