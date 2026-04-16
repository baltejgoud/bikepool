import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class SearchHistoryItem {
  final String title;
  final String subtitle;
  final double? lat;
  final double? lng;
  final String? placeId;
  final DateTime timestamp;

  SearchHistoryItem({
    required this.title,
    required this.subtitle,
    this.lat,
    this.lng,
    this.placeId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'lat': lat,
      'lng': lng,
      'placeId': placeId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Create from Firestore document
  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      lat: map['lat'] as double?,
      lng: map['lng'] as double?,
      placeId: map['placeId'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

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

class SearchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get search history stream for a user
  Stream<List<SearchHistoryItem>> getSearchHistoryStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('searchHistory')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SearchHistoryItem.fromMap(doc.data()))
          .toList();
    });
  }

  /// Add search to history
  Future<void> addSearch(String userId, SearchHistoryItem item) async {
    try {
      // Check if search already exists
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .where('title', isEqualTo: item.title)
          .where('subtitle', isEqualTo: item.subtitle)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Delete old entry to re-add it with new timestamp (move to top)
        await query.docs.first.reference.delete();
      }

      // Add new entry
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .add(item.toMap());

      // Clean up old entries (keep only 10)
      final allDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .first;

      if (allDocs.docs.length > 10) {
        final docsToDelete = allDocs.docs.sublist(10);
        for (var doc in docsToDelete) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      throw Exception('Failed to add search to history: $e');
    }
  }

  /// Clear all search history for user
  Future<void> clearHistory(String userId) async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .get();

      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear search history: $e');
    }
  }

  /// Delete a specific search from history
  Future<void> deleteSearch(String userId, SearchHistoryItem item) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .where('title', isEqualTo: item.title)
          .where('subtitle', isEqualTo: item.subtitle)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete search from history: $e');
    }
  }
}
