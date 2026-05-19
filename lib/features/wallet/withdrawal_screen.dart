import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  String _selectedMethod = 'UPI';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Withdraw Money', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Amount',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softElevation(
                  isDark: isDark,
                  highContrast: false,
                  strength: 0.8,
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
                  Text(
                    '₹',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Withdraw to',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _buildMethodTile(
              title: 'UPI ID',
              value: 'UPI',
              icon: Icons.qr_code_rounded,
              isSelected: _selectedMethod == 'UPI',
            ),
            const SizedBox(height: 12),
            _buildMethodTile(
              title: 'Bank Account',
              value: 'BANK',
              icon: Icons.account_balance_rounded,
              isSelected: _selectedMethod == 'BANK',
            ),
            const SizedBox(height: 24),
            if (_selectedMethod == 'UPI')
              TextField(
                controller: _upiController,
                decoration: InputDecoration(
                  labelText: 'Enter UPI ID',
                  hintText: 'username@bank',
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              )
            else
              Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Terms & Conditions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Withdrawals are processed securely via Razorpay.\n'
                    '• Standard processing time is up to 24 hours.\n'
                    '• Please ensure your UPI ID or Bank Details are correct.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Withdraw Money',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Available balance: ₹1,240.00', // This should be fetched from user state
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile({
    required String title,
    required String value,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05))
              : (isDark ? AppColors.surfaceDark : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softElevation(
            isDark: isDark,
            highContrast: false,
            tint: isSelected ? AppColors.primary : null,
            strength: isSelected ? 0.9 : 0.8,
          ),
          border: Border.all(
            color: isSelected
                ? AppColors.softStroke(
                    isDark: isDark,
                    highContrast: false,
                    tint: AppColors.primary,
                    strength: 1.1,
                  )
                : AppColors.softStroke(
                    isDark: isDark,
                    highContrast: false,
                  ),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _handleWithdraw() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final accountId = _selectedMethod == 'UPI' ? _upiController.text.trim() : 'dummy_bank_account';
    if (accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your ${_selectedMethod == 'UPI' ? 'UPI ID' : 'account details'}')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final httpsCallable = FirebaseFunctions.instance.httpsCallable('createRazorpayPayout');
      await httpsCallable.call({
        'amount': amount,
        'fundAccountId': accountId,
        'mode': _selectedMethod,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              Text(
                'Withdrawal Initiated',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your request for ₹$amountText has been successfully submitted. It will reflect in your account within 24 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop(); // Close dialog
                    context.pop(); // Go back to Wallet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Wallet'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process withdrawal: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
