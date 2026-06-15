// import 'package:flutter/material.dart';

// showModalBottomSheet(
//         showDragHandle: true,
//         useSafeArea: true,
//         context: context,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
//         ),
//         isScrollControlled: true,
//         builder: (context) {
//           return FractionallySizedBox(
//             heightFactor: 0.8, // Adjust this to control the height of the bottom sheet
//             child: Padding(
//               padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 20),
//               child: PageView(
//                 controller: pageController,
//                 physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
//                 children: [
//                   // Step 1: booking facility details
//                   Consumer(
//                     builder: (context, ref, _) {
//                       return Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Center(
//                             child: const Text(
//                               'Facility Booking',
//                               style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                             ClipRRect(
//                         borderRadius: BorderRadius.circular(12.0),
//                         child:Stack(
//                           children: [
//                             Image.network(
//                               imageUrl,
//                               fit: BoxFit.cover,
//                               height: 250,
//                               width: double.infinity,
//                             ),
//                             Positioned(
//                               bottom: 8,
//                               left: 8,
//                               child: Text(
//                                 facilityNames,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),),
//                         SizedBox(height: 5),
//                         FacilityDescription(facilityName: facilityNames.replaceAll('\n', ' '),),
//                         Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   elevation: 0,
//                                   backgroundColor: Colors.lightBlueAccent.shade100,
//                                 ),
//                                 onPressed: () {
//                                   pageController.nextPage(
//                                     duration: const Duration(milliseconds: 300),
//                                     curve: Curves.easeInOut,
//                                   );
//                                 },
//                                 child: Row(
//                                   children: const [
//                                     Text('Next', style: TextStyle(color: Colors.white)),
//                                     Icon(Icons.keyboard_arrow_right_outlined, color: Colors.white),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                                   ],
//                                 );
//                               },
//                   ),

//                   //step 2: dates selection
//                   Consumer(
//                       builder: (context, ref, _) {
//                         final facilityId = ref.watch(selectedFacilityProvider);
//                         final disabledDates = ref.watch(disabledDatesStateProvider);
//                         final isLoading = ref.watch(disabledDatesProvider(facilityId)).isLoading;
//                         final asyncDisabledDates = ref.watch(disabledDatesProvider(facilityId));

//                           asyncDisabledDates.when(
//                             data: (dates) {
//                               // update the state for the calendar
//                               WidgetsBinding.instance.addPostFrameCallback((_) {
//                                 ref.read(disabledDatesStateProvider.notifier).state = dates;
//                               });
//                             },
//                             loading: () {},
//                             error: (error, stack) {},
//                           );


