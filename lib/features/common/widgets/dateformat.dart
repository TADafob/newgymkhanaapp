import 'package:intl/intl.dart';

/// Returns the formatted date string with ordinal suffix.
/// Example: 1st January 2025, 2nd February 2025, etc.
String formatDateWithSuffix(DateTime date) {
  final day = date.day;
  final suffix = _getDaySuffix(day);
  final month = DateFormat('MMM').format(date);
  final year = DateFormat('yy').format(date);

  return '$day$suffix $month $year';
}

/// Returns the appropriate ordinal suffix for a day.
String _getDaySuffix(int day) {
  if (day >= 11 && day <= 13) {
    return 'th';
  }
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
