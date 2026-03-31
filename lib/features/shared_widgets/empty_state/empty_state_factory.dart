import 'package:flutter/material.dart';
import 'empty_state.dart';

enum EmptyStateType {
  noRides,
  noNetwork,
  locationDenied,
  noFavorites,
  noSearchResults,
  noHistory,
}

class EmptyStateFactory {
  static Widget buildEmptyState({
    required EmptyStateType type,
    required BuildContext context,
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? destination,
    required bool isDark,
    required bool highContrast,
  }) {
    final isDarkMode = isDark;
    final isHighContrast = highContrast;

    switch (type) {
      case EmptyStateType.noRides:
        return EmptyState(
          icon: '🚗',
          title: 'No rides available',
          subtitle:
              'Unfortunately, there are no drivers heading to $destination right now. Set an alert and we\'ll notify you when a ride becomes available!',
          actionLabel: 'Set Alert for this Route',
          onAction: onAction,
          secondaryActionLabel: 'Schedule for Later',
          onSecondaryAction: onAction,
          isDark: isDarkMode,
          highContrast: isHighContrast,
        );

      case EmptyStateType.noNetwork:
        return EmptyState(
          icon: '📡',
          title: 'No internet connection',
          subtitle:
              'Check your WiFi or mobile data connection and try again.',
          actionLabel: 'Retry',
          onAction: onRetry,
          isDark: isDarkMode,
          highContrast: isHighContrast,
        );

      case EmptyStateType.locationDenied:
        return EmptyState(
          icon: '📍',
          title: 'Location access required',
          subtitle:
              'We need your location to find nearby rides. Please enable location in your settings.',
          actionLabel: 'Open Settings',
          onAction: onAction,
          isDark: isDarkMode,
          highContrast: isHighContrast,
        );

      case EmptyStateType.noFavorites:
        return EmptyState(
          icon: '⭐',
          title: 'No favorite routes yet',
          subtitle:
              'Save your frequently used routes for quick access later.',
          actionLabel: 'Start Exploring',
          onAction: onAction,
          isDark: isDarkMode,
          highContrast: isHighContrast,
        );

      case EmptyStateType.noSearchResults:
        return EmptyState(
          icon: '🔍',
          title: 'No places found',
          subtitle: 'Try searching for a different location or spelling.',
          isDark: isDarkMode,
          highContrast: isHighContrast,
        );

      case EmptyStateType.noHistory:
        return EmptyState(
          icon: '📋',
          title: 'No ride history',
          subtitle:
              'Your completed rides and trip history will appear here.',
          actionLabel: 'Browse Rides',
          onAction: onAction,
          isDark: isDarkMode,
          highContrast: isHighContrast,
        );
    }
  }
}