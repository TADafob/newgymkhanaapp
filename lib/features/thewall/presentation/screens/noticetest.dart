// // lib/main.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
// import 'package:carousel_slider/carousel_slider.dart';

// // New (correct)
// final _carouselController = CarouselSliderController();


// // --- Model ---
// class Notice {
//   final String id;
//   final String title;
//   final String author;
//   final DateTime date;
//   final String details;
//   final List<String> tags;
//   final List<String> imageUrls;
//   final IconData icon;

//   Notice({
//     required this.id,
//     required this.title,
//     required this.author,
//     required this.date,
//     required this.details,
//     required this.tags,
//     this.imageUrls = const [],
//     required this.icon,
//   });

//   factory Notice.fromDoc(DocumentSnapshot doc) {
//     final data = doc.data()! as Map<String, dynamic>;
//     return Notice(
//       id: doc.id,
//       title: data['title'] as String,
//       author: data['author'] as String,
//       date: (data['date'] as Timestamp).toDate(),
//       details: data['details'] as String,
//       tags: List<String>.from(data['tags'] as List),
//       imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
//       icon: Icons.campaign,
//     );
//   }
// }


// // --- Firestore-backed provider ---
// final noticeListProvider = StreamProvider<List<Notice>>((ref) {
//   return FirebaseFirestore.instance
//       .collection('notices')
//       .orderBy('date', descending: true)
//       .snapshots()
//       .map((snap) => snap.docs.map((d) => Notice.fromDoc(d)).toList());
// });


// // --- Notice List Screen ---
// class NoticeListScreen extends ConsumerWidget {
//   const NoticeListScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final noticesAsync = ref.watch(noticeListProvider);

//     return Scaffold(
//       body: Column(
//         children: [
//           CommonTopContainer(
//             title: 'Club Notices',
//             Image_url: 'assets/images/common/calendar.png',
//             titleposition: 140.w,
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 // Filters row (left as an exercise)
//                 Row(
//                   children: [
//                     const Icon(Icons.filter_list, color: Colors.black54),
//                     const SizedBox(width: 8),
//                     const Text('Filter', style: TextStyle(color: Colors.black54)),
//                     const Spacer(),
//                     _DropdownButton(label: 'Month'),
//                     const SizedBox(width: 8),
//                     _DropdownButton(label: 'Year'),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 noticesAsync.when(
//                   data: (notices) => Expanded(
//                     child: ListView.builder(
//                       itemCount: notices.length,
//                       itemBuilder: (_, i) => NoticeCard(notice: notices[i]),
//                     ),
//                   ),
//                   loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
//                   error: (e, _) => Expanded(child: Center(child: Text('Error: $e'))),
//                 ),
//               ]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class NoticeCard extends StatelessWidget {
//   final Notice notice;
//   const NoticeCard({required this.notice, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => NoticeDetailScreen(notice: notice),
//         ),
//       ),
//       child: Card(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.only(bottom: 12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             // 1) Title
//             Text(
//               notice.title,
//               style: TextStyle(fontSize: 18.w, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),

//             // 2) Faded image “peek”
//               if (notice.imageUrls.isNotEmpty) 
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: SizedBox(
//                     height: 80.h,
//                     width: double.infinity,
//                     child: ShaderMask(
//                       shaderCallback: (rect) => const LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.transparent,
//                           Colors.black,
//                           Colors.black,
//                           Colors.transparent,
//                         ],
//                         stops: [0.0, 0.1, 0.9, 1.0],
//                       ).createShader(rect),
//                       blendMode: BlendMode.dstIn,
//                       child: CarouselSlider.builder(
//                         carouselController: _carouselController,
//                         itemCount: notice.imageUrls.length,
//                         itemBuilder: (_, idx, __) => Image.network(
//                           notice.imageUrls[idx],
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                         ),
//                         options: CarouselOptions(
//                           viewportFraction: 1.0,
//                           enableInfiniteScroll: false,
//                           scrollPhysics: BouncingScrollPhysics(),
                          
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//             const SizedBox(height: 8),

//             // 3) Description snippet
//             Text(
//               notice.details,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 8),
//             Row(children: [
//               const Icon(Icons.person, size: 16, color: Colors.black54),
//               const SizedBox(width: 4),
//               Text(notice.author,
//                   style: const TextStyle(color: Colors.black54)),
//               const SizedBox(width: 16),
//               const Icon(Icons.calendar_today,
//                   size: 16, color: Colors.black54),
//               const SizedBox(width: 4),
              