//                         // Listen for updates to the FutureProvider & trigger UI rebuild
//                         // ref.listen(disabledDatesProvider(facilityId), (previous, next) {
//                         //   next.whenData((dates) {
//                         //     ref.read(disabledDatesStateProvider.notifier).state = dates;
//                         //   });
//                         // });
//                     return StatefulBuilder(
//                       builder: (context, setState){
//                         return Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Center(
//                               child: const Text(
//                                 'Step 1 : Select Dates',
//                                 style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             SizedBox(height: 20,),
//                             Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                                      children: [
//                        Row(
//                          children: [
//                            Container(
//                              height: 35,
//                              width: 35,
//                              decoration: BoxDecoration(
//                                color: Colors.grey.shade300,
//                                shape: BoxShape.circle,
//                              ),
//                              child: Center(
//                                child: Stack(
//                                  fit: StackFit.expand,
//                                  alignment: Alignment.center,
//                                  children: [
//                                    Center(
//                                      child: Text(
//                         '01',
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontSize: 16,
//                         ),
//                                      ),
//                                    ),
//                                    Positioned(
//                                      left: 5, // Adjust this to control the starting point of the line
//                                      right: 5, // Adjust this to control the ending point of the line
//                                      child: Container(
//                         height: .5,
//                         width: double.maxFinite, // Thickness of the line
//                         color: Colors.black, // Line color
//                                      ),
//                                    ),
//                                  ],
//                                ),
//                              ),
//                            ),
//                            const SizedBox(width: 8), // Add some spacing between elements
//                            Text(' - Unavailable Slot'),
//                          ],
//                        ),
//                        Row(
//                          children: [
//                            Container(
//                              height: 30,
//                              width: 30,
//                              decoration: BoxDecoration(
//                                color: Colors.grey.shade200,
//                                shape: BoxShape.circle,
//                                border: Border.all(color: Colors.grey.shade400)
//                              ),
//                              child: Center(
//                                child: Center(
//                                  child: Text(
//                                   '01',
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: 16,
//                                   ),
//                                  ),
//                                ),
//                              ),
//                            ),
//                            const SizedBox(width: 8), // Add some spacing between elements
//                            Text(' - Available Slot'),
//                          ],
//                        ),
//                                        ],
//                                      ),
//                               SizedBox(height: 20,),
//                               Expanded(
//                                 child: SfDateRangePicker(
//                                   todayHighlightColor: AppKolors.secondary,
//                                   enablePastDates: false,
//                                   selectionColor: AppKolors.secondary,
//                                   selectionMode: DateRangePickerSelectionMode.range,
//                                   onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
//                                         if (args.value is PickerDateRange) {
//                                           final startDate = args.value.startDate;
//                                           final endDate = args.value.endDate ?? startDate;
                      
//                                           bool hasBlockedDates = disabledDates.any((date) =>
//                                               (date.isAtSameMomentAs(startDate) || date.isAtSameMomentAs(endDate)) ||
//                                               (date.isAfter(startDate) && date.isBefore(endDate)));
                      
//                                           if (hasBlockedDates) {
//                                             if (lastValidRange == null ||
//                                                 lastValidRange?.startDate != startDate ||
//                                                 lastValidRange?.endDate != endDate) {
//                                               ScaffoldMessenger.of(context).showSnackBar(
//                                                 const SnackBar(content: Text('You can\'t select in-between blocked dates!')),
//                                               );
//                                             }
//                                           } else {
//                                             lastValidRange = PickerDateRange(startDate, endDate);
//                                             ref.read(dateFromProvider.notifier).state = startDate!;
//                                             ref.read(dateToProvider.notifier).state = endDate!;
//                                           }
//                                         }
//                                       },
                      
//                                   monthViewSettings: DateRangePickerMonthViewSettings(
//                                     blackoutDates: disabledDates,
//                                   ),
//                                   monthCellStyle: DateRangePickerMonthCellStyle(
//                                     blackoutDatesDecoration: BoxDecoration(
//                                         color: Colors.grey.shade300, shape: BoxShape.circle),
//                                     blackoutDateTextStyle: const TextStyle(
//                                       color: Colors.red,
//                                       decoration: TextDecoration.lineThrough,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           Text('It is recommended you refresh the dates first before selecting the dates.', style: TextStyle(color: Colors.black), textAlign: TextAlign.center,),
//                           SizedBox(height: 10,),    // Buttons Row (Back, Refresh, Next)
//                       Row(
//   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//   children: [
//     Expanded(
//       flex: 3, // Reducing the flex value for the 'Back' button to make it smaller
//       child: ElevatedButton(
//         onPressed: () {
//           pageController.previousPage(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//           );
//         },
//         style: ElevatedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: Colors.redAccent.shade100,
//         ),
//         child: Row(
//           children: const [
//             Icon(Icons.keyboard_arrow_left, color: Colors.white),
//             Text('Back', style: TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),
//     ),
//     SizedBox(width: 10),
//     Expanded(
//       flex: 4, // Giving more space to the 'Refresh Dates' button
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: Colors.orangeAccent.shade100,
//         ),
//         onPressed: () {
//           ref.invalidate(disabledDatesProvider);
//         },
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             const Icon(Icons.refresh, color: Colors.white),
//             Flexible(
//               child: Text(
//                 'Refresh Dates',
//                 style: const TextStyle(color: Colors.white),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//     SizedBox(width: 10),
//     Expanded(
//       flex: 3, // Reducing the flex value for the 'Next' button to make it smaller
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: isLoading
//               ? Colors.grey // Disable when loading
//               : Colors.lightBlueAccent.shade100, // Enable when data is ready
//         ),
//         onPressed: isLoading
//             ? () {
//                 ref.invalidate(disabledDatesProvider); // Fetch new data instead of closing the bottom sheet
//               }
//             : () {
//                 final startDate = ref.read(dateFromProvider);
//                 final endDate = ref.read(dateToProvider);
//                 if (startDate == null || endDate == null) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Please select the dates before proceeding')),
//                   );
//                   return;
//                 }
//                 pageController.nextPage(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                 );
//               },
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               isLoading ? 'Refresh' : 'Next',
//               style: const TextStyle(color: Colors.white),
//               overflow: TextOverflow.ellipsis,
//               maxLines: 1,
//             ),
//             isLoading ? SizedBox() : const Icon(Icons.keyboard_arrow_right_outlined, color: Colors.white),
//           ],
//         ),
//       ),
//     ),
//   ],
// ),             
//                             ],
//                           );
//                       }
//                     );
//         },
//                   ),
//                   // Step 2: Bookings Details
//                   Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 8),
//   child: StatefulBuilder(
//     builder: (context, setState) {
//       // Local error state variables
//       String dateError = '';
//       String attendeesError = '';
//       String reasonError = '';

