import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/responsiveness.dart';
import 'package:nrbgymkhana/features/News/presentation/screen_ui/widgets/newswidget.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Scaffold(
      //appBar: TopAppBar(),
      body: responsiveLayout(
        smallScreen: _buildSmallScreen(),
        mediumScreen: _buildMediumScreen(),
      ),
    );
  }

  Widget _buildSmallScreen() {
    return Column(
      children: [
        CommonTopContainer(title: 'NEWS PAGE', 
        Image_url: 'assets/images/common/calendar.png',
        titleposition: 130,),
        NewsScreen(),
      ],
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
