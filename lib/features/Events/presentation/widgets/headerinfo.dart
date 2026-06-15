import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

class HeaderInfo extends StatelessWidget {
  final String dateText;
  final String location;

  const HeaderInfo({
    super.key,
    required this.dateText,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.calendar_today, size: 18),
          SizedBox(width: 8.w),
          Text(dateText, style: TextStyle(color: AppKolors.secondary)),
        ]),
        SizedBox(height: 8.h),
        Row(children: [
          const Icon(Icons.location_on, size: 18),
          SizedBox(width: 8.w),
          Text(location, style: TextStyle(color: AppKolors.secondary)),
        ]),
      ],
    );
  }
}