//       return Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),
//           const Center(
//             child: Text(
//               'Step 2 : Booking Details',
//               style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(height: 10),
//            Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: RichText(
//               text: const TextSpan(
//                 text: 'Selected Dates',
//                 style: TextStyle(color: Colors.black, fontSize: 14),
//                 children: [
//                   TextSpan(
//                     text: ' *',
//                     style: TextStyle(color: Colors.red, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Consumer(
//             builder: (context, ref, child) {
//               final dateFrom = ref.watch(dateFromProvider);
//               final dateTo = ref.watch(dateToProvider);
//               return Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     width: 150,
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8.0),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Icon(Icons.calendar_today, color: Colors.grey, size: 12),
//                         Text(
//                           dateFrom != null
//                               ? formatDateWithSuffix(dateFrom)
//                               : 'Select Date',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Text('to', style: TextStyle(color: AppKolors.accent3)),
//                   Container(
//                     width: 150,
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                     margin: const EdgeInsets.only(top: 8),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8.0),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Icon(Icons.calendar_today, color: Colors.grey, size: 12),
//                         Text(
//                           dateTo != null
//                               ? formatDateWithSuffix(dateTo)
//                               : 'Select Date',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//           // Show error message for date selection if needed
//           if (dateError.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(left: 10, top: 4),
//               child: Text(
//                 dateError,
//                 style: const TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           const SizedBox(height: 10),
//           // TextField for number of attendees
//           _buildTextField(
//             80,
//             'Number of Attendees',
//             'Enter the number of people who are going to participate...',
//             TextEditingController(text: ref.read(selectedNoOfAttendeesProvider)),
//             (value) {
//               ref.read(selectedNoOfAttendeesProvider.notifier).state = value;
//             },
//             isRequired: true
//           ),
//           // Show error message for attendees if needed
//           if (attendeesError.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(left: 10, top: 4),
//               child: Text(
//                 attendeesError,
//                 style: const TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           const SizedBox(height: 10),
//           // TextField for Reason for Booking
//           _buildTextField(
//             80,
//             'Reason for Booking',
//             'Birthday Party, Wedding Party, etc...',
//             TextEditingController(text: ref.read(reasonForBookingProvider)),
//             (value) {
//               ref.read(reasonForBookingProvider.notifier).state = value;
//             },
//             isRequired: true
//           ),
//           // Show error message for reason if needed
//           if (reasonError.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(left: 10, top: 4),
//               child: Text(
//                 reasonError,
//                 style: const TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           const SizedBox(height: 10),
//           // Special Requests field (optional; no asterisk)
//           _buildTextField(
//             80,
//             'Any Special Requests?',
//             'Balloons, party poppers, clowns, etc...',
//             TextEditingController(text: ref.read(specialrequestsProvider)),
//             (value) {
//               ref.read(specialrequestsProvider.notifier).state = value;
//             },
//           ),
//           const SizedBox(height: 20),
//           // Buttons Row (Back, Refresh, Next)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Expanded(
//                 flex: 3,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Clear errors when going back
//                     setState(() {
//                       dateError = '';
//                       attendeesError = '';
//                       reasonError = '';
//                     });
//                     // Navigate back to previous page
//                     pageController.previousPage(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     elevation: 0,
//                     backgroundColor: Colors.redAccent.shade100,
//                   ),
//                   child: Row(
//                     children: const [
//                       Icon(Icons.keyboard_arrow_left, color: Colors.white),
//                       Text('Back', style: TextStyle(color: Colors.white)),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 flex: 4,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     elevation: 0,
//                     backgroundColor: Colors.orangeAccent.shade100,
//                   ),
//                   onPressed: () {
//                     // Optionally, you can trigger a refresh action here
//                     ref.invalidate(disabledDatesProvider);
//                   },
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       const Icon(Icons.refresh, color: Colors.white),
//                       Flexible(
//                         child: Text(
//                           'Refresh Dates',
//                           style: const TextStyle(color: Colors.white),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 flex: 3,
//                 child: Consumer(
//                   builder: (context, ref, _) {
//                     final facilityId = ref.watch(selectedFacilityProvider);
//                     final isLoading = ref.watch(disabledDatesProvider(facilityId)).isLoading;
//                     return ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         elevation: 0,
//                         backgroundColor: isLoading ? Colors.grey : Colors.lightBlueAccent.shade100,
//                       ),
//                       onPressed: isLoading
//                           ? () {
//                               ref.invalidate(disabledDatesProvider);
//                             }
//                           : () {
//                               // Retrieve current values from providers
//                               final dateFrom = ref.read(dateFromProvider);
//                               final dateTo = ref.read(dateToProvider);
//                               final attendees = ref.read(selectedNoOfAttendeesProvider);
//                               final reason = ref.read(reasonForBookingProvider);

