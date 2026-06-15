import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingconfirmation.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/bookingselection.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/facilitydescr.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/sheetexitmessage.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/moderncard.dart';
import 'package:nrbgymkhana/features/bookings/presentation/widgets/test.dart';
import 'package:intl/intl.dart';
import 'package:nrbgymkhana/core/utils/africas_talking_service.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:collection/collection.dart';

void showDatePickerBottomSheet(
  BuildContext context,
  WidgetRef ref,
  String imageUrl,
  List<String> images,
  String facilityNames, {
  int initialPage = 0,
}) {
  final PageController pageController =
      PageController(initialPage: initialPage);
  final facilityId = ref.read(selectedFacilityProvider);

  showModalBottomSheet(
      context: context,
      enableDrag: false,
      showDragHandle: true,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final confirmed = await showExitConfirmationDialog(context);
              if (confirmed ?? false) {
                Navigator.pop(context);
              }
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollCtrl) => Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: PageView(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // ===== STEP 1: Facility Details =====
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Text('Facility Booking',
                                    style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 16.h),
                                ImageCarousel(
                                    images: images,
                                    fallbackImageUrl: imageUrl,
                                    facilityName:
                                        facilityNames.replaceAll('\n', ' ')),
                                SizedBox(height: 8.h),
                                FacilityDescription(
                                    facilityName:
                                        facilityNames.replaceAll('\n', ' ')),
                                SizedBox(height: 16.h),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12.h, horizontal: 20.w),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              ref.invalidate(disabledDatesProvider(facilityId));
                              pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Next',
                                    style: TextStyle(
                                        color: AppKolors.background,
                                        fontSize: 16.sp)),
                                SizedBox(width: 8.w),
                                Icon(Icons.keyboard_arrow_right_outlined,
                                    color: AppKolors.background),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ===== STEP 2: Date Selection (multi-select) =====
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollCtrl,
                            child: Consumer(
                              builder: (context, ref, _) {
                                final disabledDatesAsync =
                                    ref.watch(disabledDatesProvider(facilityId));
                                final selectedDates =
                                    ref.watch(clubSelectedDatesProvider);
                                return disabledDatesAsync.when(
                                  loading: () => const Center(
                                      child: CircularProgressIndicator()),
                                  error: (e, st) => const Center(
                                      child: Text('Error loading dates')),
                                  data: (disabledDates) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Step 1: Select Date(s)',
                                          style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Tap individual dates to select. Tap again to deselect.',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600),
                                      ),
                                      SizedBox(height: 10.h),
                                      // Selected dates chips
                                      if (selectedDates.isNotEmpty)
                                        Wrap(
                                          spacing: 6.w,
                                          runSpacing: 4.h,
                                          children: selectedDates
                                              .sorted((a, b) =>
                                                  a.compareTo(b))
                                              .map((d) => Chip(
                                                    label: Text(
                                                      DateFormat('d MMM')
                                                          .format(d),
                                                      style: TextStyle(
                                                          fontSize: 12.sp),
                                                    ),
                                                    deleteIcon: const Icon(
                                                        Icons.close,
                                                        size: 14),
                                                    onDeleted: () {
                                                      final updated = [
                                                        ...selectedDates
                                                      ]..removeWhere((x) =>
                                                          x.year == d.year &&
                                                          x.month == d.month &&
                                                          x.day == d.day);
                                                      ref
                                                          .read(
                                                              clubSelectedDatesProvider
                                                                  .notifier)
                                                          .state = updated;
                                                    },
                                                    backgroundColor:
                                                        AppKolors.secondary
                                                            .withValues(
                                                                alpha: 0.15),
                                                  ))
                                              .toList(),
                                        )
                                      else
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.h, horizontal: 12.w),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'No dates selected yet',
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 13.sp),
                                          ),
                                        ),
                                      SizedBox(height: 12.h),
                                      SizedBox(
                                        height: 260.h,
                                        child: SfDateRangePicker(
                                          todayHighlightColor:
                                              AppKolors.secondary,
                                          enablePastDates: false,
                                          selectionColor: AppKolors.secondary,
                                          rangeSelectionColor: AppKolors
                                              .secondary
                                              .withValues(alpha: 0.2),
                                          selectionMode:
                                              DateRangePickerSelectionMode
                                                  .multiple,
                                          initialSelectedDates: selectedDates,
                                          onSelectionChanged: (args) {
                                            if (args.value
                                                is List<DateTime>) {
                                              final picked = (args.value
                                                      as List<DateTime>)
                                                  .where((d) => !disabledDates
                                                      .any((blocked) =>
                                                          blocked.year ==
                                                              d.year &&
                                                          blocked.month ==
                                                              d.month &&
                                                          blocked.day ==
                                                              d.day))
                                                  .toList();
                                              final blocked = (args.value
                                                      as List<DateTime>)
                                                  .where((d) =>
                                                      disabledDates.any(
                                                          (blocked) =>
                                                              blocked.year ==
                                                                  d.year &&
                                                              blocked.month ==
                                                                  d.month &&
                                                              blocked.day ==
                                                                  d.day))
                                                  .toList();
                                              if (blocked.isNotEmpty) {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        'Some selected dates are unavailable and were skipped',
                                                    backgroundColor:
                                                        Colors.orange,
                                                    textColor: Colors.white);
                                              }
                                              ref
                                                  .read(
                                                      clubSelectedDatesProvider
                                                          .notifier)
                                                  .state = picked.map((d) { final local = d.toLocal(); return DateTime(local.year, local.month, local.day); }).toList();
                                            }
                                          },
                                          monthViewSettings:
                                              DateRangePickerMonthViewSettings(
                                                  blackoutDates: disabledDates),
                                          monthCellStyle:
                                              DateRangePickerMonthCellStyle(
                                            blackoutDatesDecoration:
                                                BoxDecoration(
                                                    color: Colors.grey.shade300,
                                                    shape: BoxShape.circle),
                                            blackoutDateTextStyle: TextStyle(
                                                color: Colors.red,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 14.sp),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: Row(
                            children: [
                              Expanded(
                                  child: ElevatedButton.icon(
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white),
                                      label: const Text('Back',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      onPressed: () =>
                                          pageController.previousPage(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut),
                                      style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5.h),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          foregroundColor: Colors.red,
                                          backgroundColor:
                                              Colors.redAccent.shade100))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: ElevatedButton.icon(
                                      iconAlignment: IconAlignment.end,
                                      icon: const Icon(Icons.refresh,
                                          color: Colors.white),
                                      label: const Text('Refresh',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      onPressed: () => ref.invalidate(
                                          disabledDatesProvider(facilityId)),
                                      style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5.h),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          backgroundColor: AppKolors.primary))),
                              SizedBox(width: 8.w),
                              Expanded(
                                  child: ElevatedButton.icon(
                                      icon: const Icon(Icons.arrow_forward_ios,
                                          color: Colors.white),
                                      label: const Text('Next',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.h),
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10))),
                                      onPressed: () {
                                        final dates = ref
                                            .read(clubSelectedDatesProvider);
                                        if (dates.isEmpty) {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please select at least one date',
                                              backgroundColor: Colors.red,
                                              textColor: Colors.white);
                                        } else {
                                          pageController.nextPage(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut);
                                        }
                                      })),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ===== STEP 3: Time Selection =====
                    Consumer(
                      builder: (context, ref, _) {
                        final startTime = ref.watch(clubStartTimeProvider);
                        final endTime = ref.watch(clubEndTimeProvider);
                        final dates = ref.watch(clubSelectedDatesProvider);
                        final sorted = dates.sorted((a, b) => a.compareTo(b));
                        final firstDate = sorted.isNotEmpty
                            ? DateFormat('d MMM').format(sorted.first)
                            : '--';
                        final lastDate = sorted.isNotEmpty
                            ? DateFormat('d MMM').format(sorted.last)
                            : '--';
                        final isMultiDay = sorted.length > 1;
                        String Function(TimeOfDay?) fmt;
                        fmt = (TimeOfDay? t) =>
                            t == null ? '--:-- --' : t.format(context);
                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollCtrl,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 8.h),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Step 2: Select Timings',
                                        style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4.h),
                                    Text(
                                      isMultiDay
                                          ? 'Start time is on $firstDate, end time is on $lastDate.'
                                          : 'Choose the start and end time for your booking.',
                                      style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade600),
                                    ),
                                    SizedBox(height: 24.h),
                                    // Start time tile
                                    _TimePickerTile(
                                      label: isMultiDay
                                          ? 'Start Time  ($firstDate)'
                                          : 'Start Time',
                                      icon: Icons.schedule_outlined,
                                      value: fmt(startTime),
                                      isSet: startTime != null,
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: startTime ??
                                              const TimeOfDay(
                                                  hour: 8, minute: 0),
                                          helpText: 'Select Start Time',
                                        );
                                        if (picked != null) {
                                          ref
                                              .read(clubStartTimeProvider.notifier).state = picked;
                                          // for single-day only: clear end if now invalid
                                          if (!isMultiDay) {
                                            final end = ref
                                                .read(clubEndTimeProvider);
                                            if (end != null &&
                                                _timeToMinutes(end) <=
                                                    _timeToMinutes(picked)) {
                                              ref
                                                  .read(clubEndTimeProvider
                                                      .notifier)
                                                  .state = null;
                                            }
                                          }
                                        }
                                      },
                                    ),
                                    SizedBox(height: 16.h),
                                    // End time tile
                                    _TimePickerTile(
                                      label: isMultiDay
                                          ? 'End Time  ($lastDate)'
                                          : 'End Time',
                                      icon: Icons.schedule,
                                      value: fmt(endTime),
                                      isSet: endTime != null,
                                      onTap: () async {
                                        final start =
                                            ref.read(clubStartTimeProvider);
                                        if (start == null) {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please select a start time first',
                                              backgroundColor: Colors.orange,
                                              textColor: Colors.white);
                                          return;
                                        }
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: endTime ??
                                              TimeOfDay(
                                                  hour: (start.hour + 1)
                                                      .clamp(0, 23),
                                                  minute: start.minute),
                                          helpText: 'Select End Time',
                                        );
                                        if (picked != null) {
                                          // single-day: end must be after start
                                          if (!isMultiDay &&
                                              _timeToMinutes(picked) <=
                                                  _timeToMinutes(start)) {
                                            Fluttertoast.showToast(
                                                msg:
                                                    'End time must be after start time',
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white);
                                          } else {
                                            ref
                                                .read(clubEndTimeProvider.notifier).state = picked;
                                          }
                                        }
                                      },
                                    ),
                                    SizedBox(height: 28.h),
                                    // Summary
                                    if (startTime != null && endTime != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.h, horizontal: 16.w),
                                        decoration: BoxDecoration(
                                          color: AppKolors.secondary
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppKolors.secondary
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.timelapse,
                                                color: AppKolors.secondary,
                                                size: 18.w),
                                            SizedBox(width: 8.w),
                                            Text(
                                              isMultiDay
                                                  ? '$firstDate ${fmt(startTime)}  →  $lastDate ${fmt(endTime)}'
                                                  : 'Duration: ${_formatDuration(_timeToMinutes(endTime) - _timeToMinutes(startTime))}',
                                              style: TextStyle(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppKolors.secondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.w),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: ElevatedButton.icon(
                                          icon: const Icon(Icons.arrow_back,
                                              color: Colors.white),
                                          label: const Text('Back',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          onPressed: () =>
                                              pageController.previousPage(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut),
                                          style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 5.h),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              foregroundColor: Colors.red,
                                              backgroundColor: Colors
                                                  .redAccent.shade100))),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                      child: ElevatedButton.icon(
                                          iconAlignment: IconAlignment.end,
                                          icon: const Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.white),
                                          label: const Text('Next',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.h),
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          onPressed: () {
                                            final s = ref
                                                .read(clubStartTimeProvider);
                                            final e =
                                                ref.read(clubEndTimeProvider);
                                            if (s == null || e == null) {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      'Please select both start and end times',
                                                  backgroundColor: Colors.red,
                                                  textColor: Colors.white);
                                            } else {
                                              pageController.nextPage(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut);
                                            }
                                          })),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // ===== STEP 4: Extra Info =====
                    Consumer(
                      builder: (context, ref, _) {
                        final catererType =
                            ref.watch(clubCatererTypeProvider);
                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollCtrl,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 8.h),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Step 3: Additional Details',
                                        style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16.h),

                                    // ── Guests ──
                                    _SectionHeader(
                                        icon: Icons.people_outline_rounded,
                                        title: 'Event Details',
                                        color: AppKolors.primary),
                                    SizedBox(height: 12.h),
                                    _StyledInputCard(
                                      icon: Icons.people_outline_rounded,
                                      child: LabeledInput(
                                          label: 'Number of Guests Attending',
                                          hintText: 'e.g. 50',
                                          initialValue: ref.watch(
                                              selectedNoOfAttendeesProvider),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => ref
                                              .read(
                                                  selectedNoOfAttendeesProvider
                                                      .notifier)
                                              .state = v),
                                    ),
                                    SizedBox(height: 12.h),
                                    _StyledInputCard(
                                      icon: Icons.celebration_outlined,
                                      child: LabeledInput(
                                          label: 'Purpose of Booking',
                                          hintText:
                                              'Birthday, Wedding, Meeting…',
                                          initialValue: ref
                                              .watch(reasonForBookingProvider),
                                          onChanged: (v) => ref
                                              .read(reasonForBookingProvider
                                                  .notifier)
                                              .state = v),
                                    ),
                                    SizedBox(height: 20.h),

                                    // ── Caterers ──
                                    _SectionHeader(
                                        icon:
                                            Icons.restaurant_menu_outlined,
                                        title: 'Caterers',
                                        color: AppKolors.secondary),
                                    SizedBox(height: 10.h),
                                    // type selector chips
                                    Wrap(
                                      spacing: 8.w,
                                      children: [
                                        _CatererChip(
                                          label: 'Internal – Food',
                                          value: 'internal_food',
                                          selected:
                                              catererType == 'internal_food',
                                          onTap: () => ref
                                              .read(clubCatererTypeProvider
                                                  .notifier)
                                              .state = catererType ==
                                                  'internal_food'
                                              ? ''
                                              : 'internal_food',
                                        ),
                                        _CatererChip(
                                          label: 'Internal – Drinks',
                                          value: 'internal_drinks',
                                          selected: catererType ==
                                              'internal_drinks',
                                          onTap: () => ref
                                              .read(clubCatererTypeProvider
                                                  .notifier)
                                              .state = catererType ==
                                                  'internal_drinks'
                                              ? ''
                                              : 'internal_drinks',
                                        ),
                                        _CatererChip(
                                          label: 'External',
                                          value: 'external',
                                          selected: catererType == 'external',
                                          onTap: () => ref
                                              .read(clubCatererTypeProvider
                                                  .notifier)
                                              .state =
                                              catererType == 'external'
                                                  ? ''
                                                  : 'external',
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    // internal food options
                                    if (catererType == 'internal_food')
                                      _InternalCatererPicker(
                                        options: const [
                                          "Mum's Magic",
                                          'Munch 254'
                                        ],
                                        provider: clubCatererNameProvider,
                                      ),
                                    // internal drinks options
                                    if (catererType == 'internal_drinks')
                                      _InternalCatererPicker(
                                        options: const [
                                          'Dhostana Ventures'
                                        ],
                                        provider: clubCatererNameProvider,
                                      ),
                                    // external — free text
                                    if (catererType == 'external')
                                      _StyledInputCard(
                                        icon: Icons.storefront_outlined,
                                        child: LabeledInput(
                                            label: 'External Caterer Name',
                                            hintText:
                                                'Enter caterer name',
                                            initialValue: ref
                                                .watch(clubCatererNameProvider),
                                            optional: true,
                                            onChanged: (v) => ref
                                                .read(clubCatererNameProvider
                                                    .notifier)
                                                .state = v),
                                      ),
                                    SizedBox(height: 20.h),

                                    // ── Special Requests ──
                                    _SectionHeader(
                                        icon: Icons.star_outline_rounded,
                                        title: 'Special Requests',
                                        color: Colors.orange),
                                    SizedBox(height: 12.h),
                                    _StyledInputCard(
                                      icon: Icons.star_outline_rounded,
                                      child: LabeledInput(
                                          label: 'Any special requests?',
                                          hintText:
                                              'Balloons, decorations, AV setup…',
                                          initialValue: ref
                                              .watch(specialrequestsProvider),
                                          optional: true,
                                          onChanged: (v) => ref
                                              .read(specialrequestsProvider
                                                  .notifier)
                                              .state = v),
                                    ),
                                    SizedBox(height: 24.h),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton.icon(
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.white),
                                        label: const Text('Back',
                                            style: TextStyle(
                                                color: Colors.white)),
                                        onPressed: () =>
                                            pageController.previousPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut),
                                        style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5.h),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            foregroundColor: Colors.red,
                                            backgroundColor:
                                                Colors.redAccent.shade100))),
                                SizedBox(width: 8.w),
                                Expanded(
                                    child: ElevatedButton.icon(
                                        iconAlignment: IconAlignment.end,
                                        icon: const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white),
                                        label: const Text('Review',
                                            style: TextStyle(
                                                color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8.h),
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10))),
                                        onPressed: () {
                                          final attendees = ref.read(
                                              selectedNoOfAttendeesProvider);
                                          final reason = ref
                                              .read(reasonForBookingProvider);
                                          if (attendees.trim().isEmpty) {
                                            Fluttertoast.showToast(
                                                msg:
                                                    'Please enter number of guests',
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white);
                                            return;
                                          }
                                          if (reason.trim().isEmpty) {
                                            Fluttertoast.showToast(
                                                msg:
                                                    'Please enter purpose of booking',
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white);
                                            return;
                                          }
                                          pageController.nextPage(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut);
                                        })),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    // ===== STEP 5: Confirmation =====
                    Consumer(
                      builder: (context, ref, _) {
                        final dates =
                            ref.watch(clubSelectedDatesProvider);
                        final startTime =
                            ref.watch(clubStartTimeProvider);
                        final endTime = ref.watch(clubEndTimeProvider);
                        final attendees =
                            ref.watch(selectedNoOfAttendeesProvider);
                        final reason =
                            ref.watch(reasonForBookingProvider);
                        final requests =
                            ref.watch(specialrequestsProvider);
                        final catererType =
                            ref.watch(clubCatererTypeProvider);
                        final catererName =
                            ref.watch(clubCatererNameProvider);
                        final catererDisplay = catererType.isEmpty
                            ? 'None'
                            : catererName.isEmpty
                                ? catererType
                                    .replaceAll('_', ' ')
                                    .toUpperCase()
                                : catererName;
                        final sortedDates =
                            dates.sorted((a, b) => a.compareTo(b));
                        final datesDisplay = sortedDates
                            .map((d) => DateFormat('d MMM').format(d))
                            .join(', ');
                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollCtrl,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 8.h),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Step 4: Confirm Booking',
                                        style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4.h),
                                    Text(
                                        'Please review your booking details before submitting.',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600)),
                                    SizedBox(height: 16.h),
                                    ConfirmationRow(
                                        title: 'Facility',
                                        value: facilityNames
                                            .replaceAll('\n', ' ')),
                                    ConfirmationRow(
                                        title: 'Date(s)',
                                        value: datesDisplay),
                                    ConfirmationRow(
                                        title: 'Time',
                                        value: startTime != null &&
                                                endTime != null
                                            ? sortedDates.length > 1
                                                ? '${DateFormat('d MMM').format(sortedDates.first)} ${startTime.format(context)}  →  ${DateFormat('d MMM').format(sortedDates.last)} ${endTime.format(context)}'
                                                : '${startTime.format(context)} – ${endTime.format(context)}'
                                            : '--'),
                                    ConfirmationRow(
                                        title: 'Guests',
                                        value: attendees),
                                    ConfirmationRow(
                                        title: 'Purpose',
                                        value: reason),
                                    ConfirmationRow(
                                        title: 'Caterer',
                                        value: catererDisplay),
                                    ConfirmationRow(
                                        title: 'Special Requests',
                                        value: requests.isEmpty
                                            ? 'None'
                                            : requests),
                                    SizedBox(height: 16.h),
                                    Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.orange.shade200),
                                      ),
                                      child: Text(
                                        'Cancellation Policy: Bookings can be cancelled up to 48 hours before the event. A 50% fee applies for late cancellations.',
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.orange.shade800),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: 24.h),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton.icon(
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.white),
                                        label: const Text('Back',
                                            style: TextStyle(
                                                color: Colors.white)),
                                        onPressed: () =>
                                            pageController.previousPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut),
                                        style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5.h),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            foregroundColor: Colors.red,
                                            backgroundColor:
                                                Colors.redAccent.shade100))),
                                SizedBox(width: 8.w),
                                Expanded(
                                    child: ElevatedButton.icon(
                                        iconAlignment: IconAlignment.end,
                                        icon: const Icon(Icons.send,
                                            color: Colors.white),
                                        label: const Text('Send Request',
                                            style: TextStyle(
                                                color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8.h),
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10))),
                                        onPressed: () async {
                                          final success =
                                              await _submitBooking(
                                                  context, ref, facilityNames.replaceAll('\n', ' '));
                                          if (success && context.mounted) {
                                            resetAllProviders(ref);
                                            Navigator.pop(context, true);
                                          }
                                        })),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          )).then((result) {
    if (result != true) {
      resetAllProviders(ref);
      Fluttertoast.showToast(
          msg: 'Booking process canceled. Your changes were not saved.',
          backgroundColor: Colors.orange,
          textColor: Colors.white);
    }
  });
}

