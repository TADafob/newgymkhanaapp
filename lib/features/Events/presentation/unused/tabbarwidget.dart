// import 'package:flutter/material.dart';
// import 'package:nrbgymkhana/core/utils/appcolors.dart';

// class TabbarWidget extends StatelessWidget {
//   const TabbarWidget({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3, // Number of tabs
//       child: Scaffold(
//         body: Column(
//           children: [
//             // Sticky SliverAppBar for the tabs
//             Flexible(
//               child: NestedScrollView(
//                 headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
//                   return [
//                     SliverAppBar(
//                       pinned: true,
//                       expandedHeight: 150.0,
//                       flexibleSpace: FlexibleSpaceBar(
//                         title: Text(
//                           "Events",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       bottom: TabBar(
//                         labelColor: AppKolors.secondary,
//                         unselectedLabelColor: Colors.black,
//                         labelStyle: TextStyle(fontSize: 18),
//                         unselectedLabelStyle: TextStyle(fontSize: 14),
//                         indicator: UnderlineTabIndicator(
//                           borderRadius: BorderRadius.circular(120),
//                           borderSide: BorderSide(
//                             color: AppKolors.accent3,
//                             width: 3,
//                           ),
//                           insets: EdgeInsets.symmetric(horizontal: 16.0),
//                         ),
//                         tabs: [
//                           Tab(child: Text('Upcoming')),
//                           Tab(child: Text('Booked')),
//                           Tab(child: Text('Cancelled')),
//                         ],
//                       ),
//                     ),
//                   ];
//                 },
//                 body: TabBarView(
//                   children: [
//                     // Add proper constraints to prevent infinite size issues
//                     ListView.builder(
//                       itemCount: 4,
//                       itemBuilder: (BuildContext context, int index) {
//                         return ListTile(
//                           title: Text("DIWALI 2024"),
//                           leading: Image.network(
//                               'https://yogatalk.com/wp-content/uploads/2024/09/image_2024_09_18T13_09_47_119Z.png'),
//                           subtitle: Text(
//                               "Diwali, also known as Deepavali, is one of the most celebrated festivals in India and among Hindus worldwide."),
//                         );
//                       },
//                     ),
//                     ListView.builder(
//                       itemCount: 4,
//                       itemBuilder: (BuildContext context, int index) {
//                         return ListTile(
//                           title: Text("Event Booked"),
//                           leading: Icon(Icons.bookmark),
//                           subtitle: Text("Event is already booked."),
//                         );
//                       },
//                     ),
//                     Center(
//                       child: Text("No Cancelled Events"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
