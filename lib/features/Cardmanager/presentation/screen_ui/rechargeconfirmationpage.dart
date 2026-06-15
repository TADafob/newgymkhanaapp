import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/widgets/rechargeconfirmationwidget.dart';

class CardRechargeConfirmation extends ConsumerWidget {
  const CardRechargeConfirmation({super.key});

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
        Expanded(
          child: SingleChildScrollView(
            child: RechargeConfirmationWidget(),
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
