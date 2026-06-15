import 'package:intl/intl.dart' as intl;

String formatDateRangeWithSuffix(DateTime start, DateTime end) {
  String suffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
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

  final startDay = '${start.day}${suffix(start.day)}';
  final endDay = '${end.day}${suffix(end.day)}';
  final month = intl.DateFormat('MMM').format(start); // e.g., Jun
  final year = intl.DateFormat('yyyy').format(start);   // e.g., 25

  return '$startDay $month $year – $endDay $month $year';

}

String formatHourRange(DateTime start, DateTime end) {
  final formatter = intl.DateFormat('ha'); // e.g., 5PM
  return '${formatter.format(start)} – ${formatter.format(end)}';
}
