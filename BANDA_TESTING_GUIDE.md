# Testing Banda Booking Feature - Setup Guide

## Prerequisites
1. App must be running
2. User must be logged in
3. Banda facility must exist in Firestore

## Step 1: Add Banda to Firestore (if not already present)

Go to Firebase Console → Firestore → `Facilities` collection

Add a new document with the following structure:

```json
{
  "facility_Name": "Banda",
  "facility_Id": "banda_001",
  "facility_Type": "Sports",
  "image": "https://your-image-url.jpg",
  "images": [
    "https://your-image-url-1.jpg",
    "https://your-image-url-2.jpg"
  ],
  "courts": 1,
  "isActive": true,
  "description": "Banda facility for flexible hourly bookings"
}
```

**Important**: 
- `facility_Type` must be `"Sports"` (not "Banda")
- `facility_Name` must be exactly `"Banda"` (case-sensitive)
- `isActive` must be `true`

## Step 2: Navigate to Banda Booking

### Option A: Using the UI
1. Open the app and login
2. Go to **Home** tab
3. Click **"Book Sport Facilities"**
4. You should see "Banda" in the facilities grid
5. Click on **"Banda"**
6. The Banda booking UI will appear in a bottom sheet

### Option B: Direct URL (if using GoRouter)
Navigate to: `/book-facility/book-category/Sports`

Then select Banda from the list.

## Step 3: Test the Booking Flow

1. **Select Date**: Choose a date within the next 48 hours
2. **Select Start Time**: Tap the "Start Time" field and pick a time
3. **Select End Time**: Tap the "End Time" field and pick a time after start time
4. **View Booked Slots**: See existing bookings for that date
5. **Confirm Booking**: Click "Request Booking" button
6. **Review**: Confirm the booking details in the dialog
7. **Submit**: Click "Confirm" to submit

## Expected Behavior

✅ **Date Picker**
- Only shows dates within 48 hours
- Dates beyond 48 hours are greyed out

✅ **Time Selection**
- Start time picker opens first
- End time picker only enables after start time is selected
- End time must be after start time

✅ **Booked Slots Display**
- Shows all existing bookings for the selected date
- Displays time ranges (e.g., "8:00 AM - 12:00 PM")
- Shows "All slots available" if no bookings exist

✅ **Booking Submission**
- Creates a new booking in `bookings_collection`
- Sets status to "Unconfirmed"
- Stores start and end times
- Sets facility_Type to "Banda"

## Troubleshooting

### Issue: Banda doesn't appear in facilities list
**Solution**: 
- Check Firestore: Ensure Banda document exists in `Facilities` collection
- Verify `facility_Type` is "Sports" (not "Banda")
- Verify `facility_Name` is exactly "Banda"
- Verify `isActive` is `true`

### Issue: Clicking Banda shows sports booking UI instead
**Solution**:
- Check that facility name is exactly "Banda" (case-sensitive)
- The code checks: `facilityTitle.toLowerCase() == 'banda'`
- Ensure no extra spaces in the name

### Issue: Time picker not working
**Solution**:
- Start time must be selected first
- End time picker only enables after start time
- End time must be after start time

### Issue: Booking not submitted
**Solution**:
- Ensure all fields are filled (date, start time, end time)
- Check Firebase permissions allow writes to `bookings_collection`
- Check user is authenticated

## Database Structure

### Facilities Collection
```
Facilities/
├── banda_001/
│   ├── facility_Name: "Banda"
│   ├── facility_Id: "banda_001"
│   ├── facility_Type: "Sports"
│   ├── image: "url"
│   ├── images: ["url1", "url2"]
│   ├── courts: 1
│   ├── isActive: true
│   └── description: "..."
```

### Bookings Collection (Banda Booking)
```
bookings_collection/
├── booking_xyz/
│   ├── booking_Id: "booking_xyz"
│   ├── user_Id: "user_uid"
│   ├── facility_Id: "banda_001"
│   ├── booking_Date: Timestamp(2024-01-15)
│   ├── start_Time: Timestamp(2024-01-15 08:00:00)
│   ├── end_Time: Timestamp(2024-01-15 12:00:00)
│   ├── facility_Type: "Banda"
│   ├── reaction: { status: "Unconfirmed" }
│   ├── interested_Members: []
│   └── created_At: Timestamp(now)
```

## Files Involved

1. **banda_booking_page.dart** - Main UI component
2. **booking_category.dart** - Routes Banda to new UI
3. **bookings_provider.dart** - Provides booking data
4. **bookingselection.dart** - Shared providers (date, facility, etc.)

## Next Steps

After testing:
1. Verify bookings appear in Firestore
2. Check bookings show in "All Bookings" page
3. Test cancellation flow
4. Test with multiple users
5. Verify time overlap handling (should allow overlaps)
