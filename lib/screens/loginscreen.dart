import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController   = TextEditingController();
  final _api             = ApiService();

  bool    _otpSent = false;
  bool    _loading = false;
  String? _error;

  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toHome() => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()));

  Future<void> _handleGoogleLogin() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.loginGoogle('dev_google_token');
      if (data['access_token'] != null) {
        await _api.saveToken(data['access_token'] as String);
        _toHome();
      } else {
        setState(() =>
            _error = 'Google sign-in failed. Check server.');
      }
    } catch (_) {
      setState(() => _error = 'Google sign-in failed. Check server.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    if (_phoneController.text.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _api.sendOtp('+91${_phoneController.text}');
      setState(() => _otpSent = true);
    } catch (_) {
      setState(() => _error = 'Could not send OTP. Is the server running?');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.verifyOtp(
        '+91${_phoneController.text}',
        _otpController.text,
      );
      if (data['access_token'] != null) {
        await _api.saveToken(data['access_token'] as String);
        _toHome();
      } else {
        setState(() =>
            _error = data['detail']?.toString() ?? 'Invalid OTP');
      }
    } catch (_) {
      setState(() => _error = 'Verification failed. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2035),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // ── Logo ──────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.scale(
                  scale: 0.93 + _pulse.value * 0.07,
                  child: child,
                ),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3555),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: Colors.white70, size: 36),
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Bharat Problem Solver AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'One Photo. One Report. One Solution.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tamil  •  Hindi  •  Telugu  •  English',
                style: TextStyle(color: Colors.white30, fontSize: 11),
              ),

              const SizedBox(height: 40),

              // ── Login card ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF232B45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login with Mobile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Report civic issues in your area',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    if (!_otpSent)
                      _PhoneField(controller: _phoneController)
                    else
                      _OtpField(
                          controller: _otpCtrl,
                          phone: _phoneController.text),

                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFFF6B35), size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontSize: 12)),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : (_otpSent
                                ? _handleVerifyOtp
                                : _handleSendOtp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                _otpSent ? 'Verify OTP' : 'Send OTP',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _otpSent = false),
                          child: const Text(
                            'Change number',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: Divider(
                        color: Colors.white.withOpacity(0.08))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('or',
                      style:
                          TextStyle(color: Colors.white24, fontSize: 12)),
                ),
                Expanded(
                    child: Divider(
                        color: Colors.white.withOpacity(0.08))),
              ]),
              const SizedBox(height: 16),

              // ── Google login ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _handleGoogleLogin,
                  icon: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                      ),
                    ),
                    child: const Icon(Icons.g_mobiledata_rounded,
                        color: Colors.white, size: 18),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Empowering citizens to fix India',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore lint warning — using _otpController not _otpCtrl below
  TextEditingController get _otpCtrl => _otpController;
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        counterText: '',
        prefixText: '+91  ',
        prefixStyle: const TextStyle(
            color: Color(0xFFFF6B35), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: const Color(0xFF1A2035),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFFFF6B35), width: 1.5)),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final String phone;
  const _OtpField({required this.controller, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 12),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle: const TextStyle(
                color: Colors.white12, letterSpacing: 8),
            filled: true,
            fillColor: const Color(0xFF1A2035),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFFF6B35), width: 1.5)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'OTP sent to +91 $phone  •  Dev OTP: 123456',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
