import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/topuppage.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/statement_page.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/homecenterpart.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/topcontainer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const actions = [
    {
      'title': 'My Subs',
      'icon': Icons.card_membership_outlined,
      'image': 'assets/images/homescreen/subscription.png'
    },
    {
      'title': 'Book Facility',
      'icon': Icons.edit_calendar_outlined,
      'image': 'assets/images/homescreen/Hire_facility.png'
    },
    {
      'title': 'My Bookings',
      'icon': Icons.calendar_month_outlined,
      'image': 'assets/images/homescreen/topup.png'
    },
    {
      'title': 'Card Usage',
      'icon': Icons.data_usage_outlined,
      'image': 'assets/images/homescreen/rooms.png'
    },
    {
      'title': 'Top Up',
      'icon': Icons.add_card_outlined,
      'image': 'assets/images/homescreen/badminton.png'
    },
    {
      'title': 'Card Statements',
      'icon': Icons.description_outlined,
      'image': 'assets/images/homescreen/subscription.png'
    },
  ];

  static const actionRoutes = {
    'My Subs': '/subspage',
    'Book Facility': '/book-facility',
    'My Bookings': '/all-bookings',
    'Card Usage': '/card-manager',
  };

  static const engagments = [
    {
      'title': 'Events',
      'icon': Icons.calendar_today_outlined,
      'image': 'assets/images/homescreen/subscription.png'
    },
    {
      'title': 'Lost & Found',
      'icon': Icons.backpack_outlined,
      'image': 'assets/images/homescreen/rooms.png'
    },
    {
      'title': 'News',
      'icon': Icons.newspaper_outlined,
      'image': 'assets/images/homescreen/topup.png'
    },
  ];

  static const engagementsRoutes = {
    'Events': '/the-wall/Events-thewall',
    'Lost & Found': '/the-wall/lost-found-thewall',
    'News': '/the-wall/noticeboard-thewall',
  };

  static const otherservices = [
    {
      'title': 'Club Tour',
      'icon': Icons.map_outlined,
      'image': 'assets/images/homescreen/subscription.png'
    },
    {
      'title': "FAQ's",
      'icon': Icons.question_mark_outlined,
      'image': 'assets/images/homescreen/Hire_facility.png'
    },
  ];

  static const otherservicesRoutes = {
    'Club Tour': '/club-tour',
    "FAQ's": '/faq-page',
  };

  Future<void> _refresh() async {
    ref.invalidate(userStreamProvider);
    ref.invalidate(cardStreamProvider);
    ref.invalidate(subsBadgeProvider);
    ref.invalidate(bookingsBadgeProvider);
    ref.invalidate(cardsBadgeProvider);
    ref.invalidate(noticesBadgeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final body = _buildBody(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF0F4F8),
      body: SafeArea(
        child: responsiveLayout(
          smallScreen: body,
          mediumScreen: Center(child: SizedBox(width: 420, child: body)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      color: AppKolors.primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: TopHomeContainer()),
          SliverToBoxAdapter(
            child: HomeCenterPart(
              multi: true,
              title: 'Quick Actions',
              subtitle: 'Manage your membership',
              actions: actions,
              actionRoutes: actionRoutes,
              actionCallbacks: {
                'Top Up': () => showTopUpDialog(context, ref),
                'Card Statements': () => showCardStatementSheet(context, ref),
              },
              accentColor: const Color(0xFF0693e3),
            ),
          ),
          SliverToBoxAdapter(
            child: HomeCenterPart(
              title: 'Engagements',
              subtitle: 'Stay connected with the club',
              actions: engagments,
              actionRoutes: engagementsRoutes,
              accentColor: const Color(0xFF07d8c3),
            ),
          ),
          SliverToBoxAdapter(
            child: HomeCenterPart(
              title: 'Other Services',
              subtitle: 'Explore more',
              actions: otherservices,
              actionRoutes: otherservicesRoutes,
              accentColor: const Color(0xFF7c3aed),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }
}
