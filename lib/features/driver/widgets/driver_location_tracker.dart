import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/data_providers.dart';

class DriverLocationTracker extends ConsumerStatefulWidget {
  final String rideId;
  final String driverUid;

  const DriverLocationTracker({
    super.key,
    required this.rideId,
    required this.driverUid,
  });

  @override
  ConsumerState<DriverLocationTracker> createState() =>
      _DriverLocationTrackerState();
}

class _DriverLocationTrackerState extends ConsumerState<DriverLocationTracker> {
  bool _isTracking = false;

  @override
  Widget build(BuildContext context) {
    final locationService = ref.watch(locationServiceProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isTracking ? Icons.location_on : Icons.location_off,
                  color: _isTracking ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Tracking',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Switch(
                  value: _isTracking,
                  onChanged: (value) async {
                    if (value) {
                      // Start tracking
                      await locationService.startLocationTracking(
                        widget.rideId,
                        widget.driverUid,
                      );
                    } else {
                      // Stop tracking
                      await locationService.stopLocationTracking();
                    }
                    setState(() => _isTracking = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isTracking
                  ? 'Your location is being shared with riders in real-time'
                  : 'Enable location tracking to share your live location with riders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Stop tracking when widget is disposed
    ref.read(locationServiceProvider).stopLocationTracking();
    super.dispose();
  }
}
