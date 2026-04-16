import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_pill.dart';

class PlanRideSheet extends StatelessWidget {
  final String vehicleTitle;
  final IconData vehicleIcon;
  final Color vehicleColor;
  /// Real GPS origin — passed down from HomeScreen.
  /// Falls back to Hyderabad centre only when permissions are denied.
  final double? originLat;
  final double? originLng;

  const PlanRideSheet({
    super.key,
    required this.vehicleTitle,
    required this.vehicleIcon,
    required this.vehicleColor,
    this.originLat,
    this.originLng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle for bottom sheet (optional but good practice)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Plan your ride',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the row
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ride details card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          // Vertical trip indicator (circle and square)
                          Column(
                            children: [
                              const SizedBox(
                                  height:
                                      18), // Centers circle with first field
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: _AnimatedTripLine(),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(2)),
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      18), // Centers square with second field
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Trip locations field
                          Expanded(
                            child: Column(
                              children: [
                                // Pickup location field
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: '173, Road No. 16',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12),
                                    ),
                                  ),
                                ),
                                Divider(height: 16, color: Colors.grey[200]),

                                // Destination location field
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0),
                                  child: TextField(
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (value) {
                                      if (value.isNotEmpty) {
                                        Navigator.pop(context);
                                        context
                                            .goNamed('available-rides', extra: {
                                          'destination': value,
                                          'lat': 17.3850,
                                          'lng': 78.4867,
                                          'originLat': originLat,
                                          'originLng': originLng,
                                          'initialVehicleType': vehicleTitle,
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Where to?',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Add stop button
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded,
                                    size: 22, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 24),
                        AppPill(
                          label: vehicleTitle,
                          icon: vehicleIcon,
                          pillContext: AppPillContext.primary,
                          style: AppPillStyle.soft,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent / Suggested locations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildRecentLocationItem(
                    context: context,
                    distance: '3.4 km',
                    title: '17, Golnaka',
                    subtitle: 'Alwal, Secunderabad, Hyderabad, Telangana',
                  ),
                  const SizedBox(height: 16),
                  _buildRecentLocationItem(
                    context: context,
                    distance: '3.2 km',
                    title: 'Suchitra',
                    subtitle: 'Alwal, Secunderabad, Telangana',
                  ),
                  const SizedBox(height: 16),
                  _buildRecentLocationItem(
                    context: context,
                    distance: '700 m',
                    title: 'Punya Residency',
                    subtitle:
                        'Father Balaiah Nagar, Alwal, Secunderabad, Telan...',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey[200], height: 1),
            ),
            const SizedBox(height: 16),

            // Extra Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildOptionItem(
                    icon: Icons.location_on_outlined,
                    title: 'Set location on map',
                  ),
                  const SizedBox(height: 16),
                  _buildOptionItem(
                    icon: Icons.star_border_rounded,
                    title: 'Saved places',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRecentLocationItem({
    required BuildContext context,
    required String distance,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.goNamed('available-rides', extra: {
          'destination': '$title, $subtitle',
          'lat': 17.3850,
          'lng': 78.4867,
          'originLat': originLat,
          'originLng': originLng,
          'initialVehicleType': vehicleTitle,
        });
      },
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 20, color: Colors.black54),
                const SizedBox(height: 4),
                Text(
                  distance,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTripLine extends StatefulWidget {
  @override
  State<_AnimatedTripLine> createState() => _AnimatedTripLineState();
}

class _AnimatedTripLineState extends State<_AnimatedTripLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(1.5, double.infinity),
          painter: _TripLinePainter(_animation.value),
        );
      },
    );
  }
}

class _TripLinePainter extends CustomPainter {
  final double progress;

  _TripLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const startY = 4.0;
    final endY = size.height - 4.0;
    final currentEndY = startY + (endY - startY) * progress;

    canvas.drawLine(
      Offset(size.width / 2, startY),
      Offset(size.width / 2, currentEndY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TripLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
