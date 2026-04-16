import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/search_history_service.dart';
import '../../core/auth/auth_provider.dart';

final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  return SearchHistoryService();
});

/// Stream provider that automatically syncs search history from Firestore
final searchHistoryProvider = StreamProvider<List<SearchHistoryItem>>((ref) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(searchHistoryServiceProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return service.getSearchHistoryStream(user.uid);
});

/// Notifier for adding/removing search items
class SearchHistoryNotifier extends StateNotifier<AsyncValue<void>> {
  final SearchHistoryService _service;
  final String userId;

  SearchHistoryNotifier(this._service, this.userId)
      : super(const AsyncValue.data(null));

  Future<void> addSearch(SearchHistoryItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.addSearch(userId, item));
  }

  Future<void> clearHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.clearHistory(userId));
  }

  Future<void> deleteSearch(SearchHistoryItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.deleteSearch(userId, item));
  }
}

final searchHistoryNotifierProvider = StateNotifierProvider.family<
    SearchHistoryNotifier,
    AsyncValue<void>,
    String>((ref, userId) {
  final service = ref.watch(searchHistoryServiceProvider);
  return SearchHistoryNotifier(service, userId);
});

/// Convenience provider to add/remove from current user's search history
final currentUserSearchHistoryNotifierProvider =
    StateNotifierProvider<SearchHistoryNotifier, AsyncValue<void>>((ref) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(searchHistoryServiceProvider);

  final user = authState.value;
  if (user == null) {
    return SearchHistoryNotifier(service, '');
  }

  return SearchHistoryNotifier(service, user.uid);
});
