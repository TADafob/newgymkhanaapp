import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/homecenterpart.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/topcontainer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final actions = [
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
      'title': 'Transactions',
      'icon': Icons.data_usage_outlined,
      'image': 'assets/images/homescreen/subscription.png'
    },
  ];

  final actionRoutes = {
    'My Subs': '/subspage',
    'Book Facility': '/book-facility',
    'My Bookings': '/all-bookings',
    'Card Usage': '/card-history',
    'Top Up': '/top-up-card',
    'Transactions': '/card-manager',
  };

  final engagments = [
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
    // {
    //   'title': 'Messages',
    //   'icon': Icons.message_outlined,
    //   'image': 'assets/images/homescreen/Hire_facility.png',
    //   'ischatpage': true,
    // },
    {
      'title': 'News',
      'icon': Icons.newspaper_outlined,
      'image': 'assets/images/homescreen/topup.png'
    },
  ];

  final engagementsRoutes = {
    'Events': '/the-wall/Events-thewall',
    'Lost & Found': '/the-wall/lost-found-thewall',
    'Messages': '/chat/notifications?tab=1',
    'News': '/the-wall/noticeboard-thewall',
  };

  final otherservices = [
    {
      'title': 'Club Tour',
      'icon': Icons.map_outlined,
      'image': 'assets/images/homescreen/subscription.png'
    },
    {
      'title': 'FAQ\'s',
      'icon': Icons.question_mark_outlined,
      'image': 'assets/images/homescreen/Hire_facility.png'
    },
  ];

  final otherservicesRoutes = {
    'Club Tour': '/club-tour',
    'Q&A\'s': '/faq-page',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: TopAppBar(),
      body: SafeArea(
        child: responsiveLayout(
          smallScreen: _buildSmallScreen(),
          mediumScreen: _buildMediumScreen(),
        ),
      ),
    );
  }

  Widget _buildSmallScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TopHomeContainer(),
          HomeCenterPart(
            multi: true,
            title: 'Quick Actions',
            actions: actions,
            actionRoutes: actionRoutes,
          ),
          HomeCenterPart(
            title: 'Engagements',
            actions: engagments,
            actionRoutes: engagementsRoutes,
          ),
          HomeCenterPart(
            title: 'Other Services',
            actions: otherservices,
            actionRoutes: otherservicesRoutes,
          ),
          SizedBox(
            height: 20.h,
          )
        ],
      ),
    );
  }

  Widget _buildMediumScreen() {
    return Center(
      child: SizedBox(
        width: 400,
        child: _buildSmallScreen(),
      ),
    );
  }
}
