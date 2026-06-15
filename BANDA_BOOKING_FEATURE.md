# Banda Booking Feature Implementation

## Overview
A separate booking procedure has been implemented for the Banda facility with its own UI/UX. Unlike sports facilities that have a 2-slot limit per facility, Banda allows flexible hourly or full-day bookings with overlapping time slots.

## Key Features

### 1. Flexible Time Slot Booking
- Users can book Banda for any hourly duration
- Example: User A books 8am-12pm, User B can book 3pm-7pm on the same day
- No court-based restrictions like sports facilities

### 2. Separate UI/UX
- **File**: `lib/features/bookings/presentation/widgets/banda_booking_page.dart`
- Clean, intuitive interface specifically designed for time-based bookings
- Date picker for selecting booking date (within 48 hours)
- Time pickers for start and end times
- Real-time display of booked slots for the selected date

### 3. Booking Flow

#### Step 1: Facility Selection
- User navigates to Sports Facilities booking
- Selects "Banda" from the facility list
- Automatically routes to Banda booking UI (not the standard sports booking)

#### Step 2: Date Selection
- Calendar picker shows available dates (next 48 hours)
- User selects desired booking date

#### Step 3: Time Selection
- Start time picker (required)
- End time picker (only enabled after start time is selected)
- End time must be after start time
- Validation ensures proper time range

#### Step 4: View Booked Slots
- Real-time display of all booked slots for the selected date
- Shows time ranges of existing bookings
- Helps user identify available time windows

#### Step 5: Confirmation
- Summary dialog shows:
  - Selected date
  - Time range (start - end)
  - Duration in hours
- User confirms or cancels booking

### 4. Database Structure
Banda bookings are stored in `bookings_collection` with:
```
{
  'booking_Id': string,
  'user_Id': string,
  'facility_Id': string,
  'booking_Date': Timestamp,
  'start_Time': Timestamp,
  'end_Time': Timestamp,
  'facility_Type': 'Banda',
  'reaction': {
    'status': 'Unconfirmed' | 'Confirmed' | 'Cancelled'
  },
  'interested_Members': [],
  'created_At': Timestamp
}
```

### 5. Key Differences from Sports Facilities

| Feature | Sports | Banda |
|---------|--------|-------|
| Booking Type | Per court, per hour | Flexible time slots |
| Slot Limit | 2 per facility | Unlimited (no overlap) |
| Time Overlap | Not allowed | Allowed (different times) |
| UI | Grid-based slots | Time picker-based |
| Duration | Fixed 1 hour | Variable (user-defined) |

## Files Modified/Created

### New Files
1. **banda_booking_page.dart** - Main Banda booking UI component
   - Time selection logic
   - Booked slots display
   - Booking submission

### Modified Files
1. **booking_category.dart** - Updated to detect Banda facility
   - Added `showBandaBookingBottomSheet()` function
   - Routes Banda facility to new booking page
   - Maintains existing sports/club booking flows

## Usage

### For Users
1. Go to Book Sport Facilities
2. Click on "Banda"
3. Select date and time range
4. Review booked slots
5. Confirm booking

### For Developers
To add more facilities with custom booking logic:
1. Create a new booking page component
2. Add facility name detection in `booking_category.dart`
3. Create corresponding bottom sheet function
4. Ensure database structure matches booking type

## Validation Rules

1. **Date Validation**
   - Only dates within 48 hours allowed
   - Past dates disabled

2. **Time Validation**
   - Start time required
   - End time required and must be after start time
   - Minimum 1 hour duration recommended

3. **Overlap Validation**
   - Multiple bookings allowed on same date
   - No time overlap checking (by design)
   - Users responsible for selecting non-overlapping times

## Future Enhancements

1. Add duration presets (1hr, 2hrs, half-day, full-day)
2. Pricing based on duration
3. Bulk booking for multiple days
4. Cancellation with refund logic
5. Booking history and analytics
