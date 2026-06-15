import 'package:nrbgymkhana/core/utils/emojis.dart';

// Define holidays and their dates
final holidays = {
  'New Year\'s Day': DateTime(2025, 1, 1),
  'Christmas': DateTime(2024, 12, 25),
  'Independence Day': DateTime(2024, 7, 4),
};

// Method to get the current greeting based on time and holidays
String getGreeting() {
  final now = DateTime.now();
  final currentHour = now.hour;

  // Check for holidays
  for (final entry in holidays.entries) {
    if (entry.value.month == now.month && entry.value.day == now.day) {
      return 'Happy ${entry.key} ${Emoji.party.emoji}';
    }
  }

  // Check time of day for standard greetings
  if (currentHour < 12) {
    return 'Good morning ${Emoji.sunrise.emoji}';
  } else if (currentHour < 18) {
    return 'Good afternoon ${Emoji.sun.emoji}';
  } else {
    return 'Good evening ${Emoji.moon.emoji}';
  }
}
