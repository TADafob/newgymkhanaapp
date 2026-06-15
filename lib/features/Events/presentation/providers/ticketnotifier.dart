import 'package:flutter_riverpod/flutter_riverpod.dart';

class TicketQuantitiesNotifier extends StateNotifier<Map<String, int>> {
  TicketQuantitiesNotifier() : super({});

  void increment(String categoryName) {
    state = {...state, categoryName: (state[categoryName] ?? 0) + 1};
  }

  void decrement(String categoryName) {
    final current = state[categoryName] ?? 0;
    if (current > 0) {
      state = {...state, categoryName: current - 1};
    }
  }

  void resetAll() {
    state = {};
  }
}
final ticketQuantitiesProvider =
    StateNotifierProvider<TicketQuantitiesNotifier, Map<String, int>>(
  (ref) => TicketQuantitiesNotifier(),
);