class LegendItem extends StatelessWidget {
  final Widget icon;
  final String label;
  const LegendItem({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      icon,
      SizedBox(width: 8.w),
      Text(label, style: TextStyle(fontSize: 14.sp))
    ]);
  }
}

class ConfirmationRow extends StatelessWidget {
  final String title;
  final String value;
  const ConfirmationRow({super.key, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.check_circle, color: AppKolors.secondary, size: 16.w),
            SizedBox(width: 6.w),
            Expanded(
                child: Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    softWrap: true,
                    maxLines: null))
          ]),
          SizedBox(height: 4.h),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Text(value,
                  style: TextStyle(fontSize: 15.sp),
                  softWrap: true,
                  maxLines: null))
        ]));
  }
}

Future<bool> _submitBooking(BuildContext context, WidgetRef ref, String facilityNames) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(
          msg: 'Not logged in. Please sign in and try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return false;
    }
    final userId = user.uid;
    final facilityId = ref.read(selectedFacilityProvider);
    final dates = ref.read(clubSelectedDatesProvider);
    final startTime = ref.read(clubStartTimeProvider);
    final endTime = ref.read(clubEndTimeProvider);

    if (facilityId.isEmpty || dates.isEmpty || startTime == null || endTime == null) {
      Fluttertoast.showToast(
          msg: 'Missing booking details. Please go back and check.',
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return false;
    }

    final attendees = ref.read(selectedNoOfAttendeesProvider);
    final reason = ref.read(reasonForBookingProvider);
    final requests = ref.read(specialrequestsProvider);
    final catererType = ref.read(clubCatererTypeProvider);
    final catererName = ref.read(clubCatererNameProvider);
    final catererDisplay = catererType.isEmpty
        ? 'None'
        : catererName.isEmpty
            ? catererType.replaceAll('_', ' ')
            : catererName;

    // one booking doc per selected date
    // first date: startTime → midnight, last date: midnight → endTime
    // middle dates (if any): startTime → endTime (full span)
    final sortedDates = dates.sorted((a, b) => a.compareTo(b));
    final batch = firestore.batch();
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final datePart = DateFormat('yyyyMMdd').format(date); final bookingId = 'CLB_\${facilityId}_\${datePart}_\$i';
      final DateTime start;
      final DateTime end;
      if (sortedDates.length == 1) {
        // single date: use exact times
        start = DateTime(
            date.year, date.month, date.day, startTime.hour, startTime.minute);
        end = DateTime(
            date.year, date.month, date.day, endTime.hour, endTime.minute);
      } else if (i == 0) {
        // first date: starts at startTime, ends at midnight
        start = DateTime(
            date.year, date.month, date.day, startTime.hour, startTime.minute);
        end = DateTime(date.year, date.month, date.day, 23, 59);
      } else if (i == sortedDates.length - 1) {
        // last date: starts at midnight, ends at endTime
        start = DateTime(date.year, date.month, date.day, 0, 0);
        end = DateTime(
            date.year, date.month, date.day, endTime.hour, endTime.minute);
      } else {
        // middle dates: full day
        start = DateTime(date.year, date.month, date.day, 0, 0);
        end = DateTime(date.year, date.month, date.day, 23, 59);
      }
      batch.set(firestore.collection('bookings_collection').doc(bookingId), {
        'facility_Id': facilityId,
        'date_Booked': Timestamp.now(),
        'facility_Type': 'Club',
        'court_No': '',
        'booking_Id': bookingId,
        'booking_Date': Timestamp.fromDate(start),
        'start_Time': Timestamp.fromDate(start),
        'end_Time': Timestamp.fromDate(end),
        'user_Id': userId,
        'booking_Reason': reason,
        'no_of_Attendees': attendees,
        'special_Requests': requests,
        'catering': catererDisplay,
        'reaction': {
          'reaction_Id': '',
          'reaction_Date': null,
          'status': 'Unconfirmed',
          'isPaid': false,
          'reacted_By': ''
        },
      });
    }
    await batch.commit();

    // SMS + WhatsApp — fire and forget
    firestore.collection('users_members').doc(userId).get().then((userDoc) async {
      final phone = userDoc.data()?['phone_Number']?.toString() ?? '';
      final userName = userDoc.data()?['f_Name']?.toString() ?? 'Member';
      if (phone.isNotEmpty) {
        final dateRange = sortedDates.length == 1
            ? DateFormat('d MMM').format(sortedDates.first)
            : '${DateFormat('d MMM').format(sortedDates.first)} – ${DateFormat('d MMM').format(sortedDates.last)}';
        try {
          await AfricasTalkingService.sendClubBookingRequest(
              phone: phone, userName: userName, facilityName: facilityNames, dateRange: dateRange);
        } catch (_) {}
        try {
          await AfricasTalkingService.sendClubBookingRequest(
              phone: phone,
              userName: userName,
              facilityName: facilityNames,
              dateRange: dateRange,
              channel: ATChannel.whatsapp);
        } catch (_) {}
      }
    }, onError: (e) => debugPrint('User fetch error: $e'));

    if (context.mounted) {
      await GeneralDialog(context, ref,
          isSuccess: true,
          isSports: false,
          message:
              'Booking request successfully sent.\nPlease await confirmation from the club.\nA copy has been shared to your WhatsApp.');
    }
    return true;
  } catch (e) {
    Fluttertoast.showToast(
        msg: 'Booking failed: ${e.toString().replaceAll('Exception: ', '')}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG);
    if (context.mounted) {
      await GeneralDialog(context, ref,
          isSuccess: false,
          isSports: false,
          message: 'Sorry, we couldn\'t send your booking request.\nPlease try again later.');
    }
    return false;
  }
}

