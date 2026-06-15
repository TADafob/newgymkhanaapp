// class PurchaseOptionsBottomSheet extends ConsumerStatefulWidget {
//   final String category; // Gym or Club

//   const PurchaseOptionsBottomSheet({
//     super.key,
//     required this.category,
//   });

//   @override
//   ConsumerState<PurchaseOptionsBottomSheet> createState() =>
//       _PurchaseOptionsBottomSheetState();
// }

// class _PurchaseOptionsBottomSheetState
//     extends ConsumerState<PurchaseOptionsBottomSheet> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   // Determine subscription plans based on category
//   List<Map<String, dynamic>> getPlans() {
//     if (widget.category == 'Gym') {
//       return [
//         {'name': 'Monthly', 'duration': 31, 'id': 'Gym_Monthly'},
//         {'name': 'Quarterly', 'duration': 120, 'id': 'Gym_Quarterly'},
//         {'name': 'Semi-Annual', 'duration': 180, 'id': 'Gym_Semi'},
//         {'name': 'Annual', 'duration': 365, 'id': 'Gym_Annual'},
//       ];
//     } else if (widget.category == 'Club') {
//       return [
//         {'name': 'Annual', 'duration': 365, 'id': 'Club_Annual'},
//       ];
//     }
//     return [];
//   }

//   Future<void> _onContinue() async {
//     if (_currentPage < 1) {
//       setState(() {
//         _currentPage++;
//       });
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     } else {
//       // Save data to Firestore based on the selected plan
//       try {
//         final selectedTab = ref.read(selectedTabProvider);
//         final price = ref.read(priceProvider);
//         final userId = FirebaseAuth.instance.currentUser!.uid;

//         final plans = getPlans();
//         final selectedPlan = plans[selectedTab];

//         DateTime expiryDate = DateTime.now().add(
//           Duration(days: selectedPlan['duration']),
//         );

//         await FirebaseFirestore.instance.collection('subscriptions_collection').add({
//           'amount': int.parse(price.replaceAll(RegExp(r'[^\d]'), '')),
//           'expiry_Date': expiryDate,
//           'reaction': {
//             'isPaid': false,
//             'reacted_By': '',
//             'reaction_Date': '',
//             'reaction_Id': '',
//             'status': 'Unconfirmed',
//           },
//           'subs_Date': DateTime.now(),
//           'subs_Id': 'Subs_${DateTime.now().millisecondsSinceEpoch}',
//           'subs_Plan': widget.category,
//           'subs_cat_Id': selectedPlan['id'],
//           'user_Id': userId,
//         });

//         // Show success dialog
//         showResultDialog(context, true);
//       } catch (e) {
//         // Show failure dialog
//         showResultDialog(context, false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedTab = ref.watch(selectedTabProvider);
//     final price = ref.watch(priceProvider);
//     final plans = getPlans();

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
//             Expanded(
//               child: PageView(
//                 controller: _pageController,
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: [
//                   Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             "Choose Plan Option",
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close),
//                             onPressed: () => Navigator.pop(context),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // Tabs based on plans
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: List.generate(
//                           plans.length,
//                           (index) => _buildTabButton(
//                             context,
//                             ref,
//                             plans[index]['name'],
//                             index,
//                             selectedTab,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       _buildSlideshow(),
//                       const SizedBox(height: 8),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: _buildTabContent(selectedTab, ref),
//                         ),
//                       ),
//                     ],
//                   ),
//                   _buildConfirmationPage(plans[selectedTab]),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: _currentPage == 0
//                   ? ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8)),
//                       ),
//                       onPressed: _onContinue,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             "Continue",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           Text(
//                             price,
//                             style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8)),
//                       ),
//                       onPressed: _onContinue,
//                       child: const Text(
//                         "Send Request",
//                         style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white),
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildConfirmationPage(Map<String, dynamic> selectedPlan) {
//     final price = ref.read(priceProvider);
//     final selectedFacility = ref.read(selectedFacilityProvider);

//     return Center(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Confirm Details for ${widget.category}",
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           Text("Plan: ${selectedPlan['name']}"),
//           Text("Price: $price"),
//           Text("Category: ${widget.category}"),
//           // Additional details here
//         ],
//       ),
//     );
//   }
// }
