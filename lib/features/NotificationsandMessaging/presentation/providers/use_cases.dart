import 'package:intl/intl.dart';

Map<String, List<Map<String, dynamic>>> groupByDate(List<Map<String, dynamic>> notifications) {
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));

  Map<String, List<Map<String, dynamic>>> grouped = {};

  // Add notifications to their respective groups
  for (var notification in notifications) {
    DateTime date = notification['date'];
    
    if (isSameDay(date, today)) {
      grouped.putIfAbsent('Today', () => []).add(notification);
    } else if (isSameDay(date, yesterday)) {
      grouped.putIfAbsent('Yesterday', () => []).add(notification);
    } else {
      grouped.putIfAbsent('Older (more than 3 days)', () => []).add(notification);
    }
  }

  return grouped;
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}

// Format timestamp
String formatTime(DateTime date) {
  DateTime now = DateTime.now();
  if (isSameDay(date, now)) {
    return DateFormat('h:mm a').format(date);
  } else if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  } else {
    return DateFormat('MMM d').format(date);
  }
}





