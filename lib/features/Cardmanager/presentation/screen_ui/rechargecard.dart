import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/widgets/rechargescreenwidget.dart';

class CardRecharge extends ConsumerWidget {
  const CardRecharge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      //appBar: TopAppBar(),
      body: responsiveLayout(
        smallScreen: _buildSmallScreen(context, ref),
        mediumScreen: _buildMediumScreen(context, ref),
      ),
    );
  }

  Widget _buildSmallScreen(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // CommonTopContainer(
        //   title: 'CARD RECHARGE',
        //   Image_url: 'assets/images/common/calendar.png',
        //   titleposition: 120,
        // ),
        Expanded(
          child: SingleChildScrollView(
            child: RechargeCardScreen(),
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
