import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background circles (similar to sign-up screen)
          Positioned(
            left: 260,
            top: 30,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            right: 200,
            top: 350,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            right: 260,
            bottom: -10,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 10,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF545454),
                    const Color(0xFF999999),
                    const Color(0xFFFFFFFF),
                  ],
                  stops: const [0.0, 0.0001, 0.0002, 0.976],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    decoration: BoxDecoration(
                      color: Color(0xB8F2F2F2),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        const Text(
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle with email
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'Please Enter the code we just sent to email\n'),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // OTP Input Fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _controllers[index].text.isEmpty
                                      ? const Color(0xFFE0E0E0)
                                      : const Color(0xFF1A1A1A),
                                  width: _controllers[index].text.isEmpty ? 1 : 2,
                                ),
                              ),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                  if (value.isNotEmpty && index < 3) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }

                                  // Auto-verify when all fields are filled
                                  if (index == 3 && value.isNotEmpty) {
                                    bool allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
                                    if (allFilled) {
                                      _handleVerification();
                                    }
                                  }
                                },
                                onTap: () {
                                  // Clear the field when tapped
                                  _controllers[index].clear();
                                  setState(() {});
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),

                        // Resend code section
                        if (!_canResend) ...[
                          Text(
                            'Didn\'t receive code?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Resend code in ${_resendTimer}s',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: _handleResendCode,
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                                children: [
                                  TextSpan(text: 'Didn\'t receive code? '),
                                  TextSpan(
                                    text: 'Resend code',
                                    style: TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerification() async {
    // Check if all fields are filled
    bool allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
    if (!allFilled) {
      _showSnackBar('Please enter all digits', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get the complete code
    String verificationCode = _controllers.map((controller) => controller.text).join();

    try {
      // Simulate verification process
      await Future.delayed(const Duration(seconds: 2));

      // Here you would typically verify the code with your backend
      // For now, we'll simulate success

      if (mounted) {
        // Navigate to homepage or next screen
        Navigator.pushReplacementNamed(context, '/homepage');
        // Or use: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomepageScreen()));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Verification failed. Please try again.', Colors.red);

        // Clear all fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        setState(() {});
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _handleResendCode() async {
    try {
      // Here you would typically resend the verification code
      // For now, we'll simulate the resend process

      _showSnackBar('Verification code sent successfully', Colors.green);
      _startResendTimer();

      // Clear all fields
      for (var controller in _controllers) {
        controller.clear();
      }
      setState(() {});
      _focusNodes[0].requestFocus();

    } catch (e) {
      _showSnackBar('Failed to resend code. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}