import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
import 'package:nrbgymkhana/features/common/widgets/sectionheader.dart';
import 'package:nrbgymkhana/features/common/widgets/homecenternavs.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/widgets/bottomsheet.dart' as bottom;

class SubsCatPage extends ConsumerWidget {
  final String category;

  const SubsCatPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        //  appBar: TopAppBar(),
          body:  SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: responsiveLayout(
          smallScreen: _buildSmallScreen(context, ref),
          mediumScreen: _buildMediumScreen(context, ref),
        ),
      ),
          ),
    );
  }

  Widget _buildSmallScreen(BuildContext context, WidgetRef ref) {
    final subItems = categoryData[category] ?? [];

    return Column(
      children: [
        CommonTopContainer(
          title: 'SUBSCRIPTIONS',
          Image_url: 'assets/images/common/calendar.png',
          titleposition: 125,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: SectionHeader(
            title: '$category Subscriptions',
            onSeeAll: () {},
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 16,
            children: subItems.map((subItem) {
              return SizedBox(
                width: MediaQuery.of(context).size.width / 3 - 20,
                child: CenterHomeNavs(
                  title: subItem['title'] ?? '',
                  icon: null,
                  imageurl: subItem['imageurl'] ?? '',
                  onTapped: () {
                    print('Tapped ${subItem['title']}');
                    final selectedFacilityId = subItem['title'];
                    ref.read(selectedFacilityProvider.notifier).state = selectedFacilityId.toString();
                    showPurchaseOptionsBottomSheet(context, ref, category);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumScreen(BuildContext context, WidgetRef ref) {
    return Center(
      child: SizedBox(
        width: 400,
        child: _buildSmallScreen(context, ref),
      ),
    );
  }
}

final Map<String, List<Map<String, String>>> categoryData = {
  'Club': [
    {'title': 'Annual Membership', 'imageurl': 'assets/images/subspage/member-card.png'},
    {'title': 'Yoga \nPractices', 'imageurl': 'assets/images/subspage/meditation.png'},
    {'title': 'Chess\n Practices', 'imageurl': 'assets/images/subspage/strategy.png'},
  ],
  'Gym': [
    {'title': 'Member & Spouse', 'imageurl': 'assets/images/subspage/couple.png'},
    {'title': 'Individual Member', 'imageurl': 'assets/images/subspage/individual.png'},
    {'title': 'Junior\n Member', 'imageurl': 'assets/images/subspage/juniors.png'},
  ],
};

void showPurchaseOptionsBottomSheet(BuildContext context, WidgetRef ref, String category) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isDismissible: true,
    enableDrag: true,
    useRootNavigator: true,
    builder: (_) => bottom.PurchaseOptionsBottomSheet(category: category),
  );
}

void resetProviders(WidgetRef ref) {
  ref.read(selectedFacilityProvider.notifier).state = '';
  ref.read(bottom.priceProvider.notifier).state = 'Ksh ...';
  ref.read(bottom.selectedTabProvider.notifier).state = 0;
}



// final subscriptionsByCategoryProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, category) async* {
//   // Assuming the user is logged in and you have access to the current user ID
//   final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';  // Replace with actual user ID from FirebaseAuth or your auth state
//   // Print the current user ID for troubleshooting

//   // First: Fetch the category document (e.g., Gym or Club)
//   final categorySnapshot = await FirebaseFirestore.instance
//       .collection('subs_Category')
//       .where('subs_Id', isEqualTo: category)  // Match the category (e.g., Gym, Club)
//       .limit(1)
//       .get();

//   if (categorySnapshot.docs.isEmpty) {
//     // Print if no category is found
//     yield [];  // No such category found
//     return;
//   }

//   final categoryDoc = categorySnapshot.docs.first;
//   final subsId = categoryDoc['subs_Id'];
//   // Print the category ID

//   // Second: Fetch all sub-categories linked to this category
//   final subCategorySnapshot = await FirebaseFirestore.instance
//       .collection('Subs_sub_Category')
//       .where('subs_Id', isEqualTo: subsId)  // Get all sub-categories for the category (e.g., Gym)
//       .get();

//   final subCategoryDocs = subCategorySnapshot.docs;
//   // Print number of sub-categories found

//   if (subCategoryDocs.isEmpty) {
//     // Print if no sub-categories are found
//     yield [];  // No sub-categories found for this category
//     return;
//   }

//   // Extract all subs_cat_Id's from the sub-category documents
//   final subsCatIds = subCategoryDocs.map((doc) => doc['sub_cat_Id']).toList();
//   // Print the sub-category IDs

//   // Third: Fetch all subscriptions for the found subs_cat_Ids where the user_id matches
//   final subscriptionsSnapshot = FirebaseFirestore.instance
//       .collection('subscriptions_collection')
//       .where('subs_cat_Id', whereIn: subsCatIds)  // Fetch subscriptions that match any subs_cat_Id from above
//       .where('user_Id', isEqualTo: currentUserId)   // Filter by the current user's user_Id
//       .snapshots();

//   await for (var snapshot in subscriptionsSnapshot) {  // Print number of fetched subscription items

// final subscriptionItems = snapshot.docs.map((doc) async {
//   final data = doc.data();
//   final subCatId = data['subs_cat_Id'];

//   // Fetch sub-category details
//   final subCategorySnapshot = await FirebaseFirestore.instance
//       .collection('Subs_sub_Category')
//       .where('sub_cat_Id', isEqualTo: subCatId)
//       .limit(1)
//       .get();

//   String subCategoryName = 'Unknown';
//   if (subCategorySnapshot.docs.isNotEmpty) {
//     final subCategoryDoc = subCategorySnapshot.docs.first;
//     subCategoryName = subCategoryDoc['name'] ?? 'Unknown';
//   }

//   return {
//     'subs_Plan': '${data['subs_Plan']} ($subCategoryName)',
//     'status': data['reaction']?['status'] ?? 'Pending',
//     'subs_Date': data['subs_Date'] as Timestamp?,
//     'amount': data['amount']?.toString() ?? '0',
//     'isPaid': data['reaction']?['isPaid'] ?? false,
//     'subs_cat_Id': subCatId ?? 'Unknown',
//   };
// }).toList();


//     yield await Future.wait(subscriptionItems);  // Wait for all async calls to complete
//   }
// });

