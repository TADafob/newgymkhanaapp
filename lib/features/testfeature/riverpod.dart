import 'package:flutter_riverpod/flutter_riverpod.dart';

final facilityAvailabilityProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'Squash Court': true,
    'Cricket Ground': true,
    'Tennis Court': true,
    'Badminton Court': true,
    'Volleyball Court': true,
  };
});