//             ]),
//             const SizedBox(height: 12),
//             Row(
//                 children: notice.tags
//                     .map((tag) => Container(
//                           margin: const EdgeInsets.only(right: 8),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: _tagColor(tag).withValues(alpha: 0.2),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(tag,
//                               style:
//                                   TextStyle(color: _tagColor(tag), fontSize: 12)),
//                         ))
//                     .toList()),
//             const SizedBox(height: 8),
//              Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
//                        SizedBox(width: 16.w),
                      
//                  Text(
//                     '${notice.date.day.toString().padLeft(2, '0')} ${_monthName(notice.date.month)}, ${notice.date.year}',
//                     style: const TextStyle(color: Colors.black54),
//                   ),
//                ],
//                   ),
//                   const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
//                 ],
//              ),
//           ]),
//         ),
//       ),
//     );
//   }
// }

// // --- Notice Detail Screen ---
// class NoticeDetailScreen extends StatefulWidget {
//   final Notice notice;
//   const NoticeDetailScreen({super.key, required this.notice});

//   @override
//   _NoticeDetailScreenState createState() => _NoticeDetailScreenState();
// }
// class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
//   bool _hasReacted = false;
//   String? _myReaction; // 'like' or 'dislike'
//   int _likes = 0, _dislikes = 0;
//   final _user = FirebaseAuth.instance.currentUser!;

//   @override
//   void initState() {
//     super.initState();
//     _loadReactions();
//   }

//   Future<void> _loadReactions() async {
//     final doc = FirebaseFirestore.instance
//         .collection('notices')
//         .doc(widget.notice.id);
//     final snap = await doc.get();
//     final data = snap.data()!;
//     // Read aggregate counts
//     _likes = (data['likesCount'] ?? 0) as int;
//     _dislikes = (data['dislikesCount'] ?? 0) as int;
//     // Check if this user already reacted
//     final myReactDoc = await doc
//         .collection('reactions')
//         .doc(_user.uid)
//         .get();
//     if (myReactDoc.exists) {
//       _hasReacted = true;
//       _myReaction = myReactDoc.data()!['type'] as String;
//     }
//     setState(() {});
//   }

//   Future<void> _react(String type) async {
//     if (_hasReacted) return;
//     final noticeRef = FirebaseFirestore.instance
//         .collection('notices')
//         .doc(widget.notice.id);

//     await FirebaseFirestore.instance.runTransaction((tx) async {
//       final snapshot = await tx.get(noticeRef);
//       if (!snapshot.exists) throw Exception("Notice gone!");
//       final data = snapshot.data()!;
//       final likes = data['likesCount'] ?? 0;
//       final dislikes = data['dislikesCount'] ?? 0;
//       // Update aggregate
//       tx.update(noticeRef, {
//         if (type == 'like') 'likesCount': likes + 1,
//         if (type == 'dislike') 'dislikesCount': dislikes + 1,
//       });
//       // Record user reaction
//       tx.set(
//         noticeRef.collection('reactions').doc(_user.uid),
//         {'type': type, 'timestamp': FieldValue.serverTimestamp()},
//       );
//     });

//     // Optimistically update UI
//     setState(() {
//       _hasReacted = true;
//       _myReaction = type;
//       if (type == 'like') _likes++;
//       else _dislikes++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final n = widget.notice;
//     return Scaffold(
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child:
//                   Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Row(children: [
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(n.icon, color: Colors.blue),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                       child: Text(n.title,
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.w600))),
//                 ]),
//                 const SizedBox(height: 12),
//                 Row(children: [
//                   const Icon(Icons.person, size: 16, color: Colors.black54),
//                   const SizedBox(width: 4),
//                   Text(n.author,
//                       style: const TextStyle(color: Colors.black54)),
//                   const SizedBox(width: 16),
//                   const Icon(Icons.calendar_today,
//                       size: 16, color: Colors.black54),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${n.date.day.toString().padLeft(2, '0')} ${_monthName(n.date.month)}, ${n.date.year}',
//                     style: const TextStyle(color: Colors.black54),
//                   ),
//                 ]),
//                 SizedBox(height: 12.h),
//                 ...[
//                 const SizedBox(height: 16),
//                 Stack(
//                   children: [
//                     CarouselSlider.builder(
//                       carouselController: _carouselController,
//                       itemCount: n.imageUrls.length,
//                       itemBuilder: (_, idx, __) => GestureDetector(
//                         onTap: () {
//                           // full-screen dialog
//                           showDialog(
//                             context: context,
//                             builder: (_) => Dialog(
//                               insetPadding: EdgeInsets.zero,
//                               backgroundColor: Colors.black,
//                               child: InteractiveViewer(
//                                 child: Image.network(
//                                   n.imageUrls[idx],
//                                   fit: BoxFit.contain,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: Image.network(
//                             n.imageUrls[idx],
//                             width: double.infinity,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       options: CarouselOptions(
//                         height: 200,                // peek height in detail
//                         viewportFraction: 1.0,
//                         enableInfiniteScroll: false,
//                         enlargeCenterPage: false,
//                         scrollPhysics: BouncingScrollPhysics(),
//                       ),
//                     ),

