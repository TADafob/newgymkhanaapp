# Club Booking Redesign TODO
Track progress on redesigning club booking to match sports booking flow (Intro/Date → Attendants → Time Slots → Confirm).

## Steps

### 1. [x] Add Club-Specific Providers
- Edit `lib/features/bookings/presentation/providers/bookings_provider.dart`
- Added: `selectedClubDateProvider`, `clubGuestCountProvider` (int), `selectedClubTimeSlotProvider`, `selectedClubFacilityProvider`, `clubUnavailableDatesProvider.family`, `clubTimeSlotsProvider.family`
- Query Firestore for 'Club' bookings/dates/slots.


### 2. [x] Redesign ClubBookingPage
- Rewrote `lib/features/Profile/presentation/screens_ui/club_booking_page.dart` as full copy/adapt of sports_booking_page.dart
- 4 steps: Date (w/ unavailable), Guests counter, Time slots (8am-10pm availability), Confirm
- Progress bar, PageView, providers integrated, validation/Bottom CTA.


### 3. [ ] Update Navigations
- Edit `lib/features/bookings/presentation/screen_ui/booking_category.dart`: Replace bottom sheets w/ Navigator.push(ClubBookingPage(...))
- Edit `lib/features/thewall/presentation/screens/all_facilities.dart`: Ensure ClubBookingPage gets imageUrl, ProviderScope w/ facilityId.

### 4. [ ] Deprecate Legacy
- Comment/remove `clubbooking.dart`, `banda_booking_page.dart` references.

### 5. [ ] Test & Cleanup
- Test full flow: unavailable dates/slots, submit (use existing confirmation).
- `flutter analyze`, hot reload.
- Update TODO progress.

**Progress: 0/5 complete**

