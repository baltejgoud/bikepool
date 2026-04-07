import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../profile/providers/profile_setup_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _phoneController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0D1F12), const Color(0xFF0D0D0D)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFFFFFFF)],
              ),
            ),
          ),
          // Green radial glow at top
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      // Logo & Brand
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.directions_bike_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'BikePool',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Share the\njourney.',
                        style: GoogleFonts.outfit(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color:
                              Theme.of(context).textTheme.displayLarge?.color,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Real-time bike & car pooling\nacross Hyderabad.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              height: 1.5,
                            ),
                      ),
                      const Spacer(),
                      // OTP logic or Google Login
                      if (!_otpSent) ...[
                        Text(
                          'Enter your mobile number',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            prefixText: '+91  ',
                            prefixStyle: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            hintText: '9876543210',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final phone = _phoneController.text.trim();
                                  if (phone.length != 10) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Enter a valid 10-digit mobile number'),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  try {
                                    final auth =
                                        ref.read(authRepositoryProvider);
                                    await auth.verifyPhone(
                                      phoneNumber: '+91$phone',
                                      disableAppVerificationForTesting:
                                          kDebugMode && kIsWeb,
                                      verificationCompleted:
                                          (PhoneAuthCredential
                                              credential) async {
                                        // Auto-resolution (often works on Android)
                                        await FirebaseAuth.instance
                                            .signInWithCredential(credential);
                                        if (context.mounted) {
                                          ref
                                              .read(
                                                  profileSetupProvider.notifier)
                                              .updatePhoneNumber(phone);
                                          context.goNamed('home');
                                        }
                                      },
                                      verificationFailed:
                                          (FirebaseAuthException e) {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Verification failed: ${e.message}')),
                                          );
                                        }
                                      },
                                      codeSent: (String verificationId,
                                          int? resendToken) {
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                            _verificationId = verificationId;
                                            _otpSent = true;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'OTP sent successfully!')),
                                          );
                                        }
                                      },
                                      codeAutoRetrievalTimeout:
                                          (String verificationId) {
                                        if (mounted) {
                                          _verificationId = verificationId;
                                        }
                                      },
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      setState(() => _isLoading = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Send OTP'),
                        ),
                      ] else ...[
                        Text(
                          'Enter OTP sent to +91 ${_phoneController.text}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(counterText: ''),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final code = _otpController.text.trim();
                                  final phone = _phoneController.text.trim();

                                  if (code.length != 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Enter the 6-digit OTP to continue'),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  try {
                                    final auth =
                                        ref.read(authRepositoryProvider);

                                    // Developer Bypass for testing (000000)
                                    if (code == '000000') {
                                      await auth.signInAnonymously();
                                      if (context.mounted) {
                                        ref
                                            .read(profileSetupProvider.notifier)
                                            .updatePhoneNumber(phone);
                                        context.goNamed('home');
                                      }
                                      return;
                                    }

                                    if (_verificationId != null) {
                                      final userCred = await auth.signInWithOTP(
                                        verificationId: _verificationId!,
                                        smsCode: code,
                                      );
                                      if (userCred != null && context.mounted) {
                                        ref
                                            .read(profileSetupProvider.notifier)
                                            .updatePhoneNumber(phone);
                                        context.goNamed('home');
                                      } else if (context.mounted) {
                                        setState(() => _isLoading = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Invalid OTP. Please try again.')),
                                        );
                                      }
                                    } else {
                                      setState(() => _isLoading = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Verification ID missing. Please resend OTP.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      setState(() => _isLoading = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Verify & Continue'),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _otpSent = false),
                            child: const Text(
                              'Change number',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms & Privacy Policy.',
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
