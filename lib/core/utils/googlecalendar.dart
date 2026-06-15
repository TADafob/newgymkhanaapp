import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart';

class GoogleCalendarAPI {
  static const calendarId = 'en.kenya%23holiday%40group.v.calendar.google.com';
  static const scopes = [CalendarApi.calendarReadonlyScope];

  Future<List<String>> getHolidays(DateTime startDate, DateTime endDate) async {
    // Load service account credentials
    final serviceAccountKey = File('assets/apis/service_account.json');
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(await serviceAccountKey.readAsString()),
    );

    // Create an authenticated client
    final client = await clientViaServiceAccount(credentials, scopes);
    final calendarApi = CalendarApi(client);

    try {
      // Pass DateTime directly to `timeMin` and `timeMax`
      final events = await calendarApi.events.list(
        calendarId,
        timeMin: startDate, // DateTime is expected here
        timeMax: endDate,   // DateTime is expected here
      );

      // Extract holiday names
      return events.items?.map((event) => event.summary ?? 'Unnamed Event').toList() ?? [];
    } finally {
      client.close(); // Close the client to free up resources
    }
  }
}
