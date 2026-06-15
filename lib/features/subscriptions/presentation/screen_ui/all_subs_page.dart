import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/widgets/shimmer_widgets.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
import 'package:nrbgymkhana/features/common/widgets/nodatawidget.dart';
import 'package:nrbgymkhana/features/common/widgets/dateformat.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/screen_ui/subspage.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/widgets/renew_subs_dialog.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/widgets/subscard.dart';
import 'package:nrbgymkhana/features/subscriptions/data/model/subsmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AllSubscriptionsPage extends ConsumerWidget {
  const AllSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final subscriptionsAsync = ref.watch(subscriptionsProvider(userId));
    final subCategoriesAsync = ref.watch(subsCategoryProvider);
    final mainCategoriesAsync = ref.watch(subsMainCategoryProvider);

    return subscriptionsAsync.when(
      data: (subscriptions) {
        return subCategoriesAsync.when(
          data: (subCategories) {
            return mainCategoriesAsync.when(
              data: (mainCategories) {
                final now = DateTime.now();
                final activeSubs = subscriptions
                    .where((sub) => sub.expiryDate.isAfter(now))
                    .toList();
                final expiredSubs = subscriptions
                    .where((sub) => !sub.expiryDate.isAfter(now))
                    .toList();

                // Sort by subscription date (newest first)
                activeSubs.sort((a, b) => b.subsDate.compareTo(a.subsDate));
                expiredSubs.sort((a, b) => b.subsDate.compareTo(a.subsDate));

                return DefaultTabController(
                  length: 2,
                  child: Scaffold(
                      body: Column(
                    children: [
                      CommonTopContainer(
                          title: 'All Subscriptions',
                          Image_url: 'assets/images/common/calendar.png',
                          titleposition: 120),
                      SizedBox(height: 10.h),
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Scaffold(
                            body: Column(
                              children: [
                                // place your TabBar here instead
                                TabBar(
                                  indicatorColor: AppKolors.secondary,
                                  unselectedLabelStyle: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  labelColor: AppKolors.secondary,
                                  dividerColor: Colors.transparent,
                                  unselectedLabelColor: Colors.black54,
                                  tabs: [
                                    Tab(text: 'Active'),
                                    Tab(text: 'Expired'),
                                  ],
                                ),
                                // now the content:
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _buildSubscriptionsTab(
                                          activeSubs,
                                          subCategories,
                                          mainCategories,
                                          true,
                                          ref,
                                          context),
                                      _buildSubscriptionsTab(
                                          expiredSubs,
                                          subCategories,
                                          mainCategories,
                                          false,
                                          ref,
                                          context),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                );
              },
              loading: () => const PageShimmer(itemCount: 4),
              error: (err, _) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const PageShimmer(itemCount: 4),
          error: (err, _) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const PageShimmer(itemCount: 5),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSubscriptionsTab(
      List<Subscription> subsList,
      Map<String, Map<String, String>> subCategories,
      Map<String, String> mainCategories,
      bool isActiveTab,
      WidgetRef ref,
      BuildContext context) {
    if (subsList.isEmpty) {
      return Center(
        child: nodatawidget(
          title:
              'You currently don\'t have any \n${isActiveTab ? 'Active' : 'Expired'} subscriptions.',
        ),
      );
    }

    // Group subscriptions by month
    final groupedMap = <String, List<Subscription>>{};
    for (var sub in subsList) {
      final date = sub.subsDate;
      final monthKey = DateFormat('MMMM yyyy').format(date);
      groupedMap.putIfAbsent(monthKey, () => []);
      groupedMap[monthKey]!.add(sub);
    }

    // Sort months in descending order (latest first)
    final sortedMonths = groupedMap.keys.toList()
      ..sort((a, b) {
        final aDate = DateFormat('MMMM yyyy').parse(a);
        final bDate = DateFormat('MMMM yyyy').parse(b);
        return bDate.compareTo(aDate); // Descending
      });

    // Build the list of widgets
    List<Widget> items = [];

    for (var month in sortedMonths) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            month,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      final monthSubs = groupedMap[month]!;
      for (var subscription in monthSubs) {
        final subCategory = subCategories[subscription.subsCatId] ?? {};
        final subCategoryName = subCategory['name'] ?? 'Unknown Subcategory';
        final mainCategoryId = subCategory['subs_Id'] ?? '';
        final mainCategoryName =
            mainCategories[mainCategoryId] ?? 'Unknown Category';
        final displayTitle = "${subscription.subsPlan} ($subCategoryName)";
        final displayType = mainCategoryName;

        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SubscriptionCard(
              title: displayTitle,
              status: subscription.status,
              datePaid: formatDateWithSuffix(subscription.subsDate),
              amount: subscription.amount.toString(),
              substype: displayType,
              isActive: isActiveTab,
              onRenew: !isActiveTab && subscription.docId.isNotEmpty
                  ? () => showRenewSubsDialog(
                        context,
                        ref,
                        subsDocId: subscription.docId,
                        title: displayTitle,
                        amount: subscription.amount,
                        subsCatId: subscription.subsCatId,
                        expiryDate: subscription.expiryDate,
                      )
                  : null,
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        ref.invalidate(subscriptionsProvider(userId));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: items,
      ),
    );
  }
}
