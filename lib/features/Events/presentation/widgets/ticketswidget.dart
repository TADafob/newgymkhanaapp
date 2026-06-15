import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EventTicketScreen extends StatelessWidget {
  final String eventId;
  final String orderId;

  const EventTicketScreen({super.key, required this.eventId, required this.orderId});

  @override
  Widget build(BuildContext context) {
      final size = MediaQuery.of(context).size;
  // quarter of screen‐height, but don’t let it exceed screen‐width
  final qrSize = min(size.height * 0.3, size.width);
  
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('E-Ticket', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events_collection')
              .doc(eventId)
              .collection('bookings')
              .doc(orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
        
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('Ticket not found', style: TextStyle(color: Colors.black)));
            }
            // Extracting data from the booking details snapshot
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final userid = data['booked_By'] ?? '';
        
            // Use another StreamBuilder to get event data
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events_collection')
                  .doc(eventId)
                  .snapshots(),
              builder: (context, eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (eventSnapshot.hasError) {
                  return Center(child: Text('Error: ${eventSnapshot.error}'));
                }
                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                  return Center(child: Text('Event not found', style: TextStyle(color: Colors.black)));
                }
                final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;
                final eventName = eventData['title'] ?? '';
                final eventLocation = eventData['location'] ?? '';
                final eventdate = eventData['date'] is Timestamp 
                    ? (eventData['date'] as Timestamp).toDate() 
                    : (eventData['date'] is DateTime 
                        ? eventData['date'] 
                        : null);
                final formattedDate = eventdate != null ? formatDate(eventdate) : '';
                final tickets = data['tickets'] as Map<String, dynamic>;
                // Calculate total number of tickets and their types
                num totalTickets = 0;
                List<String> ticketTypes = [];

                tickets.forEach((type, value) {
                  if (value is num) {
                    totalTickets += value;
                    ticketTypes.add(type);
                  } else if (value is Map && value['count'] is num) {
                    totalTickets += value['count'] as num;
                    ticketTypes.add(type);
                  }
                });

                // when you build your summary:
                final totalInt = totalTickets.toInt();
                final ticketsSummary = '$totalInt (${ticketTypes.join(', ')})';
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users_members')
                      .doc(userid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}'));
                    }
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return Center(child: Text('user not found', style: TextStyle(color: Colors.black)));
                    }
        
                    // Extracting data from the booking details snapshot
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    final fName = userData['f_Name'] ?? '';
                    final lName = userData['l_Name'] ?? '';
                    final attendeeName = '$fName $lName';
                return Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── GROUP PASS QR ───────────────────────────────────────────────────────────
Center(
  child: SizedBox(
    width: qrSize,
    height: qrSize,
    child: QrImageView(
      data: orderId,
      embeddedImage: const AssetImage('assets/images/common/logo.png'),
      version: QrVersions.auto,
      size: qrSize,
      gapless: true,
      eyeStyle: QrEyeStyle(
        color: Colors.black,
        eyeShape: QrEyeShape.square,
      ),
      dataModuleStyle: QrDataModuleStyle(color: Colors.black),
      backgroundColor: Colors.transparent,
    ),
  ),
),

SizedBox(height: 16.h),

Text(
  'Group Pass · $ticketsSummary',
  style: TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.bold,
  ),
),
Divider(color: Colors.grey, thickness: 1, height: 32.h),

// ─── INDIVIDUAL TICKETS ────────────────────────────────────────────────────
ExpansionTile(
  leading: Icon(CupertinoIcons.ticket, size: 24.sp),
  title: Text(
    'View Individual Tickets',
    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
  ),
  childrenPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  children: ticketTypes.expand((type) {
    final raw = tickets[type]!;
    final count = raw is num ? raw.toInt() : (raw['count'] as num).toInt();

    return List.generate(count, (i) {
      final uniqueTicketId = '$orderId-$type-$i';

      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini QR Code
            QrImageView(
              data: uniqueTicketId,
              version: QrVersions.auto,
              size: 50.w,
            ),
            SizedBox(width: 12.w),

            // Ticket Info + Download Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$type Ticket ${i + 1}',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.h),
                  TextButton.icon(
                    onPressed: () async {
                      // Implement ticket download logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ticket $uniqueTicketId...')),
                      );
                      await downloadAllTicketsShared(
                        context: context,
                        eventId: eventId,
                        userId: userid,
                        orderId: orderId,
                        tickets: tickets,
                        ticketTypes: ticketTypes,
                      );
                    },
                    icon: Icon(Icons.download, size: 16.sp),
                    label: Text(
                      'Download',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(60.w, 30.h),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }).toList(),
),

Divider(color: Colors.grey, thickness: 1, height: 32.h),

// ─── TICKET DETAILS ─────────────────────────────────────────────────────────────
                  Text(
                    'Event:',
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  ),
                  Text(
                    '$eventName: $eventLocation',
                    style: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 32.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name:', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                          Text(attendeeName, style: TextStyle(color: Colors.black, fontSize: 14.sp)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Ticket:', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                          Text(ticketsSummary, style: TextStyle(color: Colors.black, fontSize: 14.sp)),
                        ],
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 20.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date and Hour:', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                           SizedBox(height: 10.h),
                          Text(formattedDate, style: TextStyle(color: Colors.black, fontSize: 14.sp)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Order ID:', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                          SizedBox(height: 10.h),
                          Text(orderId, style: TextStyle(color: Colors.black, fontSize: 14.sp)),
                        ],
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 20.h,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      //  ticket download
                      await downloadAllTicketsShared(
                        context: context,
                        eventId: eventId,
                        userId: userid,
                        orderId: orderId,
                        tickets: tickets,
                        ticketTypes: ticketTypes,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00B7B7),
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Download Ticket',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                                  ],
                                ),
            );
          },
            );
          },  
            );
          },
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('dd MMMM yyyy');
  return formatter.format(date);
}


