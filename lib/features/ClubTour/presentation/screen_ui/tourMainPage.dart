import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/ClubTour/presentation/widgets/tourcontent.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';

class ClubTourPage extends ConsumerWidget {
  const ClubTourPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Scaffold(
      //appBar: TopAppBar(),
      body: responsiveLayout(
        smallScreen: _buildSmallScreen(context),
        mediumScreen: _buildMediumScreen(context),
      ),
    );
  }

  Widget _buildSmallScreen(BuildContext context) {
    return ListView(
      children: [
        CommonTopContainer(
          title: 'CLUB TOUR', 
          Image_url: 'assets/images/common/calendar.png',
          titleposition: 130,),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: FeaturePage(),
      ),
    ]);
  }

  Widget _buildMediumScreen(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        child: _buildSmallScreen(context),
      ),
    );
  }
}
