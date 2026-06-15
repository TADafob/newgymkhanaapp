// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';
// import 'package:nrbgymkhana/tests/test4.dart';

// // Riverpod provider for user data
// final userProvider = Provider((ref) => {
//       "name": "Dalih Rusmana",
//       "profilePic": "assets/image/profile_pic.png",
//       "shipment": 5,
//       "transactions": 2,
//       "spending": 3,
//       "address": "Jl. Sekeloa Utara No. 11 Coblong, Kota Bandung",
//       "premiumPrice": "\$24.5/month"
//     });

// class ProfilePage extends ConsumerWidget {
//   const ProfilePage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final user = ref.watch(userProvider);

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           _buildTopTitle(title: 'Activities'),
//           SizedBox(height: 10,),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildStatCard("Active\nBookings", user["shipment"].toString()),
//               _buildStatCard("Transactions\nToday", user["transactions"].toString()),
//               _buildStatCard("Active\nSubscriptions", user["spending"].toString()),
//             ],
//           ),
//           SizedBox(height: 20),
//           _buildTopTitle(title: 'Account Settings'),
//           SizedBox(height: 10,),
//           _buildMenuOption(
//             icon: Icons.payment,
//             title: "Payment Methods",
//             onTap: () {},
//           ),
//           _buildMenuOption(
//             icon: Icons.settings,
//             title: "Account Settings",
//             onTap: () {},
//           ),
//           _buildMenuOption(
//             icon: Icons.contact_support,
//             title: "Report Issue",
//             onTap: () {
//               Navigator.push(context,
//                MaterialPageRoute(builder: (context)
//                => ContactSupportPage()));
//             },
//           ),
//           SizedBox(height: 20,),
//           _buildTopTitle(title: 'App Settings'),
//           SizedBox(height: 10,),
//           _buildMenuOption(
//             icon: Icons.settings,
//             title: "App Settings",
//             onTap: () {},
//           ),
//           // _buildMenuOption(
//           //   icon: Icons.location_on,
//           //   title: user["address"] as String,
//           //   trailing: "Map",
//           //   onTap: () {},
//           // ),
//              _buildMenuOption(
//             icon: Icons.support_agent,
//             title: "FAQ's",
//             onTap: () {},
//           ),
//           SizedBox(height: 20),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppKolors.primary.withValues(alpha: .4),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Having Problems?",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     Text('Call/Text 0708042394\nor send an email to\nTechsupport@nairobigymkhana.com', style: TextStyle(fontSize: 12),),
//                   ],
//                 ),
//                 ElevatedButton(
//                   style: ButtonStyle(
//                     backgroundColor: WidgetStatePropertyAll(Colors.blue),
//                   ),
//                   onPressed: () {},
//                   child: Text("Report", style: TextStyle(fontWeight: FontWeight.bold),),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 20),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 50),
//             child: ElevatedButton(
//               style: ButtonStyle(
//                 backgroundColor: WidgetStatePropertyAll(AppKolors.accent3),
//                 minimumSize: WidgetStatePropertyAll(Size(double.maxFinite, 40)),
//                 shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))
//               ),
//               onPressed: () {},
//               child: Text(
//                 "Log Out",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value) {
//     return Container(
//       height: 120,
//       width: 120,
//       decoration: BoxDecoration(
//         color: AppKolors.primary.withValues(alpha: .4),

//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             value,
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 4),
//           Text(
//             title,
//             style: TextStyle(color: Colors.grey, fontSize: 12),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuOption({
//     required IconData icon,
//     required String title,
//     String? trailing,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: AppKolors.primary),
//       title: Text(title),
//       trailing: trailing != null
//           ? Text(
//               trailing,
//               style: TextStyle(color: Colors.deepPurple),
//             )
//           : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//       onTap: onTap,
//     );
//   }
  
//   Widget _buildTopTitle({required String title,}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: TextStyle(fontSize: 16),),
//           Text('more', style: TextStyle(fontSize: 12, color: Colors.grey),)
//         ],
//       ),
//     );
//   }
// }
