import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String bookingId;
  final DateTime bookingDate;
  final DateTime startTime;
  final String? court_No;
  final String? imageUrl;
  final DateTime endTime;
  final String facilityId;
  final String facilityName; // Facility name will be fetched
  final String facilityType;
  final String userId;
  final bool isPaid;
  final int guestCount;
  final String status;
  final String userName;
  final String noOfAttendees; // User name from the `users_members` collection

  Booking({
    required this.bookingId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    required this.facilityId,
    required this.facilityName,
    required this.facilityType,
    required this.userId,
    required this.isPaid,
    required this.guestCount,
    required this.status,
    required this.userName,
    required this.noOfAttendees,
    this.court_No,
  });

  // Factory to create a Booking object from Firestore document data
  static Future<Booking> fromFirestore(DocumentSnapshot bookingDoc) async {
    final bookingData = bookingDoc.data() as Map<String, dynamic>;

    // Fetch facility details based on facilityId
    final facilityQuerySnapshot = await FirebaseFirestore.instance
        .collection('Facilities')
        .where('facility_Id', isEqualTo: bookingData['facility_Id'])
        .limit(1) // Assuming there is only one facility with the given ID
        .get();

    // Ensure that the facility document exists
    final facilityDoc = facilityQuerySnapshot.docs.isNotEmpty
        ? facilityQuerySnapshot.docs.first
        : null;

    final facilityName = facilityDoc != null
        ? facilityDoc['facility_Name'] as String
        : 'Unknown Facility';
    final imageUrl = facilityDoc != null
        ? facilityDoc['image'] as String
        : 'https://res.cloudinary.com/dbeofdu5x/image/upload/v1744020084/NAIROBI_GYMKHANA_LOGO_BANNER_kiaxwy.png'; // Default image URL if not found

    // Fetch user details based on userId
    final userDoc = await FirebaseFirestore.instance
        .collection('users_members')
        .doc(bookingData['user_Id'])
        .get();
    final userName =
        userDoc.exists ? userDoc['f_Name'] as String : 'Unknown User';

    // Extract reaction map and safely access isPaid and status
    final reaction = bookingData['reaction'] as Map<String, dynamic>?;
    final isPaid =
        reaction?['isPaid'] as bool? ?? false; // Default to false if null
    final status = reaction?['status'] as String? ?? 'Unknown';
    final participants =
        bookingData['Participants_Details'] as Map<String, dynamic>? ?? {};
    final guestCount = (participants['guests'] as num?)?.toInt() ?? 0;
    // final reacted_By = reaction?['reacted_By'] as String? ?? 'Unknown';
    // final reaction_Date = reaction?['reaction_Date'] as Timestamp? ?? DateTime.now();
    // final reaction_Id = reaction?['reaction_Id'] as String? ?? 'R_unknown';// Default to 'Unknown' if null

    // Return the Booking object with all the necessary fields
    return Booking(
      bookingId: bookingData['booking_Id'] as String,
      bookingDate: (bookingData['booking_Date'] as Timestamp).toDate(),
      startTime: (bookingData['start_Time'] as Timestamp).toDate(),
      endTime: (bookingData['end_Time'] as Timestamp).toDate(),
      facilityId: bookingData['facility_Id'] as String,
      facilityName: facilityName,
      facilityType: bookingData['facility_Type'] as String,
      userId: bookingData['user_Id'] as String,
      userName: userName,
      imageUrl: imageUrl,
      noOfAttendees: bookingData['no_of_Attendees'] as String ?? '0',
      isPaid: isPaid,
      guestCount: guestCount,
      status: status,
      court_No: bookingData['court_No'] as String,
    );
  }
}