//                     // Left-arrow
//                     if (n.imageUrls.length > 1)
//                       Positioned(
//                         left: 8,
//                         top: 0,
//                         bottom: 0,
//                         child: IconButton(
//                           icon: Icon(Icons.chevron_left, size: 32, color: Colors.white70),
//                           onPressed: () => _carouselController.previousPage(
//                             duration: Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                           ),
//                         ),
//                       ),

//                     // Right-arrow
//                     if (n.imageUrls.length > 1)
//                       Positioned(
//                         right: 8,
//                         top: 0,
//                         bottom: 0,
//                         child: IconButton(
//                           icon: Icon(Icons.chevron_right, size: 32, color: Colors.white70),
//                           onPressed: () => _carouselController.nextPage(
//                             duration: Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                           ),
//                         ),
//                       ),
//                   ],
//     ),
//   ],
//                 const SizedBox(height: 16),
//                 const Text('Notice Details',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 8),
//                 Text(n.details, style: const TextStyle(height: 1.5)),
//                 const SizedBox(height: 16),
//                 Row(
//                     children: n.tags
//                         .map((tag) => Container(
//                               margin: const EdgeInsets.only(right: 8),
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: _tagColor(tag).withValues(alpha: 0.2),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(tag,
//                                   style:
//                                       TextStyle(color: _tagColor(tag), fontSize: 12)),
//                             ))
//                         .toList()),
//                 const SizedBox(height: 24),
//               ]),
//             ),
//           ),
//           // Reaction Center
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _ReactionButton(
//                     icon: Icons.thumb_up,
//                     label: '$_likes',
//                     enabled: !_hasReacted,
//                     onTap: () => _react('like'),
//                     active: _myReaction == 'like',
//                   ),
//                   const SizedBox(width: 32),
//                   _ReactionButton(
//                     icon: Icons.thumb_down,
//                     label: '$_dislikes',
//                     enabled: !_hasReacted,
//                     onTap: () => _react('dislike'),
//                     active: _myReaction == 'dislike',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- Widgets & Helpers ---
// class _ReactionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool enabled;
//   final VoidCallback onTap;
//   final bool active;

//   const _ReactionButton({
//     required this.icon,
//     required this.label,
//     required this.enabled,
//     required this.onTap,
//     required this.active,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: enabled ? onTap : null,
//       child: Opacity(
//         opacity: enabled ? 1.0 : 0.6,
//         child: Row(
//           children: [
//             Icon(icon, size: 28, color: active ? Colors.blue : Colors.black54),
//             const SizedBox(width: 8),
//             Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//           ],
//         ),
//       ),
//     );
//   }
// }


// class _DropdownButton extends StatelessWidget {
//   final String label;
//   const _DropdownButton({required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.blue),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(children: [
//         Text(label, style: const TextStyle(color: Colors.blue)),
//         const Icon(Icons.arrow_drop_down, color: Colors.blue),
//       ]),
//     );
//   }
// }


// Color _tagColor(String tag) {
//   switch (tag.toLowerCase()) {
//     case 'important':
//       return Colors.red;
//     case 'gym':
//       return Colors.purple;
//     case 'payments':
//       return Colors.orange;
//     case 'random':
//       return Colors.teal;
//     default:
//       return Colors.grey;
//   }
// }

// String _monthName(int month) {
//   const names = [
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December'
//   ];
//   return names[month - 1];
// }