//                               bool valid = true;
//                               if (dateFrom == null || dateTo == null) {
//                                 setState(() {
//                                   dateError = 'Please select both start and end dates.';
//                                 });
//                                 valid = false;
//                               } else {
//                                 setState(() {
//                                   dateError = '';
//                                 });
//                               }
//                               if (attendees.trim().isEmpty) {
//                                 setState(() {
//                                   attendeesError = 'Please enter the number of attendees.';
//                                 });
//                                 valid = false;
//                               } else {
//                                 setState(() {
//                                   attendeesError = '';
//                                 });
//                               }
//                               if (reason.trim().isEmpty) {
//                                 setState(() {
//                                   reasonError = 'Please enter the reason for booking.';
//                                 });
//                                 valid = false;
//                               } else {
//                                 setState(() {
//                                   reasonError = '';
//                                 });
//                               }

//                               // Only move to the next page if all validations pass.
//                               if (valid) {
//                                 pageController.nextPage(
//                                   duration: const Duration(milliseconds: 300),
//                                   curve: Curves.easeInOut,
//                                 );
//                               }
//                             },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             isLoading ? 'Refresh' : 'Next',
//                             style: const TextStyle(color: Colors.white),
//                             overflow: TextOverflow.ellipsis,
//                             maxLines: 1,
//                           ),
//                           if (!isLoading)
//                             const Icon(Icons.keyboard_arrow_right_outlined, color: Colors.white),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ],
//       );
//     },
//   ),
// ),

