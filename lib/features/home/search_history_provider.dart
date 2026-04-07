import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchHistoryItem {
  final String title;
  final String subtitle;
  final double? lat;
  final double? lng;
  final String? placeId;

  SearchHistoryItem({
    required this.title,
    required this.subtitle,
    this.lat,
    this.lng,
    this.placeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistoryItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          subtitle == other.subtitle;

  @override
  int get hashCode => title.hashCode ^ subtitle.hashCode;
}

class SearchHistoryNotifier extends StateNotifier<List<SearchHistoryItem>> {
  SearchHistoryNotifier() : super([]);

  void addSearch(SearchHistoryItem item) {
    // Remove if already exists to move it to top
    final newList = state.where((element) => element != item).toList();
    
    // Add to top and limit to 5 items
    state = [item, ...newList].take(5).toList();
  }

  void clearHistory() {
    state = [];
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<SearchHistoryItem>>((ref) {
  return SearchHistoryNotifier();
});
