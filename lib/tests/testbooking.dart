// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final selectedTabProvider = StateProvider<int>((ref) => 0); // To track the selected tab
// final priceProvider = StateProvider<String>((ref) {
//   return 'Ksh ...';
// });

// class PurchaseOptionsBottomSheet extends ConsumerStatefulWidget {
//   const PurchaseOptionsBottomSheet({super.key});

//   @override
//   ConsumerState<PurchaseOptionsBottomSheet> createState() => _PurchaseOptionsBottomSheetState();
// }

// class _PurchaseOptionsBottomSheetState extends ConsumerState<PurchaseOptionsBottomSheet> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   void _onContinue() {
//     if (_currentPage < 1) {
//       setState(() {
//         _currentPage++;
//       });
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     } else {
//       Navigator.pop(context); // Close bottom sheet or navigate as needed
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedTab = ref.watch(selectedTabProvider);
//     final price = ref.watch(priceProvider);

//     return GestureDetector(
//       onTap: () {},
//       child: Container(
//         height: 600,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   "Choose Plan Option",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),

//             // Tab Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildTabButton(context, ref, "Monthly", 0, selectedTab),
//                 _buildTabButton(context, ref, "Quarterly", 1, selectedTab),
//                 _buildTabButton(context, ref, "Semi-Annual", 2, selectedTab),
//                 _buildTabButton(context, ref, "Annual", 3, selectedTab),
//               ],
//             ),
//             const SizedBox(height: 16),

//             Expanded(
//               child: PageView(
//                 controller: _pageController,
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: [
//                   Column(
//                     children: [
//                       _buildSlideshow(),
//                       const SizedBox(height: 8),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: _buildTabContent(selectedTab, ref),
//                         ),
//                       ),
//                     ],
//                   ),
//                   _buildConfirmationPage(),
//                 ],
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   minimumSize: const Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 onPressed: _onContinue,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "Continue",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     Text(
//                       _currentPage == 0 ? price : "Confirm",
//                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

//   Widget _buildConfirmationPage() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: const [
//           Text(
//             "Confirmation Page",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 10),
//           Text(
//             "Review your selection and proceed.",
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 14, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabButton(
//       BuildContext context, WidgetRef ref, String label, int index, int selectedTab) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           ref.read(selectedTabProvider.notifier).state = index;
//           _updatePrice(ref, index);
//         },
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: selectedTab == index ? Colors.blue[200] : Colors.transparent,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Center(
//                 child: Text(
//                   label,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: selectedTab == index ? 12.5 : 10,
//                     fontWeight: FontWeight.bold,
//                     color: selectedTab == index ? Colors.black : Colors.grey,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 4),
//             Container(
//               height: 2,
//               width: double.infinity,
//               color: selectedTab == index ? Colors.redAccent : Colors.transparent,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSlideshow() {
//     // Slideshow logic remains unchanged
//   }

//   Widget _buildTabContent(int selectedTab, WidgetRef ref) {
//     // Tab content logic remains unchanged
//   }

//   void _updatePrice(WidgetRef ref, int selectedTab) {
//     // Update price logic remains unchanged
//   }
// }