// Helper function to generate a QR code image for PDF
Future<pw.ImageProvider> _makeQrImage(String data) async {
  final qrValidationResult = QrValidator.validate(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.Q,
  );
  if (qrValidationResult.status == QrValidationStatus.valid) {
    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );
    final picData = await painter.toImageData(300);
    return pw.MemoryImage(picData!.buffer.asUint8List());
  } else {
    // Return a blank image if QR generation fails
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, 300, 300), paint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(byteData!.buffer.asUint8List());
  }
}

// Replace your downloadAllTicketsShared function with this:
Future<void> downloadAllTicketsShared({
  required BuildContext context,
  required String orderId,
  required Map<String, dynamic> tickets,
  required List<String> ticketTypes,
  required String eventId,
  required String userId,
}) async {
  // Request storage permission
  if (await Permission.storage.request().isGranted) {
    final pdf = pw.Document();
    
    // Load logo for header/footer
    final ByteData logoData = await rootBundle.load('assets/images/common/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    
    // Get event data from Firestore
    final eventSnapshot = await FirebaseFirestore.instance
        .collection('events_collection')
        .doc(eventId)
        .get();
    
    final userData = await FirebaseFirestore.instance
        .collection('users_members')
        .doc(userId)
        .get();
    
    final eventData = eventSnapshot.data()!;
    final userName = '${userData['f_Name']} ${userData['l_Name']}';
    final eventDate = (eventData['date'] as Timestamp).toDate();
    
    // Build PDF with enhanced design
    for (final type in ticketTypes) {
      final raw = tickets[type]!;
      final count = raw is num
          ? raw.toInt()
          : (raw is Map && raw['count'] is num)
              ? (raw['count'] as num).toInt()
              : 0;
              
      for (var i = 0; i < count; i++) {
        final ticketId = '$orderId-$type-${i + 1}';
        
        final qrImage = await _makeQrImage(ticketId);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2, color: PdfColor.fromHex('#00B7B7')),
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                padding: pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo
                    pw.Image(pw.MemoryImage(logoBytes), height: 60),
                    
                    pw.SizedBox(height: 20),
                    
                    // Event Title
                    pw.Text(
                      eventData['title'],
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    
                    pw.SizedBox(height: 10),
                    
                    // Ticket Type
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#00B7B7'),
                        borderRadius: pw.BorderRadius.circular(25),
                      ),
                      child: pw.Text(
                        '$type Ticket',
                        style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
                      ),
                    ),
                    
                    pw.SizedBox(height: 20),
                    
                    // QR Code
                    pw.Image(qrImage, width: 150, height: 150),
                    
                    pw.SizedBox(height: 20),
                    
                    // Ticket Details
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 24.w),
                        // Left column
                        pw.Expanded(
                          child:
                          pw.Padding(padding: pw.EdgeInsets.only(left: 30.w,),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text(userName),
                              pw.SizedBox(height: 8),
                              pw.Text('Location:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text(eventData['location']),
                            ],
                          ),),
                          
                        ),
                        // Right column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text(DateFormat('dd MMM yyyy').format(eventDate)),
                              pw.SizedBox(height: 8),
                              pw.Text('Order ID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text(orderId),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16.w),
                    
                    pw.SizedBox(height: 20.w),
                    
                    // Ticket ID
                    pw.Container(
                      padding: pw.EdgeInsets.all(8.w),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 2, color: PdfColor.fromHex('#00B7B7')),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        'Ticket ID: $ticketId',
                        style: pw.TextStyle(fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }
    
    // Save PDF to device
    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/tickets_$orderId.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    // Open file for viewing
    await OpenFile.open(filePath);
  } else {
    // Handle permission denied
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Storage permission required to save tickets')),
    );
  }
}