//                   //third page
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       Center(
//                             child: const Text(
//                               'Step 3 : Confirm Booking',
//                               style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
//                             ),),
//                             Expanded(
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//                                 child: Consumer(
//                                   builder: (context, ref, child) {
//                                     final selectedNoOfAttendees = ref.watch(selectedNoOfAttendeesProvider);
//                                     final reasonForBooking = ref.watch(reasonForBookingProvider);
//                                     final specialrequests = ref.watch(specialrequestsProvider);
//                                     final formatteddateto = formatDateWithSuffix(dateTo ?? DateTime.now());
//                                     final formatteddatefrom = formatDateWithSuffix(dateFrom ?? DateTime.now());
//                                   return Column(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       confirmationrow(
//                                         title: 'Facility : ',
//                                         subtitle: facilityNames.replaceAll('\n', ' '),
//                                         color: Colors.red,
//                                       ),
//                                       confirmationrow(
//                                         title: 'Date : ',
//                                         subtitle: '$formatteddatefrom to $formatteddateto',
//                                         color: Colors.green,
//                                       ),
//                                      confirmationrow(
//                                       title: 'Number of Attendees :',
//                                       subtitle: selectedNoOfAttendees.toString(),
//                                       color: Colors.green,
//                                       ),
//                                       confirmationrow(
//                                         title: 'Reason for Booking :', 
//                                         subtitle: reasonForBooking, 
//                                         color: Colors.green,
//                                       ),
//                                       confirmationrow(
//                                         title: 'Special Requests :', 
//                                         subtitle:  specialrequests, 
//                                         color: Colors.green,
//                                       ),
//                                       Divider(),
//                                       Center(child: FacilityDescription(facilityName: facilityNames.replaceAll('\n', ' '),))   
//                                     ],
//                                   );}
//                                 ),
//                               ),
//                             ),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                  ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 elevation: 0,
//                                 backgroundColor: Colors.redAccent.shade100,
//                               ),
//                               onPressed: () {
//                                 pageController.previousPage(
//                                       duration: const Duration(milliseconds: 300),
//                                       curve: Curves.easeInOut,);
//                               },
//                               child: Row(
//                                     children: const [
//                                       Icon(Icons.keyboard_arrow_left, color: Colors.white),
//                                       SizedBox(width: 5),
//                                       Text('back', style: TextStyle(color: Colors.white)),
//                                     ],
//                                   ),
//                             ),
//                                 ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     elevation: 0,
//                                     backgroundColor: Colors.green,
//                                   ),
//                                   onPressed: () {
//                                      final reasonForBooking = ref.read(reasonForBookingProvider);
//                                     final selectedNoOfAttendees = ref.read(selectedNoOfAttendeesProvider);
//                                     final specialrequests = ref.read(specialrequestsProvider);
//                                     final facilityId = ref.read(selectedFacilityProvider);
//                                     final dateFrom = ref.read(dateFromProvider);
//                                     final dateTo = ref.read(dateToProvider);
                                  
//                                     if (dateFrom == null || dateTo == null) {
//                                       // Show an error message or handle the null case appropriately
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(content: Text('Please select both start and end dates')),
//                                       );
//                                       return;
//                                     }
                                  
//                                     _submitBooking(
//                                       context,
//                                       ref,
//                                       dateFrom,
//                                       dateTo,
//                                       TimeOfDay.now(),
//                                       TimeOfDay.now(),
//                                       facilityId,
//                                       selectedNoOfAttendees,
//                                       reasonForBooking,
//                                       specialrequests,
//                                     );
                                  
//                                     print(reasonForBooking);
//                                     print(selectedNoOfAttendees);
//                                     print(specialrequests);
//                                     print(facilityId);
                                  
//                                     resetAllProviders(ref);
//                                     Navigator.of(context).pop();
//                                   },
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: const [
//                                       Text('Send Request', style: TextStyle(color: Colors.white)),
//                                       Icon(Icons.arrow_forward_ios, color: Colors.white),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                     ],
//                   ),
                  

//                 ],
//               ),
//             ),
//           );
//         },
//       ).whenComplete( () {
//         resetAllProviders(ref);
//       }
//       );
//     }