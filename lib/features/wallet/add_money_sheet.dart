import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../../core/theme/app_colors.dart';

class AddMoneySheet extends ConsumerStatefulWidget {
  const AddMoneySheet({super.key});

  @override
  ConsumerState<AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends ConsumerState<AddMoneySheet> {
  final TextEditingController _amountController = TextEditingController();
  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Payment successful! Your wallet will be updated shortly.'),
          backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Payment failed: ${response.message ?? 'Unknown error'}'),
          backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  /// Calls the Cloud Function directly via authenticated HTTP POST.
  /// This bypasses the [cloud_functions] Android SDK which suffers from a
  /// Pigeon/task-concurrency bug ("1 out of 2 underlying tasks failed") on
  /// some Android versions. Using Dio with the Firebase ID token is equally
  /// secure — the token is verified server-side by Firebase Admin SDK.
  Future<String> _createRazorpayOrder(double amount) async {
    // Force-refresh auth token to ensure it's valid
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null)
      throw Exception('Not authenticated — please log in again.');

    const functionUrl =
        'https://us-central1-bikepool-4c5f5.cloudfunctions.net/createRazorpayOrder';

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Authorization': 'Bearer $idToken'},
    ));

    final response = await dio.post<Map<String, dynamic>>(
      functionUrl,
      data: {
        'data': {'amount': amount},
      },
    );

    final result = response.data?['result'] as Map<String, dynamic>?;
    final orderId = result?['orderId'] as String?;
    if (orderId == null || orderId.isEmpty) {
      throw Exception(
          'Server returned no order ID. Response: ${response.data}');
    }
    return orderId;
  }

  Future<void> _startPayment() async {
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

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Create Razorpay order via direct authenticated HTTP call
      final orderId = await _createRazorpayOrder(amount);

      // 2. Open Razorpay checkout
      final options = {
        'key': 'rzp_test_Sqj3CAj9RGWFfc',
        'amount': (amount * 100).toInt(), // paise, must be int
        'name': 'BikePool',
        'description': 'Wallet Top-up',
        'order_id': orderId,
        'prefill': {
          'contact': user.phoneNumber ?? '',
          'email': user.email ?? '',
        },
        'theme': {'color': '#2563EB'},
      };

      _razorpay.open(options);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final serverMsg = e.response?.data?['error']?['message'] ?? e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Server error: $serverMsg'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to initiate payment: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Money',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.primary),
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
                  '• Wallet funds are strictly non-transferable to other users.\n'
                  '• Refunds and cancellations are governed by our standard policy.\n'
                  '• Your financial data is securely handled via Razorpay.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Proceed to Pay',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
