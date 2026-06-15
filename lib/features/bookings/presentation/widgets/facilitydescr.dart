import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/features/bookings/presentation/providers/bookings_provider.dart';

class FacilityDescription extends ConsumerWidget {
  final String facilityName;

  const FacilityDescription({super.key, required this.facilityName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityDataAsync = ref.watch(allFacilitiesProvider);

    return facilityDataAsync.when(
      data: (facilitiesMap) {
        final normalizedKey = facilityName.toLowerCase();
        final description = facilitiesMap[normalizedKey]?['description'] ?? 
            "Information for this facility is not available.";

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'About the Facility',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.sp),
                ),
                SizedBox(height: 10.h),
                Divider(indent: 10.w, endIndent: 10.w),
                SizedBox(height: 10.h),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading description: $error',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}