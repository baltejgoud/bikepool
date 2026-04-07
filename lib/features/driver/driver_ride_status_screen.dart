import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import 'providers/driver_ride_provider.dart';
import 'widgets/driver_location_tracker.dart';

class DriverRideStatusScreen extends ConsumerWidget {
  const DriverRideStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(driverRideProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title:
            Text('Ride Status', style: Theme.of(context).textTheme.titleLarge),
        leading: const AppBackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(rideState.status),
                          color: _getStatusColor(rideState.status),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getStatusText(rideState.status),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(rideState.status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRideDetails(rideState),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Location Tracking (only show when en route)
            if (rideState.status == DriverRideStatus.enRoute &&
                rideState.riderName != null)
            const DriverLocationTracker(
                rideId: 'mock_ride_id', // In real app, get from ride state
                driverUid: 'mock_driver_uid', // In real app, get from auth
              ),

            // Action Buttons
            _buildActionButtons(context, ref, rideState),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(DriverRideStatus status) {
    switch (status) {
      case DriverRideStatus.findingRiders:
        return Icons.search;
      case DriverRideStatus.accepted:
        return Icons.check_circle;
      case DriverRideStatus.enRoute:
        return Icons.directions_bike;
      case DriverRideStatus.completed:
        return Icons.done_all;
      default:
        return Icons.schedule;
    }
  }

  Color _getStatusColor(DriverRideStatus status) {
    switch (status) {
      case DriverRideStatus.findingRiders:
        return Colors.orange;
      case DriverRideStatus.accepted:
        return Colors.blue;
      case DriverRideStatus.enRoute:
        return Colors.green;
      case DriverRideStatus.completed:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(DriverRideStatus status) {
    switch (status) {
      case DriverRideStatus.findingRiders:
        return 'Finding Riders';
      case DriverRideStatus.accepted:
        return 'Rider Accepted';
      case DriverRideStatus.enRoute:
        return 'Ride in Progress';
      case DriverRideStatus.completed:
        return 'Ride Completed';
      default:
        return 'Ride Posted';
    }
  }

  Widget _buildRideDetails(DriverRideState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('From: ${state.from}', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text('To: ${state.to}', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text('Time: ${state.time}', style: const TextStyle(fontSize: 16)),
        if (state.price != null) ...[
          const SizedBox(height: 4),
          Text('Price: ₹${state.price}', style: const TextStyle(fontSize: 16)),
        ],
        if (state.riderName != null) ...[
          const SizedBox(height: 12),
          const Text('Rider:', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(state.riderName!, style: const TextStyle(fontSize: 16)),
          if (state.riderRating != null)
            Text('Rating: ${state.riderRating} ⭐',
                style: const TextStyle(fontSize: 14)),
        ],
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, DriverRideState state) {
    final notifier = ref.read(driverRideProvider.notifier);

    switch (state.status) {
      case DriverRideStatus.findingRiders:
        return ElevatedButton(
          onPressed: () async => await notifier.cancelRide(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Cancel Ride'),
        );

      case DriverRideStatus.accepted:
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => notifier.startRide(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Start Ride'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async => await notifier.cancelRide(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancel Ride'),
            ),
          ],
        );

      case DriverRideStatus.enRoute:
        return ElevatedButton(
          onPressed: () => notifier.updateStatus(DriverRideStatus.completed),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Complete Ride'),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
