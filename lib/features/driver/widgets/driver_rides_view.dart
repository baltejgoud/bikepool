import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/staggered_entrance.dart';

class DriverRidesView extends StatefulWidget {
  const DriverRidesView({super.key});

  @override
  State<DriverRidesView> createState() => _DriverRidesViewState();
}

class _DriverRidesViewState extends State<DriverRidesView> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'This Week', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F4);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              child: Text(
                'Ride History',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            
            // Filter Tabs
            _buildFilterTabs(isDark),
            const SizedBox(height: 16),

            // Rides List
            Expanded(
              child: _buildRidesList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary 
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.grey[300]!),
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRidesList(bool isDark) {
    // Mock Data
    final rides = [
      {'rider': 'Rahul', 'route': 'Ameerpet → Madhapur', 'amount': '₹45', 'time': '12min', 'rating': '4.8', 'status': 'Completed'},
      {'rider': 'Priya', 'route': 'JNTU → KPHB', 'amount': '₹120', 'time': '25min', 'rating': '5.0', 'status': 'Completed'},
      {'rider': 'Amit', 'route': 'Gachibowli → Secunderabad', 'amount': '₹200', 'time': '40min', 'rating': '4.9', 'status': 'Cancelled'},
    ];

    final filteredRides = _selectedFilter == 'All' 
        ? rides 
        : rides.where((r) => r['status'] == _selectedFilter || _selectedFilter == 'Today' || _selectedFilter == 'This Week').toList();

    if (filteredRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 64, color: isDark ? Colors.white24 : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No previous rides",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredRides.length,
      itemBuilder: (context, index) {
        final ride = filteredRides[index];
        return StaggeredEntrance(
          index: index,
          child: _RideHistoryCard(
            rider: ride['rider']!,
            route: ride['route']!,
            amount: ride['amount']!,
            time: ride['time']!,
            rating: ride['rating']!,
            status: ride['status']!,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _RideHistoryCard extends StatefulWidget {
  final String rider;
  final String route;
  final String amount;
  final String time;
  final String rating;
  final String status;
  final bool isDark;

  const _RideHistoryCard({
    required this.rider,
    required this.route,
    required this.amount,
    required this.time,
    required this.rating,
    required this.status,
    required this.isDark,
  });

  @override
  State<_RideHistoryCard> createState() => _RideHistoryCardState();
}

class _RideHistoryCardState extends State<_RideHistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isCancelled = widget.status == 'Cancelled';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softElevation(
          isDark: widget.isDark,
          highContrast: false,
          strength: 0.9,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: widget.isDark,
            highContrast: false,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Collapsed View)
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isCancelled ? Colors.red.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person_rounded, color: isCancelled ? Colors.red : AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.rider,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                widget.amount,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isCancelled ? Colors.red : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                widget.route,
                                style: GoogleFonts.inter(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.time,
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.blue[700], fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Expanded Details
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Map Preview Mock
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.black26 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=Hyderabad&zoom=11&size=400x150'),
                        fit: BoxFit.cover,
                        opacity: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Trip Route Summary",
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Earnings Split
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Base Fare", style: GoogleFonts.inter(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black54)),
                      Text("₹40.00", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Surge", style: GoogleFonts.inter(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black54)),
                      Text("₹5.00", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rating given", style: GoogleFonts.inter(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black54)),
                      Row(
                        children: [
                          Text(widget.rating, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        ],
                      )
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