void resetAllProviders(WidgetRef ref) {
  ref.read(clubSelectedDatesProvider.notifier).state = [];
  ref.read(clubStartTimeProvider.notifier).state = null;
  ref.read(clubEndTimeProvider.notifier).state = null;
  ref.read(clubCatererTypeProvider.notifier).state = '';
  ref.read(clubCatererNameProvider.notifier).state = '';
  ref.read(selectedNoOfAttendeesProvider.notifier).state = '';
  ref.read(reasonForBookingProvider.notifier).state = '';
  ref.read(specialrequestsProvider.notifier).state = '';
  ref.read(dateFromProvider.notifier).state = null;
  ref.read(dateToProvider.notifier).state = null;
  ref.read(cateringProvider.notifier).state = '';
  ref.read(disabledDatesStateProvider.notifier).state = [];
}

// ===== Time helpers =====

int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

String _formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}min';
  if (m == 0) return '${h}h';
  return '${h}h ${m}min';
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isSet;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.isSet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: isSet
              ? AppKolors.secondary.withValues(alpha: 0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSet
                ? AppKolors.secondary.withValues(alpha: 0.4)
                : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSet
                    ? AppKolors.secondary.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 20.w,
                  color: isSet ? AppKolors.secondary : Colors.grey.shade500),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12.sp, color: Colors.grey.shade600)),
                  SizedBox(height: 2.h),
                  Text(value,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isSet
                              ? AppKolors.secondary
                              : Colors.grey.shade400)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 18.w,
                color: isSet ? AppKolors.secondary : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ===== Caterer helper widgets =====

class _CatererChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _CatererChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? AppKolors.secondary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppKolors.secondary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _InternalCatererPicker extends ConsumerWidget {
  final List<String> options;
  final StateProvider<String> provider;

  const _InternalCatererPicker(
      {required this.options, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(provider);
    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      children: options
          .map((opt) => GestureDetector(
                onTap: () =>
                    ref.read(provider.notifier).state =
                        selected == opt ? '' : opt,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: selected == opt
                        ? AppKolors.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected == opt
                          ? AppKolors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: selected == opt
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected == opt
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ===== Step 3 Styled Widgets =====

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20.w),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StyledInputCard extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _StyledInputCard({
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          child,
        ],
      ),
    );
  }
}
