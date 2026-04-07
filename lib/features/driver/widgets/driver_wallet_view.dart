import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/count_up_number.dart';
import '../../../shared/widgets/staggered_entrance.dart';

class DriverWalletView extends StatelessWidget {
  const DriverWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F4);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              
              // Balance Header Card
              _buildBalanceHeader(context, isDark),
              const SizedBox(height: 24),

              // Quick Stats
              _buildQuickStats(isDark),
              const SizedBox(height: 32),

              // Transaction List
              Text(
                'Recent Transactions',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildTransactionList(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CountUpNumber(
                  value: 12450.0,
                  prefix: '₹',
                  decimalPlaces: 0,
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                label: Text('Add Money', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Today",
            amount: "₹1,250",
            icon: Icons.today_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "This Week",
            amount: "₹8,900",
            icon: Icons.date_range_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () => context.pushNamed('withdraw'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.softElevation(
                      isDark: isDark,
                      highContrast: false,
                      tint: AppColors.primary,
                      strength: 0.85,
                    ),
                    border: Border.all(
                      color: AppColors.softStroke(
                        isDark: isDark,
                        highContrast: false,
                        tint: AppColors.primary,
                        strength: 1.1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        "Withdraw",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String amount, required IconData icon, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.85,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: false,
          ),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDark ? AppColors.textSecondaryDark : Colors.black54),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          Text(amount, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isDark) {
    return Column(
      children: [
        StaggeredEntrance(
          index: 0,
          child: _buildTransactionItem(
            date: 'Today',
            rideId: '#RX123',
            rider: 'Rahul',
            amount: '+₹45',
            status: 'Completed',
            isDark: isDark,
          ),
        ),
        StaggeredEntrance(
          index: 1,
          child: _buildTransactionItem(
            date: 'Yesterday',
            rideId: '#RX098',
            rider: 'Priya',
            amount: '+₹120',
            status: 'Completed',
            isDark: isDark,
          ),
        ),
        StaggeredEntrance(
          index: 2,
          child: _buildTransactionItem(
            date: 'Mar 29',
            rideId: 'Withdrawal',
            rider: 'Bank Account',
            amount: '-₹500',
            status: 'Processing',
            isDebit: true,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String date,
    required String rideId,
    required String rider,
    required String amount,
    required String status,
    bool isDebit = false,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softElevation(
          isDark: isDark,
          highContrast: false,
          strength: 0.85,
        ),
        border: Border.all(
          color: AppColors.softStroke(
            isDark: isDark,
            highContrast: false,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDebit
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward_rounded : Icons.south_west_rounded,
              color: isDebit ? Colors.red : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rider,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      amount,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDebit ? Colors.red : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$date • $rideId',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          status == 'Completed' ? Icons.check_circle_rounded : Icons.pending_rounded,
                          size: 14,
                          color: status == 'Completed' ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: status == 'Completed' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
